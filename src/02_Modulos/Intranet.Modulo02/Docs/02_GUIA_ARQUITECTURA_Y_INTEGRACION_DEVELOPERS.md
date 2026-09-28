# 🛠️ Guía Técnica de Arquitectura, Diagramas & Especificación de Datos
## Módulo 02: Control de Asistencia Institucional & Prevención de Deserción DPI

> **Para:** Equipo de Desarrollo y Arquitecto de Software  
> **Autor:** Felipe (Equipo 02 - Asistencia)  
> **Stack:** .NET 10 LTS (C# 13) • PostgreSQL 16 LTS • Dapper • TailwindCSS / DaisyUI  
> **Arquitectura:** Esquema Soberano `mod02` con consumo en Solo Lectura de `core`  
> **Marco Normativo:** Ley N° 30512 • RVM N° 277-2019-MINEDU • RVM N° 177-2021-MINEDU • MPA (R.D. N° 109-V-DIR-2024) • RI (R.D. N° 005-V-DIR-2025)  
> **Versión:** 3.5 (Arquitectura del Rediseño Integral: Ciclo de 18 Semanas, Semana 17 Recuperación, Semana 18 Cierre y Esquema Schedule-Free)  

---

## 🧭 1. Principio de Aislamiento, Soberanía de Datos y Estructura de 18 Semanas

El Módulo 02 opera bajo **soberanía de esquema estricta (`mod02`)** y desacoplamiento de horarios externos:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                              FRONTERA DE DATOS DEL MÓDULO 02                           │
├─────────────────────────────────────────┬──────────────────────────────────────────────┤
│ 📖 ESQUEMA CENTRAL `core` (Solo Lectura)│ ✍️ ESQUEMA SOBERANO `mod02` (Control Total)   │
│ • core.estudiantes (Nómina oficial)     │ • mod02.configuracion (Parámetros y límites) │
│ • core.docentes (Planta docente)        │ • mod02.clases_docente (Carga y sílabo)      │
│ • core.unidades_didacticas (Asignaturas)│ • mod02.clase_horarios (Plantillas horario)  │
│ • core.aulas (Ambientes físicos)        │ • mod02.sesiones_clase (Semanas 1..18)       │
│ • core.periodos_academicos              │ • mod02.asistencias (Registros P/T/F/J)      │
│                                         │ • mod02.justificaciones (Expedientes 72h)    │
│                                         │ • mod02.v_resumen_asistencia_estudiante      │
└─────────────────────────────────────────┴──────────────────────────────────────────────┘
```

### 📅 Estructura Oficial de las 18 Semanas en la Base de Datos

En `mod02.sesiones_clase`, el campo `numero_semana` recorre de 1 a 18 con propósitos claros:
* **Semanas 01 a 16:** Sesiones lectivas regulares ordinarias (`tipo_sesion = 'REGULAR'`).
* **Semana 17:** Sesión de Evaluación de Recuperación Ordinaria (`tipo_sesion = 'RECUPERACION_SEMANA_17'`).
* **Semana 18:** Cierre final de asistencias y exportación para REGISTRA (`tipo_sesion = 'CIERRE_ACTAS_SEMANA_18'`).

---

## 📐 2. Diagramas de Casos de Uso por Rol (UML)

```mermaid
flowchart TD
    subgraph Actores del Ecosistema
        Docente["👨‍🏫 Docente"]
        Estudiante["👨‍🎓 Estudiante"]
        Coordinador["👔 Coordinador / Dirección"]
    end

    subgraph "Casos de Uso: Docente"
        CU01["CU-02.1: Autodetectar y Tomar Asistencia Flash en 1 Clic"]
        CU02["CU-02.2: Sábana Interactiva de 18 Semanas con Teclado"]
        CU03["CU-02.3: Importación Rápida con Smart Copy-Paste (Ctrl+V)"]
        CU04["CU-02.4: Oficializar y Cerrar Sesión (Inmutabilidad)"]
        CU05["CU-02.5: Iniciar Sesión de Recuperación / Extraordinaria"]
        CU06["CU-02.6: Cambiar Aula en Vivo si el Laboratorio está ocupado"]
        CU07["CU-02.7: Evaluar y Resolver Justificaciones Médicas (72h)"]
        CU08["CU-02.8: Gestión de Asistencia Semana 17 (Recuperación)"]
    end

    subgraph "Casos de Uso: Estudiante"
        CU09["CU-02.9: Consultar Semáforo Anti-DPI y Horas Restantes"]
        CU10["CU-02.10: Solicitar Justificación Digital con Foto (72h)"]
    end

    subgraph "Casos de Uso: Coordinación"
        CU11["CU-02.11: Reprogramar Sesiones Futuras ante cambio de horario"]
        CU12["CU-02.12: Radar de Cumplimiento Docente y Casos DPI (30%)"]
        CU13["CU-02.13: Exportar Sábanas Oficiales y Archivo para REGISTRA MINEDU"]
    end

    Docente --> CU01
    Docente --> CU02
    Docente --> CU03
    Docente --> CU04
    Docente --> CU05
    Docente --> CU06
    Docente --> CU07
    Docente --> CU08

    Estudiante --> CU09
    Estudiante --> CU10

    Coordinador --> CU07
    Coordinador --> CU11
    Coordinador --> CU12
    Coordinador --> CU13
```

---

## 🔄 3. Diagramas de Actividades del Sistema

---

### 🔹 Diagrama de Actividades: Flujo de Toma de Asistencia Multimodal

```mermaid
flowchart TD
    A([Docente accede a /Modulo02]) --> B[Backend evalúa Hora, Día y DocenteId]
    B --> C{¿Existe sesión en curso?}
    
    C -- Sí --> D[Renderizar Hero Banner 'Clase Activa Hoy']
    C -- No --> E[Renderizar Selector de Cursos del Docente]

    D --> F{Método de Registro Elegido}
    E --> F

    F -->|Modo 1: Flash| G[Cargar nómina en estado PRESENTE]
    G --> H[Docente toca a los ausentes -> FALTA]
    H --> I[Guardar y Cerrar]

    F -->|Modo 2: Sábana Live| J[Cargar Matriz de 18 Semanas]
    J --> K[Docente edita con Teclas Flechas, F, T, P]
    K --> I

    F -->|Modo 3: Copy-Paste| L[Docente presiona Ctrl+V con datos de Excel]
    L --> M[Parser JS/Backend mapea estudiantes por DNI/Nombre]
    M --> I

    I --> N[(UPDATE mod02.sesiones_clase SET estado='CERRADA')]
    N --> O([Fin del Registro])
```

---

### 🔹 Diagrama de Actividades: Flujo de Justificación y Recálculo de DPI

```mermaid
flowchart TD
    J1([Estudiante con falta injustificada]) --> J2[Abre portal y pulsa '📎 Justificar']
    J2 --> J3{¿Fecha sesión <= 72h hábiles?}

    J3 -- No --> J4[Bloquear solicitud y mostrar aviso de plazo vencido]
    J4 --> J_Fin([Fin])

    J3 -- Sí --> J5[Subir archivo PDF/Foto y motivo]
    J5 --> J6[(INSERT INTO mod02.justificaciones estado='PENDIENTE')]
    J6 --> J7[Notificar en panel del Docente]

    J7 --> J8[Docente revisa sustento adjunto]
    J8 --> J9{¿Aprobado?}

    J9 -- Sí --> J10[(UPDATE mod02.justificaciones SET estado='APROBADA')]
    J10 --> J11[(UPDATE mod02.asistencias SET estado='FALTA_JUSTIFICADA')]
    J11 --> J12[Recálculo automático de % DPI en mod02.v_resumen_asistencia]
    J12 --> J13[Notificar al estudiante: Aprobado]

    J9 -- No --> J14[(UPDATE mod02.justificaciones SET estado='RECHAZADA')]
    J14 --> J15[Notificar al estudiante: Rechazado]
```

---

## ⚡ 4. Diagramas de Secuencia E2E Críticos

---

### 🔹 Secuencia 1: Smart Copy-Paste desde Excel (`Ctrl+V`)

```mermaid
sequenceDiagram
    autonumber
    actor Docente as 👨‍🏫 Docente
    participant View as 🖥️ Matriz (Sábana Web)
    participant Parser as ⚙️ JS Clipboard Parser
    participant Ctrl as 🎮 Modulo02Controller
    participant Svc as ⚙️ AsistenciaService
    participant DB as 🗄️ PostgreSQL (mod02)

    Docente->>Docente: Copia columna/tabla de su archivo Excel (Ctrl+C)
    Docente->>View: Hace clic en celda y presiona Ctrl+V
    View->>Parser: Captura evento onPaste(clipboardData)
    Parser->>Parser: Parsea filas y columnas tabuladas (TSV)
    Parser->>View: Rellena celdas en pantalla con colores (F=Rojo, P=Verde)
    
    Docente->>View: Clic en [ 💾 Guardar Cambios ]
    View->>Ctrl: POST /Modulo02/GuardarAsistenciaMasiva (Array de 35 Alumnos)
    Ctrl->>Svc: GuardarAsistenciaSesionAsync(request)
    Svc->>DB: Bulk UPSERT en mod02.asistencias
    DB-->>Svc: 35 Registros Actualizados
    Svc-->>Ctrl: true
    Ctrl-->>View: HTTP 200 OK ("Sincronizado desde Excel con éxito")
```

---

### 🔹 Secuencia 2: Reprogramación Elástica de Horarios Futuros

```mermaid
sequenceDiagram
    autonumber
    actor Coord as 👔 Coordinador
    participant View as 🖥️ Panel Coordinación
    participant Ctrl as 🎮 Modulo02Controller
    participant Svc as ⚙️ AsistenciaService
    participant DB as 🗄️ PostgreSQL (mod02)

    Coord->>View: Cambia clase de Lunes a Miércoles desde la Semana 4
    View->>Ctrl: POST /Modulo02/ReprogramarHorarioFuturo (ClaseId, DesdeSemana: 4, NuevoDia: 3)
    Ctrl->>Svc: ReprogramarSesionesFuturasAsync(dto)
    
    rect rgb(254, 243, 199)
        Note over Svc,DB: Blindaje del Historial Pasado
        Svc->>DB: UPDATE mod02.sesiones_clase SET fecha_clase = NuevaFecha WHERE clase_docente_id = ClaseId AND numero_semana >= 4 AND estado = 'PROGRAMADA'
    end
    DB-->>Svc: 14 Sesiones Futuras Actualizadas (Semanas 1..3 Cerradas intactas)
    Svc-->>Ctrl: OK
    Ctrl-->>View: "Horario actualizado con éxito."
```

---

## 🗄️ 5. Diccionario de Datos del Esquema `mod02`

| Tabla / Vista | Propósito de Negocio | Claves Foráneas |
| :--- | :--- | :--- |
| `mod02.configuracion` | Parámetros del módulo (30% DPI, 15m tolerancia, 72h justificaciones). | N/A |
| `mod02.clases_docente` | Asignación de unidad didáctica, docente, ciclo, turno y aula. | $\rightarrow$ `core.unidades_didacticas`, `core.docentes`, `core.aulas` |
| `mod02.clase_horarios` | Plantilla semanal (Día 1..6, hora inicio/fin, horas pedagógicas). | $\rightarrow$ `mod02.clases_docente` |
| `mod02.sesiones_clase` | Instancias de clase de las 18 semanas (`REGULAR`, `RECUPERACION_SEMANA_17`, `CIERRE_ACTAS_SEMANA_18`). | $\rightarrow$ `mod02.clases_docente`, `core.docentes`, `core.aulas` |
| `mod02.asistencias` | Estado por estudiante (`PRESENTE`, `TARDANZA`, `FALTA_INJUSTIFICADA`, `FALTA_JUSTIFICADA`). | $\rightarrow$ `mod02.sesiones_clase`, `core.estudiantes` |
| `mod02.justificaciones` | Expedientes de descanso médico/laboral dentro de las 72h hábiles. | $\rightarrow$ `mod02.asistencias`, `core.estudiantes` |
| `mod02.v_resumen_asistencia_estudiante` | Vista de cálculo: horas acumuladas, porcentaje de faltas y condición DPI ($\ge 30\%$). | JOIN `mod02.asistencias` + `core.estudiantes` |

---

## 💻 6. Contrato de Servicio C# (`IAsistenciaService.cs`)

```csharp
namespace Intranet.Modulo02.Services;

public interface IAsistenciaService
{
    // 1. Detección Inteligente y Dashboard
    Task<DashboardAsistenciaViewModel> GetDashboardAsync(int? personaId, string rol);
    Task<ClaseActivaDocenteDto?> GetClaseActivaHoyAsync(int docenteId);

    // 2. Toma de Asistencia (Flash, Sábana y Smart Copy-Paste)
    Task<IEnumerable<AlumnoAsistenciaItemDto>> GetAlumnosParaSesionAsync(int sesionId, int unidadDidacticaId);
    Task<bool> GuardarAsistenciaSesionAsync(GuardarAsistenciaRequestDto request, int? usuarioId);
    Task<bool> GuardarAsistenciaMasivaMatrizAsync(GuardarMatrizRequestDto request, int? usuarioId);
    Task<SesionClaseDto> IniciarSesionExtraordinariaAsync(int claseId, string motivo);
    Task<bool> CambiarAulaEnVivoAsync(int sesionId, int nuevaAulaId);

    // 3. Portal del Estudiante & Semáforo Anti-DPI
    Task<IEnumerable<ResumenAsistenciaEstudianteDto>> GetResumenEstudianteAsync(int estudianteId, int? periodoId = null);
    Task<IEnumerable<AsistenciaHistorialItemDto>> GetHistorialDetalladoEstudianteAsync(int estudianteId, int unidadDidacticaId);

    // 4. Justificaciones (Ventana 72h)
    Task<IEnumerable<JustificacionDto>> GetJustificacionesAsync(int? estudianteId = null, string? estado = null);
    Task<bool> SolicitarJustificacionAsync(CrearJustificacionDto dto, int estudianteId);
    Task<bool> ResolverJustificacionAsync(ResolverJustificacionDto dto, int docenteId);

    // 5. Cierre Semanal, Auditoría REGISTRA y Gestión de Horarios
    Task<bool> ReprogramarSesionesFuturasAsync(ReprogramarHorarioDto dto);
    Task<IEnumerable<AlertaDpiDto>> GetAlertasDpiAsync(int? carreraId = null, int? periodoId = null);
    Task<byte[]> ExportarSabanaOficialExcelAsync(int claseDocenteId);
    Task<byte[]> GenerarActaRegistraMineduAsync(int claseDocenteId);
}
```
