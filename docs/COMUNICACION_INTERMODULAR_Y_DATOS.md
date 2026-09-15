# 🏛️ Guía de Comunicación Intermodular y Acceso a Datos
## Intranet Institucional Modular (.NET 10 + PostgreSQL 16)

Esta guía establece el estándar arquitectónico oficial para consultar datos y coordinar acciones entre los 9 módulos temáticos del sistema sin generar acoplamiento destructivo.

---

## 🚫 1. La Regla de Acero: Prohibido JOIN SQL Directo entre Módulos

Por diseño de seguridad y soberanía de datos (Zero-Blast-Radius):
* Cada módulo es **dueño exclusivo** de su esquema PostgreSQL (`mod01` al `mod09`).
* Tu usuario de base de datos (`user_equipoXX`) **no tiene permisos** para consultar tablas de otros módulos.
* ⛔ **Nunca intentes hacer:** `SELECT * FROM mod02.asistencias JOIN mod01.matriculas ...` (PostgreSQL denegará el acceso con `permission denied`).

---

## 🛡️ 2. Los 3 Patrones Oficiales de Integración

```
┌─────────────────────────────────────────────────────────────────────────┐
│              PATRONES DE COMUNICACIÓN EN MONOLITO MODULAR               │
├──────────────────────────┬─────────────────────────┬────────────────────┤
│  A. ANCLAJE A "CORE"     │  B. SERVICIOS EN MEMORIA│  C. EVENT BUS      │
│  (Single Source of Truth)│  (In-Process Contracts) │  (Domain Events)   │
│  JOINs permitidos solo   │  Inyección de interfaces│  Notificaciones    │
│  hacia tablas core.*     │  C# (<0.01ms latencia)  │  desacopladas      │
└──────────────────────────┴─────────────────────────┴────────────────────┘
```

---

### 🥇 Patrón A: Anclaje Común en `core.*` (Para Identidades y Catálogos)

El esquema `core` almacena los datos institucionales centrales de **solo lectura**. Cualquier módulo puede realizar `JOIN` directo contra estas tablas:

* `core.personas`: Nombres, apellidos, DNI, teléfono, foto.
* `core.estudiantes`: Carrera, semestre, periodo de ingreso.
* `core.docentes`: Especialidad, grado académico.
* `core.carreras`: Programas de estudio y total de semestres.
* `core.periodos_academicos`: Ciclos lectivos (ej: `2026-I`, `2026-II`).

#### 💡 Ejemplo en tu código SQL (Módulo 04 - Horarios):
```sql
-- Consulta con JOIN seguro hacia el núcleo central
SELECT 
    h.id,
    h.dia_semana,
    h.hora_inicio,
    h.hora_fin,
    a.codigo AS aula,
    p.nombres || ' ' || p.apellidos AS docente_nombre,
    c.nombre AS carrera_nombre
FROM mod04.horarios h
JOIN mod04.aulas a ON a.id = h.aula_id
JOIN core.docentes d ON d.id = h.docente_id
JOIN core.personas p ON p.id = d.persona_id
JOIN core.carreras c ON c.id = h.carrera_id;
```

---

### 🥈 Patrón B: Contratos de Servicio en C# (Llamadas en Memoria <0.01 ms)

Si tu módulo necesita datos calculados o validar un estado gestionado por otro módulo (ejemplo: *¿El alumno tiene matrícula activa antes de registrar su asistencia?*), se utiliza **Inyección de Dependencias en C#**:

#### Paso 1: Definir el Contrato en `01_Core` (`Intranet.Core/Contracts/`)
```csharp
namespace Intranet.Core.Contracts;

public interface IMatriculaService
{
    Task<bool> EstaEstudianteMatriculadoAsync(int estudianteId, int periodoId);
    Task<IReadOnlyList<int>> ObtenerEstudiantesMatriculadosAsync(int carreraId, int semestre);
}
```

#### Paso 2: Implementar la Lógica en el Módulo Propietario (`Intranet.Modulo01`)
```csharp
// src/02_Modulos/Intranet.Modulo01/Services/MatriculaService.cs
public class MatriculaService : IMatriculaService
{
    private readonly IModuleDbConnectionFactory _db;

    public MatriculaService(IModuleDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<bool> EstaEstudianteMatriculadoAsync(int estudianteId, int periodoId)
    {
        using var conn = _db.CreateConnection("01");
        return await conn.ExecuteScalarAsync<bool>(
            "SELECT COUNT(1) > 0 FROM mod01.matriculas WHERE estudiante_id = @estudianteId AND periodo_id = @periodoId AND estado = 'ACTIVO'",
            new { estudianteId, periodoId });
    }
}
```

#### Paso 3: Consumir la Interfaz en tu Módulo (`Intranet.Modulo02`)
```csharp
// src/02_Modulos/Intranet.Modulo02/Controllers/AsistenciaController.cs
public class AsistenciaController : ModuloBaseController
{
    private readonly IMatriculaService _matriculaService;

    public AsistenciaController(IMatriculaService matriculaService)
    {
        _matriculaService = matriculaService;
    }

    [HttpPost]
    public async Task<IActionResult> Registrar(int estudianteId, string estado)
    {
        var matriculado = await _matriculaService.EstaEstudianteMatriculadoAsync(estudianteId, PeriodoActualId);
        if (!matriculado)
        {
            MostrarAlertaError("El alumno no se encuentra matriculado en este periodo.");
            return RedirectToAction(nameof(Index));
        }

        // Registrar asistencia en mod02.asistencias...
        MostrarAlertaExito("Asistencia registrada correctamente.");
        return RedirectToAction(nameof(Index));
    }
}
```

---

### 🥉 Patrón C: Eventos de Dominio Asíncronos (`InMemoryEventBus`)

Cuando una acción en un módulo debe notificar a otros sin esperar respuesta sincrónica:

#### 1. Definir el Evento:
```csharp
public record EstudianteMatriculadoEvent(int EstudianteId, int CarreraId, int PeriodoId) : IEvent;
```

#### 2. Publicar el Evento (Módulo 01):
```csharp
await _eventPublisher.PublishAsync(new EstudianteMatriculadoEvent(estudianteId, carreraId, periodoId));
```

#### 3. Escuchar el Evento (Módulo 09 - Tesorería):
```csharp
public class GenerarObligacionPagoHandler : IEventHandler<EstudianteMatriculadoEvent>
{
    public async Task HandleAsync(EstudianteMatriculadoEvent @event, CancellationToken ct = default)
    {
        // Generar cuota de matrícula en mod09.obligaciones_pago
    }
}
```

---

## 🤖 3. Asistencia con Inteligencia Artificial (Cursor / Copilot / ChatGPT)

Para que tu asistente de IA respete estas reglas:
1. Las reglas de diseño ya están configuradas en el archivo `.cursorrules` y `.github/copilot-instructions.md`.
2. Si utilizas Cursor con el servidor MCP de PostgreSQL, recuerda que la IA solo podrá consultar tu esquema `modXX` y `core`.
3. Pídele siempre a la IA: *"Genera la consulta utilizando únicamente mi esquema modXX y cruzando identidades con core.personas/core.estudiantes"*.
