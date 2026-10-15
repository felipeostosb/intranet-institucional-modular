-- ==============================================================================
-- 🏛️ ESQUEMA MAESTRO CORE - INTRANET INSTITUCIONAL IESTP "ARGENTINA"
-- Patrón: Party-Role (Martin Fowler / GibbonEdu) + Bounded Contexts
-- Base de Datos: db_intranet_iestp (PostgreSQL 16 LTS)
-- Esquema: core
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS core;

-- 1. IDENTIDAD FÍSICA UNIFICADA
CREATE TABLE IF NOT EXISTS core.personas (
    id SERIAL PRIMARY KEY,
    dni VARCHAR(15) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NULL,
    sexo VARCHAR(10) NOT NULL DEFAULT 'M' CHECK (sexo IN ('M', 'F', 'Otro')),
    email_personal VARCHAR(150) NULL,
    telefono VARCHAR(20) NULL,
    direccion VARCHAR(255) NULL,
    foto_url VARCHAR(255) NULL,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. CUENTAS DE ACCESO (SSO INSTITUCIONAL)
CREATE TABLE IF NOT EXISTS core.usuarios (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL UNIQUE REFERENCES core.personas(id) ON DELETE CASCADE,
    codigo_institucional VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL DEFAULT '123456',
    ultimo_acceso TIMESTAMP WITH TIME ZONE NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. ROLES INSTITUCIONALES
CREATE TABLE IF NOT EXISTS core.roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200) NOT NULL
);

-- 4. USUARIO - ROLES
CREATE TABLE IF NOT EXISTS core.usuario_roles (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE CASCADE,
    rol_id INT NOT NULL REFERENCES core.roles(id) ON DELETE CASCADE,
    asignado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    es_activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uk_usuario_rol UNIQUE (usuario_id, rol_id)
);

-- 5. ESTRUCTURA ACADÉMICA
CREATE TABLE IF NOT EXISTS core.carreras (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(15) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    total_semestres INT NOT NULL DEFAULT 6,
    modalidad VARCHAR(20) NOT NULL DEFAULT 'Presencial' CHECK (modalidad IN ('Presencial', 'Semipresencial', 'Dual')),
    estado BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS core.periodos_academicos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    es_activo BOOLEAN NOT NULL DEFAULT FALSE,
    permite_matricula BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS core.aulas (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    pabellon VARCHAR(50) NOT NULL,
    aforo INT NOT NULL DEFAULT 35,
    tipo VARCHAR(30) NOT NULL DEFAULT 'Teoria' CHECK (tipo IN ('Teoria', 'Laboratorio_Computo', 'Taller'))
);

CREATE TABLE IF NOT EXISTS core.unidades_didacticas (
    id SERIAL PRIMARY KEY,
    carrera_id INT NOT NULL REFERENCES core.carreras(id) ON DELETE RESTRICT,
    ciclo VARCHAR(5) NOT NULL CHECK (ciclo IN ('I', 'II', 'III', 'IV', 'V', 'VI')),
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    creditos INT NOT NULL DEFAULT 3,
    horas_semanales INT NOT NULL DEFAULT 4,
    tipo VARCHAR(30) NOT NULL DEFAULT 'Formativa' CHECK (tipo IN ('Formativa', 'Transversal', 'Empleabilidad'))
);

-- 6. PERFILES DE ROL EXTENDIDOS
CREATE TABLE IF NOT EXISTS core.estudiantes (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE CASCADE,
    codigo_estudiante VARCHAR(30) NOT NULL UNIQUE,
    carrera_id INT NOT NULL REFERENCES core.carreras(id) ON DELETE RESTRICT,
    periodo_ingreso_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    ciclo_actual VARCHAR(5) NOT NULL DEFAULT 'I' CHECK (ciclo_actual IN ('I', 'II', 'III', 'IV', 'V', 'VI')),
    turno VARCHAR(10) NOT NULL DEFAULT 'Manana' CHECK (turno IN ('Manana', 'Tarde', 'Noche')),
    seccion VARCHAR(5) NOT NULL DEFAULT 'A',
    condicion VARCHAR(15) NOT NULL DEFAULT 'Regular' CHECK (condicion IN ('Regular', 'Irregular', 'Egresado', 'Titulado')),
    CONSTRAINT estudiantes_persona_id_key UNIQUE (persona_id)
);

CREATE TABLE IF NOT EXISTS core.docentes (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE CASCADE,
    codigo_docente VARCHAR(30) NOT NULL UNIQUE,
    carrera_principal_id INT NULL REFERENCES core.carreras(id) ON DELETE SET NULL,
    profesion VARCHAR(150) NOT NULL,
    grado_academico VARCHAR(100) NOT NULL DEFAULT 'Licenciado / Ingeniero',
    condicion VARCHAR(15) NOT NULL DEFAULT 'Contratado' CHECK (condicion IN ('Nombrado', 'Contratado')),
    CONSTRAINT docentes_persona_id_key UNIQUE (persona_id)
);

CREATE TABLE IF NOT EXISTS core.administrativos (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE CASCADE,
    codigo_staff VARCHAR(30) NOT NULL UNIQUE,
    cargo VARCHAR(100) NOT NULL,
    area VARCHAR(100) NOT NULL
);

-- 7. AUDITORÍA GLOBAL Y TELEMETRÍA CDC (Change Data Capture)
CREATE TABLE IF NOT EXISTS core.auditoria_logs (
    id BIGSERIAL PRIMARY KEY,
    usuario_id INT NULL REFERENCES core.usuarios(id) ON DELETE SET NULL,
    db_user VARCHAR(60) NOT NULL DEFAULT SESSION_USER,
    modulo VARCHAR(50) NOT NULL,          -- mod00..mod09, core
    entidad VARCHAR(80) NOT NULL,         -- tabla afectada
    accion VARCHAR(20) NOT NULL,          -- INSERT, UPDATE, DELETE, TRUNCATE
    registro_id VARCHAR(50) NULL,         -- ID de la fila afectada
    datos_anteriores JSONB NULL,          -- Estado antes del cambio (UPDATE/DELETE)
    datos_nuevos JSONB NULL,              -- Estado nuevo (INSERT/UPDATE)
    campos_modificados JSONB NULL,        -- Diff exacto campo por campo
    ip_origen VARCHAR(45) NULL,
    fecha TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_modulo_fecha ON core.auditoria_logs (modulo, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_audit_entidad ON core.auditoria_logs (entidad);
CREATE INDEX IF NOT EXISTS idx_audit_db_user ON core.auditoria_logs (db_user);

-- Función Trigger Universal CDC
CREATE OR REPLACE FUNCTION core.fn_audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_old_data JSONB := NULL;
    v_new_data JSONB := NULL;
    v_diff_data JSONB := '{}'::JSONB;
    v_record_id VARCHAR(50) := NULL;
    v_key TEXT;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_old_data := to_jsonb(OLD);
        IF (v_old_data ? 'id') THEN
            v_record_id := v_old_data->>'id';
        END IF;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := to_jsonb(NEW);
        IF (v_new_data ? 'id') THEN
            v_record_id := v_new_data->>'id';
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN
        v_old_data := to_jsonb(OLD);
        v_new_data := to_jsonb(NEW);
        IF (v_new_data ? 'id') THEN
            v_record_id := v_new_data->>'id';
        END IF;
        
        -- Calcular DIFF
        FOR v_key IN SELECT jsonb_object_keys(v_new_data) LOOP
            IF (v_old_data->v_key IS DISTINCT FROM v_new_data->v_key) THEN
                v_diff_data := v_diff_data || jsonb_build_object(
                    v_key, jsonb_build_object('antes', v_old_data->v_key, 'despues', v_new_data->v_key)
                );
            END IF;
        END LOOP;
    END IF;

    INSERT INTO core.auditoria_logs (
        db_user,
        modulo,
        entidad,
        accion,
        registro_id,
        datos_anteriores,
        datos_nuevos,
        campos_modificados,
        ip_origen
    ) VALUES (
        SESSION_USER,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        v_record_id,
        v_old_data,
        v_new_data,
        CASE WHEN TG_OP = 'UPDATE' THEN v_diff_data ELSE NULL END,
        inet_client_addr()::TEXT
    );

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Procedimiento para activar auditoría automática en un esquema
CREATE OR REPLACE FUNCTION core.fn_activar_auditoria_esquema(p_schema_name TEXT)
RETURNS VOID AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = p_schema_name 
          AND table_type = 'BASE TABLE'
          AND table_name != 'auditoria_logs'
    ) LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_%I ON %I.%I;', r.table_name, p_schema_name, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_audit_%I AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger();', 
                       r.table_name, p_schema_name, r.table_name);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 8. VISTAS DE TELEMETRÍA Y OBSERVABILIDAD
CREATE OR REPLACE VIEW core.v_telemetria_equipos AS
SELECT 
    t.schemaname AS esquema,
    CASE t.schemaname
        WHEN 'core'  THEN '🌐 Core: Arquitectura Central & SSO'
        WHEN 'mod00' THEN '🛡️ Equipo 00: Seguridad & Login (Toro/Felipe)'
        WHEN 'mod01' THEN '📝 Equipo 01: Matrícula & Admisión (Ismael)'
        WHEN 'mod02' THEN '📅 Equipo 02: Asistencia & DPI (Sheyla)'
        WHEN 'mod03' THEN '📦 Equipo 03: Inventario & Equipos (Brenda)'
        WHEN 'mod04' THEN '📦 Equipo 04: Módulo 04 (Morales)'
        WHEN 'mod05' THEN '🛠️ Equipo 05: Incidencias TI (Oliva)'
        WHEN 'mod06' THEN '🎓 Equipo 06: Egresados & Titulación (Sandra/Max)'
        WHEN 'mod07' THEN '📊 Equipo 07: Calidad Docente & Encuestas (Brayan)'
        WHEN 'mod08' THEN '🔐 Equipo 08: Roles & Seguridad Extendida (Toro)'
        WHEN 'mod09' THEN '💳 Equipo 09: Tesorería & Pagos TUPA (Vargas/Ismael)'
        ELSE t.schemaname
    END AS equipo_asignado,
    COUNT(t.relname) AS total_tablas,
    COALESCE(SUM(t.n_live_tup), 0) AS registros_actuales,
    COALESCE(SUM(t.n_tup_ins), 0) AS total_inserts_historicos,
    COALESCE(SUM(t.n_tup_upd), 0) AS total_updates_historicos,
    COALESCE(SUM(t.n_tup_del), 0) AS total_deletes_historicos,
    pg_size_pretty(SUM(pg_total_relation_size(quote_ident(t.schemaname) || '.' || quote_ident(t.relname)))) AS peso_en_disco,
    CASE 
        WHEN SUM(t.n_tup_ins) > 50 THEN '🟢 ALTA ACTIVIDAD'
        WHEN SUM(t.n_tup_ins) > 0  THEN '🟡 ACTIVIDAD INICIAL'
        ELSE '⚪ SIN ACTIVIDAD REGISTRADA'
    END AS semaforo_avance
FROM pg_stat_user_tables t
WHERE t.schemaname LIKE 'mod%' OR t.schemaname = 'core'
GROUP BY t.schemaname
ORDER BY t.schemaname;

CREATE OR REPLACE VIEW core.v_telemetria_tablas_detalle AS
SELECT 
    t.schemaname AS esquema,
    t.relname AS tabla,
    t.n_live_tup AS filas_estimadas,
    t.n_tup_ins AS inserciones,
    t.n_tup_upd AS modificaciones,
    t.n_tup_del AS eliminaciones,
    pg_size_pretty(pg_total_relation_size(t.relid)) AS tamano_tabla,
    t.seq_scan AS lecturas_completas,
    t.idx_scan AS lecturas_por_indice
FROM pg_stat_user_tables t
WHERE t.schemaname LIKE 'mod%' OR t.schemaname = 'core'
ORDER BY t.schemaname, t.n_tup_ins DESC;

CREATE OR REPLACE VIEW core.v_conexiones_en_vivo AS
SELECT 
    pid,
    usename AS usuario_db,
    client_addr AS ip_origen,
    application_name AS cliente_app,
    backend_start AS conexion_iniciada,
    state AS estado,
    query AS ultima_consulta_ejecutada,
    query_start AS hora_consulta
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid != pg_backend_pid()
ORDER BY query_start DESC NULLS LAST;

-- ==============================================================================
-- 🚀 DATOS SEMILLA OFICIALES - IESTP "ARGENTINA"
-- ==============================================================================

-- 1. Roles
INSERT INTO core.roles (id, nombre, descripcion) VALUES
(1, 'Admin', 'Administrador General del Sistema y TI'),
(2, 'Director', 'Dirección General Institucional'),
(3, 'Coordinador', 'Coordinación Académica de Área / Carrera'),
(4, 'Secretaria', 'Secretaría Académica y Trámites'),
(5, 'Tesoreria', 'Área de Tesorería, Facturación y Caja'),
(6, 'Docente', 'Plana Docente'),
(7, 'Alumno', 'Estudiante de Carrera Profesional'),
(8, 'Jefe Patrimonial', 'Jefatura Patrimonial de Almacén e Inventario (control total del inventario)'),
(9, 'Coordinador de Carrera', 'Coordinador de carrera: gestiona los bienes y ambientes de SU carrera'),
(10, 'OTIS', 'Oficina Técnica: mantenimiento, reparación y estado técnico de equipos'),
(11, 'Enfermeria', 'Tópico/Enfermería: atenciones médicas, historial clínico y botica'),
(12, 'Psicologia', 'Consultorio psicológico: citas, sesiones y expediente del alumno')
ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre, descripcion = EXCLUDED.descripcion;

SELECT setval('core.roles_id_seq', (SELECT MAX(id) FROM core.roles));

-- 2. Carreras (3 Oficiales)
INSERT INTO core.carreras (id, codigo, nombre, total_semestres, modalidad) VALUES
(1, 'DSI', 'Desarrollo de Sistemas de Información', 6, 'Presencial'),
(2, 'CONT', 'Contabilidad', 6, 'Presencial'),
(3, 'ADM', 'Administración de Empresas', 6, 'Presencial')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo, nombre = EXCLUDED.nombre;

SELECT setval('core.carreras_id_seq', (SELECT MAX(id) FROM core.carreras));

-- 3. Periodos Académicos
-- (2026-I ya cerrado; 2026-II activo en curso. Los 2025 son historia de los alumnos de ciclo III.)
INSERT INTO core.periodos_academicos (id, codigo, fecha_inicio, fecha_fin, es_activo, permite_matricula) VALUES
(1, '2026-I', '2026-03-15', '2026-07-25', FALSE, FALSE),
(2, '2026-II', '2026-08-15', '2026-12-20', TRUE, TRUE),
(3, '2025-I',  '2025-03-15', '2025-07-25', FALSE, FALSE),
(4, '2025-II', '2025-08-15', '2025-12-20', FALSE, FALSE)
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo;

SELECT setval('core.periodos_academicos_id_seq', (SELECT MAX(id) FROM core.periodos_academicos));

-- 4. Aulas y Laboratorios
INSERT INTO core.aulas (id, codigo, pabellon, aforo, tipo) VALUES
(1, 'LAB-COMP-01', 'Pabellon A', 35, 'Laboratorio_Computo'),
(2, 'LAB-COMP-02', 'Pabellon A', 35, 'Laboratorio_Computo'),
(3, 'AULA-TEO-101', 'Pabellon B', 40, 'Teoria'),
(4, 'AULA-TEO-102', 'Pabellon B', 40, 'Teoria')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo;

SELECT setval('core.aulas_id_seq', (SELECT MAX(id) FROM core.aulas));

-- 5. Unidades Didácticas — MALLA OFICIAL SI (Desarrollo de Sistemas de Información)
INSERT INTO core.unidades_didacticas (id, carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo) VALUES
-- 01 CICLO
(1,   1, 'I',  'SI-101', 'Fundamentos de Programación', 3, 4, 'Formativa'),
(2,   1, 'I',  'SI-102', 'Networking de Comunicación', 3, 4, 'Formativa'),
(18,  1, 'I',  'SI-103', 'Arquitectura y Componentes de Computadoras', 3, 4, 'Formativa'),
(19,  1, 'I',  'SI-104', 'Principios de Diseño Gráfico', 2, 3, 'Formativa'),
(20,  1, 'I',  'SI-105', 'Fundamentos de Interfaces Web Interactivas', 3, 4, 'Formativa'),
(100, 1, 'I',  'SI-106', 'Lógica Computacional', 2, 3, 'Transversal'),
(101, 1, 'I',  'SI-107', 'Comunicación Oral', 1, 2, 'Transversal'),
(102, 1, 'I',  'SI-108', 'Aplicaciones en Internet', 1, 2, 'Transversal'),
-- 02 CICLO
(3,   1, 'II', 'SI-201', 'Diseño y Configuración de Redes', 2, 3, 'Formativa'),
(21,  1, 'II', 'SI-202', 'Programación de Macros', 3, 4, 'Formativa'),
(22,  1, 'II', 'SI-203', 'Desarrollo de Interfaces Web Dinámicas', 2, 3, 'Formativa'),
(4,   1, 'II', 'SI-204', 'Lenguaje de Programación', 3, 4, 'Formativa'),
(23,  1, 'II', 'SI-205', 'Reparación de Equipos Tecnológicos', 3, 4, 'Formativa'),
(103, 1, 'II', 'SI-206', 'Herramientas para el Análisis de Datos', 2, 3, 'Formativa'),
(104, 1, 'II', 'SI-207', 'Interpretación y Producción de Textos', 2, 3, 'Transversal'),
(105, 1, 'II', 'SI-208', 'Ofimática', 2, 3, 'Transversal'),
(106, 1, 'II', 'SI-209', 'Experiencias Formativas en Situaciones Reales de Trabajo (EFSRT)', 4, 6, 'Formativa'),
-- 03 CICLO
(107, 1, 'III', 'SI-301', 'Automatización de Redes', 2, 3, 'Formativa'),
(6,   1, 'III', 'SI-302', 'Programación Orientada a Objetos', 4, 6, 'Formativa'),
(5,   1, 'III', 'SI-303', 'Programación del Lado del Servidor', 2, 3, 'Formativa'),
(24,  1, 'III', 'SI-304', 'Modelamiento de Bases de Datos', 3, 4, 'Formativa'),
(25,  1, 'III', 'SI-305', 'Diseño de Sistemas de Información', 2, 3, 'Formativa'),
(26,  1, 'III', 'SI-306', 'Programación en Lenguajes Relevantes', 3, 4, 'Formativa'),
(108, 1, 'III', 'SI-307', 'Inglés para la Comunicación Oral', 2, 3, 'Transversal'),
(109, 1, 'III', 'SI-308', 'Fundamentos de Innovación Tecnológica', 1, 2, 'Transversal'),
-- 04 CICLO
(110, 1, 'IV', 'SI-401', 'Marketing Digital y E-Commerce', 2, 3, 'Formativa'),
(111, 1, 'IV', 'SI-402', 'Desarrollo de Servicios Web Escalables', 3, 4, 'Formativa'),
(112, 1, 'IV', 'SI-403', 'Administración de Bases de Datos', 3, 4, 'Formativa'),
(113, 1, 'IV', 'SI-404', 'Metodologías Ágiles en Proyectos de TI', 3, 4, 'Formativa'),
(114, 1, 'IV', 'SI-405', 'Animación Gráfica', 2, 3, 'Formativa'),
(115, 1, 'IV', 'SI-406', 'Técnicas de Seguridad Cibernética', 2, 3, 'Formativa'),
(116, 1, 'IV', 'SI-407', 'Comprensión y Redacción en Inglés', 2, 3, 'Transversal'),
(117, 1, 'IV', 'SI-408', 'Innovación Tecnológica', 2, 3, 'Formativa'),
(118, 1, 'IV', 'SI-409', 'Experiencias Formativas en Situaciones Reales de Trabajo (EFSRT)', 4, 6, 'Formativa'),
-- 05 CICLO
(119, 1, 'V', 'SI-501', 'Administración de Servicios de TI', 2, 3, 'Formativa'),
(120, 1, 'V', 'SI-502', 'Desarrollo de Plataformas Móviles', 2, 3, 'Formativa'),
(121, 1, 'V', 'SI-503', 'Producción de Contenidos Multimedia', 3, 4, 'Formativa'),
(122, 1, 'V', 'SI-504', 'Herramientas para Business Intelligence', 2, 3, 'Formativa'),
(123, 1, 'V', 'SI-505', 'Bases de Datos NoSQL', 3, 4, 'Formativa'),
(124, 1, 'V', 'SI-506', 'Diseño de Integración de Tecnologías de la Información', 3, 4, 'Formativa'),
(125, 1, 'V', 'SI-507', 'Comportamiento Ético', 2, 3, 'Transversal'),
(126, 1, 'V', 'SI-508', 'Oportunidades de Negocios', 2, 3, 'Transversal'),
-- 06 CICLO
(127, 1, 'VI', 'SI-601', 'Desarrollo de Aplicaciones Móviles Empresariales', 2, 3, 'Formativa'),
(128, 1, 'VI', 'SI-602', 'Gestión de la Calidad de Software', 2, 3, 'Formativa'),
(129, 1, 'VI', 'SI-603', 'Inteligencia Artificial y Ciencia de Datos', 3, 4, 'Formativa'),
(130, 1, 'VI', 'SI-604', 'Big Data y Análisis de Datos', 3, 4, 'Formativa'),
(131, 1, 'VI', 'SI-605', 'Tecnologías Emergentes', 2, 3, 'Formativa'),
(132, 1, 'VI', 'SI-606', 'Desarrollo de Proyectos Tecnológicos Integrados', 3, 4, 'Formativa'),
(133, 1, 'VI', 'SI-607', 'Plan de Negocios', 2, 2, 'Transversal'),
(134, 1, 'VI', 'SI-608', 'Estrategias para la Solución de Problemas', 2, 2, 'Transversal'),
(135, 1, 'VI', 'SI-609', 'Experiencias Formativas en Situaciones Reales de Trabajo (EFSRT)', 4, 6, 'Formativa'),
-- Contabilidad (carrera 2, intacta)
(7, 2, 'I', 'CONT-101', 'Contabilidad Básica y Principios Contables', 4, 6, 'Formativa'),
(8, 2, 'I', 'CONT-102', 'Legislación Tributaria y Laboral', 3, 4, 'Transversal')
ON CONFLICT (id) DO UPDATE SET
    ciclo = EXCLUDED.ciclo, codigo = EXCLUDED.codigo, nombre = EXCLUDED.nombre,
    creditos = EXCLUDED.creditos, horas_semanales = EXCLUDED.horas_semanales, tipo = EXCLUDED.tipo;

SELECT setval('core.unidades_didacticas_id_seq', (SELECT MAX(id) FROM core.unidades_didacticas));

-- 6. Personas Físicas Semilla
-- NOTA: DNIs 10000001, 20000001, 30000001, 40000001, 10000003, 12345678, 87654321 son los usados
--       en los botones de acceso rápido del Login. Deben tener usuario con el mismo codigo_institucional.
INSERT INTO core.personas (id, dni, nombres, apellidos, email_personal, telefono, sexo) VALUES
(1,  '00000001', 'Administrador',    'General de TI',        'admin.ti@ieargentina.edu.pe',    '999000001', 'M'),
(2,  '10000001', 'Manuel',           'Alvarado Carranza',    'manuel.alvarado@gmail.com',      '999100001', 'M'),
(3,  '20000001', 'Carlos',           'Mendoza Rivas',        'carlos.mendoza@gmail.com',       '999200001', 'M'),
(4,  '30000001', 'Rosa',             'Morales Salazar',      'rosa.morales@gmail.com',         '999300001', 'F'),
(5,  '40000001', 'Elena',            'Ramos Palacios',       'elena.ramos@gmail.com',          '999400001', 'F'),
(6,  '12345678', 'Sheyla',           'Quispe Torres',        'sheyla.quispe@gmail.com',        '999123456', 'F'),
(7,  '87654321', 'Carlos Alberto',   'Mendoza Flores',       'cmendoza.est@gmail.com',         '999876543', 'M'),
(8,  '77654321', 'Ana',              'García Flores',        'ana.garcia@gmail.com',           '999776543', 'F'),
(9,  '66554433', 'Luis',             'Torres Quispe',        'luis.torres@gmail.com',          '999665544', 'M'),
(10, '10000003', 'Docente',          'Montero',              'montero@iestpargentina.edu.pe',  '999100003', 'M'),
(11, '47915633', 'Felipe Pedro Jose','Ostos Bermudez',       'fpedro.ostos@gmail.com',        '999479156', 'M'),
(12, '51000001', 'Jorge',            'Ramírez Salazar',      'jorge.ramirez@iestpargentina.edu.pe',  '999510001', 'M'),
(13, '51000002', 'María',            'Torres Vega',          'maria.torres@iestpargentina.edu.pe',   '999510002', 'F'),
(14, '51000003', 'Carlos',           'Huamán Ríos',          'carlos.huaman@iestpargentina.edu.pe', '999510003', 'M'),
(15, '51000004', 'Rosa',             'Vargas Muñoz',         'rosa.vargas@iestpargentina.edu.pe',   '999510004', 'F'),
(16, '51000005', 'Luis',             'Chávez Paredes',       'luis.chavez@iestpargentina.edu.pe',   '999510005', 'M'),
(17, '51000006', 'Lucía',            'Fernández Quispe',     'lucia.fernandez@iestpargentina.edu.pe', '999510006', 'F'),
(18, '51000007', 'Andrés',           'Salazar Morales',      'andres.salazar@iestpargentina.edu.pe',  '999510007', 'M')
ON CONFLICT (id) DO UPDATE SET dni = EXCLUDED.dni, nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

-- Asegurar que Montero y Felipe existan por DNI aunque los IDs difieran
INSERT INTO core.personas (dni, nombres, apellidos, email_personal, telefono, sexo) VALUES
('10000003', 'Docente',           'Montero',           'montero@iestpargentina.edu.pe', '999100003', 'M'),
('47915633', 'Felipe Pedro Jose', 'Ostos Bermudez',   'fpedro.ostos@gmail.com',        '999479156', 'M')
ON CONFLICT (dni) DO NOTHING;

SELECT setval('core.personas_id_seq', (SELECT MAX(id) FROM core.personas));

-- 7. Cuentas de Acceso (core.usuarios)
-- IMPORTANTE: codigo_institucional = DNI para que los botones del login rápido funcionen en producción
-- FIX 2026-10-07: la fila del Admin General de TI decía '10000001' (duplicado con el Director,
-- volaba el UNIQUE y abortaba TODO el batch de seeds en BD vírgenes). Alineado con producción
-- y con provision_postgresql_master.sql: 'ADMIN-2026'.
INSERT INTO core.usuarios (id, persona_id, codigo_institucional, email, password_hash, estado) VALUES
(1,  1,  'ADMIN-2026', 'admin.ti@ieargentina.edu.pe',         '123456', TRUE),
(2,  2,  '10000001', 'director@iestpargentina.edu.pe',      '123456', TRUE),
(3,  3,  '20000001', 'coordinacion@iestpargentina.edu.pe',  '123456', TRUE),
(4,  4,  '30000001', 'secretaria@iestpargentina.edu.pe',    '123456', TRUE),
(5,  5,  '40000001', 'tesoreria@iestpargentina.edu.pe',     '123456', TRUE),
(6,  6,  '12345678', 'sheyla.docente@iestpargentina.edu.pe','123456', TRUE),
(7,  7,  '87654321', 'mendoza@iestpargentina.edu.pe',       '123456', TRUE),
(8,  8,  'EST-DSI-002', 'ana.garcia@ieargentina.edu.pe',   '123456', TRUE),
(9,  9,  'EST-CONT-001','luis.torres@ieargentina.edu.pe',  '123456', TRUE),
(10, 10, '10000003', 'montero@iestpargentina.edu.pe',       '123456', TRUE),
(11, 11, '47915633', 'felipe.ostos@iestpargentina.edu.pe',  '123456', TRUE),
(12, 12, '51000001', 'jefe.general@iestpargentina.edu.pe',  '123456', TRUE),
(13, 13, '51000002', 'jefe.esp.dsi@iestpargentina.edu.pe',  '123456', TRUE),
(14, 14, '51000003', 'jefe.esp.cont@iestpargentina.edu.pe', '123456', TRUE),
(15, 15, '51000004', 'jefe.esp.adm@iestpargentina.edu.pe',   '123456', TRUE),
(16, 16, '51000005', 'otis@iestpargentina.edu.pe',           '123456', TRUE),
(17, 17, '51000006', 'enfermeria@iestpargentina.edu.pe',      '123456', TRUE),
(18, 18, '51000007', 'psicologia@iestpargentina.edu.pe',      '123456', TRUE)
ON CONFLICT (id) DO UPDATE SET
    codigo_institucional = EXCLUDED.codigo_institucional,
    email = EXCLUDED.email,
    password_hash = EXCLUDED.password_hash,
    estado = EXCLUDED.estado;

-- Asegurar que Montero exista por código aunque los IDs difieran
INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
SELECT p.id, '10000003', 'montero@iestpargentina.edu.pe', '123456', TRUE
FROM core.personas p WHERE p.dni = '10000003'
ON CONFLICT (codigo_institucional) DO UPDATE SET
    email = EXCLUDED.email, password_hash = EXCLUDED.password_hash, estado = EXCLUDED.estado;

-- Asegurar que Felipe exista por código
INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
SELECT p.id, '47915633', 'felipe.ostos@iestpargentina.edu.pe', '123456', TRUE
FROM core.personas p WHERE p.dni = '47915633'
ON CONFLICT (codigo_institucional) DO UPDATE SET
    email = EXCLUDED.email, password_hash = EXCLUDED.password_hash, estado = EXCLUDED.estado;

SELECT setval('core.usuarios_id_seq', (SELECT MAX(id) FROM core.usuarios));

-- 8. Asignación de Roles
INSERT INTO core.usuario_roles (id, usuario_id, rol_id) VALUES
(1,  1,  1),  -- Admin: Admin General
(2,  2,  2),  -- Director: 10000001
(3,  3,  3),  -- Coordinador: 20000001
(4,  4,  4),  -- Secretaria: 30000001
(5,  5,  5),  -- Tesoreria: 40000001
(6,  6,  6),  -- Docente: Sheyla 12345678
(7,  7,  7),  -- Alumno: Carlos Mendoza 87654321
(8,  8,  7),  -- Alumno: Ana García
(9,  9,  7),  -- Alumno: Luis Torres
(10, 10, 6),  -- Docente: Montero 10000003
(11, 11, 2),  -- Director: Felipe 47915633
(12, 11, 1),  -- Admin: Felipe
(13, 11, 6),  -- Docente: Felipe
(14, 11, 7),  -- Alumno: Felipe
(15, 11, 3),  -- Coordinador: Felipe
(16, 11, 4),  -- Secretaria: Felipe
(17, 11, 5),  -- Tesoreria: Felipe
(18, 12, 8),  -- Jefe Patrimonial: Jorge Ramírez 51000001
(19, 13, 9),  -- Coordinador de Carrera: María Torres (DSI) 51000002
(20, 14, 9),  -- Coordinador de Carrera: Carlos Huamán (CONT) 51000003
(21, 15, 9),  -- Coordinador de Carrera: Rosa Vargas (ADM) 51000004
(22, 16, 10),  -- OTIS: Luis Chávez 51000005
(23, 17, 11),  -- Enfermería: Lucía Fernández 51000006
(24, 18, 12)   -- Psicología: Andrés Salazar 51000007
ON CONFLICT (id) DO NOTHING;

-- Asegurar roles de Enfermería/Psicología por DNI (robusto contra ids diferentes en producción)
INSERT INTO core.usuario_roles (usuario_id, rol_id)
SELECT u.id, 11
FROM core.usuarios u
JOIN core.personas p ON p.id = u.persona_id
WHERE p.dni = '51000006'
ON CONFLICT DO NOTHING;

INSERT INTO core.usuario_roles (usuario_id, rol_id)
SELECT u.id, 12
FROM core.usuarios u
JOIN core.personas p ON p.id = u.persona_id
WHERE p.dni = '51000007'
ON CONFLICT DO NOTHING;

SELECT setval('core.usuario_roles_id_seq', (SELECT MAX(id) FROM core.usuario_roles));

-- Asegurar rol Docente para Montero (robusto contra id diferente en producción)
INSERT INTO core.usuario_roles (usuario_id, rol_id)
SELECT u.id, 6
FROM core.usuarios u
JOIN core.personas p ON p.id = u.persona_id
WHERE p.dni = '10000003'
ON CONFLICT DO NOTHING;

-- Asegurar todos los roles para Felipe
INSERT INTO core.usuario_roles (usuario_id, rol_id)
SELECT u.id, r.id
FROM core.usuarios u
JOIN core.personas p ON p.id = u.persona_id
CROSS JOIN core.roles r
WHERE p.dni = '47915633'
ON CONFLICT DO NOTHING;

SELECT setval('core.usuario_roles_id_seq', (SELECT MAX(id) FROM core.usuario_roles));

-- 9. Perfiles de Alumno
INSERT INTO core.estudiantes (id, persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion) VALUES
(1, 7, 'EST-DSI-2026-001', 1, 3, 'IV', 'Noche', 'Regular'),
(2, 8, 'EST-DSI-2026-002', 1, 3, 'IV', 'Manana', 'Regular'),
(3, 9, 'EST-CONT-2026-001', 2, 1, 'I', 'Noche', 'Regular')
ON CONFLICT (id) DO UPDATE SET codigo_estudiante = EXCLUDED.codigo_estudiante;

SELECT setval('core.estudiantes_id_seq', (SELECT MAX(id) FROM core.estudiantes));

-- 10. Perfiles de Docente
INSERT INTO core.docentes (id, persona_id, codigo_docente, carrera_principal_id, profesion, condicion) VALUES
(1, 6, 'DOC-001', 1, 'Licenciada en Educación', 'Nombrado'),
(2, 10, 'DOC-MONTERO', 1, 'Licenciado en Computación e Informática', 'Contratado')
ON CONFLICT (id) DO UPDATE SET codigo_docente = EXCLUDED.codigo_docente;

-- Asegurar perfil docente para Montero por DNI
INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
SELECT p.id, 'DOC-MONTERO', 1, 'Licenciado en Computación e Informática', 'Contratado'
FROM core.personas p WHERE p.dni = '10000003'
ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;

SELECT setval('core.docentes_id_seq', (SELECT MAX(id) FROM core.docentes));

-- 11. Perfiles Administrativos
INSERT INTO core.administrativos (id, persona_id, codigo_staff, cargo, area) VALUES
(1, 4, 'ADM-SEC-01', 'Secretaria Académica', 'Secretaría General'),
(2, 5, 'ADM-TES-01', 'Jefa de Caja y Tesorería', 'Tesorería'),
(3, 12, 'JEF-GRAL-01', 'Jefe Patrimonial de Almacén e Inventario', 'Almacén e Inventario'),
(4, 13, 'JEF-ESP-DSI', 'Coordinador de Carrera - DSI', 'Departamento Académico'),
(5, 14, 'JEF-ESP-CONT', 'Coordinador de Carrera - Contabilidad', 'Departamento Académico'),
(6, 15, 'JEF-ESP-ADM', 'Coordinador de Carrera - Administración', 'Departamento Académico'),
(7, 16, 'OTIS-01', 'Técnico OTIS', 'Oficina Técnica')
ON CONFLICT (id) DO UPDATE SET codigo_staff = EXCLUDED.codigo_staff;

SELECT setval('core.administrativos_id_seq', (SELECT MAX(id) FROM core.administrativos));
