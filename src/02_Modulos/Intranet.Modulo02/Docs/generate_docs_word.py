import os
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def create_styled_document():
    doc = Document()
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
    style_normal = doc.styles['Normal']
    style_normal.font.name = 'Calibri'
    style_normal.font.size = Pt(10.5)
    style_normal.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    return doc

def add_header_banner(doc, title, subtitle, author_meta):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    
    cell = tbl.cell(0, 0)
    cell.width = Inches(6.9)
    set_cell_background(cell, "1E293B")
    set_cell_margins(cell, top=240, bottom=240, left=240, right=240)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(2)
    run_inst = p.add_run("🏛️ IESTP \"ARGENTINA\" • INTRANET INSTITUCIONAL MODULAR")
    run_inst.font.name = 'Calibri'
    run_inst.font.size = Pt(9.5)
    run_inst.font.bold = True
    run_inst.font.color.rgb = RGBColor(0x94, 0xA3, 0xB8)
    
    p2 = cell.add_paragraph()
    p2.paragraph_format.space_before = Pt(2)
    p2.paragraph_format.space_after = Pt(4)
    run_title = p2.add_run(title)
    run_title.font.name = 'Calibri'
    run_title.font.size = Pt(16)
    run_title.font.bold = True
    run_title.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    
    p3 = cell.add_paragraph()
    p3.paragraph_format.space_before = Pt(0)
    p3.paragraph_format.space_after = Pt(6)
    run_sub = p3.add_run(subtitle)
    run_sub.font.name = 'Calibri'
    run_sub.font.size = Pt(11)
    run_sub.font.italic = True
    run_sub.font.color.rgb = RGBColor(0x38, 0xBD, 0xF8)
    
    p4 = cell.add_paragraph()
    p4.paragraph_format.space_before = Pt(4)
    p4.paragraph_format.space_after = Pt(2)
    run_meta = p4.add_run(author_meta)
    run_meta.font.name = 'Calibri'
    run_meta.font.size = Pt(9)
    run_meta.font.color.rgb = RGBColor(0xCB, 0xD5, 0xE1)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

def add_heading_1(doc, text):
    h = doc.add_paragraph()
    h.paragraph_format.space_before = Pt(14)
    h.paragraph_format.space_after = Pt(4)
    h.paragraph_format.keep_with_next = True
    r = h.add_run(text)
    r.font.name = 'Calibri'
    r.font.size = Pt(14)
    r.font.bold = True
    r.font.color.rgb = RGBColor(0x0F, 0x17, 0x2A)
    return h

def add_heading_2(doc, text):
    h = doc.add_paragraph()
    h.paragraph_format.space_before = Pt(10)
    h.paragraph_format.space_after = Pt(3)
    h.paragraph_format.keep_with_next = True
    r = h.add_run(text)
    r.font.name = 'Calibri'
    r.font.size = Pt(12)
    r.font.bold = True
    r.font.color.rgb = RGBColor(0x1D, 0x4E, 0xD8)
    return h

def add_callout(doc, text, title="💡 NOTA TÉCNICA", fill="F1F5F9"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    cell = tbl.cell(0, 0)
    cell.width = Inches(6.9)
    set_cell_background(cell, fill)
    set_cell_margins(cell, top=140, bottom=140, left=180, right=180)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    r_t = p.add_run(f"{title}\n")
    r_t.font.bold = True
    r_t.font.size = Pt(9.5)
    r_t.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)
    
    r_b = p.add_run(text)
    r_b.font.size = Pt(9.5)
    r_b.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_table_from_markdown(doc, headers, rows):
    tbl = doc.add_table(rows=len(rows) + 1, cols=len(headers))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = True
    
    for i, h in enumerate(headers):
        cell = tbl.cell(0, i)
        set_cell_background(cell, "1E293B")
        set_cell_margins(cell, top=100, bottom=100, left=120, right=120)
        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run(h)
        r.font.bold = True
        r.font.size = Pt(9)
        r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        
    for r_idx, row in enumerate(rows):
        bg = "F8FAFC" if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, val in enumerate(row):
            cell = tbl.cell(r_idx + 1, c_idx)
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(str(val))
            r.font.size = Pt(9)
            r.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
            
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

def generate_pm_docx(output_path):
    doc = create_styled_document()
    
    add_header_banner(
        doc,
        title="Especificación de Producto (PRD) & Historias de Usuario (v3.0)",
        subtitle="Módulo 02: Control de Asistencia, Rediseño 'Excel-Killer' y Prevención DPI",
        author_meta="Para: Product Manager (PM) & Dirección • Autor: Felipe (Equipo 02) • Triple Experiencia Docente"
    )
    
    add_heading_1(doc, "1. Diagnóstico de Campo y Propuesta de Valor")
    doc.add_paragraph("Las entrevistas de campo con docentes del IESTP Argentina demostraron que el competidor real no es otro software, sino su archivo Excel o la hoja física de firmas. Los docentes prefieren Excel porque entran en 3 clics, ven la sábana de 18 semanas y solo marcan la letra 'F' a los ausentes.")
    doc.add_paragraph("Nuestra solución resuelve el problema superando al Excel en su propio juego mediante tres motores de entrada:")
    doc.add_paragraph("• Motor 1 (Flash Móvil en 1 Clic): Autodetección de clase en curso y nómina en PRESENTE para pasar lista en 8 segundos.", style='List Bullet')
    doc.add_paragraph("• Motor 2 (Sábana Interactiva Live Grid): Matriz de 18 semanas con atajos de teclado (flechas, F, T, P) y cálculo automático de DPI.", style='List Bullet')
    doc.add_paragraph("• Motor 3 (Smart Copy-Paste Ctrl+V): El docente pega directamente una columna o tabla desde su Excel personal y sincroniza en 1 segundo.", style='List Bullet')
    
    add_heading_1(doc, "2. Matriz Exhaustiva de Casos de Uso por Rol")
    doc.add_paragraph("• ROL DOCENTE: CU-DOC-01 (Toma Flash 1-Clic), CU-DOC-02 (Sábana Live Grid), CU-DOC-03 (Pegar desde Excel Ctrl+V), CU-DOC-04 (Cierre y Oficialización), CU-DOC-05 (Sesión Extraordinaria/Recuperación), CU-DOC-06 (Cambio de Aula en Vivo), CU-DOC-07 (Aprobar Justificaciones en 72h).")
    doc.add_paragraph("• ROL ESTUDIANTE: CU-EST-01 (Semáforo Anti-DPI y Horas de Margen), CU-EST-02 (Solicitud de Justificación Digital con Foto), CU-EST-03 (Historial Detallado).")
    doc.add_paragraph("• ROL COORDINACIÓN: CU-COORD-01 (Radar de Cumplimiento Docente en Vivo), CU-COORD-02 (Radar Preventivo de Deserción y Casos DPI), CU-COORD-03 (Reprogramar Horarios Futuros), CU-COORD-04 (Exportación Oficial en Excel .xlsx y PDF).")

    add_heading_1(doc, "3. Diagramas de Actividades de Negocio")
    doc.add_paragraph("• Flujo 1 (Toma de Asistencia): Docente ingresa -> Selecciona Modo (Flash, Sábana o Pegar Excel) -> Marca faltas -> Oficializa -> Transacción en mod02.asistencias y congelamiento de sesión.")
    doc.add_paragraph("• Flujo 2 (Justificación Digital): Alumno pulsa 'Justificar' -> Sistema valida fecha <= 72h hábiles -> Sube comprobante -> Docente evalúa y aprueba -> Se reclasifica a FALTA_JUSTIFICADA y se actualiza el porcentaje DPI en vivo.")
    doc.add_paragraph("• Flujo 3 (Reprogramación Futura): Coordinador cambia día/aula a partir de Semana N -> Se actualizan únicamente sesiones PROGRAMADAS (Semana >= N) sin alterar el historial cerrado de las semanas anteriores.")

    add_heading_1(doc, "4. Historias de Usuario Formales (Formato Gherkin)")
    
    add_heading_2(doc, "👤 HU-02.1: Toma de Asistencia Flash Contextual en 1 Clic")
    add_callout(doc, "Escenario Gherkin:\nDado que el docente inicia sesión en el horario de su clase\nCuando entra al Módulo 02\nEntonces observa el Hero Banner '⚡ TOMAR ASISTENCIA AHORA'\nY al presionar el botón se abre la lista con 35 alumnos en PRESENTE\nY al tocar al alumno ausente cambia inmediatamente a FALTA_INJUSTIFICADA.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")
    
    add_heading_2(doc, "👤 HU-02.2: Sábana Interactiva de 18 Semanas con Teclado")
    add_callout(doc, "Escenario Gherkin:\nDado que el docente abre la vista 'Matriz de 18 Semanas'\nCuando se desplaza con las flechas del teclado y presiona la tecla 'F'\nEntonces la celda se pinta de rojo con la letra 'F'\nY la columna de resumen a la derecha actualiza en vivo el total de inasistencias y el semáforo DPI.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")

    add_heading_2(doc, "👤 HU-02.3: Smart Copy-Paste desde Excel Personal (Ctrl+V)")
    add_callout(doc, "Escenario Gherkin:\nDado que el docente copió una lista de asistencias desde su archivo Excel\nCuando hace clic en '📋 Pegar desde Excel' y presiona 'Ctrl+V'\nEntonces el sistema valida los DNIs/nombres y rellena automáticamente las 35 celdas en 1 segundo.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")

    add_heading_2(doc, "👤 HU-02.4: Radar Semafórico Anti-DPI para Estudiantes")
    add_callout(doc, "Escenario Gherkin:\nDado que un estudiante acumula 16 horas de falta en un curso de 68 horas (23.5%)\nCuando consulta su panel de 'Mi Asistencia'\nEntonces observa el indicador '🟠 RIESGO ALTO (23.5%)' con alerta: 'A solo 4 horas de inasistencia de quedar en DPI'.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")

    add_heading_2(doc, "👤 HU-02.5: Justificación Digital Móvil en 72 Horas")
    add_callout(doc, "Escenario Gherkin:\nDado que la inasistencia fue hace menos de 72 horas hábiles\nCuando el alumno pulsa '📎 Justificar Falta' y sube la foto de su certificado\nEntonces queda registrada con estado PENDIENTE en la bandeja del docente titular.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")

    add_heading_1(doc, "5. Matriz MoSCoW de Priorización")
    headers = ["Prioridad", "Historias de Usuario", "Justificación de Negocio"]
    rows = [
        ["Must Have (Obligatorio)", "HU-02.1 (Flash 1-Clic), HU-02.2 (Sábana Teclado), HU-02.3 (Copy-Paste), HU-02.4 (Semáforo), HU-02.5 (Justif 72h)", "Garantiza la adopción total superando al Excel en velocidad y eliminando el doble trabajo."],
        ["Should Have (Importante)", "HU-02.6 (Recuperación Ad-hoc), HU-02.7 (Reprogramación Futura), HU-02.8 (Reportes DPI)", "Resiliencia ante cambios de horarios y reportería oficial."],
        ["Could Have (Deseable)", "Descarga de plantilla personalizada .xlsx, selector de cambio de aula.", "Comodidad visual y soporte para laboratorios ocupados."],
        ["Won't Have (Descartado)", "Reconocimiento biométrico facial.", "Fuera del alcance."]
    ]
    add_table_from_markdown(doc, headers, rows)
    
    doc.save(output_path)
    print(f"✅ Generado: {output_path}")

def generate_dev_docx(output_path):
    doc = create_styled_document()
    
    add_header_banner(
        doc,
        title="Guía Técnica de Arquitectura, Diagramas & Datos (v3.0)",
        subtitle="Módulo 02: Control de Asistencia Institucional & Prevención DPI",
        author_meta="Para: Equipo de Desarrollo & Arquitecto • Autor: Felipe • .NET 10 + PostgreSQL 16 (mod02)"
    )
    
    add_heading_1(doc, "1. Soberanía de Esquema y Aislamiento de Datos")
    doc.add_paragraph("El Módulo 02 opera bajo soberanía total de datos:")
    doc.add_paragraph("• mod02 posee control de escritura EXCLUSIVO sobre sus tablas (mod02.*).", style='List Bullet')
    doc.add_paragraph("• mod02 consume el catálogo central (core.*) en MODO ESTRICTO DE SOLO LECTURA (SELECT).", style='List Bullet')
    doc.add_paragraph("• Cero invasión: No modifica tablas ni lógica de ningún otro módulo.", style='List Bullet')
    doc.add_paragraph("• Cálculo Autónomo: La vista mod02.v_resumen_asistencia_estudiante calcula internamente las horas acumuladas, porcentaje de faltas y condición DPI (>=30%).", style='List Bullet')

    add_heading_1(doc, "2. Casos de Uso del Módulo 02 (UML)")
    doc.add_paragraph("• DOCENTE: CU-02.1 (Toma Flash 1-Clic), CU-02.2 (Sábana Live Grid), CU-02.3 (Smart Copy-Paste Ctrl+V), CU-02.4 (Cierre y Oficialización), CU-02.5 (Sesión Extraordinaria/Recuperación), CU-02.6 (Cambio de Aula en Vivo), CU-02.7 (Resolver Justificaciones en 72h).")
    doc.add_paragraph("• ESTUDIANTE: CU-02.8 (Consultar Semáforo Anti-DPI), CU-02.9 (Solicitar Justificación con Sustento en 72h).")
    doc.add_paragraph("• COORDINACIÓN: CU-02.10 (Reprogramar Sesiones Futuras), CU-02.11 (Radar de Cumplimiento Docente y Deserción), CU-02.12 (Exportar Actas Oficiales y Sábanas en Excel .xlsx).")

    add_heading_1(doc, "3. Diagramas de Actividades del Sistema")
    doc.add_paragraph("• Actividad 1 (Toma Multimodal): Detección automática -> Selección entre Modo Flash (móvil), Sábana (teclado) o Smart Copy-Paste (Ctrl+V) -> Transacción atómica en mod02.asistencias.")
    doc.add_paragraph("• Actividad 2 (Justificación): Alumno sube comprobante -> Validación temporal <= 72h -> Docente evalúa -> UPDATE mod02.asistencias (FALTA_JUSTIFICADA) y recálculo automático de DPI.")
    doc.add_paragraph("• Actividad 3 (Reprogramación Futura): Coordinador mueve horario desde Semana N -> Actualiza únicamente sesiones con estado PROGRAMADA sin alterar el pasado.")

    add_heading_1(doc, "4. Diagramas de Secuencia E2E Críticos")
    add_heading_2(doc, "Secuencia 1: Smart Copy-Paste desde Excel (Ctrl+V)")
    doc.add_paragraph("1. Docente copia tabla de su Excel (Ctrl+C).\n2. Hace clic en la sábana web y presiona Ctrl+V.\n3. Parser JS captura el portapapeles y rellena las celdas en pantalla.\n4. Clic en 'Guardar Cambios' -> POST /Modulo02/GuardarAsistenciaMasiva -> Bulk UPSERT en mod02.asistencias.")

    add_heading_2(doc, "Secuencia 2: Reprogramación de Horarios Futuros")
    doc.add_paragraph("1. Coordinador modifica día u horario de una clase desde la Semana N.\n2. Backend ejecuta: UPDATE mod02.sesiones_clase SET fecha_clase = NuevaFecha WHERE clase_docente_id = @ClaseId AND numero_semana >= N AND estado = 'PROGRAMADA'.\n3. Las sesiones de las semanas 1 a N-1 (cerradas) quedan blindadas e inmutables.")

    add_heading_1(doc, "5. Diccionario de Datos del Esquema Soberano mod02")
    headers = ["Tabla / Vista", "Descripción y Propósito", "Clave Foránea / Relación"]
    rows = [
        ["mod02.configuracion", "Parámetros institucionales (30% DPI, 15m tolerancia, 72h justificaciones).", "Configuración interna."],
        ["mod02.clases_docente", "Asignación de asignatura, docente, ciclo, turno y aula.", "FK -> core.unidades_didacticas, core.docentes, core.aulas."],
        ["mod02.clase_horarios", "Plantilla teórica semanal (Día 1..6, horas pedagógicas).", "FK -> mod02.clases_docente."],
        ["mod02.sesiones_clase", "Instancias físicas de clase semana a semana 1..18.", "FK -> mod02.clases_docente, core.docentes."],
        ["mod02.asistencias", "Registro individual (PRESENTE, TARDANZA, FALTA_INJUSTIFICADA, FALTA_JUSTIFICADA).", "FK -> mod02.sesiones_clase, core.estudiantes."],
        ["mod02.justificaciones", "Expedientes de justificación médica/laboral en 72h.", "FK -> mod02.asistencias, core.estudiantes."],
        ["mod02.v_resumen_asistencia_estudiante", "Vista de cálculo: horas acumuladas, porcentaje de faltas y condición DPI.", "JOIN soberano mod02.asistencias + core.estudiantes."]
    ]
    add_table_from_markdown(doc, headers, rows)

    add_heading_1(doc, "6. Contrato C# de Servicio (IAsistenciaService)")
    add_callout(doc, "public interface IAsistenciaService {\n    Task<DashboardAsistenciaViewModel> GetDashboardAsync(int? personaId, string rol);\n    Task<ClaseActivaDocenteDto?> GetClaseActivaHoyAsync(int docenteId);\n    Task<IEnumerable<AlumnoAsistenciaItemDto>> GetAlumnosParaSesionAsync(int sesionId, int udId);\n    Task<bool> GuardarAsistenciaSesionAsync(GuardarAsistenciaRequestDto request, int? usuarioId);\n    Task<bool> GuardarAsistenciaMasivaMatrizAsync(GuardarMatrizRequestDto request, int? usuarioId);\n    Task<bool> SolicitarJustificacionAsync(CrearJustificacionDto dto, int estudianteId);\n    Task<bool> ResolverJustificacionAsync(ResolverJustificacionDto dto, int docenteId);\n    Task<bool> ReprogramarSesionesFuturasAsync(ReprogramarHorarioDto dto);\n}", "C# INTERFACE CONTRACT")

    doc.save(output_path)
    print(f"✅ Generado: {output_path}")

if __name__ == "__main__":
    base_vault = "/media/prozac/DATA/Documents/Obsidian Vault/🏛️ 04_Instituto_Argentina/🏛️ 01_Intranet_y_ERP_Modular/📦 Fichas_Distribucion_Equipos/02_EQUIPO_02_ASISTENCIA"
    base_repo = "/home/prozac/dev/intranet-institucional-modular/src/02_Modulos/Intranet.Modulo02/Docs"
    base_art = "/home/prozac/.gemini/antigravity-cli/brain/814c6d2f-783a-4810-9316-3b07d3f1af1e"
    
    os.makedirs(base_vault, exist_ok=True)
    os.makedirs(base_repo, exist_ok=True)
    
    generate_pm_docx(os.path.join(base_vault, "01_DOCUMENTO_PRODUCTO_Y_HISTORIAS_USUARIO_PM.docx"))
    generate_pm_docx(os.path.join(base_repo, "01_DOCUMENTO_PRODUCTO_Y_HISTORIAS_USUARIO_PM.docx"))
    generate_pm_docx(os.path.join(base_art, "01_DOCUMENTO_PRODUCTO_Y_HISTORIAS_USUARIO_PM.docx"))
    
    generate_dev_docx(os.path.join(base_vault, "02_GUIA_ARQUITECTURA_Y_INTEGRACION_DEVELOPERS.docx"))
    generate_dev_docx(os.path.join(base_repo, "02_GUIA_ARQUITECTURA_Y_INTEGRACION_DEVELOPERS.docx"))
    generate_dev_docx(os.path.join(base_art, "02_GUIA_ARQUITECTURA_Y_INTEGRACION_DEVELOPERS.docx"))
