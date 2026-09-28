-- ============================================================================
-- 🗄️ ESQUEMA SOBERANO mod09: TESORERÍA, TRÁMITES TUPA Y PAGOS (Equipo 09)
-- Portado desde db_intranet_iestp local (schema 3.2.0) a las reglas del
-- proyecto: FKs INT al core de Felipe, DDL idempotente, snake_case.
-- Historia: diseño del equipo 09 (54 conceptos TUPA reales del IESTP),
-- normalizado 3NF, verificado con pruebas negativas en el repo
-- gestion-estudiantes-intranet.
-- ============================================================================

-- 1. Catálogo: tipos de pago (Efectivo, Transferencia...)
CREATE TABLE IF NOT EXISTS mod09.tipos_pago (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 2. Catálogo: conceptos de pago TUPA (los 53 conceptos oficiales)
CREATE TABLE IF NOT EXISTS mod09.conceptos_pago (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    monto NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (monto >= 0),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3. Catálogo: tipos de trámite TUPA (admisión, certificados, titulación...)
CREATE TABLE IF NOT EXISTS mod09.tipos_tramite (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    -- el trámite se paga con un concepto TUPA (FK interna del módulo)
    concepto_pago_id INT NULL REFERENCES mod09.conceptos_pago(id) ON DELETE SET NULL,
    dias_habiles INT NOT NULL DEFAULT 3 CHECK (dias_habiles > 0),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- 4. Catálogo: requisitos por tipo de trámite (checklist TUPA)
CREATE TABLE IF NOT EXISTS mod09.requisitos_tipos_tramite (
    id SERIAL PRIMARY KEY,
    tipo_tramite_id INT NOT NULL REFERENCES mod09.tipos_tramite(id) ON DELETE CASCADE,
    orden INT NOT NULL DEFAULT 1,
    requisito VARCHAR(300) NOT NULL,
    UNIQUE (tipo_tramite_id, orden, requisito)
);

-- 5. Feriados (para cálculo de plazos en días hábiles)
CREATE TABLE IF NOT EXISTS mod09.feriados (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
);

-- 6. Trámites TUPA: el expediente del ciudadano
CREATE TABLE IF NOT EXISTS mod09.tramites (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    tipo_tramite_id INT NOT NULL REFERENCES mod09.tipos_tramite(id) ON DELETE RESTRICT,
    estudiante_id INT NULL REFERENCES core.estudiantes(id) ON DELETE SET NULL,
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    fecha_solicitud DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_limite DATE NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Recibido' CHECK (estado IN ('Recibido','En evaluación','Aprobado','Observado','Rechazado','Entregado')),
    datos JSONB NULL,
    resolucion VARCHAR(300) NULL,
    fecha_resolucion DATE NULL,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_tramites_estudiante ON mod09.tramites (estudiante_id);
CREATE INDEX IF NOT EXISTS idx_tramites_estado ON mod09.tramites (estado);

-- 7. Requisitos presentados por trámite (instancia del checklist)
CREATE TABLE IF NOT EXISTS mod09.tramite_requisitos (
    id SERIAL PRIMARY KEY,
    tramite_id INT NOT NULL REFERENCES mod09.tramites(id) ON DELETE CASCADE,
    requisito_catalogo_id INT NOT NULL REFERENCES mod09.requisitos_tipos_tramite(id) ON DELETE RESTRICT,
    presentado BOOLEAN NOT NULL DEFAULT FALSE,
    observacion VARCHAR(300) NULL,
    archivo_nombre VARCHAR(260) NULL,
    archivo_tipo VARCHAR(100) NULL,
    archivo_contenido BYTEA NULL,
    UNIQUE (tramite_id, requisito_catalogo_id)
);

-- 8. Pagos TUPA
CREATE TABLE IF NOT EXISTS mod09.pagos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    estudiante_id INT NOT NULL REFERENCES core.estudiantes(id) ON DELETE RESTRICT,
    concepto_pago_id INT NOT NULL REFERENCES mod09.conceptos_pago(id) ON DELETE RESTRICT,
    periodo_id INT NOT NULL REFERENCES core.periodos_academicos(id) ON DELETE RESTRICT,
    tipo_pago_id INT NOT NULL REFERENCES mod09.tipos_pago(id) ON DELETE RESTRICT,
    tramite_id INT NULL REFERENCES mod09.tramites(id) ON DELETE SET NULL,
    monto NUMERIC(10,2) NOT NULL CHECK (monto > 0),
    fecha_pago DATE NOT NULL DEFAULT CURRENT_DATE,
    voucher_estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente' CHECK (voucher_estado IN ('Pendiente','Validado','Rechazado')),
    motivo_rechazo VARCHAR(300) NULL,
    fecha_validacion DATE NULL,
    validado_por INT NULL REFERENCES core.usuarios(id) ON DELETE SET NULL,
    intentos INT NOT NULL DEFAULT 0,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_pagos_estudiante ON mod09.pagos (estudiante_id);
CREATE INDEX IF NOT EXISTS idx_pagos_periodo ON mod09.pagos (periodo_id);

-- 9. Avisos internos (buzón de confirmaciones para el estudiante)
CREATE TABLE IF NOT EXISTS mod09.avisos (
    id SERIAL PRIMARY KEY,
    remitente_id INT NULL REFERENCES core.usuarios(id) ON DELETE SET NULL,
    tipo VARCHAR(30) NOT NULL DEFAULT 'Información',
    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 10. Destinatarios de avisos (muchos por aviso)
CREATE TABLE IF NOT EXISTS mod09.avisos_destinatarios (
    id SERIAL PRIMARY KEY,
    aviso_id INT NOT NULL REFERENCES mod09.avisos(id) ON DELETE CASCADE,
    destinatario_id INT NOT NULL REFERENCES core.usuarios(id) ON DELETE CASCADE,
    leido BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_lectura TIMESTAMP WITH TIME ZONE NULL,
    UNIQUE (aviso_id, destinatario_id)
);

-- ============================================================================
-- SEMILLA (TUPA real del instituto: tipos de pago, feriados, plantillas)
-- ============================================================================
INSERT INTO mod09.tipos_pago (codigo, nombre) VALUES
  ('TPM','Matrícula'),('MEN','Mensual'),('TRA','Trámite'),('OTR','Otro')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO mod09.feriados (fecha, descripcion) VALUES
  ('2026-01-01','Año Nuevo'),('2026-05-01','Día del Trabajo'),
  ('2026-06-24','Día del Campesino'),('2026-07-28','Fiestas Patrias'),
  ('2026-07-29','Fiestas Patrias'),('2026-08-30','Santa Rosa'),
  ('2026-10-08','Combate de Angamos'),('2026-11-01','Todos los Santos'),
  ('2026-12-08','Inmaculada Concepción'),('2026-12-25','Navidad')
ON CONFLICT (fecha) DO NOTHING;

-- ---------------------------------------------------------------------------
-- SEMILLAS TUPA: tipos de trámite (con su concepto de pago y plazo en días
-- hábiles) y los requisitos por tipo. Datos del TUPA 2026 del IESTP Argentina.
-- ---------------------------------------------------------------------------
-- concepto_pago_id se resuelve por CÓDIGO (ids no secuenciales entre entornos)
INSERT INTO mod09.tipos_tramite (codigo, nombre, concepto_pago_id, dias_habiles)
SELECT v.codigo, v.nombre, cp.id, v.dias
FROM (VALUES
  ('TT01','Carné de Medio Pasaje',   'CP03', 3),
  ('TT02','Cambio de Turno',        'CT05', 5),
  ('TT03','Constancia de Matrícula', 'CT24', 3),
  ('TT04','Duplicado de Carné',      'CP04', 5),
  ('TA05','Traslado interno (cambio de turno)', 'CT05', 5),
  ('TA14','Reserva de matrícula',    'CT13', 5)
) AS v(codigo, nombre, concepto, dias)
JOIN mod09.conceptos_pago cp ON cp.codigo = v.concepto
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO mod09.requisitos_tipos_tramite (tipo_tramite_id, orden, requisito)
SELECT tt.id, v.orden, v.requisito
FROM (VALUES
  ('TT01', 1, 'Solicitud dirigida al Director'),
  ('TT01', 2, 'Recibo de pago (CP03)'),
  ('TT01', 3, 'Foto carné fondo blanco'),
  ('TT02', 1, 'Solicitud dirigida al Director'),
  ('TT02', 2, 'Recibo de pago (CT05)'),
  ('TT02', 3, 'Record de notas'),
  ('TT03', 1, 'Solicitud dirigida al Director'),
  ('TT03', 2, 'Recibo de pago (CT24)'),
  ('TT04', 1, 'Solicitud dirigida al Director'),
  ('TT04', 2, 'Recibo de pago (CP04)'),
  ('TT04', 3, 'Foto carné fondo blanco'),
  ('TA05', 1, 'Solicitud dirigida al Director'),
  ('TA05', 2, 'Recibo de pago (CT05)'),
  ('TA05', 3, 'Carta de no adeudo de biblioteca'),
  ('TA14', 1, 'Solicitud dirigida al Director'),
  ('TA14', 2, 'Recibo de pago (CT13)'),
  ('TA14', 3, 'Carta de no adeudo de biblioteca')
) AS v(codigo, orden, requisito)
JOIN mod09.tipos_tramite tt ON tt.codigo = v.codigo
ON CONFLICT DO NOTHING;

-- ============================================================
-- TUPA 2026 ampliado (TM01..TM20) — catálogo oficial del TUPA-2026.pdf
-- con requisitos por tipo. Idempotente.
-- ============================================================
INSERT INTO mod09.tipos_tramite (codigo, nombre, concepto_pago_id, dias_habiles, activo) VALUES
 ('TM01','Matrícula de Ingresante',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT07'),1,true),
 ('TM02','Matrícula por Traslado Externo/Interno',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT08'),1,true),
 ('TM03','Ratificación de Matrícula',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT09'),1,true),
 ('TM04','Fraccionamiento de Matrícula',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT10'),1,true),
 ('TM05','Reserva de Matrícula',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT13'),5,true),
 ('TM06','Convalidación de Estudios',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT14'),5,true),
 ('TM07','Repitencia de Unidad Didáctica',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT15'),1,true),
 ('TM08','Repitencia de Módulo',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT17'),1,true),
 ('TM09','Reingreso',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT18'),5,true),
 ('TM10','Evaluación Extraordinaria',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT19'),1,true),
 ('TM11','Reporte Record de Notas',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT21'),10,true),
 ('TM12','Constancia de Ingreso',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT22'),15,true),
 ('TM13','Constancia de Estudios',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT24'),15,true),
 ('TM14','Constancia de Primera Matrícula',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT25'),15,true),
 ('TM15','Constancia de Egresado',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT26'),15,true),
 ('TM16','Constancia de Título en Trámite',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT27'),15,true),
 ('TM17','Constancia de Tercio Superior o Conducta',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT28'),15,true),
 ('TM18','Carta de Presentación',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT29'),10,true),
 ('TM19','Duplicado de Carné Estudiantil',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT04'),5,true),
 ('TM20','Diploma de Egresado',(SELECT id FROM mod09.conceptos_pago WHERE codigo='CT45'),15,true)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO mod09.requisitos_tipos_tramite (tipo_tramite_id, orden, requisito)
SELECT tt.id, v.orden, v.requisito
FROM (VALUES
 ('TM01',1,'Recibo de pago de matrícula ingresante'),
 ('TM01',2,'Copia de DNI'),
 ('TM02',1,'Recibo de pago de matrícula por traslado'),
 ('TM02',2,'Constancia de vacante o resolución de traslado'),
 ('TM03',1,'Copia de boleta de notas'),
 ('TM03',2,'Recibo de pago de ratificación'),
 ('TM04',1,'Copia de boleta de notas'),
 ('TM04',2,'Declaración jurada de fraccionamiento'),
 ('TM05',1,'Solicitud dirigida al Director General'),
 ('TM05',2,'Recibo de pago (CT13 Reserva de matrícula)'),
 ('TM05',3,'Declaración jurada del motivo de reserva'),
 ('TM06',1,'Solicitud dirigida al Director General'),
 ('TM06',2,'Certificados de estudios originales'),
 ('TM06',3,'Recibo de pago de convalidación'),
 ('TM07',1,'Verificación previa de horarios (sábana)'),
 ('TM07',2,'Boleta de notas'),
 ('TM08',1,'Recibo de pago de repitencia de módulo'),
 ('TM08',2,'Historial académico'),
 ('TM09',1,'Solicitud dirigida al Director General'),
 ('TM09',2,'Copia de boleta de notas'),
 ('TM10',1,'Solicitud dirigida al Director General'),
 ('TM10',2,'Record de notas'),
 ('TM10',3,'Recibo de pago de evaluación extraordinaria'),
 ('TM11',1,'Solicitud dirigida al Director General'),
 ('TM11',2,'Recibo de pago de record de notas'),
 ('TM12',1,'Verificación de ingreso en listado oficial de admisión'),
 ('TM12',2,'Recibo de pago de constancia de ingreso'),
 ('TM13',1,'Solicitud dirigida al Director General'),
 ('TM13',2,'01 foto tamaño carné'),
 ('TM13',3,'Recibo de pago de constancia de estudios'),
 ('TM14',1,'Solicitud dirigida al Director General'),
 ('TM14',2,'01 foto tamaño carné'),
 ('TM14',3,'Recibo de pago de constancia de primera matrícula'),
 ('TM15',1,'Solicitud dirigida al Director General'),
 ('TM15',2,'02 fotos tamaño carné'),
 ('TM15',3,'Recibo de pago de constancia de egresado'),
 ('TM16',1,'Solicitud dirigida al Director General'),
 ('TM16',2,'02 fotos tamaño carné'),
 ('TM16',3,'Recibo de pago de constancia de título en trámite'),
 ('TM17',1,'Solicitud dirigida al Director General'),
 ('TM17',2,'Recibo de pago de constancia de tercio superior'),
 ('TM18',1,'Solicitud dirigida al Director General'),
 ('TM18',2,'Recibo de pago de carta de presentación'),
 ('TM19',1,'Solicitud dirigida al Director General'),
 ('TM19',2,'Recibo de pago de duplicado de carné'),
 ('TM19',3,'01 foto tamaño carné fondo blanco'),
 ('TM20',1,'Solicitud dirigida al Director General'),
 ('TM20',2,'01 foto tamaño carné'),
 ('TM20',3,'Recibo de pago de diploma de egresado')
) AS v(codigo, orden, requisito)
JOIN mod09.tipos_tramite tt ON tt.codigo = v.codigo
ON CONFLICT (tipo_tramite_id, orden, requisito) DO NOTHING;

-- ============================================================
-- Flujo voucher: el trámite con costo genera el pago y el alumno
-- adjunta el voucher PDF que Tesorería valida.
-- ============================================================
ALTER TABLE mod09.tramites ADD COLUMN IF NOT EXISTS pago_id INT REFERENCES mod09.pagos_v2(id);
CREATE INDEX IF NOT EXISTS idx_tramites_pago ON mod09.tramites(pago_id);

CREATE TABLE IF NOT EXISTS mod09.voucher_archivos (
    pago_id INT NOT NULL PRIMARY KEY REFERENCES mod09.pagos_v2(id) ON DELETE CASCADE,
    archivo_nombre VARCHAR(200) NOT NULL,
    archivo_tipo VARCHAR(100) NOT NULL,
    archivo_contenido BYTEA NOT NULL,
    subido_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
