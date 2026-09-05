-- ==============================================================================
-- 🏛️ PROVISIÓN DE BASES DE DATOS MODULARES - INTRANET INSTITUCIONAL 2026
-- Servidor: mili2 (MariaDB 10.11)
-- Arquitectura: Zero-Blast-Radius (Aislamiento Total por Equipo)
-- ==============================================================================

-- 1. BASE DE DATOS CORE
CREATE DATABASE IF NOT EXISTS `db_core` 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

USE `db_core`;

CREATE TABLE IF NOT EXISTS `core_usuarios` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `Dni` VARCHAR(20) NOT NULL UNIQUE,
  `CodigoInstitucional` VARCHAR(50) NOT NULL UNIQUE,
  `Nombres` VARCHAR(100) NOT NULL,
  `Apellidos` VARCHAR(100) NOT NULL,
  `Email` VARCHAR(150) NOT NULL,
  `Rol` VARCHAR(50) NOT NULL DEFAULT 'Alumno',
  `Estado` TINYINT(1) NOT NULL DEFAULT 1,
  `CreadoEn` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Usuarios Semilla (Seed Data)
INSERT IGNORE INTO `core_usuarios` (`Id`, `Dni`, `CodigoInstitucional`, `Nombres`, `Apellidos`, `Email`, `Rol`, `Estado`) VALUES
(1, '00000001', 'ADMIN-2026', 'Administrador', 'General', 'admin@instituto.edu.pe', 'Admin', 1),
(2, '12345678', 'DOC-2026-01', 'Profesor', 'Pérez', 'docente.perez@instituto.edu.pe', 'Docente', 1),
(3, '87654321', 'EST-2026-001', 'Felipe', 'Ostos', 'felipe.ostos@instituto.edu.pe', 'Alumno', 1),
(4, '77654321', 'EST-2026-002', 'Ana', 'García', 'ana.garcia@instituto.edu.pe', 'Alumno', 1);

-- 2. BASES DE DATOS MODULARES (01 AL 09)
CREATE DATABASE IF NOT EXISTS `db_modulo01` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo02` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo03` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo04` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo05` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo06` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo07` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo08` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS `db_modulo09` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Tablas de ejemplo iniciales por módulo para que tengan estructura base
USE `db_modulo01`;
CREATE TABLE IF NOT EXISTS `m01_admisiones` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `usuario_id` INT NOT NULL COMMENT 'FK lógica a db_core.core_usuarios',
  `carrera` VARCHAR(100) NOT NULL,
  `periodo` VARCHAR(20) NOT NULL,
  `estado_postulacion` VARCHAR(50) DEFAULT 'Pendiente',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo02`;
CREATE TABLE IF NOT EXISTS `m02_matriculas` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `usuario_id` INT NOT NULL COMMENT 'FK lógica a db_core.core_usuarios',
  `semestre` VARCHAR(20) NOT NULL,
  `creditos_totales` INT DEFAULT 0,
  `fecha_matricula` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo03`;
CREATE TABLE IF NOT EXISTS `m03_docentes_asignaciones` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `docente_usuario_id` INT NOT NULL,
  `curso_codigo` VARCHAR(50) NOT NULL,
  `aula` VARCHAR(30),
  `turno` VARCHAR(20)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo04`;
CREATE TABLE IF NOT EXISTS `m04_calificaciones` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `alumno_usuario_id` INT NOT NULL,
  `curso_id` INT NOT NULL,
  `nota_eval_1` DECIMAL(5,2) DEFAULT 0,
  `nota_eval_2` DECIMAL(5,2) DEFAULT 0,
  `nota_final` DECIMAL(5,2) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo05`;
CREATE TABLE IF NOT EXISTS `m05_pagos` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `alumno_usuario_id` INT NOT NULL,
  `concepto` VARCHAR(150) NOT NULL,
  `monto` DECIMAL(10,2) NOT NULL,
  `estado` VARCHAR(30) DEFAULT 'Pendiente',
  `fecha_vencimiento` DATE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo06`;
CREATE TABLE IF NOT EXISTS `m06_prestamos_libros` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `usuario_id` INT NOT NULL,
  `libro_titulo` VARCHAR(200) NOT NULL,
  `fecha_prestamo` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `fecha_devolucion` DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo07`;
CREATE TABLE IF NOT EXISTS `m07_tramites_mesa_partes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `usuario_id` INT NOT NULL,
  `tipo_tramite` VARCHAR(100) NOT NULL,
  `numero_expediente` VARCHAR(50) UNIQUE,
  `estado` VARCHAR(50) DEFAULT 'En Revision'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo08`;
CREATE TABLE IF NOT EXISTS `m08_ofertas_laborales` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `empresa_nombre` VARCHAR(150) NOT NULL,
  `puesto` VARCHAR(150) NOT NULL,
  `requisitos` TEXT,
  `contacto_email` VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

USE `db_modulo09`;
CREATE TABLE IF NOT EXISTS `m09_tickets_soporte` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `usuario_id` INT NOT NULL,
  `asunto` VARCHAR(150) NOT NULL,
  `descripcion` TEXT NOT NULL,
  `prioridad` VARCHAR(20) DEFAULT 'Media',
  `estado` VARCHAR(30) DEFAULT 'Abierto'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. USUARIOS DEDICADOS POR EQUIPO (Con permisos estrictos y aislados)
-- Equipo 1
CREATE USER IF NOT EXISTS 'user_equipo01'@'%' IDENTIFIED BY 'Equipo01_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo01`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo01'@'%';

-- Equipo 2
CREATE USER IF NOT EXISTS 'user_equipo02'@'%' IDENTIFIED BY 'Equipo02_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo02`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo02'@'%';

-- Equipo 3
CREATE USER IF NOT EXISTS 'user_equipo03'@'%' IDENTIFIED BY 'Equipo03_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo03`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo03'@'%';

-- Equipo 4
CREATE USER IF NOT EXISTS 'user_equipo04'@'%' IDENTIFIED BY 'Equipo04_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo04`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo04'@'%';

-- Equipo 5
CREATE USER IF NOT EXISTS 'user_equipo05'@'%' IDENTIFIED BY 'Equipo05_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo05`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo05'@'%';

-- Equipo 6
CREATE USER IF NOT EXISTS 'user_equipo06'@'%' IDENTIFIED BY 'Equipo06_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo06`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo06'@'%';

-- Equipo 7
CREATE USER IF NOT EXISTS 'user_equipo07'@'%' IDENTIFIED BY 'Equipo07_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo07`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo07'@'%';

-- Equipo 8
CREATE USER IF NOT EXISTS 'user_equipo08'@'%' IDENTIFIED BY 'Equipo08_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo08`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo08'@'%';

-- Equipo 9
CREATE USER IF NOT EXISTS 'user_equipo09'@'%' IDENTIFIED BY 'Equipo09_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo09`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_core`.`core_usuarios` TO 'user_equipo09'@'%';

FLUSH PRIVILEGES;
