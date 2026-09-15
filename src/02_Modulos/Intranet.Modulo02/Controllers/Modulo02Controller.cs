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

    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "Módulo 02 - Control de Asistencia Institucional";
        ViewData["TeamName"] = "Equipo 02";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        var vm = await _asistenciaService.GetDashboardAsync(PersonaActualId, UsuarioActualRol);
        return View(vm);
    }

    /// <summary>
    /// Vista de la Clase con selector de las 18 Semanas (1 a 17 Regulares + 18 Recuperación)
    /// </summary>
    [HttpGet("Clase/{claseId:int}")]
    public async Task<IActionResult> Clase(int claseId)
    {
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
    /// Matriz General / Sábana Excel Institucional de Asistencias (18 Semanas)
    /// </summary>
    [HttpGet("Matriz/{claseId:int}")]
    public async Task<IActionResult> Matriz(int claseId)
    {
        var matriz = await _asistenciaService.GetMatrizAsistenciaClaseAsync(claseId);
        if (matriz == null)
        {
            MostrarAlertaError("La clase seleccionada no existe o no tiene alumnos matriculados.");
            return RedirectToAction(nameof(Index));
        }

        ViewData["Title"] = $"Matriz de Asistencia - {matriz.UnidadDidacticaNombre} ({matriz.Turno})";
        return View(matriz);
    }

    /// <summary>
    /// Toma de Asistencia Focalizada en el Aula (Docente)
    /// </summary>
    [HttpGet("TomarAsistencia/{sesionId:int}")]
    public async Task<IActionResult> TomarAsistencia(int sesionId)
    {
        var sesion = await _asistenciaService.GetSesionPorIdAsync(sesionId);
        if (sesion == null)
        {
            MostrarAlertaError("La sesión de clase solicitada no existe o no se encuentra disponible.");
            return RedirectToAction(nameof(Index));
        }

        var alumnos = await _asistenciaService.GetAlumnosParaSesionAsync(sesionId, sesion.UnidadDidacticaId);
        ViewBag.Sesion = sesion;
        ViewData["Title"] = $"Toma de Asistencia - {sesion.UnidadDidacticaNombre} (Semana {sesion.NumeroSemana})";

        return View(alumnos);
    }

    /// <summary>
    /// Guardado masivo y oficialización de asistencia
    /// </summary>
    [HttpPost("GuardarAsistencia")]
    public async Task<IActionResult> GuardarAsistencia([FromBody] GuardarAsistenciaRequestDto request)
    {
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
                        ? "Sesión de clase cerrada y asistencia oficializada con éxito." 
                        : "Asistencia guardada correctamente como borrador de trabajo." 
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
    /// Bandeja de Justificaciones (72h Hábiles)
    /// </summary>
    [HttpGet("Justificaciones")]
    public async Task<IActionResult> Justificaciones([FromQuery] string? estado)
    {
        int? estudianteFiltro = null;
        if (EsAlumno && PersonaActualId.HasValue)
        {
            estudianteFiltro = await _asistenciaService.GetEstudianteIdPorPersonaAsync(PersonaActualId.Value);
        }

        var lista = await _asistenciaService.GetJustificacionesAsync(estudianteFiltro, estado);
        ViewData["Title"] = "Bandeja de Justificaciones de Inasistencia";
        ViewBag.EstadoActual = estado ?? "TODAS";

        return View(lista);
    }

    [HttpPost("SolicitarJustificacion")]
    public async Task<IActionResult> SolicitarJustificacion([FromForm] CrearJustificacionDto dto)
    {
        if (!ModelState.IsValid)
        {
            MostrarAlertaError("Por favor complete todos los campos obligatorios para la justificación.");
            return RedirectToAction(nameof(Justificaciones));
        }

        int? estudianteId = null;
        if (PersonaActualId.HasValue)
        {
            estudianteId = await _asistenciaService.GetEstudianteIdPorPersonaAsync(PersonaActualId.Value);
        }
        estudianteId ??= 1;

        var ok = await _asistenciaService.SolicitarJustificacionAsync(dto, estudianteId.Value);
        if (ok)
        {
            MostrarAlertaExito("Solicitud de justificación ingresada con éxito. Pasará a evaluación docente.");
        }
        else
        {
            MostrarAlertaError("No se pudo registrar la justificación.");
        }

        return RedirectToAction(nameof(Justificaciones));
    }

    [HttpPost("ResolverJustificacion")]
    public async Task<IActionResult> ResolverJustificacion([FromForm] ResolverJustificacionDto dto)
    {
        int? docenteId = null;
        if (PersonaActualId.HasValue)
        {
            docenteId = await _asistenciaService.GetDocenteIdPorPersonaAsync(PersonaActualId.Value);
        }
        docenteId ??= 1;

        var ok = await _asistenciaService.ResolverJustificacionAsync(dto, docenteId.Value);
        if (ok)
        {
            MostrarAlertaExito(dto.Aprobada 
                ? "Justificación APROBADA. La falta fue reclasificada y el porcentaje DPI actualizado." 
                : "Justificación RECHAZADA.");
        }
        else
        {
            MostrarAlertaError("No se pudo resolver la justificación.");
        }

        return RedirectToAction(nameof(Justificaciones));
    }

    /// <summary>
    /// Reportes de Deserción y Riesgo DPI Ministerial
    /// </summary>
    [HttpGet("ReportesDpi")]
    public async Task<IActionResult> ReportesDpi([FromQuery] int? carreraId)
    {
        var alertas = await _asistenciaService.GetAlertasDpiAsync(carreraId);
        ViewData["Title"] = "Reporte de Riesgo DPI y Deserción Estudiantil";
        ViewBag.CarreraId = carreraId;

        return View(alertas);
    }
}
