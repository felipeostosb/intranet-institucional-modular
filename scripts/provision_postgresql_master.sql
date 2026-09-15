-- ==============================================================================
-- 🏛️ SCRIPT MAESTRO DE PROVISIÓN POSTGRESQL 16 - INTRANET IESTP ARGENTINA
-- Arquitectura: Monolito Modular con Aislamiento Estricto por Esquemas (Zero-Blast-Radius)
-- Motor: PostgreSQL 16 LTS | Servidor: ssh postgres (35.206.81.32)
-- Base de Datos: db_intranet_iestp
-- ==============================================================================

-- 1. CREACIÓN DE ESQUEMAS SOBERANOS
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS mod01; -- Matrícula
CREATE SCHEMA IF NOT EXISTS mod02; -- Asistencia
CREATE SCHEMA IF NOT EXISTS mod03; -- Calificaciones
CREATE SCHEMA IF NOT EXISTS mod04; -- Horarios & Aulas
CREATE SCHEMA IF NOT EXISTS mod05; -- Prácticas EFSRT
CREATE SCHEMA IF NOT EXISTS mod06; -- Mesa de Partes / TUPA
CREATE SCHEMA IF NOT EXISTS mod07; -- Biblioteca Virtual
CREATE SCHEMA IF NOT EXISTS mod08; -- Bolsa de Trabajo
CREATE SCHEMA IF NOT EXISTS mod09; -- Tesorería / Pagos

-- 2. CREACIÓN DE ROLES Y USUARIOS CON CONTRASEÑAS SEGURAS (ALTA ENTROPÍA / ZERO-PATTERN)
DO $$
BEGIN
    -- Usuario Core Engine
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_app_core') THEN
        CREATE USER user_app_core WITH ENCRYPTED PASSWORD 'IQ7#pHBI5jmN5XZmlw#SjaF9';
    ELSE
        ALTER USER user_app_core WITH ENCRYPTED PASSWORD 'IQ7#pHBI5jmN5XZmlw#SjaF9';
    END IF;

    -- Usuarios Modulares (Equipos 01 al 09)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo01') THEN
        CREATE USER user_equipo01 WITH ENCRYPTED PASSWORD 'MWsJkwHnstfp6Y92EF0p';
    ELSE
        ALTER USER user_equipo01 WITH ENCRYPTED PASSWORD 'MWsJkwHnstfp6Y92EF0p';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo02') THEN
        CREATE USER user_equipo02 WITH ENCRYPTED PASSWORD 'SVMa8ClAvXSRWQX6VtRF';
    ELSE
        ALTER USER user_equipo02 WITH ENCRYPTED PASSWORD 'SVMa8ClAvXSRWQX6VtRF';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo03') THEN
        CREATE USER user_equipo03 WITH ENCRYPTED PASSWORD 'Oiffu1yqL58#M!#_YFgI';
    ELSE
        ALTER USER user_equipo03 WITH ENCRYPTED PASSWORD 'Oiffu1yqL58#M!#_YFgI';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo04') THEN
        CREATE USER user_equipo04 WITH ENCRYPTED PASSWORD 'wbNb!rQaj1rs6WC2MiUw';
    ELSE
        ALTER USER user_equipo04 WITH ENCRYPTED PASSWORD 'wbNb!rQaj1rs6WC2MiUw';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo05') THEN
        CREATE USER user_equipo05 WITH ENCRYPTED PASSWORD 'G0wH7Yux@3j6gk8pj6Mf';
    ELSE
        ALTER USER user_equipo05 WITH ENCRYPTED PASSWORD 'G0wH7Yux@3j6gk8pj6Mf';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo06') THEN
        CREATE USER user_equipo06 WITH ENCRYPTED PASSWORD 'Pj0y2rLN2kBrjHZFTO9x';
    ELSE
        ALTER USER user_equipo06 WITH ENCRYPTED PASSWORD 'Pj0y2rLN2kBrjHZFTO9x';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo07') THEN
        CREATE USER user_equipo07 WITH ENCRYPTED PASSWORD '4rE2#yVPrEagn!fEzfVg';
    ELSE
        ALTER USER user_equipo07 WITH ENCRYPTED PASSWORD '4rE2#yVPrEagn!fEzfVg';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo08') THEN
        CREATE USER user_equipo08 WITH ENCRYPTED PASSWORD 'm6dQA0PFOJv6iRfNMu7H';
    ELSE
        ALTER USER user_equipo08 WITH ENCRYPTED PASSWORD 'm6dQA0PFOJv6iRfNMu7H';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_equipo09') THEN
        CREATE USER user_equipo09 WITH ENCRYPTED PASSWORD 'vkcITPMZMt1oKGB6BR6C';
    ELSE
        ALTER USER user_equipo09 WITH ENCRYPTED PASSWORD 'vkcITPMZMt1oKGB6BR6C';
    END IF;
END $$;

-- 3. ASIGNACIÓN DE PRIVILEGIOS DE BASE DE DATOS
GRANT CONNECT ON DATABASE db_intranet_iestp TO user_app_core, user_equipo01, user_equipo02, user_equipo03, user_equipo04, user_equipo05, user_equipo06, user_equipo07, user_equipo08, user_equipo09;

-- A. Privilegios para user_app_core (Acceso Total a todos los esquemas)
GRANT ALL ON SCHEMA core, mod01, mod02, mod03, mod04, mod05, mod06, mod07, mod08, mod09, public TO user_app_core;
GRANT ALL ON ALL TABLES IN SCHEMA core, mod01, mod02, mod03, mod04, mod05, mod06, mod07, mod08, mod09, public TO user_app_core;
GRANT ALL ON ALL SEQUENCES IN SCHEMA core, mod01, mod02, mod03, mod04, mod05, mod06, mod07, mod08, mod09, public TO user_app_core;

ALTER DEFAULT PRIVILEGES IN SCHEMA core, mod01, mod02, mod03, mod04, mod05, mod06, mod07, mod08, mod09, public GRANT ALL ON TABLES TO user_app_core;
ALTER DEFAULT PRIVILEGES IN SCHEMA core, mod01, mod02, mod03, mod04, mod05, mod06, mod07, mod08, mod09, public GRANT ALL ON SEQUENCES TO user_app_core;

ALTER USER user_app_core SET search_path TO core, public, mod01, mod02, mod03, mod04, mod05, mod06, mod07, mod08, mod09;

-- B. Función auxiliar para blindaje y privilegios de cada equipo
-- Cada user_equipoXX:
-- 1. Control total (CREATE, INSERT, UPDATE, DELETE, ALTER, DROP) sobre su esquema modXX.
-- 2. Lectura total (USAGE, SELECT) sobre el esquema core y sobre los esquemas de los demás equipos modYY.
-- 3. Cero permisos de escritura/creación en esquemas ajenos.

DO $$
DECLARE
    schemas TEXT[] := ARRAY['mod01', 'mod02', 'mod03', 'mod04', 'mod05', 'mod06', 'mod07', 'mod08', 'mod09'];
    users TEXT[] := ARRAY['user_equipo01', 'user_equipo02', 'user_equipo03', 'user_equipo04', 'user_equipo05', 'user_equipo06', 'user_equipo07', 'user_equipo08', 'user_equipo09'];
    i INT;
    j INT;
    curr_user TEXT;
    curr_schema TEXT;
    other_schema TEXT;
BEGIN
    FOR i IN 1..9 LOOP
        curr_user := users[i];
        curr_schema := schemas[i];

        -- 1. Control total en su propio esquema
        EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO %I', curr_schema, curr_user);
        EXECUTE format('GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA %I TO %I', curr_schema, curr_user);
        EXECUTE format('GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA %I TO %I', curr_schema, curr_user);
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON TABLES TO %I', curr_schema, curr_user);
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT ALL ON SEQUENCES TO %I', curr_schema, curr_user);

        -- 2. Acceso de solo lectura al esquema core
        EXECUTE format('GRANT USAGE ON SCHEMA core TO %I', curr_user);
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA core TO %I', curr_user);
        EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA core TO %I', curr_user);
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT ON TABLES TO %I', curr_user);
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT ON SEQUENCES TO %I', curr_user);

        -- 3. Acceso de solo lectura a los demás esquemas modulares (Visibilidad del panorama completo)
        FOR j IN 1..9 LOOP
            IF i <> j THEN
                other_schema := schemas[j];
                EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I', other_schema, curr_user);
                EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO %I', other_schema, curr_user);
                EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO %I', other_schema, curr_user);
                EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO %I', other_schema, curr_user);
                EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON SEQUENCES TO %I', other_schema, curr_user);
            END IF;
        END LOOP;

        -- 4. Establecer Search Path por defecto: su módulo primero, luego core y public
        EXECUTE format('ALTER USER %I SET search_path TO %I, core, public', curr_user, curr_schema);
    END LOOP;
END $$;

-- ==============================================================================
-- 4. TABLAS MAESTRAS DEL ESQUEMA CORE (Patrón Party-Role)
-- ==============================================================================

-- A. IDENTIDAD FÍSICA UNIFICADA
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

-- B. CUENTAS DE ACCESO (SSO INSTITUCIONAL)
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

-- C. ROLES INSTITUCIONALES
CREATE TABLE IF NOT EXISTS core.roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200) NOT NULL
);

-- D. USUARIO - ROLES (Muchos a Muchos)
CREATE TABLE IF NOT EXISTS core.usuario_roles (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE CASCADE,
    rol_id INT NOT NULL REFERENCES core.roles(id) ON DELETE CASCADE,
    asignado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    es_activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uk_usuario_rol UNIQUE (usuario_id, rol_id)
);

-- E. ESTRUCTURA ACADÉMICA
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
    pabellon VARCHAR(10) NOT NULL,
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

-- F. PERFILES DE ROL EXTENDIDOS
CREATE TABLE IF NOT EXISTS core.estudiantes (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE CASCADE,
    codigo_estudiante VARCHAR(30) NOT NULL UNIQUE,
    carrera_id INT NOT NULL REFERENCES core.carreras(id) ON DELETE RESTRICT,
    periodo_ingreso_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    ciclo_actual VARCHAR(5) NOT NULL DEFAULT 'I' CHECK (ciclo_actual IN ('I', 'II', 'III', 'IV', 'V', 'VI')),
    turno VARCHAR(10) NOT NULL DEFAULT 'Manana' CHECK (turno IN ('Manana', 'Tarde', 'Noche')),
    condicion VARCHAR(15) NOT NULL DEFAULT 'Regular' CHECK (condicion IN ('Regular', 'Irregular', 'Egresado', 'Titulado'))
);

CREATE TABLE IF NOT EXISTS core.docentes (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE CASCADE,
    codigo_docente VARCHAR(30) NOT NULL UNIQUE,
    carrera_principal_id INT NULL REFERENCES core.carreras(id) ON DELETE SET NULL,
    profesion VARCHAR(150) NOT NULL,
    grado_academico VARCHAR(100) NOT NULL DEFAULT 'Licenciado / Ingeniero',
    condicion VARCHAR(15) NOT NULL DEFAULT 'Contratado' CHECK (condicion IN ('Nombrado', 'Contratado'))
);

CREATE TABLE IF NOT EXISTS core.administrativos (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id) ON DELETE CASCADE,
    codigo_staff VARCHAR(30) NOT NULL UNIQUE,
    cargo VARCHAR(100) NOT NULL,
    area VARCHAR(100) NOT NULL
);

-- G. AUDITORÍA GLOBAL
CREATE TABLE IF NOT EXISTS core.auditoria_logs (
    id SERIAL PRIMARY KEY,
    usuario_id INT NULL REFERENCES core.usuarios(id) ON DELETE SET NULL,
    modulo VARCHAR(50) NOT NULL,
    accion VARCHAR(50) NOT NULL,
    entidad VARCHAR(50) NOT NULL,
    detalle_json JSONB NULL,
    ip VARCHAR(45) NULL,
    fecha TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 5. TABLAS INICIALES DE EJEMPLO EN CADA ESQUEMA MODULAR
-- ==============================================================================

CREATE TABLE IF NOT EXISTS mod01.matriculas (
    id SERIAL PRIMARY KEY,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id),
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id),
    codigo VARCHAR(50) NOT NULL UNIQUE,
    fecha_matricula TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'Registrada',
    observaciones TEXT NULL
);

CREATE TABLE IF NOT EXISTS mod02.asistencias (
    id SERIAL PRIMARY KEY,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id),
    unidad_didactica_id INT NOT NULL REFERENCES core.unidades_didacticas(id),
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    estado VARCHAR(15) NOT NULL DEFAULT 'Presente' CHECK (estado IN ('Presente', 'Falta', 'Tardanza', 'Justificado')),
    registrado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mod03.calificaciones (
    id SERIAL PRIMARY KEY,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id),
    unidad_didactica_id INT NOT NULL REFERENCES core.unidades_didacticas(id),
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id),
    evaluacion_1 NUMERIC(4,2) NULL,
    evaluacion_2 NUMERIC(4,2) NULL,
    evaluacion_3 NUMERIC(4,2) NULL,
    promedio_final NUMERIC(4,2) NULL,
    estado VARCHAR(15) NOT NULL DEFAULT 'En Curso'
);

CREATE TABLE IF NOT EXISTS mod04.horarios (
    id SERIAL PRIMARY KEY,
    unidad_didactica_id INT NOT NULL REFERENCES core.unidades_didacticas(id),
    docente_id INT NOT NULL REFERENCES core.docentes(id),
    aula_id INT NOT NULL REFERENCES core.aulas(id),
    dia_semana VARCHAR(15) NOT NULL CHECK (dia_semana IN ('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado')),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    seccion VARCHAR(10) NOT NULL DEFAULT 'A'
);

CREATE TABLE IF NOT EXISTS mod05.practicas (
    id SERIAL PRIMARY KEY,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id),
    empresa_razon_social VARCHAR(150) NOT NULL,
    empresa_ruc VARCHAR(15) NOT NULL,
    modulo_formativo VARCHAR(5) NOT NULL CHECK (modulo_formativo IN ('MF1', 'MF2', 'MF3')),
    total_horas INT NOT NULL DEFAULT 280,
    estado VARCHAR(20) NOT NULL DEFAULT 'En_Revision'
);

CREATE TABLE IF NOT EXISTS mod06.tramites_tupa (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id),
    numero_expediente VARCHAR(30) NOT NULL UNIQUE,
    tipo_tramite VARCHAR(100) NOT NULL,
    asunto VARCHAR(200) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    fecha_ingreso TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mod07.libros (
    id SERIAL PRIMARY KEY,
    isbn VARCHAR(30) NULL,
    titulo VARCHAR(200) NOT NULL,
    autor VARCHAR(150) NOT NULL,
    carrera_id INT NULL REFERENCES core.carreras(id),
    ejemplares_disponibles INT NOT NULL DEFAULT 1,
    url_digital VARCHAR(255) NULL
);

CREATE TABLE IF NOT EXISTS mod08.ofertas_laborales (
    id SERIAL PRIMARY KEY,
    empresa_nombre VARCHAR(150) NOT NULL,
    titulo_puesto VARCHAR(150) NOT NULL,
    carrera_id INT NOT NULL REFERENCES core.carreras(id),
    descripcion TEXT NOT NULL,
    vacantes INT NOT NULL DEFAULT 1,
    fecha_limite DATE NOT NULL,
    contacto_email VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS mod09.pagos (
    id SERIAL PRIMARY KEY,
    persona_id INT NOT NULL REFERENCES core.personas(id),
    codigo_recibo VARCHAR(30) NOT NULL UNIQUE,
    concepto VARCHAR(150) NOT NULL,
    monto NUMERIC(8,2) NOT NULL,
    metodo_pago VARCHAR(30) NOT NULL DEFAULT 'Efectivo',
    fecha_pago TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pagado'
);

-- ==============================================================================
-- 6. DATOS SEMILLA OFICIALES IESTP ARGENTINA
-- ==============================================================================

-- Roles
INSERT INTO core.roles (id, nombre, descripcion) VALUES
(1, 'Admin', 'Administrador General del Sistema y TI'),
(2, 'Director', 'Dirección General Institucional'),
(3, 'Coordinador', 'Coordinación Académica de Área / Carrera'),
(4, 'Secretaria', 'Secretaría Académica y Trámites'),
(5, 'Tesoreria', 'Área de Tesorería, Facturación y Caja'),
(6, 'Docente', 'Plana Docente'),
(7, 'Alumno', 'Estudiante de Carrera Profesional')
ON CONFLICT (id) DO UPDATE SET nombre = EXCLUDED.nombre, descripcion = EXCLUDED.descripcion;

SELECT setval('core.roles_id_seq', (SELECT MAX(id) FROM core.roles));

-- Carreras (3 Oficiales)
INSERT INTO core.carreras (id, codigo, nombre, total_semestres, modalidad) VALUES
(1, 'DSI', 'Desarrollo de Sistemas de Información', 6, 'Presencial'),
(2, 'CONT', 'Contabilidad', 6, 'Presencial'),
(3, 'ADM', 'Administración de Empresas', 6, 'Presencial')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo, nombre = EXCLUDED.nombre;

SELECT setval('core.carreras_id_seq', (SELECT MAX(id) FROM core.carreras));

-- Periodos Académicos
INSERT INTO core.periodos_academicos (id, codigo, fecha_inicio, fecha_fin, es_activo, permite_matricula) VALUES
(1, '2026-I', '2026-03-15', '2026-07-25', TRUE, TRUE),
(2, '2026-II', '2026-08-15', '2026-12-20', FALSE, FALSE)
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo;

SELECT setval('core.periodos_academicos_id_seq', (SELECT MAX(id) FROM core.periodos_academicos));

-- Aulas
INSERT INTO core.aulas (id, codigo, pabellon, aforo, tipo) VALUES
(1, 'LAB-COMP-01', 'Pabellon A', 35, 'Laboratorio_Computo'),
(2, 'LAB-COMP-02', 'Pabellon A', 35, 'Laboratorio_Computo'),
(3, 'AULA-TEO-101', 'Pabellon B', 40, 'Teoria'),
(4, 'AULA-TEO-102', 'Pabellon B', 40, 'Teoria')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo;

SELECT setval('core.aulas_id_seq', (SELECT MAX(id) FROM core.aulas));

-- Unidades Didácticas
INSERT INTO core.unidades_didacticas (id, carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo) VALUES
(1, 1, 'I', 'DSI-101', 'Introducción a la Algoritmia y Programación', 4, 6, 'Formativa'),
(2, 1, 'I', 'DSI-102', 'Arquitectura de Computadoras y Redes', 3, 4, 'Formativa'),
(3, 1, 'II', 'DSI-201', 'Bases de Datos y Modelamiento SQL', 4, 6, 'Formativa'),
(4, 1, 'II', 'DSI-202', 'Programación Orientada a Objetos en C#', 4, 6, 'Formativa'),
(5, 1, 'III', 'DSI-301', 'Desarrollo de Aplicaciones Web y Servicios', 4, 6, 'Formativa'),
(6, 1, 'III', 'DSI-302', 'Ingeniería de Requerimientos y Casos de Uso', 3, 4, 'Formativa'),
(7, 2, 'I', 'CONT-101', 'Contabilidad Básica y Principios Contables', 4, 6, 'Formativa'),
(8, 2, 'I', 'CONT-102', 'Legislación Tributaria y Laboral', 3, 4, 'Transversal')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo;

SELECT setval('core.unidades_didacticas_id_seq', (SELECT MAX(id) FROM core.unidades_didacticas));

-- Personas Físicas
INSERT INTO core.personas (id, dni, nombres, apellidos, email_personal, telefono, sexo) VALUES
(1, '00000001', 'Administrador', 'General de TI', 'admin.ti@ieargentina.edu.pe', '999000001', 'M'),
(2, '10000001', 'Manuel', 'Alvarado Carranza', 'manuel.alvarado@gmail.com', '999100001', 'M'),
(3, '20000001', 'Carlos', 'Mendoza Rivas', 'carlos.mendoza@gmail.com', '999200001', 'M'),
(4, '30000001', 'Rosa', 'Morales Salazar', 'rosa.morales@gmail.com', '999300001', 'F'),
(5, '40000001', 'Elena', 'Ramos Palacios', 'elena.ramos@gmail.com', '999400001', 'F'),
(6, '12345678', 'Roberto', 'Sánchez Benítez', 'rsanchez.prof@gmail.com', '999123456', 'M'),
(7, '87654321', 'Felipe', 'Ostos', 'felipe.ostos@gmail.com', '999876543', 'M'),
(8, '77654321', 'Ana', 'García Flores', 'ana.garcia@gmail.com', '999776543', 'F'),
(9, '66554433', 'Luis', 'Torres Quispe', 'luis.torres@gmail.com', '999665544', 'M')
ON CONFLICT (id) DO UPDATE SET dni = EXCLUDED.dni, nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

SELECT setval('core.personas_id_seq', (SELECT MAX(id) FROM core.personas));

-- Usuarios
INSERT INTO core.usuarios (id, persona_id, codigo_institucional, email, password_hash, estado) VALUES
(1, 1, 'ADMIN-2026', 'admin.ti@ieargentina.edu.pe', '123456', TRUE),
(2, 2, 'DIR-2026', 'direccion@ieargentina.edu.pe', '123456', TRUE),
(3, 3, 'COORD-DSI', 'coord.sistemas@ieargentina.edu.pe', '123456', TRUE),
(4, 4, 'SEC-ACAD', 'secretaria.academica@ieargentina.edu.pe', '123456', TRUE),
(5, 5, 'TES-2026', 'tesoreria@ieargentina.edu.pe', '123456', TRUE),
(6, 6, 'DOC-DSI-01', 'rsanchez@ieargentina.edu.pe', '123456', TRUE),
(7, 7, 'EST-DSI-001', 'felipe.ostos@ieargentina.edu.pe', '123456', TRUE),
(8, 8, 'EST-DSI-002', 'ana.garcia@ieargentina.edu.pe', '123456', TRUE),
(9, 9, 'EST-CONT-001', 'luis.torres@ieargentina.edu.pe', '123456', TRUE)
ON CONFLICT (id) DO UPDATE SET codigo_institucional = EXCLUDED.codigo_institucional;

SELECT setval('core.usuarios_id_seq', (SELECT MAX(id) FROM core.usuarios));

-- Asignación de Roles
INSERT INTO core.usuario_roles (id, usuario_id, rol_id) VALUES
(1, 1, 1),
(2, 2, 2),
(3, 3, 3),
(4, 4, 4),
(5, 5, 5),
(6, 6, 6),
(7, 7, 7),
(8, 7, 6),
(9, 7, 1),
(10, 8, 7),
(11, 9, 7)
ON CONFLICT (id) DO NOTHING;

SELECT setval('core.usuario_roles_id_seq', (SELECT MAX(id) FROM core.usuario_roles));

-- Estudiantes
INSERT INTO core.estudiantes (id, persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion) VALUES
(1, 7, 'EST-DSI-2026-001', 1, 1, 'III', 'Noche', 'Regular'),
(2, 8, 'EST-DSI-2026-002', 1, 1, 'III', 'Manana', 'Regular'),
(3, 9, 'EST-CONT-2026-001', 2, 1, 'I', 'Noche', 'Regular')
ON CONFLICT (id) DO UPDATE SET codigo_estudiante = EXCLUDED.codigo_estudiante;

SELECT setval('core.estudiantes_id_seq', (SELECT MAX(id) FROM core.estudiantes));

-- Docentes
INSERT INTO core.docentes (id, persona_id, codigo_docente, carrera_principal_id, profesion, condicion) VALUES
(1, 6, 'DOC-DSI-001', 1, 'Ingeniero de Sistemas e Informática', 'Nombrado'),
(2, 7, 'DOC-DSI-002', 1, 'Senior Backend & Systems Engineer', 'Contratado')
ON CONFLICT (id) DO UPDATE SET codigo_docente = EXCLUDED.codigo_docente;

SELECT setval('core.docentes_id_seq', (SELECT MAX(id) FROM core.docentes));

-- Administrativos
INSERT INTO core.administrativos (id, persona_id, codigo_staff, cargo, area) VALUES
(1, 4, 'ADM-SEC-01', 'Secretaria Académica', 'Secretaría General'),
(2, 5, 'ADM-TES-01', 'Jefa de Caja y Tesorería', 'Tesorería')
ON CONFLICT (id) DO UPDATE SET codigo_staff = EXCLUDED.codigo_staff;

SELECT setval('core.administrativos_id_seq', (SELECT MAX(id) FROM core.administrativos));
