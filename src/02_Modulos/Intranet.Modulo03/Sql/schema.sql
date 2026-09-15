-- ==============================================================================
-- 🗄️ ESQUEMA DE BASE DE DATOS: mod03 (Equipo 03) - PostgreSQL 16
-- ==============================================================================
-- Este archivo se ejecuta automáticamente al arrancar la aplicación.
-- Agrega aquí tus sentencias CREATE TABLE con IF NOT EXISTS para tu módulo.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS mod03.t_modulo03_registros (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);
