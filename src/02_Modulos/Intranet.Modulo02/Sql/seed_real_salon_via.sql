-- ==============================================================================
-- 🏛️ SEEDER REAL: VI-A COMPUTACIÓN E INFORMÁTICA / DSI - IESTP ARGENTINA
-- ==============================================================================
BEGIN;

INSERT INTO core.carreras (id, codigo, nombre, total_semestres, modalidad) VALUES
(4, 'COMP', 'Computación e Informática', 6, 'Presencial')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo, nombre = EXCLUDED.nombre;
SELECT setval('core.carreras_id_seq', (SELECT MAX(id) FROM core.carreras));


INSERT INTO core.aulas (id, codigo, pabellon, aforo, tipo) VALUES
(10, 'LAB-01', 'Pab. Central', 35, 'Laboratorio_Computo'),
(11, 'LAB-02', 'Pab. Central', 35, 'Laboratorio_Computo'),
(12, 'LAB-05', 'Pabellón B', 35, 'Laboratorio_Computo'),
(13, 'AULA-401', 'Pabellón B', 40, 'Teoria'),
(14, 'AULA-402', 'Pabellón B', 40, 'Teoria'),
(15, 'AULA-403', 'Pabellón B', 40, 'Teoria'),
(16, 'AULA-404', 'Pabellón B', 40, 'Teoria'),
(17, 'AULA-405', 'Pabellón B', 40, 'Teoria'),
(18, 'AULA-408', 'Pabellón B', 40, 'Teoria'),
(19, 'AULA-411', 'Pabellón B', 40, 'Teoria'),
(20, 'AULA-502', 'Pabellón B', 40, 'Teoria')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo, pabellon = EXCLUDED.pabellon;
SELECT setval('core.aulas_id_seq', (SELECT MAX(id) FROM core.aulas));


    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000002', 'Gina', 'Huertas Camacho', 'gina.huertas@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000002'), '10000002', 'gina.huertas@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000002'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000002'), 'DOC-HUERTAS', 1, 'Ingeniera de Sistemas', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000003', 'Docente', 'Montero', 'montero@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000003'), '10000003', 'montero@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000003'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000003'), 'DOC-MONTERO', 1, 'Licenciado en Computación', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000004', 'Docente', 'Belleza', 'belleza@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000004'), '10000004', 'belleza@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000004'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000004'), 'DOC-BELLEZA', 1, 'Ingeniero de Software', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000005', 'Docente', 'Galindo', 'galindo@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000005'), '10000005', 'galindo@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000005'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000005'), 'DOC-GALINDO', 1, 'Especialista Audiovisual', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000006', 'Docente', 'Campomanes', 'campomanes@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000006'), '10000006', 'campomanes@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000006'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000006'), 'DOC-CAMPOMANES', 1, 'Magíster en E-Commerce', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000007', 'Docente', 'Cano', 'cano@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000007'), '10000007', 'cano@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000007'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000007'), 'DOC-CANO', 1, 'Licenciado en Administración / Liderazgo', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000008', 'Docente', 'Dominguez', 'dominguez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000008'), '10000008', 'dominguez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000008'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000008'), 'DOC-DOMINGUEZ', 1, 'Abogado / Legislación Laboral', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000009', 'Docente', 'Delgado', 'delgado@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000009'), '10000009', 'delgado@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000009'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000009'), 'DOC-DELGADO', 1, 'Magíster en Gestión Empresarial', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000010', 'Docente', 'Rugel', 'rugel@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000010'), '10000010', 'rugel@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000010'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000010'), 'DOC-RUGEL', 1, 'Licenciado en Legislación', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000011', 'Docente', 'Balcazar', 'balcazar@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000011'), '10000011', 'balcazar@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000011'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000011'), 'DOC-BALCAZAR', 1, 'Ingeniero de Ciberseguridad', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000012', 'Docente', 'Barnett', 'barnett@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000012'), '10000012', 'barnett@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000012'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000012'), 'DOC-BARNETT', 1, 'Ingeniero de Sistemas', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000013', 'Docente', 'Mundaca', 'mundaca@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000013'), '10000013', 'mundaca@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000013'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000013'), 'DOC-MUNDACA', 1, 'Scrum Master / Metodologías Ágiles', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000014', 'Docente', 'Palomino', 'palomino@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000014'), '10000014', 'palomino@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000014'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000014'), 'DOC-PALOMINO', 1, 'Ingeniero de Sistemas', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000015', 'Docente', 'Padilla', 'padilla@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000015'), '10000015', 'padilla@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000015'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000015'), 'DOC-PADILLA', 1, 'Especialista en Hardware y Redes', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000016', 'Docente', 'Gutierrez', 'gutierrez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000016'), '10000016', 'gutierrez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000016'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000016'), 'DOC-GUTIERREZ', 1, 'Especialista en Marketing Digital', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000017', 'Docente', 'Castillo', 'castillo@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000017'), '10000017', 'castillo@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000017'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000017'), 'DOC-CASTILLO', 1, 'Licenciado en Comunicación', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('10000018', 'Docente', 'Pedro De La Cruz', 'pedro.delacruz@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000018'), '10000018', 'pedro.delacruz@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '10000018'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '10000018'), 'DOC-DELACRUZ', 1, 'Ingeniero de Software', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('90000004', 'Docente', 'Bolsa de Horas 04', 'bolsa04@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '90000004'), '90000004', 'bolsa04@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '90000004'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '90000004'), 'DOC-BOLSA04', 1, 'Docente de Idiomas / Transversal', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74096398', 'Franco Stefano', 'ALCALA MANCILLA', 'franco.alcala@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74096398'), '74096398', 'franco.alcala@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74096398'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74096398'), 'EST-74096398', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('71454696', 'Diego Mathias', 'ALEGRE SERNAQUE', 'diego.alegre@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '71454696'), '71454696', 'diego.alegre@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '71454696'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '71454696'), 'EST-71454696', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('60193650', 'Diego Angelo', 'ALEJOS DIAZ', 'diego.alejos@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60193650'), '60193650', 'diego.alejos@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '60193650'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60193650'), 'EST-60193650', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72152355', 'Alexander Giovanni', 'ALVITES CALDERON', 'alexander.alvites@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72152355'), '72152355', 'alexander.alvites@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72152355'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72152355'), 'EST-72152355', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('76534884', 'Max Jordan', 'ANDRADE CONTRERAS', 'max.andrade@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '76534884'), '76534884', 'max.andrade@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '76534884'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '76534884'), 'EST-76534884', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('63036807', 'Jherson Jesus', 'ARIAS VELASQUEZ', 'jherson.arias@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '63036807'), '63036807', 'jherson.arias@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '63036807'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '63036807'), 'EST-63036807', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('75070472', 'Cristian Daniel', 'AZAÑERO CAPUÑAY', 'cristian.azaero@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75070472'), '75070472', 'cristian.azaero@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '75070472'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75070472'), 'EST-75070472', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72152206', 'Carlos Gonzalo', 'BULLON MARIÑAS', 'carlos.bullon@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72152206'), '72152206', 'carlos.bullon@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72152206'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72152206'), 'EST-72152206', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('75433169', 'Esteban Andres', 'CABANILLAS GONZALES', 'esteban.cabanillas@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75433169'), '75433169', 'esteban.cabanillas@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '75433169'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75433169'), 'EST-75433169', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('70500766', 'Gustavo Sebastian', 'CAICEDO AQUINO', 'gustavo.caicedo@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70500766'), '70500766', 'gustavo.caicedo@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '70500766'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70500766'), 'EST-70500766', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74296138', 'Carlos Ismael', 'CAMPOS ESPINOZA', 'carlos.campos@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74296138'), '74296138', 'carlos.campos@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74296138'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74296138'), 'EST-74296138', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('78018329', 'Jordad Jhimi', 'CARHUAZ LAUREANO', 'jordad.carhuaz@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '78018329'), '78018329', 'jordad.carhuaz@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '78018329'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '78018329'), 'EST-78018329', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('60914536', 'Paulo Miguel', 'CARREON SUCASAIRE', 'paulo.carreon@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60914536'), '60914536', 'paulo.carreon@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '60914536'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60914536'), 'EST-60914536', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74915413', 'Eduardo Alexander', 'CARRION BEDON', 'eduardo.carrion@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74915413'), '74915413', 'eduardo.carrion@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74915413'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74915413'), 'EST-74915413', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('75800799', 'Aribel Veronica', 'CASTRO CUBA ANGELES', 'aribel.castro@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75800799'), '75800799', 'aribel.castro@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '75800799'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75800799'), 'EST-75800799', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('60914650', 'Iris Raffaella', 'CHAVEZ CARRERA', 'iris.chavez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60914650'), '60914650', 'iris.chavez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '60914650'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60914650'), 'EST-60914650', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('71653177', 'Fabrizio Thierry', 'CHERRES ESCALANTE', 'fabrizio.cherres@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '71653177'), '71653177', 'fabrizio.cherres@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '71653177'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '71653177'), 'EST-71653177', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74839702', 'Hanz Peter', 'CHISQUIPAMA TAPULLIMA', 'hanz.chisquipama@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74839702'), '74839702', 'hanz.chisquipama@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74839702'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74839702'), 'EST-74839702', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('63229403', 'Diana Azucena', 'CONTRERAS LUNA', 'diana.contreras@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '63229403'), '63229403', 'diana.contreras@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '63229403'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '63229403'), 'EST-63229403', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72430930', 'Jesus Gabriel', 'ESPEJO CUETO', 'jesus.espejo@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72430930'), '72430930', 'jesus.espejo@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72430930'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72430930'), 'EST-72430930', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72803597', 'Brayan Emanuel', 'ESPINOZA CARTAGENA', 'brayan.espinoza@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72803597'), '72803597', 'brayan.espinoza@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72803597'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72803597'), 'EST-72803597', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74065833', 'Jimmy Joel', 'FERNANDEZ TORRES', 'jimmy.fernandez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74065833'), '74065833', 'jimmy.fernandez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74065833'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74065833'), 'EST-74065833', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('60247353', 'Taskya Marlene', 'FLORES SAQUIRAY', 'taskya.flores@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60247353'), '60247353', 'taskya.flores@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '60247353'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60247353'), 'EST-60247353', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('76608263', 'Velu Beatriz', 'GOMEZ JAVIER', 'velu.gomez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '76608263'), '76608263', 'velu.gomez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '76608263'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '76608263'), 'EST-76608263', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('60958150', 'Daldison David', 'GONZALES ORDINOLA', 'daldison.gonzales@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60958150'), '60958150', 'daldison.gonzales@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '60958150'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60958150'), 'EST-60958150', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74034034', 'Joan Sebastian', 'HERNANDEZ TARAZONA', 'joan.hernandez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74034034'), '74034034', 'joan.hernandez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74034034'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74034034'), 'EST-74034034', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72823152', 'Sandra Daniela', 'HINOSTROZA SAMANES', 'sandra.hinostroza@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72823152'), '72823152', 'sandra.hinostroza@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72823152'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72823152'), 'EST-72823152', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72385549', 'Brenda Ingrid', 'MALVACEDA RUIZ', 'brenda.malvaceda@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72385549'), '72385549', 'brenda.malvaceda@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72385549'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72385549'), 'EST-72385549', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('70591147', 'Dylan Jaret', 'MANRIQUE TARAZONA', 'dylan.manrique@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70591147'), '70591147', 'dylan.manrique@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '70591147'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70591147'), 'EST-70591147', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('48411509', 'Cesar Antonio', 'MAQUERA ROSAS', 'cesar.maquera@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '48411509'), '48411509', 'cesar.maquera@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '48411509'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '48411509'), 'EST-48411509', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('70507925', 'Noé Angel', 'NAVARRO SEGURA', 'no.navarro@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70507925'), '70507925', 'no.navarro@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '70507925'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70507925'), 'EST-70507925', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('70636593', 'Ruben Jhonatan Esmid', 'OLIVA ANDRES', 'ruben.oliva@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70636593'), '70636593', 'ruben.oliva@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '70636593'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '70636593'), 'EST-70636593', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('47915633', 'Felipe Pedro Jose', 'OSTOS BERMUDEZ', 'felipe.ostos@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '47915633'), '47915633', 'felipe.ostos@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '47915633'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

        INSERT INTO core.usuario_roles (usuario_id, rol_id)
        VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '47915633'), 1)
        ON CONFLICT (usuario_id, rol_id) DO NOTHING;
        INSERT INTO core.usuario_roles (usuario_id, rol_id)
        VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '47915633'), 2)
        ON CONFLICT (usuario_id, rol_id) DO NOTHING;
        INSERT INTO core.usuario_roles (usuario_id, rol_id)
        VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '47915633'), 6)
        ON CONFLICT (usuario_id, rol_id) DO NOTHING;
        

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '47915633'), 'EST-47915633', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('76262323', 'Ruben Antonio', 'PARVINA ARIAS', 'ruben.parvina@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '76262323'), '76262323', 'ruben.parvina@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '76262323'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '76262323'), 'EST-76262323', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('73436674', 'Lucero', 'POZZO LOPEZ', 'lucero.pozzo@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '73436674'), '73436674', 'lucero.pozzo@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '73436674'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '73436674'), 'EST-73436674', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('60938474', 'Luis Fabiano', 'RODRIGUEZ MEDINA', 'luis.rodriguez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60938474'), '60938474', 'luis.rodriguez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '60938474'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '60938474'), 'EST-60938474', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72910115', 'Josias Fernando', 'TORO GRANADOS', 'josias.toro@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72910115'), '72910115', 'josias.toro@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72910115'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72910115'), 'EST-72910115', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74646496', 'Joseph Williams', 'TUCTO ANTUNEZ', 'joseph.tucto@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74646496'), '74646496', 'joseph.tucto@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74646496'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74646496'), 'EST-74646496', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('75200556', 'Nery Sheylla', 'VASQUEZ CHAVEZ', 'nery.vasquez@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75200556'), '75200556', 'nery.vasquez@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '75200556'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '75200556'), 'EST-75200556', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('72859669', 'Nicole Alexandra', 'VERASTEGUI GARCIA', 'nicole.verastegui@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72859669'), '72859669', 'nicole.verastegui@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '72859669'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '72859669'), 'EST-72859669', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('74114320', 'Richard Adriano', 'YANCCE DOMINGUEZ', 'richard.yancce@iestpargentina.edu.pe', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74114320'), '74114320', 'richard.yancce@iestpargentina.edu.pe', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '74114320'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    

    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '74114320'), 'EST-74114320', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-601', 'Taller de Programación Web', 4, 6, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-602', 'Aplicaciones Móviles', 4, 6, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-603', 'Producción Audiovisual', 3, 4, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-604', 'Comercio Electrónico', 3, 4, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-605', 'Liderazgo y Trabajo en Equipo', 2, 2, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-606', 'Legislación e Inserción Laboral', 2, 3, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-607', 'Proyecto Empresarial', 3, 4, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-608', 'Comprensión y Redacción en Inglés', 2, 2, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, 'VI', 'COMP-501', 'Gestión y Administración Web', 4, 6, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-601'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000003'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-401'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-602'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000004'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'LAB-05'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-603'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000005'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'LAB-05'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-604'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000006'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-401'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-605'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000007'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-401'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-606'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000008'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-401'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-607'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000009'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-401'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-501'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000002'),
        1, 1, 'VI', 'Manana', 'A',
        (SELECT id FROM core.aulas WHERE codigo = 'LAB-01'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-601'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000002'),
        1, 1, 'VI', 'Manana', 'B',
        (SELECT id FROM core.aulas WHERE codigo = 'LAB-05'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-602'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000004'),
        1, 1, 'VI', 'Manana', 'B',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-402'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-603'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000005'),
        1, 1, 'VI', 'Manana', 'B',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-402'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-604'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000006'),
        1, 1, 'VI', 'Manana', 'B',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-402'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-605'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000007'),
        1, 1, 'VI', 'Manana', 'B',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-402'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-606'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000010'),
        1, 1, 'VI', 'Manana', 'B',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-402'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = 'COMP-607'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '10000009'),
        1, 1, 'VI', 'Manana', 'B',
        (SELECT id FROM core.aulas WHERE codigo = 'AULA-402'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    

DO $GEN_SESIONES$
DECLARE
    r_clase RECORD;
    w INT;
    f_inicio DATE := '2026-03-16';
    f_sesion DATE;
BEGIN
    FOR r_clase IN SELECT cd.id, cd.unidad_didactica_id, cd.docente_id, cd.periodo_id, cd.aula_id, cd.seccion
                   FROM mod02.clases_docente cd
                   WHERE cd.ciclo = 'VI' AND cd.turno = 'Manana'
    LOOP
        FOR w IN 1..18 LOOP
            f_sesion := f_inicio + ((w - 1) * 7);
            
            INSERT INTO mod02.sesiones_clase (
                clase_docente_id, unidad_didactica_id, docente_id, periodo_id, aula_id,
                fecha_clase, hora_inicio, hora_fin, horas_pedagogicas, numero_semana, numero_sesion,
                es_semana_recuperacion, tema_desarrollado, estado
            )
            VALUES (
                r_clase.id, r_clase.unidad_didactica_id, r_clase.docente_id, r_clase.periodo_id, r_clase.aula_id,
                f_sesion, '08:15:00', '10:30:00', 3, w, 1,
                (w = 17),
                CASE 
                    WHEN w = 17 THEN 'Evaluación Extraordinaria de Recuperación'
                    WHEN w = 18 THEN 'Consolidación de Actas y Cierre REGISTRA MINEDU'
                    ELSE 'Sesión de Aprendizaje Semana ' || w
                END,
                CASE WHEN w <= 3 THEN 'CERRADA' WHEN w = 4 THEN 'ABIERTA' ELSE 'PROGRAMADA' END
            )
            ON CONFLICT (unidad_didactica_id, docente_id, fecha_clase, hora_inicio) DO NOTHING;
        END LOOP;
    END LOOP;
END $GEN_SESIONES$;


DO $GEN_ASISTENCIAS$
DECLARE
    r_sesion RECORD;
    r_est RECORD;
    r_cnt INT := 0;
BEGIN
    FOR r_sesion IN 
        SELECT s.id AS sesion_id, s.numero_semana, s.unidad_didactica_id
        FROM mod02.sesiones_clase s
        JOIN mod02.clases_docente cd ON cd.id = s.clase_docente_id
        WHERE cd.ciclo = 'VI' AND cd.turno = 'Manana' AND cd.seccion = 'A' AND s.numero_semana <= 3
    LOOP
        FOR r_est IN 
            SELECT e.id AS estudiante_id, p.dni
            FROM core.estudiantes e
            JOIN core.personas p ON p.id = e.persona_id
            WHERE e.ciclo_actual = 'VI' AND e.turno = 'Manana'
        LOOP
            r_cnt := r_cnt + 1;
            
            INSERT INTO mod02.asistencias (sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion)
            VALUES (
                r_sesion.sesion_id,
                r_est.estudiante_id,
                CASE 
                    WHEN r_cnt % 19 = 0 THEN 'FALTA_INJUSTIFICADA'
                    WHEN r_cnt % 11 = 0 THEN 'TARDANZA'
                    WHEN r_cnt % 29 = 0 THEN 'FALTA_JUSTIFICADA'
                    ELSE 'PRESENTE'
                END,
                CASE WHEN r_cnt % 11 = 0 THEN 10 ELSE 0 END,
                'Registro de Asistencia Aula'
            )
            ON CONFLICT (sesion_clase_id, estudiante_id) DO NOTHING;
        END LOOP;
    END LOOP;
END $GEN_ASISTENCIAS$;

COMMIT;