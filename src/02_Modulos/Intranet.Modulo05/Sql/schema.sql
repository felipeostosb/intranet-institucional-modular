-- =================================================================================
-- MÓDULO 05 - REQUERIMIENTOS E INCIDENCIAS
-- Acoplado a: core (usuarios, personas, docentes, aulas, carreras, unidades, periodos),
--             mod02 (clases_docente)  y  mod03 (inventario: bien, ambiente, asignacion)
--
-- Tablas propias (esquema mod05, dueño user_equipo05):
--   reportes_incidencia    reporte que hace un docente (o cualquier usuario)
--   incidencias            registro formal y dictamen del Asistente de Soporte
--   requerimientos         solicitudes de servicio / soporte
--   botica_medicamentos    catálogo de medicamentos del tópico
--   atenciones_topico      atención de enfermería (la registra quien atiende)
--   citas_psicologia       citas del formulario de Google Calendar (30 min)
--   atenciones_psicologia  atención psicológica (la registra el psicólogo)
--
-- NO toca mod05.practicas (es de postgres) ni mod05.t_modulo05_registros.
-- Idempotente: se puede ejecutar varias veces. Ejecutar completo con Alt+X.
--
-- Relaciones con mod02 y mod03: tu usuario solo tiene SELECT ahí (no REFERENCES).
-- Mientras no te den REFERENCES, la integridad se valida con un trigger; en cuanto
-- te lo den, vuelve a ejecutar este script y se crean las llaves foráneas reales.
-- =================================================================================

SET search_path TO mod05, core, public;

-- =================================================================================
-- 1. FUNCIÓN GENÉRICA: valida que un valor exista en otra tabla (sustituye a una FK)
-- =================================================================================
CREATE OR REPLACE FUNCTION mod05.fn_validar_referencia()
RETURNS TRIGGER AS $$
DECLARE
    v_col    TEXT := TG_ARGV[0];   -- columna local
    v_dest   TEXT := TG_ARGV[1];   -- tabla destino (esquema.tabla)
    v_dcol   TEXT := TG_ARGV[2];   -- columna destino
    v_val    TEXT;
    v_existe BOOLEAN;
BEGIN
    v_val := to_jsonb(NEW) ->> v_col;
    IF v_val IS NULL THEN
        RETURN NEW;
    END IF;
    EXECUTE format('SELECT EXISTS (SELECT 1 FROM %s WHERE %I::text = $1)', v_dest::regclass, v_dcol)
        INTO v_existe USING v_val;
    IF NOT v_existe THEN
        RAISE EXCEPTION 'No existe % = % en %', v_col, v_val, v_dest
            USING ERRCODE = '23503';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crea una FK real si tienes REFERENCES sobre la tabla destino; si no, deja el trigger
CREATE OR REPLACE FUNCTION pg_temp.ref_externa(
    p_tabla TEXT, p_col TEXT, p_dest TEXT, p_dcol TEXT, p_accion TEXT DEFAULT 'SET NULL')
RETURNS VOID AS $$
DECLARE
    v_fk  TEXT := split_part(p_tabla, '.', 2) || '_' || p_col || '_fkey';
    v_trg TEXT := 'trg_ref_' || p_col;
BEGIN
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %s', v_trg, p_tabla);
    IF has_table_privilege(current_user, p_dest, 'REFERENCES') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_constraint
                       WHERE conname = v_fk AND conrelid = p_tabla::regclass) THEN
            EXECUTE format(
                'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %s(%I) ON DELETE %s',
                p_tabla, v_fk, p_col, p_dest, p_dcol, p_accion);
        END IF;
        RAISE NOTICE 'FK real: %.% -> %.%', p_tabla, p_col, p_dest, p_dcol;
    ELSE
        EXECUTE format(
            'CREATE TRIGGER %I BEFORE INSERT OR UPDATE OF %I ON %s
             FOR EACH ROW EXECUTE FUNCTION mod05.fn_validar_referencia(%L, %L, %L)',
            v_trg, p_col, p_tabla, p_col, p_dest, p_dcol);
        RAISE NOTICE 'Validación por trigger (falta REFERENCES sobre %): %.%', p_dest, p_tabla, p_col;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =================================================================================
-- 2. REPORTES DE INCIDENCIA (los hace el docente; aún no es un dictamen)
-- =================================================================================
CREATE TABLE IF NOT EXISTS mod05.reportes_incidencia (
    id SERIAL PRIMARY KEY,
    reportado_por INT NOT NULL REFERENCES core.usuarios(id) ON DELETE RESTRICT,
    docente_id INT REFERENCES core.docentes(id) ON DELETE SET NULL,
    clase_docente_id INT,                         -- mod02.clases_docente (más abajo)
    aula_id INT REFERENCES core.aulas(id) ON DELETE SET NULL,
    carrera_id INT REFERENCES core.carreras(id) ON DELETE SET NULL,
    unidad_didactica_id INT REFERENCES core.unidades_didacticas(id) ON DELETE SET NULL,
    periodo_id INT REFERENCES core.periodos_academicos(id) ON DELETE SET NULL,
    bien_id INT,                                  -- mod03.bien (más abajo)
    equipo_descripcion VARCHAR(150),              -- si el docente no sabe el código del bien
    tipo_falla VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    urgencia VARCHAR(20) NOT NULL DEFAULT 'Media'
        CHECK (urgencia IN ('Baja', 'Media', 'Alta', 'Crítica')),
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'En revisión', 'Convertido', 'Descartado')),
    fecha_reporte TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revisado_por INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    fecha_revision TIMESTAMPTZ,
    observacion_revision TEXT,
    CONSTRAINT ck_reporte_equipo CHECK (bien_id IS NOT NULL OR equipo_descripcion IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_reportes_estado      ON mod05.reportes_incidencia (estado, fecha_reporte DESC);
CREATE INDEX IF NOT EXISTS idx_reportes_reportado   ON mod05.reportes_incidencia (reportado_por);

-- =================================================================================
-- 3. INCIDENCIAS (registro formal; el Asistente de Soporte dictamina si está dañado)
--    Puede nacer de un reporte (reporte_id) o ser registrada directamente por Soporte.
-- =================================================================================
CREATE TABLE IF NOT EXISTS mod05.incidencias (
    id SERIAL PRIMARY KEY,
    reporte_id INT UNIQUE REFERENCES mod05.reportes_incidencia(id) ON DELETE SET NULL,
    bien_id INT NOT NULL,                         -- mod03.bien (más abajo)
    ambiente_id INT,                              -- mod03.ambiente (más abajo)
    aula_id INT REFERENCES core.aulas(id) ON DELETE SET NULL,
    carrera_id INT REFERENCES core.carreras(id) ON DELETE SET NULL,
    unidad_didactica_id INT REFERENCES core.unidades_didacticas(id) ON DELETE SET NULL,
    docente_id INT REFERENCES core.docentes(id) ON DELETE SET NULL,
    registrada_por INT NOT NULL REFERENCES core.usuarios(id) ON DELETE RESTRICT,
    tecnico_id INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre TIMESTAMPTZ,
    tipo_falla VARCHAR(100) NOT NULL,
    gravedad VARCHAR(20) NOT NULL DEFAULT 'Media'
        CHECK (gravedad IN ('Baja', 'Media', 'Alta', 'Crítica')),
    descripcion TEXT NOT NULL,
    dictamen VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (dictamen IN ('Pendiente', 'Dañado', 'Sin falla')),
    solucion_aplicada TEXT,
    estado VARCHAR(30) NOT NULL DEFAULT 'Abierta'
        CHECK (estado IN ('Abierta', 'En diagnóstico', 'En espera de repuesto',
                          'Reparado', 'Baja Definitiva', 'Descartada')),
    estado_bien_previo VARCHAR(30),               -- estado del bien en mod03 al registrar
    CONSTRAINT ck_incidencia_fechas CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_registro)
);

CREATE INDEX IF NOT EXISTS idx_incidencias_estado ON mod05.incidencias (estado, fecha_registro DESC);
CREATE INDEX IF NOT EXISTS idx_incidencias_bien   ON mod05.incidencias (bien_id);

-- =================================================================================
-- 4. REQUERIMIENTOS (solicitudes de servicio)
-- =================================================================================
CREATE TABLE IF NOT EXISTS mod05.requerimientos (
    id SERIAL PRIMARY KEY,
    solicitante_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE RESTRICT,
    tecnico_id INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    ambiente_id INT,                              -- mod03.ambiente (más abajo)
    aula_id INT REFERENCES core.aulas(id) ON DELETE SET NULL,
    carrera_id INT REFERENCES core.carreras(id) ON DELETE SET NULL,
    tipo_servicio VARCHAR(50) NOT NULL,
    prioridad VARCHAR(20) NOT NULL DEFAULT 'Media'
        CHECK (prioridad IN ('Baja', 'Media', 'Alta', 'Urgente')),
    descripcion TEXT NOT NULL,
    fecha_solicitud TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_atencion TIMESTAMPTZ,
    estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'En revisión', 'Aprobado', 'Atendido', 'Rechazado')),
    observacion_resolucion TEXT
);

CREATE INDEX IF NOT EXISTS idx_requerimientos_estado ON mod05.requerimientos (estado, fecha_solicitud DESC);

-- =================================================================================
-- 5. TÓPICO (enfermería): la atención la registra quien atiende
-- =================================================================================
CREATE TABLE IF NOT EXISTS mod05.botica_medicamentos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    presentacion VARCHAR(50) NOT NULL,
    stock_actual INT NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
    fecha_vencimiento DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Disponible'
        CHECK (estado IN ('Disponible', 'Por vencer', 'Agotado')),
    CONSTRAINT uq_medicamento UNIQUE (nombre, presentacion, fecha_vencimiento)
);

CREATE TABLE IF NOT EXISTS mod05.atenciones_topico (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE RESTRICT,   -- paciente
    atendido_por INT NOT NULL REFERENCES core.usuarios(id) ON DELETE RESTRICT,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo VARCHAR(250) NOT NULL,
    medicamento_id INT REFERENCES mod05.botica_medicamentos(id) ON DELETE SET NULL,
    es_alergico BOOLEAN NOT NULL DEFAULT false,
    detalle_alergia VARCHAR(250),
    seguro_salud VARCHAR(20) NOT NULL DEFAULT 'NINGUNO'
        CHECK (seguro_salud IN ('SIS', 'ESSALUD', 'EPS', 'NINGUNO')),
    observacion TEXT,
    CONSTRAINT ck_topico_alergia CHECK (NOT es_alergico OR detalle_alergia IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_topico_persona ON mod05.atenciones_topico (persona_id, fecha_hora DESC);

-- =================================================================================
-- 6. PSICOLOGÍA: citas (formulario de Google Calendar) y atenciones
--    El formulario pide nombre, apellido y correo; las citas duran 30 minutos.
-- =================================================================================
CREATE TABLE IF NOT EXISTS mod05.citas_psicologia (
    id SERIAL PRIMARY KEY,
    persona_id INT REFERENCES core.personas(id) ON DELETE SET NULL,   -- se enlaza por correo
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    inicio TIMESTAMPTZ NOT NULL,
    fin TIMESTAMPTZ NOT NULL,
    motivo VARCHAR(250),
    estado VARCHAR(20) NOT NULL DEFAULT 'Programada'
        CHECK (estado IN ('Programada', 'Confirmada', 'Atendida', 'Cancelada', 'No asistió')),
    origen VARCHAR(20) NOT NULL DEFAULT 'Google Calendar'
        CHECK (origen IN ('Google Calendar', 'Presencial', 'Sistema')),
    google_event_id VARCHAR(100) UNIQUE,
    psicologo_id INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    motivo_cancelacion VARCHAR(250),
    creado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_cita_horario CHECK (fin > inicio)
);

-- Un solo horario activo por franja (no se pueden agendar dos citas a la misma hora)
CREATE UNIQUE INDEX IF NOT EXISTS uq_cita_franja_activa
    ON mod05.citas_psicologia (inicio) WHERE estado IN ('Programada', 'Confirmada');
CREATE INDEX IF NOT EXISTS idx_cita_email ON mod05.citas_psicologia (lower(email));

CREATE TABLE IF NOT EXISTS mod05.atenciones_psicologia (
    id SERIAL PRIMARY KEY,
    cita_id INT UNIQUE REFERENCES mod05.citas_psicologia(id) ON DELETE SET NULL,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE RESTRICT,
    psicologo_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE RESTRICT,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_consulta VARCHAR(250) NOT NULL,
    observacion_notas TEXT,
    estado_atencion VARCHAR(30) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado_atencion IN ('Pendiente', 'En proceso', 'Dado de Alta', 'Derivado externamente'))
);

CREATE INDEX IF NOT EXISTS idx_psico_persona ON mod05.atenciones_psicologia (persona_id, fecha_hora DESC);

-- =================================================================================
-- 7. RELACIONES CON mod02 Y mod03 (FK real si hay REFERENCES; si no, trigger)
-- =================================================================================
SELECT pg_temp.ref_externa('mod05.reportes_incidencia', 'clase_docente_id', 'mod02.clases_docente', 'id', 'SET NULL');
SELECT pg_temp.ref_externa('mod05.reportes_incidencia', 'bien_id',          'mod03.bien',           'id_bien', 'SET NULL');
SELECT pg_temp.ref_externa('mod05.incidencias',         'bien_id',          'mod03.bien',           'id_bien', 'RESTRICT');
SELECT pg_temp.ref_externa('mod05.incidencias',         'ambiente_id',      'mod03.ambiente',       'id_ambiente', 'SET NULL');
SELECT pg_temp.ref_externa('mod05.requerimientos',      'ambiente_id',      'mod03.ambiente',       'id_ambiente', 'SET NULL');

-- =================================================================================
-- 8. LÓGICA AUTOMÁTICA (completa los datos para que el reporte "suelte" todo)
-- =================================================================================

-- 8.1 Reporte: completa docente, aula, carrera, curso y periodo
CREATE OR REPLACE FUNCTION mod05.fn_reporte_before()
RETURNS TRIGGER AS $$
BEGIN
    -- Docente a partir de quien reporta (usuario -> persona -> docente)
    IF NEW.docente_id IS NULL THEN
        SELECT d.id INTO NEW.docente_id
        FROM core.usuarios u
        JOIN core.docentes d ON d.persona_id = u.persona_id
        WHERE u.id = NEW.reportado_por;
    END IF;

    -- Si indica la clase, trae aula, carrera, curso, periodo y docente de mod02
    IF NEW.clase_docente_id IS NOT NULL THEN
        SELECT COALESCE(NEW.aula_id, cd.aula_id),
               COALESCE(NEW.carrera_id, cd.carrera_id),
               COALESCE(NEW.unidad_didactica_id, cd.unidad_didactica_id),
               COALESCE(NEW.periodo_id, cd.periodo_id),
               COALESCE(NEW.docente_id, cd.docente_id)
          INTO NEW.aula_id, NEW.carrera_id, NEW.unidad_didactica_id,
               NEW.periodo_id, NEW.docente_id
        FROM mod02.clases_docente cd
        WHERE cd.id = NEW.clase_docente_id;
    END IF;

    -- Periodo activo por defecto
    IF NEW.periodo_id IS NULL THEN
        SELECT p.id INTO NEW.periodo_id
        FROM core.periodos_academicos p
        WHERE p.es_activo ORDER BY p.id DESC LIMIT 1;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reporte_before ON mod05.reportes_incidencia;
CREATE TRIGGER trg_reporte_before
BEFORE INSERT ON mod05.reportes_incidencia
FOR EACH ROW EXECUTE FUNCTION mod05.fn_reporte_before();

-- 8.2 Incidencia: copia datos del reporte, ubica el bien en su ambiente y cierra solo
CREATE OR REPLACE FUNCTION mod05.fn_incidencia_before()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.reporte_id IS NOT NULL THEN
            SELECT COALESCE(NEW.bien_id, r.bien_id),
                   COALESCE(NEW.aula_id, r.aula_id),
                   COALESCE(NEW.carrera_id, r.carrera_id),
                   COALESCE(NEW.unidad_didactica_id, r.unidad_didactica_id),
                   COALESCE(NEW.docente_id, r.docente_id),
                   COALESCE(NEW.tipo_falla, r.tipo_falla),
                   COALESCE(NEW.descripcion, r.descripcion)
              INTO NEW.bien_id, NEW.aula_id, NEW.carrera_id, NEW.unidad_didactica_id,
                   NEW.docente_id, NEW.tipo_falla, NEW.descripcion
            FROM mod05.reportes_incidencia r
            WHERE r.id = NEW.reporte_id;
        END IF;

        -- Ambiente = donde está asignado hoy el bien en el inventario (mod03)
        IF NEW.ambiente_id IS NULL AND NEW.bien_id IS NOT NULL THEN
            SELECT a.id_ambiente INTO NEW.ambiente_id
            FROM mod03.asignacion a
            WHERE a.id_bien = NEW.bien_id AND a.estado = 'Activa'
            ORDER BY a.fecha_asignacion DESC, a.id_asignacion DESC
            LIMIT 1;
        END IF;

        -- Foto del estado del bien antes de la incidencia
        SELECT b.estado INTO NEW.estado_bien_previo
        FROM mod03.bien b WHERE b.id_bien = NEW.bien_id;
    END IF;

    -- Fecha de cierre automática
    IF NEW.estado IN ('Reparado', 'Baja Definitiva', 'Descartada') THEN
        IF NEW.fecha_cierre IS NULL THEN
            NEW.fecha_cierre := CURRENT_TIMESTAMP;
        END IF;
    ELSIF TG_OP = 'UPDATE' AND OLD.estado IN ('Reparado', 'Baja Definitiva', 'Descartada') THEN
        NEW.fecha_cierre := NULL;   -- se reabrió
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_incidencia_before ON mod05.incidencias;
CREATE TRIGGER trg_incidencia_before
BEFORE INSERT OR UPDATE ON mod05.incidencias
FOR EACH ROW EXECUTE FUNCTION mod05.fn_incidencia_before();

-- 8.3 Al crear la incidencia, el reporte queda como "Convertido"
CREATE OR REPLACE FUNCTION mod05.fn_incidencia_after()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reporte_id IS NOT NULL THEN
        UPDATE mod05.reportes_incidencia
           SET estado = 'Convertido',
               revisado_por = COALESCE(revisado_por, NEW.registrada_por),
               fecha_revision = COALESCE(fecha_revision, CURRENT_TIMESTAMP)
         WHERE id = NEW.reporte_id AND estado <> 'Convertido';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_incidencia_after ON mod05.incidencias;
CREATE TRIGGER trg_incidencia_after
AFTER INSERT ON mod05.incidencias
FOR EACH ROW EXECUTE FUNCTION mod05.fn_incidencia_after();

-- 8.4 Cita de psicología: enlaza a la persona por el correo (core.usuarios.email)
CREATE OR REPLACE FUNCTION mod05.fn_cita_before()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.persona_id IS NULL THEN
        SELECT u.persona_id INTO NEW.persona_id
        FROM core.usuarios u
        WHERE lower(u.email) = lower(NEW.email);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cita_before ON mod05.citas_psicologia;
CREATE TRIGGER trg_cita_before
BEFORE INSERT ON mod05.citas_psicologia
FOR EACH ROW EXECUTE FUNCTION mod05.fn_cita_before();

-- =================================================================================
-- 9. INVENTARIO (mod03): estado del bien según la incidencia  [OPCIONAL]
--    Escribe en mod03.bien.estado, por eso solo se activa si tu usuario tiene
--    UPDATE sobre esa columna (hay que pedírselo al equipo 03). Si no, se omite.
--      Abierta                       -> Inoperativo
--      En diagnóstico / en repuesto  -> En reparación
--      Reparado                      -> Bueno
--      Baja Definitiva               -> Baja en trámite
--      Descartada / Sin falla        -> el estado que tenía antes
-- =================================================================================
CREATE OR REPLACE FUNCTION mod05.fn_sync_estado_bien()
RETURNS TRIGGER AS $$
DECLARE
    v_nuevo TEXT;
BEGIN
    IF NEW.dictamen = 'Dañado' THEN
        v_nuevo := CASE NEW.estado
            WHEN 'Abierta'               THEN 'Inoperativo'
            WHEN 'En diagnóstico'        THEN 'En reparación'
            WHEN 'En espera de repuesto' THEN 'En reparación'
            WHEN 'Reparado'              THEN 'Bueno'
            WHEN 'Baja Definitiva'       THEN 'Baja en trámite'
            WHEN 'Descartada'            THEN COALESCE(NEW.estado_bien_previo, 'Bueno')
        END;
    ELSIF TG_OP = 'UPDATE' AND OLD.dictamen = 'Dañado' THEN
        v_nuevo := COALESCE(NEW.estado_bien_previo, 'Bueno');   -- ya no está dañado
    END IF;

    IF v_nuevo IS NOT NULL THEN
        UPDATE mod03.bien SET estado = v_nuevo
         WHERE id_bien = NEW.bien_id AND estado IS DISTINCT FROM v_nuevo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    DROP TRIGGER IF EXISTS trg_sync_estado_bien ON mod05.incidencias;
    IF has_column_privilege(current_user, 'mod03.bien', 'estado', 'UPDATE') THEN
        CREATE TRIGGER trg_sync_estado_bien
        AFTER INSERT OR UPDATE OF dictamen, estado ON mod05.incidencias
        FOR EACH ROW EXECUTE FUNCTION mod05.fn_sync_estado_bien();
        RAISE NOTICE 'Sincronización con mod03.bien ACTIVADA';
    ELSE
        RAISE NOTICE 'Sin UPDATE sobre mod03.bien.estado: la sincronización con inventario NO se activó';
    END IF;
END $$;

-- =================================================================================
-- 10. VISTAS (lo que "suelta" cada reporte o incidencia: salón, carrera, curso, docente, bien)
-- =================================================================================
DROP VIEW IF EXISTS mod05.v_incidencias_detalle CASCADE;
DROP VIEW IF EXISTS mod05.v_reportes_incidencia_detalle CASCADE;
DROP VIEW IF EXISTS mod05.v_requerimientos_detalle CASCADE;
DROP VIEW IF EXISTS mod05.v_citas_psicologia CASCADE;

CREATE VIEW mod05.v_reportes_incidencia_detalle AS
SELECT
    r.id AS reporte_id,
    r.fecha_reporte, r.estado, r.urgencia, r.tipo_falla, r.descripcion,
    r.reportado_por,
    CONCAT(pu.nombres, ' ', pu.apellidos) AS reportado_por_nombre,
    r.docente_id, d.codigo_docente,
    CONCAT(pd.nombres, ' ', pd.apellidos) AS docente_nombre,
    r.aula_id, a.codigo AS aula, a.pabellon,
    r.carrera_id, c.nombre AS carrera,
    r.unidad_didactica_id, ud.nombre AS curso,
    r.periodo_id, pa.codigo AS periodo,
    r.clase_docente_id,
    r.bien_id, b.cbi, b.codigo_inventario, b.descripcion AS bien_descripcion,
    b.estado AS bien_estado, r.equipo_descripcion,
    i.id AS incidencia_id
FROM mod05.reportes_incidencia r
JOIN core.usuarios u            ON u.id = r.reportado_por
JOIN core.personas pu           ON pu.id = u.persona_id
LEFT JOIN core.docentes d       ON d.id = r.docente_id
LEFT JOIN core.personas pd      ON pd.id = d.persona_id
LEFT JOIN core.aulas a          ON a.id = r.aula_id
LEFT JOIN core.carreras c       ON c.id = r.carrera_id
LEFT JOIN core.unidades_didacticas ud ON ud.id = r.unidad_didactica_id
LEFT JOIN core.periodos_academicos pa ON pa.id = r.periodo_id
LEFT JOIN mod03.bien b          ON b.id_bien = r.bien_id
LEFT JOIN mod05.incidencias i   ON i.reporte_id = r.id;

CREATE VIEW mod05.v_incidencias_detalle AS
SELECT
    i.id AS incidencia_id,
    i.reporte_id,
    i.fecha_registro, i.fecha_cierre, i.estado, i.dictamen, i.gravedad,
    i.tipo_falla, i.descripcion, i.solucion_aplicada,
    -- Bien (inventario mod03)
    i.bien_id, b.cbi, b.codigo_inventario, b.descripcion AS bien_descripcion,
    b.marca, b.modelo, b.serie, cb.nombre AS tipo_bien,
    b.estado AS bien_estado_actual, i.estado_bien_previo,
    -- Dónde está
    i.ambiente_id, am.nombre AS ambiente, e.nombre AS especialidad,
    i.aula_id, a.codigo AS aula, a.pabellon,
    -- Contexto académico
    i.carrera_id, c.nombre AS carrera,
    i.unidad_didactica_id, ud.nombre AS curso,
    i.docente_id, CONCAT(pd.nombres, ' ', pd.apellidos) AS docente_nombre,
    -- Quién
    i.registrada_por, CONCAT(pr.nombres, ' ', pr.apellidos) AS registrada_por_nombre,
    i.tecnico_id, CONCAT(pt.nombres, ' ', pt.apellidos) AS tecnico_nombre
FROM mod05.incidencias i
LEFT JOIN mod03.bien b                  ON b.id_bien = i.bien_id
LEFT JOIN mod03.clasificaciones_bien cb ON cb.id_clasificacion = b.id_clasificacion
LEFT JOIN mod03.ambiente am             ON am.id_ambiente = i.ambiente_id
LEFT JOIN mod03.especialidad e          ON e.id_especialidad = am.id_especialidad
LEFT JOIN core.aulas a                  ON a.id = i.aula_id
LEFT JOIN core.carreras c               ON c.id = i.carrera_id
LEFT JOIN core.unidades_didacticas ud   ON ud.id = i.unidad_didactica_id
LEFT JOIN core.docentes d               ON d.id = i.docente_id
LEFT JOIN core.personas pd              ON pd.id = d.persona_id
LEFT JOIN core.usuarios ur              ON ur.id = i.registrada_por
LEFT JOIN core.personas pr              ON pr.id = ur.persona_id
LEFT JOIN core.usuarios ut              ON ut.id = i.tecnico_id
LEFT JOIN core.personas pt              ON pt.id = ut.persona_id;

CREATE VIEW mod05.v_requerimientos_detalle AS
SELECT
    q.id AS requerimiento_id,
    q.fecha_solicitud, q.fecha_atencion, q.estado, q.prioridad,
    q.tipo_servicio, q.descripcion, q.observacion_resolucion,
    q.solicitante_id, CONCAT(ps.nombres, ' ', ps.apellidos) AS solicitante_nombre,
    q.tecnico_id, CONCAT(pt.nombres, ' ', pt.apellidos) AS tecnico_nombre,
    q.ambiente_id, am.nombre AS ambiente,
    q.aula_id, a.codigo AS aula,
    q.carrera_id, c.nombre AS carrera
FROM mod05.requerimientos q
JOIN core.usuarios us         ON us.id = q.solicitante_id
JOIN core.personas ps         ON ps.id = us.persona_id
LEFT JOIN core.usuarios ut    ON ut.id = q.tecnico_id
LEFT JOIN core.personas pt    ON pt.id = ut.persona_id
LEFT JOIN mod03.ambiente am   ON am.id_ambiente = q.ambiente_id
LEFT JOIN core.aulas a        ON a.id = q.aula_id
LEFT JOIN core.carreras c     ON c.id = q.carrera_id;

CREATE VIEW mod05.v_citas_psicologia AS
SELECT
    ct.id AS cita_id,
    ct.inicio, ct.fin, ct.estado, ct.origen,
    ct.nombres, ct.apellidos, ct.email, ct.motivo,
    ct.persona_id, p.dni,
    est.codigo_estudiante, ca.nombre AS carrera,
    ct.psicologo_id, CONCAT(pp.nombres, ' ', pp.apellidos) AS psicologo_nombre,
    ap.id AS atencion_id, ap.estado_atencion
FROM mod05.citas_psicologia ct
LEFT JOIN core.personas p          ON p.id = ct.persona_id
LEFT JOIN core.estudiantes est     ON est.persona_id = ct.persona_id
LEFT JOIN core.carreras ca         ON ca.id = est.carrera_id
LEFT JOIN core.usuarios up         ON up.id = ct.psicologo_id
LEFT JOIN core.personas pp         ON pp.id = up.persona_id
LEFT JOIN mod05.atenciones_psicologia ap ON ap.cita_id = ct.id;

-- =================================================================================
-- 11. PRIVACIDAD: datos de salud y psicología solo para este módulo
--     (los permisos por defecto de mod05 dan SELECT a todos los equipos)
-- =================================================================================
DO $$
DECLARE
    r TEXT;
    t TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['user_equipo00','user_equipo01','user_equipo02','user_equipo03',
                             'user_equipo04','user_equipo06','user_equipo07','user_equipo08',
                             'user_equipo09'] LOOP
        FOREACH t IN ARRAY ARRAY['atenciones_topico','atenciones_psicologia','citas_psicologia'] LOOP
            BEGIN
                EXECUTE format('REVOKE ALL ON mod05.%I FROM %I', t, r);
            EXCEPTION WHEN others THEN
                RAISE NOTICE 'No se pudo revocar % a %: %', t, r, SQLERRM;
            END;
        END LOOP;
    END LOOP;
END $$;