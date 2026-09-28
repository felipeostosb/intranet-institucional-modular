using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo02.Models;
using Intranet.Modulo02.Services;

namespace Intranet.Modulo02.Controllers;

[Route("Modulo02")]
public class Modulo02Controller : ModuloBaseController
{
    private readonly IAsistenciaService _asistenciaService;

    public Modulo02Controller(IAsistenciaService asistenciaService)
    {
        _asistenciaService = asistenciaService;
    }

    private bool EsModoAlumno
    {
        get
        {
            if (UsuarioActualRol.Equals("Alumno", StringComparison.OrdinalIgnoreCase) ||
                UsuarioActualRol.Equals("Estudiante", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }

            return EsAlumno && !EsDocente;
        }
    }

    /// <summary>
    /// Dashboard del Módulo 02 con enrutamiento inteligente según el Rol:
    /// - Estudiante: Redirige de inmediato a su panel personal Anti-DPI (MiAsistencia) en 1 clic.
    /// - Docente / Coordinador: Carga el panel operativo con detección de clase activa y sábanas.
    /// </summary>
    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "Módulo 02 - Control de Asistencia Institucional & DPI";
        ViewData["TeamName"] = "Equipo 02";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        // 🛡️ REGLA ESTRICTA DE ACCESO: Si el usuario es Estudiante, va directo a su portal
        if (EsModoAlumno)
        {
            return RedirectToAction(nameof(MiAsistencia));
        }

        var vm = await _asistenciaService.GetDashboardAsync(PersonaActualId, UsuarioActualRol);
        vm.NombreUsuario = UsuarioActualNombre;
        return View(vm);
    }

    /// <summary>
    /// Acceso rápido en 1 Clic a la toma de asistencia / clase activa de hoy (Exclusivo Docente)
    /// </summary>
    [HttpGet("TomarAsistencia")]
    [HttpGet("IniciarClaseActiva")]
    public async Task<IActionResult> IniciarClaseActiva()
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: La toma de asistencia es exclusiva para docentes.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        int docenteId = 1;
        if (PersonaActualId.HasValue)
        {
            var docId = await _asistenciaService.GetDocenteIdPorPersonaAsync(PersonaActualId.Value);
            if (docId.HasValue) docenteId = docId.Value;
        }

        var claseActiva = await _asistenciaService.GetClaseActivaHoyAsync(docenteId);
        if (claseActiva != null && claseActiva.SesionId > 0)
        {
            return RedirectToAction(nameof(TomarAsistencia), new { sesionId = claseActiva.SesionId });
        }

        // Si no hay una sesión activa detectada para hoy, buscar la primera sesión disponible de sus clases
        var clases = (await _asistenciaService.GetClasesDocenteAsync(docenteId)).ToList();
        if (clases.Any())
        {
            var semanas = (await _asistenciaService.GetSemanasDeClaseAsync(clases.First().ClaseId)).ToList();
            var sesion = semanas.SelectMany(s => s.Sesiones).FirstOrDefault(s => s.Estado == "ABIERTA" || s.Estado == "PROGRAMADA")
                         ?? semanas.SelectMany(s => s.Sesiones).FirstOrDefault();
            if (sesion != null)
            {
                return RedirectToAction(nameof(TomarAsistencia), new { sesionId = sesion.Id });
            }
        }

        MostrarAlertaInfo("No se encontró ninguna sesión programada para tus asignaturas.");
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Acceso directo a la gestión de sesiones de la primera clase del docente
    /// </summary>
    [HttpGet("Clase")]
    public async Task<IActionResult> ClaseDirecto()
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: La gestión de sesiones es exclusiva para docentes.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        int docenteId = 1;
        if (PersonaActualId.HasValue)
        {
            var docId = await _asistenciaService.GetDocenteIdPorPersonaAsync(PersonaActualId.Value);
            if (docId.HasValue) docenteId = docId.Value;
        }

        var clases = (await _asistenciaService.GetClasesDocenteAsync(docenteId)).ToList();
        if (clases.Any())
        {
            return RedirectToAction(nameof(Clase), new { claseId = clases.First().ClaseId });
        }

        MostrarAlertaInfo("No tienes asignaturas activas asignadas actualmente.");
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Vista de la Clase con selector de las 18 Semanas (Exclusivo Docente / Coordinador)
    /// </summary>
    [HttpGet("Clase/{claseId:int}")]
    public async Task<IActionResult> Clase(int claseId)
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: La gestión de sesiones es exclusiva para docentes.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        var semanas = (await _asistenciaService.GetSemanasDeClaseAsync(claseId)).ToList();
        var sesionEjemplo = semanas.SelectMany(s => s.Sesiones).FirstOrDefault();
        
        ViewBag.ClaseId = claseId;
        ViewBag.SesionEjemplo = sesionEjemplo;
        ViewData["Title"] = sesionEjemplo != null 
            ? $"Semanas de Clase - {sesionEjemplo.UnidadDidacticaNombre}" 
            : "Gestión de Semanas de Clase";

        return View(semanas);
    }

    /// <summary>
    /// Acceso directo a la Matriz / Sábana de la primera clase del docente
    /// </summary>
    [HttpGet("Matriz")]
    public async Task<IActionResult> MatrizDirecto()
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: La sábana consolidada es de acceso reservado para docentes y coordinadores.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        int docenteId = 1;
        if (PersonaActualId.HasValue)
        {
            var docId = await _asistenciaService.GetDocenteIdPorPersonaAsync(PersonaActualId.Value);
            if (docId.HasValue) docenteId = docId.Value;
        }

        var clases = (await _asistenciaService.GetClasesDocenteAsync(docenteId)).ToList();
        if (clases.Any())
        {
            return RedirectToAction(nameof(Matriz), new { claseId = clases.First().ClaseId });
        }

        MostrarAlertaInfo("No tienes asignaturas activas asignadas actualmente.");
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Matriz General / Sábana Live Grid de Asistencias (18 Semanas - Exclusivo Docente)
    /// </summary>
    [HttpGet("Matriz/{claseId:int}")]
    public async Task<IActionResult> Matriz(int claseId)
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: La sábana consolidada es de acceso reservado para docentes y coordinadores.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        var matriz = await _asistenciaService.GetMatrizAsistenciaClaseAsync(claseId);
        if (matriz == null)
        {
            MostrarAlertaError("La clase seleccionada no existe o no tiene alumnos matriculados.");
            return RedirectToAction(nameof(Index));
        }

        ViewData["Title"] = $"Sábana Live Grid - {matriz.UnidadDidacticaNombre} ({matriz.Turno})";
        return View(matriz);
    }

    /// <summary>
    /// Toma de Asistencia Flash Focalizada en el Aula (Exclusivo Docente - 1 Clic)
    /// </summary>
    [HttpGet("TomarAsistencia/{sesionId:int}")]
    public async Task<IActionResult> TomarAsistencia(int sesionId)
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: Un estudiante no tiene permisos para tomar asistencia en el aula.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        var sesion = await _asistenciaService.GetSesionPorIdAsync(sesionId);
        if (sesion == null)
        {
            MostrarAlertaError("La sesión de clase solicitada no existe o no se encuentra disponible.");
            return RedirectToAction(nameof(Index));
        }

        var alumnos = await _asistenciaService.GetAlumnosParaSesionAsync(sesionId, sesion.UnidadDidacticaId);
        ViewBag.Sesion = sesion;
        ViewData["Title"] = $"Toma Flash de Asistencia - {sesion.UnidadDidacticaNombre} (Semana {sesion.NumeroSemana})";

        return View(alumnos);
    }

    /// <summary>
    /// Guardado focalizado de sesión (Exclusivo Docente)
    /// </summary>
    [HttpPost("GuardarAsistencia")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> GuardarAsistencia([FromBody] GuardarAsistenciaRequestDto request)
    {
        if (EsModoAlumno)
        {
            return Forbid();
        }

        if (request == null || request.SesionClaseId <= 0)
        {
            return BadRequest(new { success = false, message = "Datos de sesión inválidos." });
        }

        try
        {
            var ok = await _asistenciaService.GuardarAsistenciaSesionAsync(request, UsuarioActualId);
            if (ok)
            {
                return Ok(new { 
                    success = true, 
                    message = request.CerrarSesion 
                        ? "🔒 Sesión de clase cerrada y asistencia oficializada con éxito." 
                        : "💾 Asistencia guardada correctamente como borrador de trabajo." 
                });
            }

            return StatusCode(500, new { success = false, message = "No se pudo registrar la asistencia." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// Guardado masivo de la Matriz completa (Live Grid y Smart Copy-Paste - Exclusivo Docente)
    /// </summary>
    [HttpPost("GuardarMatriz")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> GuardarMatriz([FromBody] GuardarMatrizRequestDto request)
    {
        if (EsModoAlumno)
        {
            return Forbid();
        }

        if (request == null || request.ClaseId <= 0)
        {
            return BadRequest(new { success = false, message = "Datos de matriz inválidos." });
        }

        try
        {
            var ok = await _asistenciaService.GuardarMatrizAsistenciaAsync(request, UsuarioActualId);
            if (ok)
            {
                return Ok(new { 
                    success = true, 
                    message = $"✅ Sábana de asistencia sincronizada con éxito ({request.Celdas.Count} registros actualizados)." 
                });
            }

            return StatusCode(500, new { success = false, message = "No se pudo sincronizar la matriz." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    /// <summary>
    /// Reprogramación elástica de horarios futuros (Exclusivo Coordinación / Docente)
    /// </summary>
    [HttpPost("ReprogramarHorario")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> ReprogramarHorario([FromForm] ReprogramarHorarioDto dto)
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: Solo docentes o coordinadores pueden reprogramar horarios.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        if (dto.ClaseDocenteId <= 0 || dto.DesdeSemana < 1)
        {
            MostrarAlertaError("Parámetros de reprogramación inválidos.");
            return RedirectToAction(nameof(Index));
        }

        var ok = await _asistenciaService.ReprogramarSesionesFuturasAsync(dto);
        if (ok)
        {
            MostrarAlertaExito($"Sesiones futuras a partir de la Semana {dto.DesdeSemana} reprogramadas con éxito sin alterar el historial.");
        }
        else
        {
            MostrarAlertaError("No se pudo completar la reprogramación de horarios.");
        }

        return RedirectToAction(nameof(Clase), new { claseId = dto.ClaseDocenteId });
    }

    /// <summary>
    /// Exportación de Sábana en Formato Excel (.csv/.xlsx - Exclusivo Docente / Coordinación)
    /// </summary>
    [HttpGet("ExportarExcel")]
    public async Task<IActionResult> ExportarExcelDirecto()
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        int docenteId = 1;
        if (PersonaActualId.HasValue)
        {
            var docId = await _asistenciaService.GetDocenteIdPorPersonaAsync(PersonaActualId.Value);
            if (docId.HasValue) docenteId = docId.Value;
        }

        var clases = (await _asistenciaService.GetClasesDocenteAsync(docenteId)).ToList();
        if (clases.Any())
        {
            return await ExportarExcel(clases.First().ClaseId);
        }

        MostrarAlertaInfo("No tienes asignaturas activas para exportar.");
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Exportación de Sábana en Formato Excel (.csv/.xlsx - Exclusivo Docente / Coordinación)
    /// </summary>
    [HttpGet("ExportarExcel/{claseId:int}")]
    public async Task<IActionResult> ExportarExcel(int claseId)
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        var bytes = await _asistenciaService.ExportarSabanaExcelAsync(claseId);
        return File(bytes, "text/csv", $"Sabana_Asistencia_Clase_{claseId}_{DateTime.Now:yyyyMMdd}.csv");
    }

    /// <summary>
    /// Exportación Oficial para REGISTRA MINEDU (Exclusivo Docente / Coordinación)
    /// </summary>
    [HttpGet("ExportarRegistra")]
    public async Task<IActionResult> ExportarRegistraDirecto()
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        int docenteId = 1;
        if (PersonaActualId.HasValue)
        {
            var docId = await _asistenciaService.GetDocenteIdPorPersonaAsync(PersonaActualId.Value);
            if (docId.HasValue) docenteId = docId.Value;
        }

        var clases = (await _asistenciaService.GetClasesDocenteAsync(docenteId)).ToList();
        if (clases.Any())
        {
            return await ExportarRegistra(clases.First().ClaseId);
        }

        MostrarAlertaInfo("No tienes asignaturas activas para exportar.");
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Exportación Oficial para REGISTRA MINEDU (Exclusivo Docente / Coordinación)
    /// </summary>
    [HttpGet("ExportarRegistra/{claseId:int}")]
    public async Task<IActionResult> ExportarRegistra(int claseId)
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        var bytes = await _asistenciaService.GenerarActaRegistraAsync(claseId);
        return File(bytes, "text/plain", $"Acta_Registra_MINEDU_Clase_{claseId}_{DateTime.Now:yyyyMMdd}.txt");
    }

    /// <summary>
    /// Portal del Estudiante (Semáforo de Faltas y Horas Restantes a DPI)
    /// </summary>
    [HttpGet("MiAsistencia")]
    public async Task<IActionResult> MiAsistencia()
    {
        int? estudianteId = null;
        if (PersonaActualId.HasValue)
        {
            estudianteId = await _asistenciaService.GetEstudianteIdPorPersonaAsync(PersonaActualId.Value);
        }

        estudianteId ??= 1;

        var cursos = await _asistenciaService.GetResumenEstudianteAsync(estudianteId.Value);
        ViewData["Title"] = "Mi Asistencia & Semáforo de Riesgo DPI";
        ViewBag.EstudianteId = estudianteId.Value;

        return View(cursos);
    }

    /// <summary>
    /// Historial sesión por sesión del estudiante
    /// </summary>
    [HttpGet("DetalleCurso/{unidadDidacticaId:int}")]
    public async Task<IActionResult> DetalleCurso(int unidadDidacticaId, [FromQuery] int? estudianteId)
    {
        if (!estudianteId.HasValue && PersonaActualId.HasValue)
        {
            estudianteId = await _asistenciaService.GetEstudianteIdPorPersonaAsync(PersonaActualId.Value);
        }

        estudianteId ??= 1;

        var historial = await _asistenciaService.GetHistorialDetalladoEstudianteAsync(estudianteId.Value, unidadDidacticaId);
        ViewData["Title"] = "Historial Detallado de Asistencias";
        ViewBag.UnidadDidacticaId = unidadDidacticaId;
        ViewBag.EstudianteId = estudianteId.Value;

        return View(historial);
    }

    /// <summary>
    /// Bandeja de Justificaciones (72h hábiles)
    /// </summary>
    [HttpGet("Justificaciones")]
    public async Task<IActionResult> Justificaciones([FromQuery] string? estado)
    {
        int? estudianteFiltro = null;
        if (EsModoAlumno && PersonaActualId.HasValue)
        {
            estudianteFiltro = await _asistenciaService.GetEstudianteIdPorPersonaAsync(PersonaActualId.Value);
        }

        var list = await _asistenciaService.GetJustificacionesAsync(estudianteFiltro, estado);
        ViewData["Title"] = "Bandeja de Justificaciones de Inasistencia (72h)";
        ViewBag.EstadoActual = estado ?? "TODAS";
        ViewBag.EsSoloAlumno = (EsModoAlumno);

        return View(list);
    }

    /// <summary>
    /// Solicitud de justificación enviada por el estudiante dentro de las 72 horas
    /// </summary>
    [HttpPost("SolicitarJustificacion")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> SolicitarJustificacion([FromForm] CrearJustificacionDto dto)
    {
        int estudianteId = 1;
        if (PersonaActualId.HasValue)
        {
            var est = await _asistenciaService.GetEstudianteIdPorPersonaAsync(PersonaActualId.Value);
            if (est.HasValue) estudianteId = est.Value;
        }

        var ok = await _asistenciaService.SolicitarJustificacionAsync(dto, estudianteId);
        if (ok)
        {
            MostrarAlertaExito("Justificación ingresada con éxito. El docente evaluará el sustento dentro de las 72h.");
        }
        else
        {
            MostrarAlertaError("No se pudo registrar la solicitud de justificación.");
        }

        return RedirectToAction(nameof(Justificaciones));
    }

    /// <summary>
    /// Evaluación y resolución de justificación (Exclusivo Docente)
    /// </summary>
    [HttpPost("ResolverJustificacion")]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> ResolverJustificacion([FromForm] ResolverJustificacionDto dto)
    {
        if (EsModoAlumno)
        {
            return Forbid();
        }

        int docenteId = 1;
        if (PersonaActualId.HasValue)
        {
            var doc = await _asistenciaService.GetDocenteIdPorPersonaAsync(PersonaActualId.Value);
            if (doc.HasValue) docenteId = doc.Value;
        }

        var ok = await _asistenciaService.ResolverJustificacionAsync(dto, docenteId);
        if (ok)
        {
            MostrarAlertaExito(dto.Aprobada 
                ? "✅ Justificación APROBADA: Inasistencia reclasificada a Falta Justificada." 
                : "❌ Justificación RECHAZADA: Se mantiene la inasistencia injustificada.");
        }
        else
        {
            MostrarAlertaError("No se pudo actualizar el estado de la justificación.");
        }

        return RedirectToAction(nameof(Justificaciones));
    }

    /// <summary>
    /// Reportes de Deserción y Casos Críticos DPI (Exclusivo Coordinación y Dirección)
    /// </summary>
    [HttpGet("ReportesDpi")]
    public async Task<IActionResult> ReportesDpi()
    {
        if (EsModoAlumno)
        {
            MostrarAlertaError("Acceso denegado: El radar de deserción y reportes DPI es exclusivo para la Coordinación y Dirección Académica.");
            return RedirectToAction(nameof(MiAsistencia));
        }

        var alertas = await _asistenciaService.GetAlertasDpiAsync();
        ViewData["Title"] = "Radar Preventivo de Deserción & Casos DPI (30%)";
        return View(alertas);
    }
}
