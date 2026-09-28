import re

# Read students
students = []
with open('/tmp/alumnos_5a10.txt') as f:
    for line in f:
        clean = line.replace('\x0c', '').strip()
        m = re.match(r'^(\d+)\s+(\d{8})\s+([^0-9]+?)(?:\s+\d+.*|\s*)$', clean)
        if m:
            num = int(m.group(1))
            dni = m.group(2)
            name = m.group(3).strip()
            parts = [p.strip() for p in name.split(',') if p.strip()]
            apellidos = parts[0] if len(parts) > 0 else name
            nombres = parts[1] if len(parts) > 1 else ''
            students.append({'num': num, 'dni': dni, 'apellidos': apellidos, 'nombres': nombres})

out = []
out.append('-- ==============================================================================')
out.append('-- 🏛️ SEEDER REAL: VI-A COMPUTACIÓN E INFORMÁTICA / DSI - IESTP ARGENTINA')
out.append('-- ==============================================================================')
out.append('BEGIN;')

# 1. Carreras
out.append("""
INSERT INTO core.carreras (id, codigo, nombre, total_semestres, modalidad) VALUES
(4, 'COMP', 'Computación e Informática', 6, 'Presencial')
ON CONFLICT (id) DO UPDATE SET codigo = EXCLUDED.codigo, nombre = EXCLUDED.nombre;
SELECT setval('core.carreras_id_seq', (SELECT MAX(id) FROM core.carreras));
""")

# 2. Aulas y Laboratorios
out.append("""
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
""")

# 3. Docentes Reales
docentes = [
    ('10000002', 'Huertas Camacho', 'Gina', 'gina.huertas@iestpargentina.edu.pe', 'DOC-HUERTAS', 'Ingeniera de Sistemas'),
    ('10000003', 'Montero', 'Docente', 'montero@iestpargentina.edu.pe', 'DOC-MONTERO', 'Licenciado en Computación'),
    ('10000004', 'Belleza', 'Docente', 'belleza@iestpargentina.edu.pe', 'DOC-BELLEZA', 'Ingeniero de Software'),
    ('10000005', 'Galindo', 'Docente', 'galindo@iestpargentina.edu.pe', 'DOC-GALINDO', 'Especialista Audiovisual'),
    ('10000006', 'Campomanes', 'Docente', 'campomanes@iestpargentina.edu.pe', 'DOC-CAMPOMANES', 'Magíster en E-Commerce'),
    ('10000007', 'Cano', 'Docente', 'cano@iestpargentina.edu.pe', 'DOC-CANO', 'Licenciado en Administración / Liderazgo'),
    ('10000008', 'Dominguez', 'Docente', 'dominguez@iestpargentina.edu.pe', 'DOC-DOMINGUEZ', 'Abogado / Legislación Laboral'),
    ('10000009', 'Delgado', 'Docente', 'delgado@iestpargentina.edu.pe', 'DOC-DELGADO', 'Magíster en Gestión Empresarial'),
    ('10000010', 'Rugel', 'Docente', 'rugel@iestpargentina.edu.pe', 'DOC-RUGEL', 'Licenciado en Legislación'),
    ('10000011', 'Balcazar', 'Docente', 'balcazar@iestpargentina.edu.pe', 'DOC-BALCAZAR', 'Ingeniero de Ciberseguridad'),
    ('10000012', 'Barnett', 'Docente', 'barnett@iestpargentina.edu.pe', 'DOC-BARNETT', 'Ingeniero de Sistemas'),
    ('10000013', 'Mundaca', 'Docente', 'mundaca@iestpargentina.edu.pe', 'DOC-MUNDACA', 'Scrum Master / Metodologías Ágiles'),
    ('10000014', 'Palomino', 'Docente', 'palomino@iestpargentina.edu.pe', 'DOC-PALOMINO', 'Ingeniero de Sistemas'),
    ('10000015', 'Padilla', 'Docente', 'padilla@iestpargentina.edu.pe', 'DOC-PADILLA', 'Especialista en Hardware y Redes'),
    ('10000016', 'Gutierrez', 'Docente', 'gutierrez@iestpargentina.edu.pe', 'DOC-GUTIERREZ', 'Especialista en Marketing Digital'),
    ('10000017', 'Castillo', 'Docente', 'castillo@iestpargentina.edu.pe', 'DOC-CASTILLO', 'Licenciado en Comunicación'),
    ('10000018', 'Pedro De La Cruz', 'Docente', 'pedro.delacruz@iestpargentina.edu.pe', 'DOC-DELACRUZ', 'Ingeniero de Software'),
    ('90000004', 'Bolsa de Horas 04', 'Docente', 'bolsa04@iestpargentina.edu.pe', 'DOC-BOLSA04', 'Docente de Idiomas / Transversal')
]

for dni, ape, nom, email, cod, prof in docentes:
    out.append(f"""
    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('{dni}', '{nom}', '{ape}', '{email}', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '{dni}'), '{dni}', '{email}', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '{dni}'), 6)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;

    INSERT INTO core.docentes (persona_id, codigo_docente, carrera_principal_id, profesion, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '{dni}'), '{cod}', 1, '{prof}', 'Contratado')
    ON CONFLICT (persona_id) DO UPDATE SET profesion = EXCLUDED.profesion;
    """)

# 4. Estudiantes Reales
for st in students:
    dni = st['dni']
    ape = st['apellidos'].replace("'", "''")
    nom = st['nombres'].replace("'", "''")
    email = f"{nom.lower().split()[0] if nom else 'est'}.{ape.lower().split()[0]}@iestpargentina.edu.pe"
    email = re.sub(r'[^a-zA-Z0-9.@]', '', email)
    cod = f"EST-{dni}"
    is_felipe = '47915633' in dni or 'OSTOS' in ape.upper()

    out.append(f"""
    INSERT INTO core.personas (dni, nombres, apellidos, email_personal, sexo)
    VALUES ('{dni}', '{nom}', '{ape}', '{email}', 'M')
    ON CONFLICT (dni) DO UPDATE SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos;

    INSERT INTO core.usuarios (persona_id, codigo_institucional, email, password_hash, estado)
    VALUES ((SELECT id FROM core.personas WHERE dni = '{dni}'), '{dni}', '{email}', '123456', TRUE)
    ON CONFLICT (persona_id) DO UPDATE SET email = EXCLUDED.email;

    INSERT INTO core.usuario_roles (usuario_id, rol_id)
    VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '{dni}'), 7)
    ON CONFLICT (usuario_id, rol_id) DO NOTHING;
    """)

    if is_felipe:
        out.append(f"""
        INSERT INTO core.usuario_roles (usuario_id, rol_id)
        VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '{dni}'), 1)
        ON CONFLICT (usuario_id, rol_id) DO NOTHING;
        INSERT INTO core.usuario_roles (usuario_id, rol_id)
        VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '{dni}'), 2)
        ON CONFLICT (usuario_id, rol_id) DO NOTHING;
        INSERT INTO core.usuario_roles (usuario_id, rol_id)
        VALUES ((SELECT id FROM core.usuarios WHERE codigo_institucional = '{dni}'), 6)
        ON CONFLICT (usuario_id, rol_id) DO NOTHING;
        """)

    out.append(f"""
    INSERT INTO core.estudiantes (persona_id, codigo_estudiante, carrera_id, periodo_ingreso_id, ciclo_actual, turno, condicion)
    VALUES ((SELECT id FROM core.personas WHERE dni = '{dni}'), '{cod}', 1, 1, 'VI', 'Manana', 'Regular')
    ON CONFLICT (persona_id) DO UPDATE SET ciclo_actual = 'VI', turno = 'Manana';
    """)

# 5. Unidades Didácticas
cursos = [
    ('COMP-601', 'Taller de Programación Web', 'VI', 4, 6),
    ('COMP-602', 'Aplicaciones Móviles', 'VI', 4, 6),
    ('COMP-603', 'Producción Audiovisual', 'VI', 3, 4),
    ('COMP-604', 'Comercio Electrónico', 'VI', 3, 4),
    ('COMP-605', 'Liderazgo y Trabajo en Equipo', 'VI', 2, 2),
    ('COMP-606', 'Legislación e Inserción Laboral', 'VI', 2, 3),
    ('COMP-607', 'Proyecto Empresarial', 'VI', 3, 4),
    ('COMP-608', 'Comprensión y Redacción en Inglés', 'VI', 2, 2),
    ('COMP-501', 'Gestión y Administración Web', 'VI', 4, 6)
]

for cod, nom, cic, cred, hrs in cursos:
    out.append(f"""
    INSERT INTO core.unidades_didacticas (carrera_id, ciclo, codigo, nombre, creditos, horas_semanales, tipo)
    VALUES (1, '{cic}', '{cod}', '{nom}', {cred}, {hrs}, 'Formativa')
    ON CONFLICT (codigo) DO UPDATE SET nombre = EXCLUDED.nombre, horas_semanales = EXCLUDED.horas_semanales;
    """)

# 6. Clases Docente VI-A y VI-B
clases = [
    ('COMP-601', '10000003', 'AULA-401', 'VI', 'Manana', 'A', 6), # Taller Web - Montero
    ('COMP-602', '10000004', 'LAB-05',   'VI', 'Manana', 'A', 6), # Móviles - Belleza
    ('COMP-603', '10000005', 'LAB-05',   'VI', 'Manana', 'A', 4), # Audiovisual - Galindo
    ('COMP-604', '10000006', 'AULA-401', 'VI', 'Manana', 'A', 4), # Comercio - Campomanes
    ('COMP-605', '10000007', 'AULA-401', 'VI', 'Manana', 'A', 2), # Liderazgo - Cano
    ('COMP-606', '10000008', 'AULA-401', 'VI', 'Manana', 'A', 3), # Legislación - Dominguez
    ('COMP-607', '10000009', 'AULA-401', 'VI', 'Manana', 'A', 4), # Proyecto Empresarial - Delgado
    ('COMP-501', '10000002', 'LAB-01',   'VI', 'Manana', 'A', 6), # Gestión Web - Gina Huertas
    ('COMP-601', '10000002', 'LAB-05',   'VI', 'Manana', 'B', 6), # Taller Web - Gina Huertas (VI-B)
    ('COMP-602', '10000004', 'AULA-402', 'VI', 'Manana', 'B', 6), # Móviles - Belleza (VI-B)
    ('COMP-603', '10000005', 'AULA-402', 'VI', 'Manana', 'B', 4), # Audiovisual - Galindo (VI-B)
    ('COMP-604', '10000006', 'AULA-402', 'VI', 'Manana', 'B', 4), # Comercio - Campomanes (VI-B)
    ('COMP-605', '10000007', 'AULA-402', 'VI', 'Manana', 'B', 2), # Liderazgo - Cano (VI-B)
    ('COMP-606', '10000010', 'AULA-402', 'VI', 'Manana', 'B', 3), # Legislación - Rugel (VI-B)
    ('COMP-607', '10000009', 'AULA-402', 'VI', 'Manana', 'B', 4), # Proyecto Empresarial - Delgado (VI-B)
]

for cod_ud, dni_doc, cod_aula, cic, turno, secc, hrs in clases:
    out.append(f"""
    INSERT INTO mod02.clases_docente (unidad_didactica_id, docente_id, periodo_id, carrera_id, ciclo, turno, seccion, aula_id, total_sesiones_semanales, estado)
    VALUES (
        (SELECT id FROM core.unidades_didacticas WHERE codigo = '{cod_ud}'),
        (SELECT d.id FROM core.docentes d JOIN core.personas p ON p.id = d.persona_id WHERE p.dni = '{dni_doc}'),
        1, 1, '{cic}', '{turno}', '{secc}',
        (SELECT id FROM core.aulas WHERE codigo = '{cod_aula}'),
        2, TRUE
    )
    ON CONFLICT (unidad_didactica_id, docente_id, periodo_id, turno, seccion) 
    DO UPDATE SET aula_id = EXCLUDED.aula_id;
    """)

# 7. Generar las 18 Semanas de Sesiones
out.append("""
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
""")

# 8. Asistencias para Semanas 1 a 3
out.append("""
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
""")

out.append('COMMIT;')

with open('src/02_Modulos/Intranet.Modulo02/Sql/seed_real_salon_via.sql', 'w') as f:
    f.write('\n'.join(out))

print('SQL script written to src/02_Modulos/Intranet.Modulo02/Sql/seed_real_salon_via.sql')
