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
    private readonly ITramiteServicio _servicioTramite;
    private readonly IPagoServicio _servicioPago;

    public Modulo09Controller(ITramiteServicio servicioTramite, IPagoServicio servicioPago)
    {
        _servicioTramite = servicioTramite;
        _servicioPago = servicioPago;
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

        var resumenPagos = await _servicioPago.ResumenAsync();
        var rolActivoVM = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        var esAlumnoVM = rolActivoVM.Equals("Alumno", StringComparison.OrdinalIgnoreCase);

        // Alumno: SUS trámites y pagos — no la mesa/bandeja de todo el instituto.
        IEnumerable<ModeloTramiteMesa> ultimosTramites;
        IEnumerable<ModeloPagoBandeja> ultimosPagos;
        if (esAlumnoVM)
        {
            var estudianteId = await ObtenerEstudianteIdAsync();
            var mios = await _servicioTramite.ListarPorEstudianteAsync(estudianteId, null);
            ultimosTramites = mios.Select(t => new ModeloTramiteMesa
            {
                Id = t.Id,
                Codigo = t.Codigo,
                Estado = t.Estado,
                FechaSolicitud = t.FechaSolicitud,
                TipoCodigo = t.TipoCodigo,
                TipoNombre = t.TipoNombre
            });
            var misPagos = await _servicioPago.ListarPorEstudianteAsync(estudianteId);
            ultimosPagos = misPagos.Select(p => new ModeloPagoBandeja
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
            ultimosTramites = await _servicioTramite.ListarMesaAsync(null);
            ultimosPagos = await _servicioPago.ListarBandejaAsync(null);
        }

        // Fix portada por rol ACTIVO: el usuario demo multi-rol (Alumno+Docente+Admin) en Modo
        // Alumno caía en la portada de staff porque !EsAdmin mira la LISTA de roles. Con el
        // ActiveRole (modo elegido) el alumno ve SU portada aunque tenga otros roles dormidos.
        var rolActivo = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        var esAlumnoActivo = rolActivo.Equals("Alumno", StringComparison.OrdinalIgnoreCase);
        var vm = new ModeloPanelModulo09Vista
        {
            EsAlumno = esAlumnoActivo,
            RolActivo = rolActivo,
            TramitesPendientes = await _servicioTramite.ContarPendientesAsync(),
            ResumenPagos = resumenPagos,
            UltimosTramites = ultimosTramites.Take(5),
            UltimosPagos = ultimosPagos.Take(5),
            NombreUsuario = UsuarioActualNombre,
            RolUsuario = UsuarioActualRol
        };

        // Resumen POR ROL ACTIVO (fix anti-confusión Tesorería/Secretaría):
        // cada puesto ve SU panel — Tesorería lo financiero, Secretaría la
        // mesa de partes, el alumno lo suyo. Jefaturas mantienen la vista general.
        var esTesoreriaActiva = rolActivo.Equals("Tesoreria", StringComparison.OrdinalIgnoreCase);
        var esSecretariaActiva = rolActivo.Equals("Secretaria", StringComparison.OrdinalIgnoreCase);
        if (esTesoreriaActiva)
            vm.ResumenTesoreria = await _servicioPago.ResumenTesoreriaAsync();
        if (esSecretariaActiva)
            vm.ResumenSecretaria = await _servicioTramite.ResumenSecretariaAsync();
        if (esAlumnoActivo)
            vm.ResumenAlumno = await _servicioPago.ResumenAlumnoAsync(
                await ObtenerEstudianteIdAsync());
        return View(vm);
    }

    /// <summary>claim PersonaId → core.estudiantes (misma vía que TramitesController).</summary>
    private async Task<int> ObtenerEstudianteIdAsync()
    {
        var fabrica = HttpContext.RequestServices.GetRequiredService<Intranet.Core.Contracts.IModuleDbConnectionFactory>();
        using var conn = fabrica.CreateConnection("09");
        var id = await conn.ExecuteScalarAsync<int?>(
            "SELECT e.id FROM core.estudiantes e WHERE e.persona_id = @PersonaId;",
            new { PersonaId = PersonaActualId ?? 0 });
        return id ?? 0;
    }
}

/// <summary>ViewModel de la portada del módulo.</summary>
public class ModeloPanelModulo09Vista
{
    public bool EsAlumno { get; set; }
    /// <summary>Rol activo (modo del selector) — decide la portada que se muestra.</summary>
    public string RolActivo { get; set; } = "";
    public int TramitesPendientes { get; set; }
    public ModeloResumenPagos ResumenPagos { get; set; } = new();
    public IEnumerable<ModeloTramiteMesa> UltimosTramites { get; set; } = [];
    public IEnumerable<ModeloPagoBandeja> UltimosPagos { get; set; } = [];
    public string NombreUsuario { get; set; } = "";
    public string RolUsuario { get; set; } = "";
    /// <summary>Panel financiero del puesto (solo rol activo Tesorería).</summary>
    public ModeloResumenTesoreria? ResumenTesoreria { get; set; }
    /// <summary>Panel de mesa de partes (solo rol activo Secretaría).</summary>
    public ModeloResumenSecretaria? ResumenSecretaria { get; set; }
    /// <summary>Panel personal (solo rol activo Alumno).</summary>
    public ModeloResumenAlumno? ResumenAlumno { get; set; }
}
