-- ==============================================================================
-- 🗄️ ESQUEMA DE BASE DE DATOS: mod06 (Equipo 06) - PostgreSQL 16
-- ==============================================================================
-- Este archivo se ejecuta automáticamente al arrancar la aplicación.
-- Agrega aquí tus sentencias CREATE TABLE con IF NOT EXISTS para tu módulo.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS mod06.t_modulo06_registros (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS mod06.tramites_tupa_06 (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    denominacion VARCHAR(150) NOT NULL,
    requisitos TEXT NULL,
    costo NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS mod06.expedientes_06 (
    id SERIAL PRIMARY KEY,
    numero_expediente VARCHAR(50) NOT NULL UNIQUE,
    solicitante_persona_id INT NOT NULL REFERENCES core.personas(id),
    tramite_tupa_id INT NOT NULL REFERENCES mod06.tramites_tupa_06(id),
    estado VARCHAR(50) NOT NULL DEFAULT 'Pendiente',
    fecha_ingreso TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT NULL
);

