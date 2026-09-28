using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Controllers;
using Intranet.Modulo01.Models;
using Intranet.Modulo01.Services;

namespace Intranet.Modulo01.Controllers;

/// <summary>
/// Portada del Módulo 01 (patrón del Módulo 02): UNA sola entrada en el
/// menú global → dashboard con métricas, secciones y accesos a las
/// sub-vistas del equipo (Mi Matrícula, Panel de trabajo, Vacantes).
/// </summary>
[Route("Modulo01")]
public class Modulo01Controller : ModuloBaseController
{
    private readonly IMatriculaService _matriculaService;
    private readonly IMatriculaturaService _matriculaturaService;

    public Modulo01Controller(IMatriculaService matriculaService,
        IMatriculaturaService matriculaturaService)
    {
        _matriculaService = matriculaService;
        _matriculaturaService = matriculaturaService;
    }

    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "01. Matrícula Académica";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;
        // Fix multi-rol: el filtro de tabs usa el ROL ACTIVO (el modo elegido con el selector
        // se guarda en el claim "ActiveRole"), no la lista completa de roles — si no, un
        // multi-rol (p. ej. Director+Alumno) ve pestañas de staff estando en Modo Alumno.
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var esAlumno = EsAlumno; // ActiveRole-aware: demo 87654321 multi-rol en Modo Alumno

        var vm = new Modulo01DashboardViewModel
        {
            EsAlumno = esAlumno,
            Resumen = await _matriculaService.ObtenerResumenAsync(),
            Ultimas = (await _matriculaService.ListarPorPeriodoAsync(null)).Take(5),
            VacantesCriticas = (await _matriculaService.ListarVacantesAsync())
                .OrderBy(v => v.Disponibles).Take(4),
            NombreUsuario = UsuarioActualNombre,
            RolUsuario = UsuarioActualRol
        };
        // Mini-dashboard personal del alumno: historial, promedio y estado de SU flujo.
        if (esAlumno)
        {
            var factory = HttpContext.RequestServices
                .GetRequiredService<Intranet.Core.Contracts.IModuleDbConnectionFactory>();
            using var conn = factory.CreateConnection("01");
            var estudianteId = await conn.ExecuteScalarAsync<int?>(
                "SELECT e.id FROM core.estudiantes e WHERE e.persona_id = @PersonaId;",
                new { PersonaId = PersonaActualId ?? 0 }) ?? 0;
            vm.Panel = await _matriculaturaService.PanelAlumnoAsync(estudianteId);
        }
        return View(vm);
    }
}

/// <summary>ViewModel de la portada del módulo.</summary>
public class Modulo01DashboardViewModel
{
    public bool EsAlumno { get; set; }
    public ResumenMatriculaDto Resumen { get; set; } = new();
    public IEnumerable<MatriculaListaDto> Ultimas { get; set; } = [];
    public IEnumerable<VacanteDto> VacantesCriticas { get; set; } = [];
    public string NombreUsuario { get; set; } = "";
    public string RolUsuario { get; set; } = "";
    /// <summary>Mini-dashboard personal (solo rol activo Alumno).</summary>
    public PanelAlumnoDto? Panel { get; set; }
}
