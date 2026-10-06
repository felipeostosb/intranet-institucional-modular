-- ==============================================================================
-- 🗄️ ESQUEMA DE BASE DE DATOS: mod06 (Equipo 06) - PostgreSQL 16
-- ==============================================================================
-- Este archivo se ejecuta automáticamente al arrancar la aplicación.
-- Agrega aquí tus sentencias CREATE TABLE con IF NOT EXISTS para tu módulo.
-- Alineado al estado REAL de producción (2026-10-01): production drift fixed.
-- El CREATE TABLE IF NOT EXISTS no modifica tablas existentes, por lo que las
-- definiciones de aquí DEBEN coincidir con las de producción o el auto-runner
-- creará estructuras distintas a las reales en un entorno nuevo.
-- ==============================================================================

-- Registro genérico del módulo (provision del dueño)
CREATE SCHEMA IF NOT EXISTS mod06;

CREATE TABLE IF NOT EXISTS mod06.t_modulo06_registros (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

-- Catálogo TUPA del módulo 06 — estructura REAL de producción:
-- solo id, denominacion y activo (sin codigo/requisitos/costo del borrador).
CREATE TABLE IF NOT EXISTS mod06.tramites_tupa_06 (
    id SERIAL PRIMARY KEY,
    denominacion VARCHAR(200) NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

-- Expediente del egresado — estructura REAL de producción (sin observaciones).
CREATE TABLE IF NOT EXISTS mod06.expedientes_06 (
    id SERIAL PRIMARY KEY,
    numero_expediente VARCHAR(50) NOT NULL UNIQUE,
    solicitante_persona_id INT NOT NULL REFERENCES core.personas(id),
    tramite_tupa_id INT NOT NULL REFERENCES mod06.tramites_tupa_06(id),
    estado VARCHAR(50) NOT NULL DEFAULT 'Pendiente',
    fecha_ingreso TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seeds del catálogo TUPA (idempotentes, resueltos por denominación)
INSERT INTO mod06.tramites_tupa_06 (denominacion, activo)
SELECT v.denominacion, TRUE
FROM (VALUES
    ('Trámite documentario de egresado'),
    ('Certificado de estudios de egresado')
) AS v(denominacion)
WHERE NOT EXISTS (
    SELECT 1 FROM mod06.tramites_tupa_06 t WHERE t.denominacion = v.denominacion
);

-- Auditoría CDC (los triggers ya existen en producción; idempotente)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_tramites_tupa_06') THEN
        CREATE TRIGGER trg_audit_tramites_tupa_06 AFTER INSERT OR DELETE OR UPDATE ON mod06.tramites_tupa_06
            FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_expedientes_06') THEN
        CREATE TRIGGER trg_audit_expedientes_06 AFTER INSERT OR DELETE OR UPDATE ON mod06.expedientes_06
            FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger();
    END IF;
END $$;

-- ------------------------------------------------------------------
-- EGRESOS — tabla real de producción ( estaba faltando en este schema.sql:
-- drift detectado; el flujo de titulación del módulo escribe aquí y el
-- core la escucha con trg_titular_al_egresar definido en core_schema.sql ).
-- Estructura exacta de producción (2026-10-06).
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mod06.egresos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id) ON DELETE RESTRICT,
    carrera_id INT NOT NULL REFERENCES core.carreras(id) ON DELETE RESTRICT,
    periodo_fin_id INT NULL REFERENCES core.periodos_academicos(id) ON DELETE SET NULL,
    promedio NUMERIC(4,2) NOT NULL CHECK (promedio >= 0 AND promedio <= 20),
    fecha_egreso DATE NOT NULL,
    confirmado_por_id INT NULL REFERENCES core.usuarios(id) ON DELETE SET NULL,
    obs TEXT NULL,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (estudiante_id, carrera_id)
);
CREATE INDEX IF NOT EXISTS idx_egresos_estudiante ON mod06.egresos (estudiante_id);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_audit_egresos') THEN
        CREATE TRIGGER trg_audit_egresos AFTER INSERT OR DELETE OR UPDATE ON mod06.egresos
            FOR EACH ROW EXECUTE FUNCTION core.fn_audit_trigger();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_titular_al_egresar') THEN
        CREATE TRIGGER trg_titular_al_egresar AFTER INSERT ON mod06.egresos
            FOR EACH ROW EXECUTE FUNCTION core.fn_titular_al_egresar();
    END IF;
END $$;
