using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
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
        // Fix multi-rol: el filtro de tabs usa el ROL ACTIVO (el modo elegido con el selector
        // se guarda en el claim "ActiveRole"), no la lista completa de roles — si no, un
        // multi-rol (p. ej. Director+Alumno) ve pestañas de staff estando en Modo Alumno.
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var resumenPagos = await _pagoService.ResumenAsync();
        var rolActivoVM = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        var esAlumnoVM = rolActivoVM.Equals("Alumno", StringComparison.OrdinalIgnoreCase);

        // Alumno: SUS trámites y pagos — no la mesa/bandeja de todo el instituto.
        IEnumerable<TramiteMesaDto> ultimosTramites;
        IEnumerable<PagoBandejaDto> ultimosPagos;
        if (esAlumnoVM)
        {
            var estudianteId = await ObtenerEstudianteIdAsync();
            var mios = await _tramiteService.ListarPorEstudianteAsync(estudianteId, null);
            ultimosTramites = mios.Select(t => new TramiteMesaDto
            {
                Id = t.Id,
                Codigo = t.Codigo,
                Estado = t.Estado,
                FechaSolicitud = t.FechaSolicitud,
                TipoCodigo = t.TipoCodigo,
                TipoNombre = t.TipoNombre
            });
            var misPagos = await _pagoService.ListarPorEstudianteAsync(estudianteId);
            ultimosPagos = misPagos.Select(p => new PagoBandejaDto
            {
                Id = p.Id,
                Codigo = p.Codigo,
                Monto = p.Monto,
                FechaPago = p.FechaPago,
                VoucherEstado = p.VoucherEstado,
                ConceptoNombre = p.ConceptoNombre,
                TipoPago = p.TipoPago
            });
        }
        else
        {
            ultimosTramites = await _tramiteService.ListarMesaAsync(null);
            ultimosPagos = await _pagoService.ListarBandejaAsync(null);
        }

        // Fix portada por rol ACTIVO: el usuario demo multi-rol (Alumno+Docente+Admin) en Modo
        // Alumno caía en la portada de staff porque !EsAdmin mira la LISTA de roles. Con el
        // ActiveRole (modo elegido) el alumno ve SU portada aunque tenga otros roles dormidos.
        var rolActivo = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        var esAlumnoActivo = rolActivo.Equals("Alumno", StringComparison.OrdinalIgnoreCase);
        var vm = new Modulo09DashboardViewModel
        {
            EsAlumno = esAlumnoActivo,
            RolActivo = rolActivo,
            TramitesPendientes = await _tramiteService.ContarPendientesAsync(),
            ResumenPagos = resumenPagos,
            UltimosTramites = ultimosTramites.Take(5),
            UltimosPagos = ultimosPagos.Take(5),
            NombreUsuario = UsuarioActualNombre,
            RolUsuario = UsuarioActualRol
        };
        return View(vm);
    }

    /// <summary>claim PersonaId → core.estudiantes (misma vía que TramitesController).</summary>
    private async Task<int> ObtenerEstudianteIdAsync()
    {
        var factory = HttpContext.RequestServices.GetRequiredService<Intranet.Core.Contracts.IModuleDbConnectionFactory>();
        using var conn = factory.CreateConnection("09");
        var id = await conn.ExecuteScalarAsync<int?>(
            "SELECT e.id FROM core.estudiantes e WHERE e.persona_id = @PersonaId;",
            new { PersonaId = PersonaActualId ?? 0 });
        return id ?? 0;
    }
}

/// <summary>ViewModel de la portada del módulo.</summary>
public class Modulo09DashboardViewModel
{
    public bool EsAlumno { get; set; }
    /// <summary>Rol activo (modo del selector) — decide la portada que se muestra.</summary>
    public string RolActivo { get; set; } = "";
    public int TramitesPendientes { get; set; }
    public PagosResumenDto ResumenPagos { get; set; } = new();
    public IEnumerable<TramiteMesaDto> UltimosTramites { get; set; } = [];
    public IEnumerable<PagoBandejaDto> UltimosPagos { get; set; } = [];
    public string NombreUsuario { get; set; } = "";
    public string RolUsuario { get; set; } = "";
}
