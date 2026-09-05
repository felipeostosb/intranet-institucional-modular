-- ==============================================================================
-- 🗄️ ESQUEMA DE BASE DE DATOS: db_modulo08 (Equipo 08)
-- ==============================================================================
-- Este archivo se ejecuta automáticamente al arrancar la aplicación.
-- Agrega aquí tus sentencias CREATE TABLE con IF NOT EXISTS para tu módulo.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS t_modulo08_registros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
