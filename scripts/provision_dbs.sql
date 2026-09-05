-- ==============================================================================
-- 🏛️ PROVISIÓN DE BASES DE DATOS MODULARES - INTRANET INSTITUCIONAL 2026
-- Servidor: mili2 (MariaDB 10.11)
-- Arquitectura: Zero-Blast-Radius con Visibilidad Cruzada de Solo Lectura (SELECT)
-- ==============================================================================

-- 1. BASE DE DATOS CORE
CREATE DATABASE IF NOT EXISTS `db_core` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

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

-- 3. USUARIOS DEDICADOS POR EQUIPO
-- Cada equipo tiene ALL PRIVILEGES en su BD y SELECT ONLY en las otras 8 BDs + db_core

-- Equipo 1
CREATE USER IF NOT EXISTS 'user_equipo01'@'%' IDENTIFIED BY 'Equipo01_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo01`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo01'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo01'@'%';

-- Equipo 2
CREATE USER IF NOT EXISTS 'user_equipo02'@'%' IDENTIFIED BY 'Equipo02_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo02`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo02'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo02'@'%';

-- Equipo 3
CREATE USER IF NOT EXISTS 'user_equipo03'@'%' IDENTIFIED BY 'Equipo03_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo03`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo03'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo03'@'%';

-- Equipo 4
CREATE USER IF NOT EXISTS 'user_equipo04'@'%' IDENTIFIED BY 'Equipo04_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo04`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo04'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo04'@'%';

-- Equipo 5
CREATE USER IF NOT EXISTS 'user_equipo05'@'%' IDENTIFIED BY 'Equipo05_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo05`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo05'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo05'@'%';

-- Equipo 6
CREATE USER IF NOT EXISTS 'user_equipo06'@'%' IDENTIFIED BY 'Equipo06_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo06`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo06'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo06'@'%';

-- Equipo 7
CREATE USER IF NOT EXISTS 'user_equipo07'@'%' IDENTIFIED BY 'Equipo07_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo07`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo07'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo07'@'%';

-- Equipo 8
CREATE USER IF NOT EXISTS 'user_equipo08'@'%' IDENTIFIED BY 'Equipo08_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo08`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo08'@'%';
GRANT SELECT ON `db_modulo09`.* TO 'user_equipo08'@'%';

-- Equipo 9
CREATE USER IF NOT EXISTS 'user_equipo09'@'%' IDENTIFIED BY 'Equipo09_Pass2026!';
GRANT ALL PRIVILEGES ON `db_modulo09`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_core`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo01`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo02`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo03`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo04`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo05`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo06`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo07`.* TO 'user_equipo09'@'%';
GRANT SELECT ON `db_modulo08`.* TO 'user_equipo09'@'%';

FLUSH PRIVILEGES;
