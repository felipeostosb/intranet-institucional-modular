-- ==============================================================================
-- 🏛️ ESQUEMA MAESTRO CORE - INTRANET INSTITUCIONAL IESTP "ARGENTINA"
-- Patrón: Party-Role (Martin Fowler / GibbonEdu) + Bounded Contexts
-- Base de Datos: db_intranet_iestp (MariaDB 10.11 / MySQL 8.0)
-- ==============================================================================

-- 1. IDENTIDAD FÍSICA UNIFICADA (PERSONA FÍSICA ÚNICA)
CREATE TABLE IF NOT EXISTS `core_personas` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `Dni` VARCHAR(15) NOT NULL UNIQUE,
  `Nombres` VARCHAR(100) NOT NULL,
  `Apellidos` VARCHAR(100) NOT NULL,
  `FechaNacimiento` DATE NULL,
  `Sexo` ENUM('M', 'F', 'Otro') NOT NULL DEFAULT 'M',
  `EmailPersonal` VARCHAR(150) NULL,
  `Telefono` VARCHAR(20) NULL,
  `Direccion` VARCHAR(255) NULL,
  `FotoUrl` VARCHAR(255) NULL,
  `CreadoEn` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. CUENTA DE ACCESO / AUTENTICACIÓN (SSO CENTRALIZADO)
CREATE TABLE IF NOT EXISTS `core_usuarios` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `PersonaId` INT NOT NULL UNIQUE,
  `CodigoInstitucional` VARCHAR(50) NOT NULL UNIQUE,
  `Email` VARCHAR(150) NOT NULL UNIQUE,
  `PasswordHash` VARCHAR(255) NOT NULL DEFAULT '123456',
  `UltimoAcceso` DATETIME NULL,
  `Estado` TINYINT(1) NOT NULL DEFAULT 1,
  `CreadoEn` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_usuarios_persona` FOREIGN KEY (`PersonaId`) REFERENCES `core_personas` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. CATÁLOGO DE ROLES INSTITUCIONALES
CREATE TABLE IF NOT EXISTS `core_roles` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `Nombre` VARCHAR(50) NOT NULL UNIQUE,
  `Descripcion` VARCHAR(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ASIGNACIÓN DE ROLES (MUCHOS A MUCHOS: 1 USUARIO PUEDE SER DOCENTE, ALUMNO Y ADMIN)
CREATE TABLE IF NOT EXISTS `core_usuario_roles` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `UsuarioId` INT NOT NULL,
  `RolId` INT NOT NULL,
  `AsignadoEn` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `EsActivo` TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY `uk_usuario_rol` (`UsuarioId`, `RolId`),
  CONSTRAINT `fk_user_roles_usuario` FOREIGN KEY (`UsuarioId`) REFERENCES `core_usuarios` (`Id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_roles_rol` FOREIGN KEY (`RolId`) REFERENCES `core_roles` (`Id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. ESTRUCTURA ACADÉMICA (CARRERAS Y PERIODOS)
CREATE TABLE IF NOT EXISTS `core_carreras` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `Codigo` VARCHAR(15) NOT NULL UNIQUE,
  `Nombre` VARCHAR(150) NOT NULL,
  `TotalSemestres` INT NOT NULL DEFAULT 6,
  `Modalidad` ENUM('Presencial', 'Semipresencial', 'Dual') NOT NULL DEFAULT 'Presencial',
  `Estado` TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `core_periodos_academicos` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `Codigo` VARCHAR(20) NOT NULL UNIQUE,
  `FechaInicio` DATE NOT NULL,
  `FechaFin` DATE NOT NULL,
  `EsActivo` TINYINT(1) NOT NULL DEFAULT 0,
  `PermiteMatricula` TINYINT(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `core_aulas` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `Codigo` VARCHAR(20) NOT NULL UNIQUE,
  `Pabellon` VARCHAR(10) NOT NULL,
  `Aforo` INT NOT NULL DEFAULT 35,
  `Tipo` ENUM('Teoria', 'Laboratorio_Computo', 'Taller') NOT NULL DEFAULT 'Teoria'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. PLAN CURRICULAR Y ASIGNATURAS (UNIDADES DIDÁCTICAS)
CREATE TABLE IF NOT EXISTS `core_unidades_didacticas` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `CarreraId` INT NOT NULL,
  `Ciclo` ENUM('I', 'II', 'III', 'IV', 'V', 'VI') NOT NULL,
  `Codigo` VARCHAR(20) NOT NULL UNIQUE,
  `Nombre` VARCHAR(150) NOT NULL,
  `Creditos` INT NOT NULL DEFAULT 3,
  `HorasSemanales` INT NOT NULL DEFAULT 4,
  `Tipo` ENUM('Formativa', 'Transversal', 'Empleabilidad') NOT NULL DEFAULT 'Formativa',
  CONSTRAINT `fk_unidades_carrera` FOREIGN KEY (`CarreraId`) REFERENCES `core_carreras` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. PERFILES DE ROL EXTENDIDOS
CREATE TABLE IF NOT EXISTS `core_estudiantes` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `PersonaId` INT NOT NULL,
  `CodigoEstudiante` VARCHAR(30) NOT NULL UNIQUE,
  `CarreraId` INT NOT NULL,
  `PeriodoIngresoId` INT NOT NULL,
  `CicloActual` ENUM('I', 'II', 'III', 'IV', 'V', 'VI') NOT NULL DEFAULT 'I',
  `Turno` ENUM('Manana', 'Tarde', 'Noche') NOT NULL DEFAULT 'Manana',
  `Condicion` ENUM('Regular', 'Irregular', 'Egresado', 'Titulado') NOT NULL DEFAULT 'Regular',
  CONSTRAINT `fk_estudiantes_persona` FOREIGN KEY (`PersonaId`) REFERENCES `core_personas` (`Id`),
  CONSTRAINT `fk_estudiantes_carrera` FOREIGN KEY (`CarreraId`) REFERENCES `core_carreras` (`Id`),
  CONSTRAINT `fk_estudiantes_periodo` FOREIGN KEY (`PeriodoIngresoId`) REFERENCES `core_periodos_academicos` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `core_docentes` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `PersonaId` INT NOT NULL,
  `CodigoDocente` VARCHAR(30) NOT NULL UNIQUE,
  `CarreraPrincipalId` INT NULL,
  `Profesion` VARCHAR(150) NOT NULL,
  `GradoAcademico` VARCHAR(100) NOT NULL DEFAULT 'Licenciado / Ingeniero',
  `Condicion` ENUM('Nombrado', 'Contratado') NOT NULL DEFAULT 'Contratado',
  CONSTRAINT `fk_docentes_persona` FOREIGN KEY (`PersonaId`) REFERENCES `core_personas` (`Id`),
  CONSTRAINT `fk_docentes_carrera` FOREIGN KEY (`CarreraPrincipalId`) REFERENCES `core_carreras` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `core_administrativos` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `PersonaId` INT NOT NULL,
  `CodigoStaff` VARCHAR(30) NOT NULL UNIQUE,
  `Cargo` VARCHAR(100) NOT NULL,
  `Area` VARCHAR(100) NOT NULL,
  CONSTRAINT `fk_admin_persona` FOREIGN KEY (`PersonaId`) REFERENCES `core_personas` (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. AUDITORÍA GLOBAL DE TRAZABILIDAD
CREATE TABLE IF NOT EXISTS `core_auditoria_logs` (
  `Id` INT AUTO_INCREMENT PRIMARY KEY,
  `UsuarioId` INT NULL,
  `Modulo` VARCHAR(50) NOT NULL,
  `Accion` VARCHAR(50) NOT NULL,
  `Entidad` VARCHAR(50) NOT NULL,
  `DetalleJson` TEXT NULL,
  `Ip` VARCHAR(45) NULL,
  `Fecha` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==============================================================================
-- 🚀 DATOS SEMILLA OFICIALES - IESTP "ARGENTINA"
-- ==============================================================================

-- 1. Roles
INSERT IGNORE INTO `core_roles` (`Id`, `Nombre`, `Descripcion`) VALUES
(1, 'Admin', 'Administrador General del Sistema y TI'),
(2, 'Director', 'Dirección General Institucional'),
(3, 'Coordinador', 'Coordinación Académica de Área / Carrera'),
(4, 'Secretaria', 'Secretaría Académica y Trámites'),
(5, 'Tesoreria', 'Área de Tesorería, Facturación y Caja'),
(6, 'Docente', 'Plana Docente'),
(7, 'Alumno', 'Estudiante de Carrera Profesional');

-- 2. Carreras Profesionales del IESTP Argentina
INSERT IGNORE INTO `core_carreras` (`Id`, `Codigo`, `Nombre`, `TotalSemestres`, `Modalidad`) VALUES
(1, 'DSI', 'Desarrollo de Sistemas de Información', 6, 'Presencial'),
(2, 'CONT', 'Contabilidad', 6, 'Presencial'),
(3, 'ADM', 'Administración de Empresas', 6, 'Presencial'),
(4, 'MKT', 'Marketing y Negocios Internacionales', 6, 'Presencial');

-- 3. Periodos Académicos
INSERT IGNORE INTO `core_periodos_academicos` (`Id`, `Codigo`, `FechaInicio`, `FechaFin`, `EsActivo`, `PermiteMatricula`) VALUES
(1, '2026-I', '2026-03-15', '2026-07-25', 1, 1),
(2, '2026-II', '2026-08-15', '2026-12-20', 0, 0);

-- 4. Aulas y Laboratorios
INSERT IGNORE INTO `core_aulas` (`Id`, `Codigo`, `Pabellon`, `Aforo`, `Tipo`) VALUES
(1, 'LAB-COMP-01', 'Pabellon A', 35, 'Laboratorio_Computo'),
(2, 'LAB-COMP-02', 'Pabellon A', 35, 'Laboratorio_Computo'),
(3, 'AULA-TEO-101', 'Pabellon B', 40, 'Teoria'),
(4, 'AULA-TEO-102', 'Pabellon B', 40, 'Teoria');

-- 5. Unidades Didácticas (Muestra curricular DSI y Contabilidad)
INSERT IGNORE INTO `core_unidades_didacticas` (`Id`, `CarreraId`, `Ciclo`, `Codigo`, `Nombre`, `Creditos`, `HorasSemanales`, `Tipo`) VALUES
(1, 1, 'I', 'DSI-101', 'Introducción a la Algoritmia y Programación', 4, 6, 'Formativa'),
(2, 1, 'I', 'DSI-102', 'Arquitectura de Computadoras y Redes', 3, 4, 'Formativa'),
(3, 1, 'II', 'DSI-201', 'Bases de Datos y Modelamiento SQL', 4, 6, 'Formativa'),
(4, 1, 'II', 'DSI-202', 'Programación Orientada a Objetos en C#', 4, 6, 'Formativa'),
(5, 1, 'III', 'DSI-301', 'Desarrollo de Aplicaciones Web y Servicios', 4, 6, 'Formativa'),
(6, 1, 'III', 'DSI-302', 'Ingeniería de Requerimientos y Casos de Uso', 3, 4, 'Formativa'),
(7, 2, 'I', 'CONT-101', 'Contabilidad Básica y Principios Contables', 4, 6, 'Formativa'),
(8, 2, 'I', 'CONT-102', 'Legislación Tributaria y Laboral', 3, 4, 'Transversal');

-- 6. Personas Físicas Semilla
INSERT IGNORE INTO `core_personas` (`Id`, `Dni`, `Nombres`, `Apellidos`, `EmailPersonal`, `Telefono`, `Sexo`) VALUES
(1, '00000001', 'Administrador', 'General de TI', 'admin.ti@ieargentina.edu.pe', '999000001', 'M'),
(2, '10000001', 'Manuel', 'Alvarado Carranza', 'manuel.alvarado@gmail.com', '999100001', 'M'),
(3, '20000001', 'Carlos', 'Mendoza Rivas', 'carlos.mendoza@gmail.com', '999200001', 'M'),
(4, '30000001', 'Rosa', 'Morales Salazar', 'rosa.morales@gmail.com', '999300001', 'F'),
(5, '40000001', 'Elena', 'Ramos Palacios', 'elena.ramos@gmail.com', '999400001', 'F'),
(6, '12345678', 'Roberto', 'Sánchez Benítez', 'rsanchez.prof@gmail.com', '999123456', 'M'),
(7, '87654321', 'Felipe', 'Ostos', 'felipe.ostos@gmail.com', '999876543', 'M'),
(8, '77654321', 'Ana', 'García Flores', 'ana.garcia@gmail.com', '999776543', 'F'),
(9, '66554433', 'Luis', 'Torres Quispe', 'luis.torres@gmail.com', '999665544', 'M');

-- 7. Cuentas de Acceso (core_usuarios)
INSERT IGNORE INTO `core_usuarios` (`Id`, `PersonaId`, `CodigoInstitucional`, `Email`, `PasswordHash`, `Estado`) VALUES
(1, 1, 'ADMIN-2026', 'admin.ti@ieargentina.edu.pe', '123456', 1),
(2, 2, 'DIR-2026', 'direccion@ieargentina.edu.pe', '123456', 1),
(3, 3, 'COORD-DSI', 'coord.sistemas@ieargentina.edu.pe', '123456', 1),
(4, 4, 'SEC-ACAD', 'secretaria.academica@ieargentina.edu.pe', '123456', 1),
(5, 5, 'TES-2026', 'tesoreria@ieargentina.edu.pe', '123456', 1),
(6, 6, 'DOC-DSI-01', 'rsanchez@ieargentina.edu.pe', '123456', 1),
(7, 7, 'EST-DSI-001', 'felipe.ostos@ieargentina.edu.pe', '123456', 1),
(8, 8, 'EST-DSI-002', 'ana.garcia@ieargentina.edu.pe', '123456', 1),
(9, 9, 'EST-CONT-001', 'luis.torres@ieargentina.edu.pe', '123456', 1);

-- 8. Asignación de Roles (Multi-Rol: Felipe es Alumno, Docente y Admin)
INSERT IGNORE INTO `core_usuario_roles` (`UsuarioId`, `RolId`) VALUES
(1, 1), -- Admin TI
(2, 2), -- Director
(3, 3), -- Coordinador
(4, 4), -- Secretaria
(5, 5), -- Tesoreria
(6, 6), -- Docente Roberto
(7, 7), -- Felipe: Alumno
(7, 6), -- Felipe: Docente (Demostración de Persona con Múltiples Roles)
(7, 1), -- Felipe: Admin
(8, 7), -- Ana: Alumno
(9, 7); -- Luis: Alumno

-- 9. Perfiles de Alumno
INSERT IGNORE INTO `core_estudiantes` (`Id`, `PersonaId`, `CodigoEstudiante`, `CarreraId`, `PeriodoIngresoId`, `CicloActual`, `Turno`, `Condicion`) VALUES
(1, 7, 'EST-DSI-2026-001', 1, 1, 'III', 'Noche', 'Regular'),
(2, 8, 'EST-DSI-2026-002', 1, 1, 'III', 'Manana', 'Regular'),
(3, 9, 'EST-CONT-2026-001', 2, 1, 'I', 'Noche', 'Regular');

-- 10. Perfiles de Docente
INSERT IGNORE INTO `core_docentes` (`Id`, `PersonaId`, `CodigoDocente`, `CarreraPrincipalId`, `Profesion`, `Condicion`) VALUES
(1, 6, 'DOC-DSI-001', 1, 'Ingeniero de Sistemas e Informática', 'Nombrado'),
(2, 7, 'DOC-DSI-002', 1, 'Senior Backend & Systems Engineer', 'Contratado');

-- 11. Perfiles Administrativos
INSERT IGNORE INTO `core_administrativos` (`Id`, `PersonaId`, `CodigoStaff`, `Cargo`, `Area`) VALUES
(1, 4, 'ADM-SEC-01', 'Secretaria Académica', 'Secretaría General'),
(2, 5, 'ADM-TES-01', 'Jefa de Caja y Tesorería', 'Tesorería');
