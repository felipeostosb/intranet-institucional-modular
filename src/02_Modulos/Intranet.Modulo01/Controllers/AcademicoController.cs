using Microsoft.AspNetCore.Mvc;
using Intranet.Modulo01.Services;
using Intranet.Modulo01.Models;

namespace Intranet.Modulo01.Controllers;

/// <summary>
/// Pestaña "Académico" del alumno (Equipo 01): rendimiento por ciclo,
/// record académico por período (formato SIGA) y resumen global.
/// Ruta EXCLUSIVA del alumno — el personal tiene su herramienta en Matriculatura
/// (expediente con historial completo por DNI).
/// </summary>
[Route("Modulo01/[controller]")]
public class AcademicoController : Modulo01BaseController
{
    private readonly AcademicoServicio _servicio;

    public AcademicoController(AcademicoServicio servicio)
    {
        _servicio = servicio;
    }

    /// <summary>Expone el rol activo a las vistas (tabs rol-aware, fix multi-rol).</summary>
    public override void OnActionExecuting(Microsoft.AspNetCore.Mvc.Filters.ActionExecutingContext context)
    {
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        base.OnActionExecuting(context);
    }

    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index()
    {
        // Puerta por rol (misma regla de la portada).
        if (!AccedeAlModulo) return View("SinAcceso");

        // Ruta del alumno: el personal no tiene "mi académico" propio (Matriculatura ya
        // trae el historial completo por DNI). Antes de este guard, cualquier rol
        // autenticado caía aquí y veía el record de un estudiante arbitrario.
        if (!EsAlumno) return NotFound();

        ViewData["Title"] = "Mi Académico";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        var estudianteId = await _servicio.ResolverEstudianteIdAsync(User);
        var modelo = new AcademicoVista
        {
            Resumen = await _servicio.ResumenAcademicoAsync(estudianteId),
            Rendimiento = await _servicio.RendimientoPorCicloAsync(estudianteId),
            Record = await _servicio.RecordPorPeriodoAsync(estudianteId),
            EstudianteNombre = UsuarioActualNombre
        };
        return View("Academico", modelo);
    }
}
