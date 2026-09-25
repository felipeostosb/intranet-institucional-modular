using Microsoft.AspNetCore.Mvc;
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

    public Modulo01Controller(IMatriculaService matriculaService)
    {
        _matriculaService = matriculaService;
    }

    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "01. Matrícula Académica";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;
        ViewData["RolesUsuario"] = string.Join(",", UsuarioActualRoles);

        var esAlumno = EsAlumno && !EsAdmin;

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
}
