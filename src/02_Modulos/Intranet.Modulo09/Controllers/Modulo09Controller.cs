using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo09.Models;
using Intranet.Modulo09.Services;

namespace Intranet.Modulo09.Controllers;

/// <summary>
/// Portada del Módulo 09 (patrón del Módulo 02): UNA sola entrada en el
/// menú global → dashboard con métricas, secciones y accesos a las
/// sub-vistas del equipo (Trámites TUPA, Pagos/Bandeja de vouchers).
/// </summary>
[Route("Modulo09")]
public class Modulo09Controller : ModuloBaseController
{
    private readonly ITramiteService _tramiteService;
    private readonly IPagoService _pagoService;

    public Modulo09Controller(ITramiteService tramiteService, IPagoService pagoService)
    {
        _tramiteService = tramiteService;
        _pagoService = pagoService;
    }

    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index()
    {
        ViewData["Title"] = "09. Tesorería & Pagos";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        var resumenPagos = await _pagoService.ResumenAsync();
        var ultimosTramites = await _tramiteService.ListarMesaAsync(null);
        var ultimosPagos = await _pagoService.ListarBandejaAsync(null);

        var vm = new Modulo09DashboardViewModel
        {
            EsAlumno = EsAlumno && !EsAdmin,
            TramitesPendientes = await _tramiteService.ContarPendientesAsync(),
            ResumenPagos = resumenPagos,
            UltimosTramites = ultimosTramites.Take(5),
            UltimosPagos = ultimosPagos.Take(5),
            NombreUsuario = UsuarioActualNombre,
            RolUsuario = UsuarioActualRol
        };
        return View(vm);
    }
}

/// <summary>ViewModel de la portada del módulo.</summary>
public class Modulo09DashboardViewModel
{
    public bool EsAlumno { get; set; }
    public int TramitesPendientes { get; set; }
    public PagosResumenDto ResumenPagos { get; set; } = new();
    public IEnumerable<TramiteMesaDto> UltimosTramites { get; set; } = [];
    public IEnumerable<PagoBandejaDto> UltimosPagos { get; set; } = [];
    public string NombreUsuario { get; set; } = "";
    public string RolUsuario { get; set; } = "";
}
