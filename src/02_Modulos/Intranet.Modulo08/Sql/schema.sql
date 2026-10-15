-- =================================================================================
-- MÓDULO 08 - SEGURIDAD, LOGIN (DNI + GOOGLE) Y ROLES  |  CONTEXTO COMPLETO
-- Base: db_intranet_iestp  |  Esquema propio: mod08  |  Usuario del equipo: user_equipo08
--
-- ESTE ARCHIVO TIENE 3 PARTES:
--   PARTE A  Contexto y reglas (comentarios).
--   PARTE B  Estructura real de core que usa el login (comentarios, SOLO LECTURA).
--   PARTE C  SQL ejecutable del módulo 08 (idempotente; Alt+X en DBeaver).
--   PARTE D  Consultas típicas del login (comentarios, para usar como ejemplo).
-- =================================================================================

-- =================================================================================
-- PARTE A - CONTEXTO Y REGLAS
-- =================================================================================
-- 1) QUÉ ES DEL MÓDULO 08 (dueño user_equipo08; se puede crear/alterar/borrar):
--      politicas_acceso        configuración: intentos máx., minutos de bloqueo,
--                              vigencia de clave, validez de sesión, dominios de Google.
--      identidades_externas    vínculo Google SSO -> core.usuarios (subject, correo, fechas).
--      intentos_login          auditoría de cada intento (DNI_LOCAL o GOOGLE_SSO).
--      asignaciones_rol        historial de roles (quién asignó/retiró y motivo);
--                              un trigger la sincroniza con core.usuario_roles.
--      permisos_modulos        catálogo de módulos y nivel de acceso (panel lateral).
--      roles_permisos          qué módulos ve cada rol de core.roles.
--      sesiones_login          sesiones activas (método, IP, expiración, estado).
--      v_usuarios_roles, v_cubrimiento_roles, v_estado_acceso   (vistas)
--
-- 2) NO TOCAR (dueño postgres): mod08.usuarios, mod08.personas, mod08.sesiones,
--    mod08.bitacora, mod08.ofertas_laborales, mod08.t_modulo08_registros, y TODO core.
--    Las tablas antiguas de mod08 duplican a core: el login NO debe usarlas.
--
-- 3) core ES LA FUENTE DE VERDAD de usuarios, personas, roles y roles por usuario.
--    El módulo 08 solo tiene SELECT y REFERENCES en core (y los permisos puntuales que
--    le den). Todas las llaves foráneas de mod08 apuntan a core o a tablas de mod08
--    del mismo equipo, nunca a las tablas ajenas de mod08.
--
-- 4) LOGIN: el usuario puede entrar por DNI+contraseña o por Google; un método NO
--    reemplaza al otro.
--      DNI_LOCAL   core.personas.dni -> core.usuarios.persona_id -> password_hash
--      GOOGLE_SSO  mod08.identidades_externas.subject_externo; el primer enlace se hace
--                  por correo (lower(core.usuarios.email) = lower(correo de Google))
--    Valores de método: 'DNI_LOCAL' y 'GOOGLE_SSO' (intentos_login.proveedor y
--    sesiones_login.metodo_autenticacion). identidades_externas.proveedor = 'Google'.
--
-- 5) BLOQUEO: los fallos de contraseña (DNI_LOCAL) bloquean solo el ingreso por DNI
--    (v_estado_acceso.bloqueado_temporal). NO bloquean el ingreso por Google.
--    Un usuario inactivo (core.usuarios.estado = false) no puede entrar por ningún método.
--
-- 6) DATOS REALES (respaldo de octubre 2026): 77 usuarios; roles en core.roles: Admin,
--    Director, Coordinador, Secretaria, Tesoreria, Docente, Alumno, Jefe General,
--    Jefe de Especialidad, OTIS. Dominios de core.usuarios.email: iestpargentina.edu.pe (64),
--    ieargentina.edu.pe (9), istpargentina.edu.pe (4). Las tablas de mod08 estaban vacías.
--
-- 7) PROBLEMAS CONOCIDOS EN core (pedir a sus dueños; no se pueden arreglar desde mod08):
--    a) core.usuarios.password_hash es NOT NULL DEFAULT '123456' (texto plano): 73 de 77
--       usuarios tienen '123456' y solo 4 tienen hash bcrypt. Quien entra solo con Google
--       no tiene contraseña. Cambio pedido:
--         ALTER TABLE core.usuarios ALTER COLUMN password_hash DROP NOT NULL,
--                                   ALTER COLUMN password_hash DROP DEFAULT;
--    b) core.fn_audit_trigger copia filas completas (incluido password_hash) a
--       core.auditoria_logs y no registra el usuario de la aplicación (usuario_id NULL).
--
-- 8) Por eso v_estado_acceso.tiene_password solo es verdadero si password_hash parece
--    un hash bcrypt (empieza con $2a$, $2b$ o $2y$).

-- =================================================================================
-- PARTE B - ESTRUCTURA REAL DE core QUE USA EL LOGIN (SOLO LECTURA, NO EJECUTAR)
-- Extraída del respaldo de la base del salón.
-- =================================================================================
-- CREATE TABLE core.personas (
--     id integer NOT NULL,
--     dni character varying(15) NOT NULL,
--     nombres character varying(100) NOT NULL,
--     apellidos character varying(100) NOT NULL,
--     fecha_nacimiento date,
--     sexo character varying(10) DEFAULT 'M'::character varying NOT NULL,
--     email_personal character varying(150),
--     telefono character varying(20),
--     direccion character varying(255),
--     foto_url character varying(255),
--     creado_en timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
--     CONSTRAINT personas_sexo_check CHECK (((sexo)::text = ANY ((ARRAY['M'::character varying, 'F'::character varying, 'Otro'::character varying])::text[])))
-- );
--
-- CREATE TABLE core.roles (
--     id integer NOT NULL,
--     nombre character varying(50) NOT NULL,
--     descripcion character varying(200) NOT NULL
-- );
--
-- CREATE TABLE core.usuario_roles (
--     id integer NOT NULL,
--     usuario_id integer NOT NULL,
--     rol_id integer NOT NULL,
--     asignado_en timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
--     es_activo boolean DEFAULT true NOT NULL
-- );
--
-- CREATE TABLE core.usuarios (
--     id integer NOT NULL,
--     persona_id integer NOT NULL,
--     codigo_institucional character varying(50) NOT NULL,
--     email character varying(150) NOT NULL,
--     password_hash character varying(255) DEFAULT '123456'::character varying NOT NULL,
--     ultimo_acceso timestamp with time zone,
--     estado boolean DEFAULT true NOT NULL,
--     creado_en timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
-- );
--
-- -- (id con secuencia) ALTER TABLE ONLY core.personas ALTER COLUMN id SET DEFAULT nextval('core.personas_id_seq'::regclass);
--
-- -- (id con secuencia) ALTER TABLE ONLY core.roles ALTER COLUMN id SET DEFAULT nextval('core.roles_id_seq'::regclass);
--
-- -- (id con secuencia) ALTER TABLE ONLY core.usuario_roles ALTER COLUMN id SET DEFAULT nextval('core.usuario_roles_id_seq'::regclass);
--
-- -- (id con secuencia) ALTER TABLE ONLY core.usuarios ALTER COLUMN id SET DEFAULT nextval('core.usuarios_id_seq'::regclass);
--
-- ALTER TABLE ONLY core.personas
--     ADD CONSTRAINT personas_dni_key UNIQUE (dni);
--
-- ALTER TABLE ONLY core.personas
--     ADD CONSTRAINT personas_pkey PRIMARY KEY (id);
--
-- ALTER TABLE ONLY core.roles
--     ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);
--
-- ALTER TABLE ONLY core.roles
--     ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
--
-- ALTER TABLE ONLY core.usuario_roles
--     ADD CONSTRAINT uk_usuario_rol UNIQUE (usuario_id, rol_id);
--
-- ALTER TABLE ONLY core.usuario_roles
--     ADD CONSTRAINT usuario_roles_pkey PRIMARY KEY (id);
--
-- ALTER TABLE ONLY core.usuarios
--     ADD CONSTRAINT usuarios_codigo_institucional_key UNIQUE (codigo_institucional);
--
-- ALTER TABLE ONLY core.usuarios
--     ADD CONSTRAINT usuarios_email_key UNIQUE (email);
--
-- ALTER TABLE ONLY core.usuarios
--     ADD CONSTRAINT usuarios_persona_id_key UNIQUE (persona_id);
--
-- ALTER TABLE ONLY core.usuarios
--     ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);
--
-- ALTER TABLE ONLY core.usuario_roles
--     ADD CONSTRAINT usuario_roles_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES core.roles(id) ON DELETE CASCADE;
--
-- ALTER TABLE ONLY core.usuario_roles
--     ADD CONSTRAINT usuario_roles_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES core.usuarios(id) ON DELETE CASCADE;
--
-- ALTER TABLE ONLY core.usuarios
--     ADD CONSTRAINT usuarios_persona_id_fkey FOREIGN KEY (persona_id) REFERENCES core.personas(id) ON DELETE CASCADE;


-- =================================================================================
-- PARTE C - SQL EJECUTABLE DEL MÓDULO 08
-- Orden: limpieza de vistas/función -> quitar sufijo _eq08 (si existe) -> tablas ->
--        trigger -> índices y restricciones -> relaciones hacia core -> vistas -> datos
-- =================================================================================

SET search_path TO mod08, core, public;

-- =================================================================================
-- 1. LIMPIEZA DE OBJETOS DERIVADOS (no guardan datos; se recrean más abajo)
-- =================================================================================
DROP VIEW IF EXISTS mod08.v_usuarios_roles_eq08 CASCADE;
DROP VIEW IF EXISTS mod08.v_cubrimiento_roles_eq08 CASCADE;
DROP VIEW IF EXISTS mod08.v_estado_acceso_eq08 CASCADE;
DROP VIEW IF EXISTS mod08.v_usuarios_roles CASCADE;
DROP VIEW IF EXISTS mod08.v_cubrimiento_roles CASCADE;
DROP VIEW IF EXISTS mod08.v_estado_acceso CASCADE;

DROP FUNCTION IF EXISTS mod08.trg_sync_core_usuario_roles_eq08() CASCADE;
DROP FUNCTION IF EXISTS mod08.trg_sync_core_usuario_roles() CASCADE;

-- =================================================================================
-- 2. QUITAR EL SUFIJO _eq08 A TABLAS, CONSTRAINTS, ÍNDICES Y SECUENCIAS EXISTENTES
-- =================================================================================
DO $$
DECLARE
    r RECORD;
    nuevo TEXT;
BEGIN
    -- Tablas
    FOR r IN SELECT tablename AS n FROM pg_tables
             WHERE schemaname = 'mod08' AND tablename LIKE '%\_eq08' LOOP
        nuevo := replace(r.n, '_eq08', '');
        BEGIN
            IF to_regclass('mod08.' || quote_ident(nuevo)) IS NULL THEN
                EXECUTE format('ALTER TABLE mod08.%I RENAME TO %I', r.n, nuevo);
                RAISE NOTICE 'Tabla % -> %', r.n, nuevo;
            ELSE
                RAISE NOTICE 'Se omite %: ya existe %', r.n, nuevo;
            END IF;
        EXCEPTION WHEN others THEN
            RAISE NOTICE 'No se pudo renombrar tabla %: %', r.n, SQLERRM;
        END;
    END LOOP;

    -- Constraints (al renombrar una PK/UNIQUE también se renombra su índice)
    FOR r IN SELECT c.conname AS n, cl.relname AS tabla
             FROM pg_constraint c
             JOIN pg_class cl ON cl.oid = c.conrelid
             JOIN pg_namespace ns ON ns.oid = cl.relnamespace
             WHERE ns.nspname = 'mod08' AND c.conname LIKE '%\_eq08%' LOOP
        BEGIN
            EXECUTE format('ALTER TABLE mod08.%I RENAME CONSTRAINT %I TO %I',
                           r.tabla, r.n, replace(r.n, '_eq08', ''));
        EXCEPTION WHEN others THEN
            RAISE NOTICE 'No se pudo renombrar constraint %: %', r.n, SQLERRM;
        END;
    END LOOP;

    -- Índices restantes
    FOR r IN SELECT indexname AS n FROM pg_indexes
             WHERE schemaname = 'mod08' AND indexname LIKE '%\_eq08%' LOOP
        BEGIN
            EXECUTE format('ALTER INDEX mod08.%I RENAME TO %I', r.n, replace(r.n, '_eq08', ''));
        EXCEPTION WHEN others THEN
            RAISE NOTICE 'No se pudo renombrar índice %: %', r.n, SQLERRM;
        END;
    END LOOP;

    -- Secuencias
    FOR r IN SELECT sequencename AS n FROM pg_sequences
             WHERE schemaname = 'mod08' AND sequencename LIKE '%\_eq08%' LOOP
        BEGIN
            EXECUTE format('ALTER SEQUENCE mod08.%I RENAME TO %I', r.n, replace(r.n, '_eq08', ''));
        EXCEPTION WHEN others THEN
            RAISE NOTICE 'No se pudo renombrar secuencia %: %', r.n, SQLERRM;
        END;
    END LOOP;
END $$;

-- =================================================================================
-- 3. TABLAS (se crean solo si faltan)
-- =================================================================================

-- politicas_acceso: configuración general de seguridad
CREATE TABLE IF NOT EXISTS mod08.politicas_acceso (
    id SERIAL PRIMARY KEY,
    max_intentos_fallidos INT DEFAULT 3,
    minutos_bloqueo INT DEFAULT 15,
    vigencia_password_dias INT DEFAULT 90,
    dias_validez_sesion INT DEFAULT 1,
    dominios_google_permitidos VARCHAR(255) DEFAULT '@istpargentina.edu.pe',
    actualizado_por INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    actualizado_en TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- identidades_externas: vinculación Google SSO -> core.usuarios
CREATE TABLE IF NOT EXISTS mod08.identidades_externas (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE CASCADE,
    proveedor VARCHAR(50) DEFAULT 'Google',
    subject_externo VARCHAR(255) UNIQUE NOT NULL,
    email_externo VARCHAR(150),
    email_verificado BOOLEAN DEFAULT false,
    vinculado_por INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    vinculado_en TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    desvinculado_en TIMESTAMPTZ
);

-- intentos_login: auditoría de intentos para bloqueos temporales
CREATE TABLE IF NOT EXISTS mod08.intentos_login (
    id SERIAL PRIMARY KEY,
    identificador_intentado VARCHAR(150),
    usuario_id INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    proveedor VARCHAR(50),
    exito BOOLEAN NOT NULL,
    motivo VARCHAR(255),
    ip_origen VARCHAR(45),
    user_agent TEXT,
    fecha TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- asignaciones_rol: historial detallado que el core NO registra
CREATE TABLE IF NOT EXISTS mod08.asignaciones_rol (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE CASCADE,
    rol_id INT NOT NULL REFERENCES core.roles(id) ON DELETE CASCADE,
    asignado_por INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    asignado_en TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    retirado_en TIMESTAMPTZ,
    retirado_por INT REFERENCES core.usuarios(id) ON DELETE SET NULL,
    motivo VARCHAR(255)
);

-- permisos_modulos: catálogo de módulos y nivel de acceso
CREATE TABLE IF NOT EXISTS mod08.permisos_modulos (
    id_permiso SERIAL PRIMARY KEY,
    nombre_modulo VARCHAR(100) NOT NULL UNIQUE,
    nivel_acceso VARCHAR(20) NOT NULL,
    descripcion TEXT
);

-- roles_permisos: qué módulos puede usar cada rol de core.roles
CREATE TABLE IF NOT EXISTS mod08.roles_permisos (
    rol_id INT NOT NULL REFERENCES core.roles(id) ON DELETE CASCADE,
    permiso_id INT NOT NULL REFERENCES mod08.permisos_modulos(id_permiso) ON DELETE CASCADE,
    PRIMARY KEY (rol_id, permiso_id)
);

-- sesiones_login: sesiones activas (intentos_login solo registra intentos)
CREATE TABLE IF NOT EXISTS mod08.sesiones_login (
    id_sesion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE CASCADE,
    metodo_autenticacion VARCHAR(20) NOT NULL
        CHECK (metodo_autenticacion IN ('DNI_LOCAL', 'GOOGLE_SSO')),
    ip_origen VARCHAR(45),
    fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion TIMESTAMPTZ NOT NULL,
    estado VARCHAR(15) NOT NULL DEFAULT 'Activa'
        CHECK (estado IN ('Activa', 'Expirada', 'Cerrada'))
);

CREATE INDEX IF NOT EXISTS idx_sesiones_login_usuario
    ON mod08.sesiones_login (usuario_id, estado);

-- =================================================================================
-- 4. TRIGGER: asignaciones_rol (mod08) -> usuario_roles (core)
-- =================================================================================
CREATE OR REPLACE FUNCTION mod08.trg_sync_core_usuario_roles()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Si existe inactivo, lo reactiva
        UPDATE core.usuario_roles
        SET es_activo = TRUE, asignado_en = NEW.asignado_en
        WHERE usuario_id = NEW.usuario_id AND rol_id = NEW.rol_id;

        -- Si no existe en el core, lo inserta
        IF NOT FOUND THEN
            INSERT INTO core.usuario_roles (usuario_id, rol_id, asignado_en, es_activo)
            VALUES (NEW.usuario_id, NEW.rol_id, NEW.asignado_en, TRUE);
        END IF;
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Si se marcó el retiro del rol, lo desactiva en el core
        IF NEW.retirado_en IS NOT NULL AND OLD.retirado_en IS NULL THEN
            UPDATE core.usuario_roles
            SET es_activo = FALSE
            WHERE usuario_id = NEW.usuario_id AND rol_id = NEW.rol_id;
        END IF;
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_roles ON mod08.asignaciones_rol;
CREATE TRIGGER trg_sync_roles
AFTER INSERT OR UPDATE ON mod08.asignaciones_rol
FOR EACH ROW EXECUTE FUNCTION mod08.trg_sync_core_usuario_roles();


-- ---------------------------------------------------------------------------------
-- 1. identidades_externas (Google)
--    Antes: subject_externo era UNIQUE contra TODAS las filas, así que una cuenta
--    desvinculada y luego vuelta a vincular chocaba con su propia fila vieja.
--    Ahora: único solo entre vínculos ACTIVOS, y un usuario no puede tener dos
--    cuentas Google activas a la vez.
--    (Si ya hubiera filas duplicadas activas, el índice avisará con un error.)
-- ---------------------------------------------------------------------------------
ALTER TABLE mod08.identidades_externas
    DROP CONSTRAINT IF EXISTS identidades_externas_subject_externo_key;

CREATE UNIQUE INDEX IF NOT EXISTS uq_identidades_subject_activo
    ON mod08.identidades_externas (subject_externo)
    WHERE desvinculado_en IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_identidades_usuario_proveedor_activo
    ON mod08.identidades_externas (usuario_id, proveedor)
    WHERE desvinculado_en IS NULL;

CREATE INDEX IF NOT EXISTS idx_identidades_email
    ON mod08.identidades_externas (lower(email_externo));

-- ---------------------------------------------------------------------------------
-- 2. intentos_login
--    El método se guarda con los mismos valores que sesiones_login
--    ('DNI_LOCAL' / 'GOOGLE_SSO'). NOT VALID: no revisa filas ya existentes.
--    Índices para que el cálculo de bloqueo temporal sea rápido.
-- ---------------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_intentos_login_proveedor'
          AND conrelid = 'mod08.intentos_login'::regclass
    ) THEN
        ALTER TABLE mod08.intentos_login
            ADD CONSTRAINT chk_intentos_login_proveedor
            CHECK (proveedor IN ('DNI_LOCAL', 'GOOGLE_SSO')) NOT VALID;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_intentos_login_usuario_fecha
    ON mod08.intentos_login (usuario_id, fecha DESC);

CREATE INDEX IF NOT EXISTS idx_intentos_login_identificador
    ON mod08.intentos_login (identificador_intentado, fecha DESC);


-- =================================================================================
-- RELACIONES: llaves foráneas de las 7 tablas, solo hacia core y mod08 propio
-- =================================================================================

-- asignaciones_rol
ALTER TABLE mod08.asignaciones_rol
    DROP CONSTRAINT IF EXISTS asignaciones_rol_usuario_id_fkey,
    ADD CONSTRAINT asignaciones_rol_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES core.usuarios(id) ON DELETE CASCADE,
    DROP CONSTRAINT IF EXISTS asignaciones_rol_rol_id_fkey,
    ADD CONSTRAINT asignaciones_rol_rol_id_fkey
        FOREIGN KEY (rol_id) REFERENCES core.roles(id) ON DELETE CASCADE,
    DROP CONSTRAINT IF EXISTS asignaciones_rol_asignado_por_fkey,
    ADD CONSTRAINT asignaciones_rol_asignado_por_fkey
        FOREIGN KEY (asignado_por) REFERENCES core.usuarios(id) ON DELETE SET NULL,
    DROP CONSTRAINT IF EXISTS asignaciones_rol_retirado_por_fkey,
    ADD CONSTRAINT asignaciones_rol_retirado_por_fkey
        FOREIGN KEY (retirado_por) REFERENCES core.usuarios(id) ON DELETE SET NULL;

-- identidades_externas
ALTER TABLE mod08.identidades_externas
    DROP CONSTRAINT IF EXISTS identidades_externas_usuario_id_fkey,
    ADD CONSTRAINT identidades_externas_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES core.usuarios(id) ON DELETE CASCADE,
    DROP CONSTRAINT IF EXISTS identidades_externas_vinculado_por_fkey,
    ADD CONSTRAINT identidades_externas_vinculado_por_fkey
        FOREIGN KEY (vinculado_por) REFERENCES core.usuarios(id) ON DELETE SET NULL;

-- intentos_login
ALTER TABLE mod08.intentos_login
    DROP CONSTRAINT IF EXISTS intentos_login_usuario_id_fkey,
    ADD CONSTRAINT intentos_login_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES core.usuarios(id) ON DELETE SET NULL;

-- politicas_acceso
ALTER TABLE mod08.politicas_acceso
    DROP CONSTRAINT IF EXISTS politicas_acceso_actualizado_por_fkey,
    ADD CONSTRAINT politicas_acceso_actualizado_por_fkey
        FOREIGN KEY (actualizado_por) REFERENCES core.usuarios(id) ON DELETE SET NULL;

-- roles_permisos (rol -> core, permiso -> tu propia tabla)
ALTER TABLE mod08.roles_permisos
    DROP CONSTRAINT IF EXISTS roles_permisos_rol_id_fkey,
    ADD CONSTRAINT roles_permisos_rol_id_fkey
        FOREIGN KEY (rol_id) REFERENCES core.roles(id) ON DELETE CASCADE,
    DROP CONSTRAINT IF EXISTS roles_permisos_permiso_id_fkey,
    ADD CONSTRAINT roles_permisos_permiso_id_fkey
        FOREIGN KEY (permiso_id) REFERENCES mod08.permisos_modulos(id_permiso) ON DELETE CASCADE;

-- sesiones_login
ALTER TABLE mod08.sesiones_login
    DROP CONSTRAINT IF EXISTS sesiones_login_usuario_id_fkey,
    ADD CONSTRAINT sesiones_login_usuario_id_fkey
        FOREIGN KEY (usuario_id) REFERENCES core.usuarios(id) ON DELETE CASCADE;


-- =================================================================================
-- VISTAS DE LECTURA (en tiempo real sobre core)
-- =================================================================================

-- Quiénes son y qué roles tienen activos
CREATE VIEW mod08.v_usuarios_roles AS
SELECT
    u.id AS usuario_id,
    p.dni,
    CONCAT(p.nombres, ' ', p.apellidos) AS nombre,
    u.codigo_institucional,
    u.email,
    u.estado,
    r.nombre AS rol
FROM core.usuarios u
JOIN core.personas p ON u.persona_id = p.id
JOIN core.usuario_roles ur ON u.id = ur.usuario_id
JOIN core.roles r ON ur.rol_id = r.id
WHERE ur.es_activo = true;

-- Conteo de usuarios por rol
CREATE VIEW mod08.v_cubrimiento_roles AS
SELECT
    r.id AS rol_id,
    r.nombre AS rol,
    COUNT(CASE WHEN u.estado = true THEN 1 END) AS usuarios_activos,
    COUNT(CASE WHEN u.estado = false THEN 1 END) AS usuarios_inactivos
FROM core.roles r
LEFT JOIN core.usuario_roles ur ON r.id = ur.rol_id AND ur.es_activo = true
LEFT JOIN core.usuarios u ON ur.usuario_id = u.id
GROUP BY r.id, r.nombre;


-- ---------------------------------------------------------------------------------
-- v_estado_acceso: agrega "tiene_password" al final, para saber qué métodos
--    tiene disponibles cada usuario (DNI con clave, Google, o ambos).
--    "bloqueado_temporal" aplica SOLO al login por DNI: los fallos de contraseña
--    no bloquean el ingreso por Google. "bloqueado" (usuario inactivo en core)
--    sí impide ambos métodos.
-- ---------------------------------------------------------------------------------
CREATE VIEW mod08.v_estado_acceso AS
SELECT
    u.id AS usuario_id,
    p.dni,
    CONCAT(p.nombres, ' ', p.apellidos) AS nombre,
    u.ultimo_acceso,
    NOT u.estado AS bloqueado,
    (SELECT MAX(il.fecha) FROM mod08.intentos_login il
      WHERE il.usuario_id = u.id AND il.exito = true) AS ultimo_login_exitoso,
    EXISTS (
        SELECT 1 FROM mod08.identidades_externas ie
        WHERE ie.usuario_id = u.id AND ie.desvinculado_en IS NULL
    ) AS tiene_google,
    (
        SELECT COUNT(*) FROM mod08.intentos_login f
        WHERE f.usuario_id = u.id
          AND f.exito = false
          AND f.proveedor = 'DNI_LOCAL'   -- solo fallos por DNI/contraseña
          AND f.fecha > now() - make_interval(mins => COALESCE(
                (SELECT pa.minutos_bloqueo FROM mod08.politicas_acceso pa
                  ORDER BY pa.id DESC LIMIT 1), 15))
          AND f.fecha > COALESCE(
                (SELECT MAX(s.fecha) FROM mod08.intentos_login s
                  WHERE s.usuario_id = u.id AND s.exito = true
                    AND s.proveedor = 'DNI_LOCAL'), '-infinity'::timestamptz)
    ) >= COALESCE(
        (SELECT pa.max_intentos_fallidos FROM mod08.politicas_acceso pa
          ORDER BY pa.id DESC LIMIT 1), 3) AS bloqueado_temporal,
    -- core.usuarios.password_hash trae '123456' por defecto (texto plano), así que
    -- "tiene clave" solo se considera cierto si el valor parece un hash bcrypt.
    (u.password_hash ~ '^\$2[aby]\$') AS tiene_password
FROM core.usuarios u
JOIN core.personas p ON u.persona_id = p.id;


-- ---------------------------------------------------------------------------------
-- politicas_acceso (fila inicial): fila inicial con los dominios reales de core.usuarios.email.
--    Con el valor por defecto anterior (@istpargentina.edu.pe) solo 4 de 77 usuarios
--    podrían entrar con Google. Varios dominios se separan con coma.
--    Ajusta la lista si alguno no es un dominio de Google Workspace de la institución.
-- ---------------------------------------------------------------------------------
ALTER TABLE mod08.politicas_acceso
    ALTER COLUMN dominios_google_permitidos
    SET DEFAULT '@iestpargentina.edu.pe,@ieargentina.edu.pe,@istpargentina.edu.pe';

INSERT INTO mod08.politicas_acceso
    (max_intentos_fallidos, minutos_bloqueo, vigencia_password_dias,
     dias_validez_sesion, dominios_google_permitidos)
SELECT 3, 15, 90, 1,
       '@iestpargentina.edu.pe,@ieargentina.edu.pe,@istpargentina.edu.pe'
WHERE NOT EXISTS (SELECT 1 FROM mod08.politicas_acceso);

-- =================================================================================
-- VERIFICACIÓN: debe devolver 0 filas (ninguna FK tuya apunta a tablas ajenas de mod08)
SELECT co.relname AS tabla_tuya, c.conname AS fk,
       nt.nspname || '.' || ct.relname AS apunta_a
FROM pg_constraint c
JOIN pg_class co     ON co.oid = c.conrelid
JOIN pg_namespace no ON no.oid = co.relnamespace
JOIN pg_roles ro     ON ro.oid = co.relowner
JOIN pg_class ct     ON ct.oid = c.confrelid
JOIN pg_namespace nt ON nt.oid = ct.relnamespace
JOIN pg_roles rt     ON rt.oid = ct.relowner
WHERE c.contype = 'f'
  AND no.nspname = 'mod08'
  AND ro.rolname = 'user_equipo08'
  AND NOT (nt.nspname = 'core'
           OR (nt.nspname = 'mod08' AND rt.rolname = 'user_equipo08'));

-- =================================================================================
-- PARTE D - CONSULTAS TÍPICAS DEL LOGIN (EJEMPLOS; $1, $2 son parámetros)
-- =================================================================================
-- Login por DNI (devuelve el hash para compararlo en la aplicación):
--   SELECT u.id, u.password_hash, u.estado, p.nombres, p.apellidos
--   FROM core.personas p JOIN core.usuarios u ON u.persona_id = p.id
--   WHERE p.dni = $1;
--
-- Login con Google (usuario ya vinculado):
--   SELECT u.id, u.estado FROM mod08.identidades_externas ie
--   JOIN core.usuarios u ON u.id = ie.usuario_id
--   WHERE ie.subject_externo = $1 AND ie.desvinculado_en IS NULL;
--
-- Primer ingreso con Google (enlazar por correo; verificar dominio en politicas_acceso):
--   SELECT u.id FROM core.usuarios u WHERE lower(u.email) = lower($1) AND u.estado;
--   INSERT INTO mod08.identidades_externas (usuario_id, subject_externo, email_externo, email_verificado)
--   VALUES ($1, $2, $3, true);
--
-- Registrar un intento (proveedor: 'DNI_LOCAL' o 'GOOGLE_SSO'):
--   INSERT INTO mod08.intentos_login (identificador_intentado, usuario_id, proveedor, exito, motivo, ip_origen, user_agent)
--   VALUES ($1, $2, 'DNI_LOCAL', false, 'Contraseña incorrecta', $3, $4);
--
-- Estado de acceso de un usuario (bloqueo por DNI, Google vinculado, método disponible):
--   SELECT bloqueado, bloqueado_temporal, tiene_google, tiene_password
--   FROM mod08.v_estado_acceso WHERE usuario_id = $1;
--
-- Crear sesión:
--   INSERT INTO mod08.sesiones_login (usuario_id, metodo_autenticacion, ip_origen, fecha_expiracion)
--   VALUES ($1, 'GOOGLE_SSO', $2, now() + make_interval(days => (SELECT dias_validez_sesion FROM mod08.politicas_acceso ORDER BY id DESC LIMIT 1)))
--   RETURNING id_sesion;
--
-- Actualizar último acceso (requiere UPDATE sobre core.usuarios.ultimo_acceso):
--   UPDATE core.usuarios SET ultimo_acceso = now() WHERE id = $1;
--
-- Panel lateral: módulos que puede ver un usuario según sus roles activos:
--   SELECT DISTINCT pm.nombre_modulo, pm.nivel_acceso
--   FROM core.usuario_roles ur
--   JOIN mod08.roles_permisos rp ON rp.rol_id = ur.rol_id
--   JOIN mod08.permisos_modulos pm ON pm.id_permiso = rp.permiso_id
--   WHERE ur.usuario_id = $1 AND ur.es_activo;
--
-- Asignar un rol (el trigger lo refleja en core.usuario_roles):
--   INSERT INTO mod08.asignaciones_rol (usuario_id, rol_id, asignado_por, motivo) VALUES ($1, $2, $3, $4);
-- Retirar un rol:
--   UPDATE mod08.asignaciones_rol SET retirado_en = now(), retirado_por = $2 WHERE id = $1;