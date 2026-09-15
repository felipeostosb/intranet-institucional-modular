-- ==============================================================================
-- 🗄️ ESQUEMA SOBERANO: mod02 (Control de Asistencia Institucional - IESTP Argentina)
-- Arquitectura: Monolito Modular Desacoplado (.NET 10 + PostgreSQL 16 LTS)
-- Normativa: MPA 2024-2026 (R.D. 109), Ley 30512, RVM 277-2019 y RVM 177-2021 MINEDU
-- ==============================================================================

-- 1. CONFIGURACIÓN INSTITUCIONAL DE ASISTENCIA Y CALENDARIO
CREATE TABLE IF NOT EXISTS mod02.configuracion (
    id SERIAL PRIMARY KEY,
    limite_porcentaje_dpi NUMERIC(5,2) NOT NULL DEFAULT 30.00, -- 30% inasistencias = DPI (Nota 00)
    minutos_tolerancia_tardanza INT NOT NULL DEFAULT 15,
    tardanzas_por_falta INT NOT NULL DEFAULT 3,
    dias_limite_justificacion INT NOT NULL DEFAULT 3, -- 72 horas hábiles
    total_semanas_regulares INT NOT NULL DEFAULT 17, -- Semanas 1 a 17: Clases regulares y evaluaciones
    semana_recuperacion INT NOT NULL DEFAULT 18,    -- Semana 18: Evaluación Extraordinaria / Subsanación
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO mod02.configuracion (id, limite_porcentaje_dpi, minutos_tolerancia_tardanza, tardanzas_por_falta, dias_limite_justificacion, total_semanas_regulares, semana_recuperacion)
VALUES (1, 30.00, 15, 3, 3, 17, 18)
ON CONFLICT (id) DO UPDATE SET
    limite_porcentaje_dpi = EXCLUDED.limite_porcentaje_dpi,
    total_semanas_regulares = EXCLUDED.total_semanas_regulares,
    semana_recuperacion = EXCLUDED.semana_recuperacion;

-- 2. ESTRUCTURA DE CLASES ASIGNADAS AL DOCENTE (Unidad Didáctica + Turno + Sección + Aula)
CREATE TABLE IF NOT EXISTS mod02.clases_docente (
    id SERIAL PRIMARY KEY,
    unidad_didactica_id INT NOT NULL REFERENCES core.unidades_didacticas(id) ON DELETE RESTRICT,
    docente_id INT NOT NULL REFERENCES core.docentes(id) ON DELETE RESTRICT,
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    carrera_id INT NOT NULL REFERENCES core.carreras(id) ON DELETE RESTRICT,
    ciclo VARCHAR(5) NOT NULL CHECK (ciclo IN ('I', 'II', 'III', 'IV', 'V', 'VI')),
    turno VARCHAR(10) NOT NULL DEFAULT 'Noche' CHECK (turno IN ('Manana', 'Tarde', 'Noche')),
    seccion VARCHAR(5) NOT NULL DEFAULT 'A',
    aula_id INT NULL REFERENCES core.aulas(id) ON DELETE SET NULL,
    total_sesiones_semanales INT NOT NULL DEFAULT 1,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    creada_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_clase_ud_docente_periodo UNIQUE (unidad_didactica_id, docente_id, periodo_id, turno, seccion)
);

-- 3. HORARIOS PROGRAMADOS DE CADA CLASE (Día y Horas de cada sesión semanal)
CREATE TABLE IF NOT EXISTS mod02.clase_horarios (
    id SERIAL PRIMARY KEY,
    clase_docente_id INT NOT NULL REFERENCES mod02.clases_docente(id) ON DELETE CASCADE,
    dia_semana INT NOT NULL CHECK (dia_semana BETWEEN 1 AND 6), -- 1=Lunes, 2=Martes, 3=Miércoles, 4=Jueves, 5=Viernes, 6=Sábado
    numero_sesion_dia INT NOT NULL DEFAULT 1,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    horas_pedagogicas INT NOT NULL DEFAULT 2,
    aula_id INT NULL REFERENCES core.aulas(id) ON DELETE SET NULL
);

-- 4. SESIONES DE CLASE FÍSICAS (Instancias de cada clase dictada semana a semana 1..18)
CREATE TABLE IF NOT EXISTS mod02.sesiones_clase (
    id SERIAL PRIMARY KEY,
    clase_docente_id INT NULL REFERENCES mod02.clases_docente(id) ON DELETE SET NULL,
    unidad_didactica_id INT NOT NULL REFERENCES core.unidades_didacticas(id) ON DELETE RESTRICT,
    docente_id INT NOT NULL REFERENCES core.docentes(id) ON DELETE RESTRICT,
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    aula_id INT NULL REFERENCES core.aulas(id) ON DELETE SET NULL,
    fecha_clase DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    horas_pedagogicas INT NOT NULL DEFAULT 2,
    numero_semana INT NOT NULL DEFAULT 1 CHECK (numero_semana BETWEEN 1 AND 18),
    numero_sesion INT NOT NULL DEFAULT 1, -- Sesión 1, 2 dentro de la misma semana
    es_semana_recuperacion BOOLEAN NOT NULL DEFAULT FALSE,
    tema_desarrollado VARCHAR(255) NULL,
    observaciones_docente TEXT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'ABIERTA' CHECK (estado IN ('PROGRAMADA', 'ABIERTA', 'CERRADA', 'CANCELADA')),
    cerrada_en TIMESTAMP WITH TIME ZONE NULL,
    creada_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_sesion_ud_fecha_hora UNIQUE (unidad_didactica_id, docente_id, fecha_clase, hora_inicio)
);

-- 5. REGISTROS INDIVIDUALES DE ASISTENCIA POR ALUMNO EN LA SESIÓN
CREATE TABLE IF NOT EXISTS mod02.asistencias (
    id SERIAL PRIMARY KEY,
    sesion_clase_id INT NOT NULL REFERENCES mod02.sesiones_clase(id) ON DELETE CASCADE,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id) ON DELETE RESTRICT,
    estado VARCHAR(25) NOT NULL DEFAULT 'PRESENTE' CHECK (estado IN ('PRESENTE', 'TARDANZA', 'FALTA_INJUSTIFICADA', 'FALTA_JUSTIFICADA')),
    minutos_tardanza INT NOT NULL DEFAULT 0,
    observacion VARCHAR(255) NULL,
    registrado_por_usuario_id INT NULL REFERENCES core.usuarios(id) ON DELETE SET NULL,
    registrado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    modificado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_asistencia_sesion_estudiante UNIQUE (sesion_clase_id, estudiante_id)
);

-- 6. JUSTIFICACIONES DE INASISTENCIA CON REGLAS FORMALES (72h Hábiles)
CREATE TABLE IF NOT EXISTS mod02.justificaciones (
    id SERIAL PRIMARY KEY,
    asistencia_id INT NOT NULL REFERENCES mod02.asistencias(id) ON DELETE CASCADE,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id) ON DELETE RESTRICT,
    motivo VARCHAR(50) NOT NULL CHECK (motivo IN ('Salud_Medica', 'Laboral', 'Tramite_Oficial', 'Fuerza_Mayor')),
    descripcion TEXT NOT NULL,
    documento_sustento_url VARCHAR(255) NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'APROBADA', 'RECHAZADA')),
    revisado_por_docente_id INT NULL REFERENCES core.docentes(id) ON DELETE SET NULL,
    respuesta_observacion TEXT NULL,
    fecha_solicitud TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMP WITH TIME ZONE NULL,
    CONSTRAINT uk_justificacion_asistencia UNIQUE (asistencia_id)
);

-- 7. VISTA INTELIGENTE DE RENDIMIENTO Y SEMÁFORO DPI MINEDU (Art. 8.8.1 MPA)
CREATE OR REPLACE VIEW mod02.v_resumen_asistencia_estudiante AS
WITH CalculoHoras AS (
    SELECT 
        a.estudiante_id,
        s.unidad_didactica_id,
        s.periodo_id,
        ud.nombre AS unidad_didactica_nombre,
        ud.codigo AS unidad_didactica_codigo,
        c.nombre AS carrera_nombre,
        e.ciclo_actual AS ciclo,
        e.turno AS turno,
        (ud.horas_semanales * 17) AS total_horas_semestre_regulares,
        (ud.horas_semanales * 18) AS total_horas_semestre_total,
        COUNT(CASE WHEN a.estado = 'PRESENTE' THEN 1 END) AS cant_presentes,
        COUNT(CASE WHEN a.estado = 'TARDANZA' THEN 1 END) AS cant_tardanzas,
        COUNT(CASE WHEN a.estado = 'FALTA_JUSTIFICADA' THEN 1 END) AS cant_faltas_justificadas,
        COUNT(CASE WHEN a.estado = 'FALTA_INJUSTIFICADA' THEN 1 END) AS cant_faltas_injustificadas,
        SUM(CASE WHEN a.estado = 'FALTA_INJUSTIFICADA' THEN s.horas_pedagogicas ELSE 0 END) AS horas_falta_injustificada,
        SUM(CASE WHEN a.estado = 'PRESENTE' THEN s.horas_pedagogicas ELSE 0 END) AS horas_asistidas,
        COUNT(a.id) AS total_sesiones_registradas
    FROM mod02.asistencias a
    JOIN mod02.sesiones_clase s ON s.id = a.sesion_clase_id
    JOIN core.unidades_didacticas ud ON ud.id = s.unidad_didactica_id
    JOIN core.estudiantes e ON e.id = a.estudiante_id
    JOIN core.carreras c ON c.id = e.carrera_id
    GROUP BY a.estudiante_id, s.unidad_didactica_id, s.periodo_id, ud.nombre, ud.codigo, ud.horas_semanales, c.nombre, e.ciclo_actual, e.turno
)
SELECT 
    c.estudiante_id,
    c.unidad_didactica_id,
    c.periodo_id,
    c.unidad_didactica_nombre,
    c.unidad_didactica_codigo,
    c.carrera_nombre,
    c.ciclo,
    c.turno,
    c.total_horas_semestre_total AS total_horas_semestre,
    c.cant_presentes,
    c.cant_tardanzas,
    c.cant_faltas_justificadas,
    c.cant_faltas_injustificadas,
    c.horas_falta_injustificada,
    c.horas_asistidas,
    c.total_sesiones_registradas,
    ROUND((c.horas_falta_injustificada::numeric / NULLIF(c.total_horas_semestre_total, 0)) * 100, 2) AS porcentaje_inasistencia,
    CASE 
        WHEN (c.horas_falta_injustificada::numeric / NULLIF(c.total_horas_semestre_total, 0)) >= 0.30 THEN 'DPI'
        WHEN (c.horas_falta_injustificada::numeric / NULLIF(c.total_horas_semestre_total, 0)) >= 0.20 THEN 'RIESGO_ALTO'
        WHEN (c.horas_falta_injustificada::numeric / NULLIF(c.total_horas_semestre_total, 0)) >= 0.10 THEN 'ALERTA'
        ELSE 'REGULAR'
    END AS semaforo_estado,
    -- Horas máximas de inasistencia antes de caer en condición DPI (<30%)
    GREATEST(0, FLOOR(c.total_horas_semestre_total * 0.299) - c.horas_falta_injustificada) AS horas_falta_disponibles
FROM CalculoHoras c;

-- ==============================================================================
-- 🚀 DATOS SEMILLA MAESTROS: CLASES Y CALENDARIO DE 18 SEMANAS (2026-I)
-- ==============================================================================

-- 1. Clases Asignadas
INSERT INTO mod02.clases_docente (id, unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales)
VALUES 
(1, 4, 1, 1, 1, 'II', 'Noche', 'A', 1, 2), -- POO en C# (DSI - Ciclo II Noche)
(2, 5, 2, 1, 1, 'III', 'Noche', 'A', 2, 2), -- Desarrollo Web (DSI - Ciclo III Noche)
(3, 7, 1, 1, 2, 'I', 'Manana', 'A', 3, 1)   -- Contabilidad Básica (CONT - Ciclo I Mañana)
ON CONFLICT (id) DO UPDATE SET
    unidad_didactica_id = EXCLUDED.unidad_didactica_id,
    docente_id = EXCLUDED.docente_id,
    aula_id = EXCLUDED.aula_id;

SELECT setval('mod02.clases_docente_id_seq', (SELECT COALESCE(MAX(id), 1) FROM mod02.clases_docente));

-- 2. Horarios de las clases
INSERT INTO mod02.clase_horarios (id, clase_docente_id, dia_semana, numero_sesion_dia, hora_inicio, hora_fin, horas_pedagogicas, aula_id)
VALUES 
(1, 1, 1, 1, '18:30:00', '20:00:00', 2, 1), -- Lunes (2h)
(2, 1, 3, 2, '18:30:00', '21:30:00', 4, 1), -- Miércoles (4h)
(3, 2, 2, 1, '18:30:00', '21:30:00', 4, 2), -- Martes (4h)
(4, 3, 5, 1, '08:00:00', '12:30:00', 6, 3)  -- Viernes (6h)
ON CONFLICT (id) DO NOTHING;

SELECT setval('mod02.clase_horarios_id_seq', (SELECT COALESCE(MAX(id), 1) FROM mod02.clase_horarios));

-- 3. Generar Sesiones para las 18 Semanas del Periodo 2026-I (Clase 1: POO en C#)
-- Semana 1 a 3 (Cerradas con Asistencias registradas), Semana 4 (Abierta hoy), Semanas 5..17 (Programadas), Semana 18 (Recuperación)
INSERT INTO mod02.sesiones_clase (id, clase_docente_id, unidad_didactica_id, docente_id, periodo_id, aula_id, fecha_clase, hora_inicio, hora_fin, horas_pedagogicas, numero_semana, numero_sesion, es_semana_recuperacion, tema_desarrollado, estado, cerrada_en)
VALUES 
-- Sem 1: Lunes y Miércoles
(1, 1, 4, 1, 1, 1, '2026-03-16', '18:30:00', '20:00:00', 2, 1, 1, FALSE, 'Introducción a la plataforma .NET 10 y Sintaxis C#', 'CERRADA', '2026-03-16 20:05:00'),
(2, 1, 4, 1, 1, 1, '2026-03-18', '18:30:00', '21:30:00', 4, 1, 2, FALSE, 'Clases, Objetos, Encapsulamiento y Namespaces', 'CERRADA', '2026-03-18 21:35:00'),

-- Sem 2: Lunes y Miércoles
(3, 1, 4, 1, 1, 1, '2026-03-23', '18:30:00', '20:00:00', 2, 2, 1, FALSE, 'Herencia, Polimorfismo y Clases Abstractas', 'CERRADA', '2026-03-23 20:05:00'),
(4, 1, 4, 1, 1, 1, '2026-03-25', '18:30:00', '21:30:00', 4, 2, 2, FALSE, 'Interfaces y Principios de Diseño SOLID', 'CERRADA', '2026-03-25 21:35:00'),

-- Sem 3: Lunes y Miércoles
(5, 1, 4, 1, 1, 1, '2026-03-30', '18:30:00', '20:00:00', 2, 3, 1, FALSE, 'Colecciones Genéricas (List, Dictionary, HashSet)', 'CERRADA', '2026-03-30 20:05:00'),
(6, 1, 4, 1, 1, 1, '2026-04-01', '18:30:00', '21:30:00', 4, 3, 2, FALSE, 'LINQ y Expresiones Lambda en C# 13', 'CERRADA', '2026-04-01 21:35:00'),

-- Sem 4 (Sesión actual en curso para toma de asistencia)
(7, 1, 4, 1, 1, 1, CURRENT_DATE, '18:30:00', '21:30:00', 4, 4, 1, FALSE, 'Acceso a Datos de Alto Rendimiento con Dapper y PostgreSQL 16', 'ABIERTA', NULL),

-- Semanas 5 a 17 Programadas
(8, 1, 4, 1, 1, 1, CURRENT_DATE + INTERVAL '7 days', '18:30:00', '21:30:00', 4, 5, 1, FALSE, 'Manejo de Transacciones y Resiliencia en BD', 'PROGRAMADA', NULL),
(9, 1, 4, 1, 1, 1, CURRENT_DATE + INTERVAL '14 days', '18:30:00', '21:30:00', 4, 6, 1, FALSE, 'Arquitectura de Monolitos Modulares Desacoplados', 'PROGRAMADA', NULL),
(10, 1, 4, 1, 1, 1, CURRENT_DATE + INTERVAL '21 days', '18:30:00', '21:30:00', 4, 7, 1, FALSE, 'Inyección de Dependencias y Scoped Lifetimes', 'PROGRAMADA', NULL),
(11, 1, 4, 1, 1, 1, CURRENT_DATE + INTERVAL '28 days', '18:30:00', '21:30:00', 4, 8, 1, FALSE, 'Evaluación Parcial de Competencias (Indicador 1)', 'PROGRAMADA', NULL),

-- Semana 18 (Recuperación Oficial MINEDU)
(12, 1, 4, 1, 1, 1, CURRENT_DATE + INTERVAL '98 days', '18:30:00', '21:30:00', 4, 18, 1, TRUE, 'Semana 18: Evaluación Extraordinaria y Subsanación (Art. 8.8.4 MPA)', 'PROGRAMADA', NULL)
ON CONFLICT (id) DO NOTHING;

SELECT setval('mod02.sesiones_clase_id_seq', (SELECT COALESCE(MAX(id), 1) FROM mod02.sesiones_clase));

-- 4. Registros de Asistencia Histórica para Estudiantes Semilla
-- Estudiante 1 (Felipe Ostos - EST-DSI-2026-001): 100% Asistencia Regular
-- Estudiante 2 (Ana García - EST-DSI-2026-002): Regular con 1 tardanza
-- Estudiante 3 (Luis Torres - EST-CONT-2026-001): En Zona de Alerta / DPI con faltas

-- Sesión 1
INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
VALUES 
(1, 1, 'PRESENTE', 0, 'Puntual'),
(1, 2, 'PRESENTE', 0, 'Puntual'),
(1, 3, 'FALTA_INJUSTIFICADA', 0, 'No asistió')
ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;

-- Sesión 2
INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
VALUES 
(2, 1, 'PRESENTE', 0, 'Participó en laboratorio'),
(2, 2, 'TARDANZA', 12, 'Llegó 12 min tarde'),
(2, 3, 'FALTA_INJUSTIFICADA', 0, 'No asistió')
ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;

-- Sesión 3
INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
VALUES 
(3, 1, 'PRESENTE', 0, 'Puntual'),
(3, 2, 'PRESENTE', 0, 'Puntual'),
(3, 3, 'FALTA_JUSTIFICADA', 0, 'Descanso médico presentado')
ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;

-- Sesión 4
INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
VALUES 
(4, 1, 'PRESENTE', 0, 'Puntual'),
(4, 2, 'PRESENTE', 0, 'Puntual'),
(4, 3, 'FALTA_INJUSTIFICADA', 0, 'Falta')
ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;

-- Sesión 5
INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
VALUES 
(5, 1, 'PRESENTE', 0, 'Puntual'),
(5, 2, 'PRESENTE', 0, 'Puntual'),
(5, 3, 'FALTA_INJUSTIFICADA', 0, 'Falta acumulada')
ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;

-- Sesión 6
INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
VALUES 
(6, 1, 'PRESENTE', 0, 'Puntual'),
(6, 2, 'PRESENTE', 0, 'Puntual'),
(6, 3, 'FALTA_INJUSTIFICADA', 0, 'Falta acumulada')
ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;

-- Sesión 7 (Sesión Abierta de Hoy) - Por defecto todos PRESENTES
INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
VALUES 
(7, 1, 'PRESENTE', 0, 'Presente en aula'),
(7, 2, 'PRESENTE', 0, 'Presente en aula'),
(7, 3, 'PRESENTE', 0, 'Presente en aula')
ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;

-- 5. Justificación Semilla
INSERT INTO mod02.justificaciones (id, asistencia_id, estudiante_id, motivo, descripcion, estado, revisado_por_docente_id, respuesta_observacion, fecha_resolucion)
VALUES 
(1, (SELECT id FROM mod02.asistencias WHERE sesion_clase_id = 3 AND estudiante_id = 3 LIMIT 1), 3, 'Salud_Medica', 'Certificado médico oficial de EsSalud por cuadro de bronquitis aguda.', 'APROBADA', 1, 'Justificación médica validada conforme al plazo de 72h.', CURRENT_TIMESTAMP - INTERVAL '10 days')
ON CONFLICT (id) DO NOTHING;

SELECT setval('mod02.justificaciones_id_seq', (SELECT COALESCE(MAX(id), 1) FROM mod02.justificaciones));
