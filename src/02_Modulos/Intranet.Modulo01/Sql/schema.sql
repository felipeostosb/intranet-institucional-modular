-- ============================================================================
-- 🗄️ ESQUEMA SOBERANO mod01: MATRÍCULA, ADMISIÓN Y CARNÉS (Equipo 01 - Ismael)
-- Portado desde db_intranet_iestp local (schema 3.2.0) a las reglas del
-- proyecto: FKs INT al core de Felipe, catálogos propios dentro de mod01,
-- DDL idempotente (IF NOT EXISTS), snake_case, TIMESTAMPTZ.
-- Historia: diseño original del equipo 01, normalizado 3FN y verificado con
-- pruebas negativas (ver repo gestion-estudiantes-intranet).
-- ============================================================================

-- 1. Catálogo: tipos de matrícula (TUPA: ordinaria, extemporánea, traslados...)
CREATE TABLE IF NOT EXISTS mod01.tipos_matricula (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    recargo NUMERIC(5,2) NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Catálogo: turnos (M=Diurno, N=Nocturno) — catálogo propio del módulo
--    mientras core no lo adopte (decisión de arquitectura 2026-09-23)
CREATE TABLE IF NOT EXISTS mod01.turnos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(5) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL
);

-- 3. Catálogo: ciclos (I..VI) — catálogo propio del módulo
CREATE TABLE IF NOT EXISTS mod01.ciclos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(5) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL
);

-- 4. Vacantes ofertadas por semestre/carrera/turno (admisión)
CREATE TABLE IF NOT EXISTS mod01.vacantes (
    id SERIAL PRIMARY KEY,
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE CASCADE,
    carrera_id INT NOT NULL REFERENCES core.carreras(id) ON DELETE CASCADE,
    turno_id INT NOT NULL REFERENCES mod01.turnos(id) ON DELETE RESTRICT,
    ciclo_id INT NOT NULL REFERENCES mod01.ciclos(id) ON DELETE RESTRICT,
    vacantes INT NOT NULL DEFAULT 0 CHECK (vacantes >= 0),
    UNIQUE (periodo_id, carrera_id, turno_id, ciclo_id)
);

-- 5. Matrícula: el hecho central (la historia académica vive AQUÍ, no en
--    core.estudiantes — el ciclo cambia cada semestre, es dato de la matrícula)
CREATE TABLE IF NOT EXISTS mod01.matriculas (
    id SERIAL PRIMARY KEY,
    codigo_matricula VARCHAR(20) NOT NULL UNIQUE,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id) ON DELETE RESTRICT,
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    carrera_id INT NOT NULL REFERENCES core.carreras(id) ON DELETE RESTRICT,
    ciclo_id INT NOT NULL REFERENCES mod01.ciclos(id) ON DELETE RESTRICT,
    turno_id INT NOT NULL REFERENCES mod01.turnos(id) ON DELETE RESTRICT,
    tipo_matricula_id INT NOT NULL REFERENCES mod01.tipos_matricula(id) ON DELETE RESTRICT,
    -- dominios reales del diseño original del equipo 01 (verificados con
    -- pruebas negativas en el repo gestion-estudiantes-intranet)
    condicion VARCHAR(30) NOT NULL DEFAULT 'Ingresante' CHECK (condicion IN
        ('Ingresante','Promovido','Promovido con curso a cargo','Repitente',
         'Reingresante','Traslado')),
    estado VARCHAR(20) NOT NULL DEFAULT 'En trámite' CHECK (estado IN
        ('En trámite','Matriculado','Reservada','Anulada')),
    etapa VARCHAR(20) NOT NULL DEFAULT 'Validación' CHECK (etapa IN
        ('Validación','Conformidad','Cerrada')),
    voucher_ok BOOLEAN NOT NULL DEFAULT FALSE,
    foto_ok BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_conformidad DATE NULL,
    conforme_por INT NULL REFERENCES core.usuarios(id) ON DELETE SET NULL,
    fecha_matricula DATE NULL,
    observaciones_cursos TEXT NULL,
    turno_origen_id INT NULL REFERENCES mod01.turnos(id),
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- regla de negocio del diseño original: UNA matrícula vigente por
-- estudiante y periodo (las anuladas liberan la vacante)
CREATE UNIQUE INDEX IF NOT EXISTS uq_matricula_vigente
  ON mod01.matriculas (estudiante_id, periodo_id)
  WHERE estado <> 'Anulada';
CREATE INDEX IF NOT EXISTS idx_mat_estudiante ON mod01.matriculas (estudiante_id);
CREATE INDEX IF NOT EXISTS idx_mat_periodo ON mod01.matriculas (periodo_id);
CREATE INDEX IF NOT EXISTS idx_mat_carrera ON mod01.matriculas (carrera_id);

-- 6. Detalle: cursos (unidades didácticas) inscritos en la matrícula
CREATE TABLE IF NOT EXISTS mod01.detalles_matricula (
    id SERIAL PRIMARY KEY,
    matricula_id INT NOT NULL REFERENCES mod01.matriculas(id) ON DELETE CASCADE,
    unidad_didactica_id INT NOT NULL REFERENCES core.unidades_didacticas(id) ON DELETE RESTRICT,
    estado VARCHAR(20) NOT NULL DEFAULT 'Inscrito' CHECK (estado IN ('Inscrito','Retirado','Convalidado'))
);
CREATE INDEX IF NOT EXISTS idx_detmat_matricula ON mod01.detalles_matricula (matricula_id);

-- 7. Carné universitario: el trámite de carnetización (cruce con mod09:
--    se genera cuando el trámite TUPA de carné es aprobado)
CREATE TABLE IF NOT EXISTS mod01.carnes (
    id SERIAL PRIMARY KEY,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id) ON DELETE RESTRICT,
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    -- tramite_tupa: referencia débil al código de trámite de mod09 (sin FK
    -- cruzada inter-módulo: soberanía. El evento/código mantiene el enlace)
    tramite_tupa VARCHAR(20) NULL,
    estado_foto VARCHAR(20) NOT NULL DEFAULT 'Pendiente' CHECK (estado_foto IN ('Pendiente','Aprobada','Rechazada')),
    entregado BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_entrega DATE NULL,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_carnes_estudiante ON mod01.carnes (estudiante_id);

-- ============================================================================
-- SEMILLA (catálogos del TUPA real del instituto)
-- ============================================================================
INSERT INTO mod01.tipos_matricula (codigo, nombre, recargo) VALUES
  ('TM1','Ordinaria',0), ('TM2','Extemporánea',0.20), ('TM3','Extraordinaria',0.50),
  ('TM4','Traslado Interno',0), ('TM5','Traslado Externo',0), ('TM6','Reserva',0)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO mod01.turnos (codigo, nombre) VALUES ('M','Diurno'),('N','Nocturno')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO mod01.ciclos (codigo, nombre) VALUES
  ('I','Ciclo I'),('II','Ciclo II'),('III','Ciclo III'),
  ('IV','Ciclo IV'),('V','Ciclo V'),('VI','Ciclo VI')
ON CONFLICT (codigo) DO NOTHING;

-- vacantes por carril (carrera × turno × ciclo) del periodo activo 2026-I (id 2).
-- Cupos oficiales del IESTP Argentina; se consumen al registrar la conformidad.
INSERT INTO mod01.vacantes (periodo_id, carrera_id, turno_id, ciclo_id, vacantes)
SELECT 2, c.id, t.id, ci.id,
       CASE WHEN c.codigo = 'DSI' THEN 24 WHEN c.codigo = 'CONT' THEN 30 ELSE 28 END
FROM core.carreras c
CROSS JOIN mod01.turnos t
CROSS JOIN mod01.ciclos ci
WHERE t.codigo IN ('M','N') AND ci.codigo IN ('I','II','III')
ON CONFLICT (periodo_id, carrera_id, turno_id, ciclo_id) DO NOTHING;
