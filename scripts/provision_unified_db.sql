-- ==============================================================================
-- 🏛️ PROVISIÓN DE BASE DE DATOS UNIFICADA - INTRANET IESTP ARGENTINA 2026
-- Servidor: mili2 (MariaDB 10.11 / phpMyAdmin puerto 8080)
-- Arquitectura: Base Unificada con Prefijos Bounded Context (core_* y mod01_* a mod09_*)
-- ==============================================================================

-- 1. CREACIÓN DE LA BASE DE DATOS PRINCIPAL
CREATE DATABASE IF NOT EXISTS `db_intranet_iestp` 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

USE `db_intranet_iestp`;

-- 2. USUARIO MAESTRO DE LA APLICACIÓN (CORE ENGINE)
CREATE USER IF NOT EXISTS 'user_app_core'@'%' IDENTIFIED BY 'CoreApp_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_app_core'@'%';

-- 3. USUARIOS DEDICADOS POR EQUIPO (01 AL 09)
-- Permisos: Acceso total para desarrollo y consultas sobre la base unificada

CREATE USER IF NOT EXISTS 'user_equipo01'@'%' IDENTIFIED BY 'Equipo01_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo01'@'%';

CREATE USER IF NOT EXISTS 'user_equipo02'@'%' IDENTIFIED BY 'Equipo02_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo02'@'%';

CREATE USER IF NOT EXISTS 'user_equipo03'@'%' IDENTIFIED BY 'Equipo03_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo03'@'%';

CREATE USER IF NOT EXISTS 'user_equipo04'@'%' IDENTIFIED BY 'Equipo04_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo04'@'%';

CREATE USER IF NOT EXISTS 'user_equipo05'@'%' IDENTIFIED BY 'Equipo05_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo05'@'%';

CREATE USER IF NOT EXISTS 'user_equipo06'@'%' IDENTIFIED BY 'Equipo06_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo06'@'%';

CREATE USER IF NOT EXISTS 'user_equipo07'@'%' IDENTIFIED BY 'Equipo07_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo07'@'%';

CREATE USER IF NOT EXISTS 'user_equipo08'@'%' IDENTIFIED BY 'Equipo08_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo08'@'%';

CREATE USER IF NOT EXISTS 'user_equipo09'@'%' IDENTIFIED BY 'Equipo09_Pass2026!';
GRANT ALL PRIVILEGES ON `db_intranet_iestp`.* TO 'user_equipo09'@'%';

FLUSH PRIVILEGES;
