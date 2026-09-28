import os
import subprocess
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

IMG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "img")

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
        section.top_margin = Inches(0.75)
        section.bottom_margin = Inches(0.75)
        section.left_margin = Inches(0.75)
        section.right_margin = Inches(0.75)
        
    style_normal = doc.styles['Normal']
    style_normal.font.name = 'Calibri'
    style_normal.font.size = Pt(10)
    style_normal.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    return doc

def add_header_banner(doc, title, subtitle, author_meta):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    
    cell = tbl.cell(0, 0)
    cell.width = Inches(7.0)
    set_cell_background(cell, "0F172A")
    set_cell_margins(cell, top=240, bottom=240, left=240, right=240)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(2)
    run_inst = p.add_run("🏛️ IESTP \"ARGENTINA\" • INTRANET INSTITUCIONAL MODULAR")
    run_inst.font.name = 'Calibri'
    run_inst.font.size = Pt(9.5)
    run_inst.font.bold = True
    run_inst.font.color.rgb = RGBColor(0x38, 0xBD, 0xF8)
    
    p2 = cell.add_paragraph()
    p2.paragraph_format.space_before = Pt(2)
    p2.paragraph_format.space_after = Pt(4)
    run_title = p2.add_run(title)
    run_title.font.name = 'Calibri'
    run_title.font.size = Pt(15)
    run_title.font.bold = True
    run_title.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    
    p3 = cell.add_paragraph()
    p3.paragraph_format.space_before = Pt(0)
    p3.paragraph_format.space_after = Pt(6)
    run_sub = p3.add_run(subtitle)
    run_sub.font.name = 'Calibri'
    run_sub.font.size = Pt(10.5)
    run_sub.font.italic = True
    run_sub.font.color.rgb = RGBColor(0x94, 0xA3, 0xB8)
    
    p4 = cell.add_paragraph()
    p4.paragraph_format.space_before = Pt(4)
    p4.paragraph_format.space_after = Pt(2)
    run_meta = p4.add_run(author_meta)
    run_meta.font.name = 'Calibri'
    run_meta.font.size = Pt(8.5)
    run_meta.font.color.rgb = RGBColor(0xCB, 0xD5, 0xE1)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_heading_1(doc, text):
    h = doc.add_paragraph()
    h.paragraph_format.space_before = Pt(14)
    h.paragraph_format.space_after = Pt(4)
    h.paragraph_format.keep_with_next = True
    r = h.add_run(text)
    r.font.name = 'Calibri'
    r.font.size = Pt(13)
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
    r.font.size = Pt(11)
    r.font.bold = True
    r.font.color.rgb = RGBColor(0x1D, 0x4E, 0xD8)
    return h

def add_callout(doc, text, title="💡 NOTA TÉCNICA", fill="F1F5F9"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    cell = tbl.cell(0, 0)
    cell.width = Inches(7.0)
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
    r_b.font.size = Pt(9)
    r_b.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_diagram_image(doc, img_name, caption, width=Inches(6.8)):
    img_path = os.path.join(IMG_DIR, img_name)
    if os.path.exists(img_path):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(8)
        p_img.paragraph_format.space_after = Pt(2)
        run_img = p_img.add_run()
        run_img.add_picture(img_path, width=width)
        
        p_cap = doc.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap.paragraph_format.space_before = Pt(0)
        p_cap.paragraph_format.space_after = Pt(8)
        r_cap = p_cap.add_run(f"📐 Figura: {caption}")
        r_cap.font.size = Pt(8.5)
        r_cap.font.italic = True
        r_cap.font.color.rgb = RGBColor(0x64, 0x74, 0x8B)

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
        r.font.size = Pt(8.5)
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
            r.font.size = Pt(8.5)
            r.font.color.rgb = RGBColor(0x1E, 0x29, 0x3B)
            
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

# ==============================================================================
# 📄 GENERACIÓN DEL PRD PARA EL PRODUCT MANAGER (PM)
# ==============================================================================
def generate_pm_docx(output_path):
    doc = create_styled_document()
    
    add_header_banner(
        doc,
        title="Especificación de Producto (PRD) & Historias de Usuario (v3.5)",
        subtitle="Módulo 02: Control de Asistencia, Rediseño 'Excel-Killer' y Prevención DPI",
        author_meta="Para: Product Manager (PM), Dirección & Docentes • Autor: Felipe (Equipo 02) • Ciclo de 18 Semanas"
    )
    
    add_heading_1(doc, "1. Marco Normativo Oficial y Diagnóstico de Campo")
    doc.add_paragraph("El diseño del Módulo 02 responde a la Ley N° 30512, RVM N° 277-2019-MINEDU y al Manual de Procedimientos Académicos (MPA 2024–2026, R.D. N° 109-V-DIR-2024-IESTP.\"ARGENTINA\").")
    doc.add_paragraph("Las entrevistas de campo demostraron que el competidor real de cualquier sistema es el Excel personal o la hoja física. Nuestra solución supera al Excel mediante tres motores de registro:")
    doc.add_paragraph("• Motor 1 (Flash Móvil en 1 Clic): Autodetección de clase en curso y nómina en PRESENTE para pasar lista en 8 segundos.", style='List Bullet')
    doc.add_paragraph("• Motor 2 (Sábana Interactiva Live Grid): Matriz completa de 18 semanas con navegación por teclado (flechas, F, T, P) y cálculo automático de DPI.", style='List Bullet')
    doc.add_paragraph("• Motor 3 (Smart Copy-Paste Ctrl+V): El docente pega directamente su columna desde Excel y el sistema mapea por DNI en 1 segundo.", style='List Bullet')
    
    add_heading_1(doc, "2. Diagramas de Casos de Uso por Rol (UML)")
    doc.add_paragraph("La arquitectura funcional del Módulo 02 se centra en los dos roles protagónicos del aula: el Docente y el Estudiante:")
    
    add_heading_2(doc, "2.1. Casos de Uso del Rol Docente (CU-DOC-01 al CU-DOC-08)")
    doc.add_paragraph("Muestra la interacción del docente en los tres motores de asistencia (Flash, Sábana y Copy-Paste), evaluación de justificaciones y cierre inmutable:")
    add_diagram_image(doc, "01_diagrama_casos_de_uso_docente.png", "Diagrama de Casos de Uso UML: Rol Docente (Toma Flash, Sábana 18 Semanas, Copy-Paste y Justificaciones)", width=Inches(6.8))

    add_heading_2(doc, "2.2. Casos de Uso del Rol Estudiante (CU-EST-01 al CU-EST-05)")
    doc.add_paragraph("Muestra la experiencia del alumno en su Portal Anti-DPI (/MiAsistencia), cálculo de horas restantes de inasistencia y justificación médica en 72 horas:")
    add_diagram_image(doc, "01_diagrama_casos_de_uso_estudiante.png", "Diagrama de Casos de Uso UML: Rol Estudiante (Portal Anti-DPI, Monitor de Horas y Justificación Digital)", width=Inches(6.8))

    add_heading_2(doc, "2.3. Interacción Dual Docente - Estudiante")
    doc.add_paragraph("Consolidado de la interacción operativa entre la toma de asistencia del docente y la prevención de deserción del estudiante:")
    add_diagram_image(doc, "01_diagrama_casos_de_uso_docente_estudiante_dual.png", "Diagrama de Interacción Operativa: Docente vs. Estudiante", width=Inches(6.8))

    add_heading_1(doc, "3. Diagramas de Actividad y Procesos de Negocio")
    
    add_heading_2(doc, "Proceso 1: Flujo Multimodal de Toma de Asistencia Docente")
    doc.add_paragraph("Muestra la interacción desde la autodetección de aula/horario hasta la congelación inmutable de la sesión en base de datos:")
    add_diagram_image(doc, "02_diagrama_actividad_toma_asistencia.png", "Diagrama de Actividad: Toma de Asistencia y Oficialización Inmutable", width=Inches(6.5))

    add_heading_2(doc, "Proceso 2: Justificación Digital de Inasistencias (Ventana 72h)")
    doc.add_paragraph("El estudiante tiene un plazo improrrogable de 72 horas hábiles para adjuntar sustento médico o laboral:")
    add_diagram_image(doc, "03_diagrama_actividad_justificacion_estudiante.png", "Diagrama de Actividad: Solicitud, Validación Temporal y Aprobación de Justificación Médica", width=Inches(6.5))

    add_heading_2(doc, "Proceso 3: Auditoría DPI, Bloqueo Semana 17 y Cierre REGISTRA (Semana 18)")
    doc.add_paragraph("Regla legal: Estudiantes con >= 30% de inasistencias quedan inhabilitados por ley para rendir examen de recuperación en Semana 17:")
    add_diagram_image(doc, "04_diagrama_actividad_cierre_sem17_sem18_registra.png", "Diagrama de Actividad: Detección de DPI, Bloqueo Semana 17 y Cierre Oficial REGISTRA", width=Inches(6.5))

    add_heading_1(doc, "4. Historias de Usuario Formales (Formato Gherkin)")
    
    add_heading_2(doc, "👤 HU-02.1: Toma de Asistencia Flash Contextual en 1 Clic")
    add_callout(doc, "Escenario Gherkin:\nDado que el docente inicia sesión en el horario de su clase\nCuando entra al Módulo 02\nEntonces observa el Hero Banner '⚡ TOMAR ASISTENCIA AHORA'\nY al presionar el botón se abre la lista con 41 alumnos en PRESENTE\nY al tocar al alumno ausente cambia inmediatamente a FALTA_INJUSTIFICADA.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")
    
    add_heading_2(doc, "👤 HU-02.2: Sábana Interactiva de 18 Semanas con Teclado")
    add_callout(doc, "Escenario Gherkin:\nDado que el docente abre la vista 'Matriz de 18 Semanas'\nCuando se desplaza con las flechas del teclado y presiona la tecla 'F'\nEntonces la celda se pinta de rojo con la letra 'F'\nY la columna de resumen a la derecha actualiza en vivo el total de inasistencias y el semáforo DPI.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")

    add_heading_2(doc, "👤 HU-02.3: Smart Copy-Paste desde Excel Personal (Ctrl+V)")
    add_callout(doc, "Escenario Gherkin:\nDado que el docente copió una lista de asistencias desde su archivo Excel\nCuando hace clic en '📋 Pegar desde Excel' y presiona 'Ctrl+V'\nEntonces el sistema valida los DNIs/nombres y rellena automáticamente las 41 celdas en 1 segundo.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")

    add_heading_2(doc, "👤 HU-02.4: Radar Semafórico Anti-DPI para Estudiantes")
    add_callout(doc, "Escenario Gherkin:\nDado que un estudiante acumula 16 horas de falta en un curso de 68 horas (23.5%)\nCuando consulta su panel de 'Mi Asistencia'\nEntonces observa el indicador '🟠 RIESGO ALTO (23.5%)' con alerta: 'A solo 4 horas de inasistencia de quedar en DPI'.", "📋 CRITERIO DE ACEPTACIÓN GHERKIN")

    add_heading_1(doc, "5. Matriz MoSCoW de Priorización")
    headers = ["Prioridad", "Historias de Usuario", "Justificación de Negocio"]
    rows = [
        ["Must Have (Obligatorio)", "HU-02.1 (Flash 1-Clic), HU-02.2 (Sábana 18 Semanas), HU-02.3 (Copy-Paste Ctrl+V), HU-02.4 (Semáforo Anti-DPI), HU-02.5 (Justif 72h)", "Garantiza adopción total eliminando el doble trabajo."],
        ["Should Have (Importante)", "HU-02.6 (Semana 17 Recuperación), HU-02.7 (Reprogramación Futura), HU-02.8 (Exportación REGISTRA MINEDU .xlsx)", "Cumplimiento normativo y auditoría oficial."],
        ["Could Have (Deseable)", "Reubicación de aula en vivo, atajos táctiles móviles.", "Comodidad operativa para laboratorios llenos."],
        ["Won't Have (Descartado)", "Reconocimiento facial biométrico.", "Fuera de alcance y costo excesivo de hardware."]
    ]
    add_table_from_markdown(doc, headers, rows)
    
    doc.save(output_path)
    print(f"✅ Generado: {output_path}")

# ==============================================================================
# 📄 GENERACIÓN DE LA GUÍA TÉCNICA PARA DESARROLLADORES & ARQUITECTURA
# ==============================================================================
def generate_dev_docx(output_path):
    doc = create_styled_document()
    
    add_header_banner(
        doc,
        title="Guía Técnica de Arquitectura, Diagramas & Especificación de Datos (v3.5)",
        subtitle="Módulo 02: Control de Asistencia Institucional & Prevención DPI",
        author_meta="Para: Equipo de Desarrollo & Arquitecto • Autor: Felipe (Equipo 02) • .NET 10 LTS + PostgreSQL 16"
    )
    
    add_heading_1(doc, "1. Soberanía de Esquema y Aislamiento de Datos")
    doc.add_paragraph("El Módulo 02 opera bajo soberanía total de datos:")
    doc.add_paragraph("• mod02 posee control de escritura EXCLUSIVO sobre sus tablas (mod02.*).", style='List Bullet')
    doc.add_paragraph("• mod02 consume el catálogo central (core.*) en MODO ESTRICTO DE SOLO LECTURA (SELECT).", style='List Bullet')
    doc.add_paragraph("• Cero invasión: No modifica tablas ni lógica de ningún otro módulo.", style='List Bullet')
    doc.add_paragraph("• Cálculo Autónomo: La vista mod02.v_resumen_asistencia_estudiante calcula internamente las horas acumuladas, porcentaje de faltas y condición DPI (>=30%).", style='List Bullet')

    add_heading_1(doc, "2. Diagramas de Casos de Uso por Rol (UML)")
    doc.add_paragraph("Especificación de los casos de uso implementados en los controladores y servicios del módulo:")
    
    add_heading_2(doc, "2.1. Casos de Uso: Rol Docente")
    add_diagram_image(doc, "01_diagrama_casos_de_uso_docente.png", "Diagrama UML: Casos de Uso del Docente en Módulo 02", width=Inches(6.8))

    add_heading_2(doc, "2.2. Casos de Uso: Rol Estudiante")
    add_diagram_image(doc, "01_diagrama_casos_de_uso_estudiante.png", "Diagrama UML: Casos de Uso del Estudiante (Anti-DPI y Justificaciones)", width=Inches(6.8))

    add_heading_1(doc, "3. Diagramas de Secuencia E2E Críticos")
    
    add_heading_2(doc, "Secuencia 1: Smart Copy-Paste desde Excel (Ctrl+V)")
    doc.add_paragraph("Detalla el flujo del portapapeles del sistema operativo, parseo en frontend JS y bulk UPSERT atómico en PostgreSQL:")
    add_diagram_image(doc, "05_diagrama_secuencia_smart_copy_paste.png", "Diagrama de Secuencia: Smart Copy-Paste desde Excel con Dapper Bulk UPSERT", width=Inches(6.8))

    add_heading_2(doc, "Secuencia 2: Toma de Asistencia Flash Móvil y Cierre Inmutable")
    doc.add_paragraph("Autodetección de clase activa, precarga de 41 alumnos en PRESENTE y cierre de sesión en menos de 8 segundos:")
    add_diagram_image(doc, "06_diagrama_secuencia_toma_flash.png", "Diagrama de Secuencia: Toma Flash Móvil y Oficialización de Sesión", width=Inches(6.8))

    add_heading_2(doc, "Secuencia 3: Justificación Digital y Reclasificación en Vivo")
    doc.add_paragraph("Carga de sustento, validación de la ventana de 72 horas y recálculo instantáneo de horas de inasistencia:")
    add_diagram_image(doc, "07_diagrama_secuencia_justificacion_digital.png", "Diagrama de Secuencia: Solicitud, Validación 72h y Resolución de Justificación Médica", width=Inches(6.8))

    add_heading_1(doc, "4. Modelo Entidad-Relación Soberano (ERD)")
    doc.add_paragraph("El siguiente diagrama representa las tablas maestras de mod02 y sus referencias a core:")
    add_diagram_image(doc, "08_diagrama_arquitectura_erd_mod02.png", "Diagrama Entidad-Relación (ERD) del Esquema Soberano mod02", width=Inches(6.8))

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
    os.makedirs(base_art, exist_ok=True)
    
    generate_pm_docx(os.path.join(base_vault, "01_DOCUMENTO_PRODUCTO_Y_HISTORIAS_USUARIO_PM.docx"))
    generate_pm_docx(os.path.join(base_repo, "01_DOCUMENTO_PRODUCTO_Y_HISTORIAS_USUARIO_PM.docx"))
    generate_pm_docx(os.path.join(base_art, "01_DOCUMENTO_PRODUCTO_Y_HISTORIAS_USUARIO_PM.docx"))
    
    generate_dev_docx(os.path.join(base_vault, "02_GUIA_ARQUITECTURA_Y_INTEGRACION_DEVELOPERS.docx"))
    generate_dev_docx(os.path.join(base_repo, "02_GUIA_ARQUITECTURA_Y_INTEGRACION_DEVELOPERS.docx"))
    generate_dev_docx(os.path.join(base_art, "02_GUIA_ARQUITECTURA_Y_INTEGRACION_DEVELOPERS.docx"))

