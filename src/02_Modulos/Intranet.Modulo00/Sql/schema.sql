-- ==============================================================================
-- 🏛️ ESQUEMA SOBERANO mod00: LOGIN, SEGURIDAD & AUDITORÍA DE ACCESOS
-- Equipo 00: Toro | Motor: PostgreSQL 16
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS mod00;

-- 1. Tabla de Auditoría de Intentos y Sesiones de Login
CREATE TABLE IF NOT EXISTS mod00.logs_acceso (
  id SERIAL PRIMARY KEY,
  usuario_id INT NULL,
  identificador VARCHAR(50) NOT NULL,
  ip_origen VARCHAR(45) NOT NULL,
  user_agent TEXT NULL,
  exitoso BOOLEAN NOT NULL DEFAULT TRUE,
  motivo_fallo VARCHAR(100) NULL,
  fecha_acceso TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Tokens de Recuperación de Contraseña
CREATE TABLE IF NOT EXISTS mod00.tokens_recuperacion (
  id SERIAL PRIMARY KEY,
  usuario_id INT NOT NULL,
  token_hash VARCHAR(128) NOT NULL,
  expira_en TIMESTAMP WITH TIME ZONE NOT NULL,
  usado BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Políticas de Seguridad Institucional
CREATE TABLE IF NOT EXISTS mod00.politicas_seguridad (
  id SERIAL PRIMARY KEY,
  max_intentos_fallidos INT NOT NULL DEFAULT 5,
  tiempo_bloqueo_minutos INT NOT NULL DEFAULT 15,
  longitud_minima_password INT NOT NULL DEFAULT 8,
  requiere_caracter_especial BOOLEAN NOT NULL DEFAULT FALSE,
  dias_expiracion_password INT NOT NULL DEFAULT 90,
  actualizado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_logs_acceso_identificador ON mod00.logs_acceso (identificador);
CREATE INDEX IF NOT EXISTS idx_logs_acceso_fecha ON mod00.logs_acceso (fecha_acceso DESC);
