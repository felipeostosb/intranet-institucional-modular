using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Controllers;
using Intranet.Modulo09.Models;
using Intranet.Modulo09.Services;

namespace Intranet.Modulo09.Controllers;

/// <summary>
/// Pagos del Módulo 09 (Tesorería & Pagos) — CU-09.1 y CU-09.2 del informe.
/// Vistas duales según rol (patrón del prototipo WebForms):
///   Alumno    → "Mis pagos" + registrar pago con voucher
///   Tesorería → bandeja de vouchers (Aprobar/Rechazar con motivo)
///               + emisión de recibos directos de caja
/// </summary>
[Route("Modulo09/[controller]")]
public class PagosController : ModuloBaseController
{
    private readonly IPagoService _pagoService;

    public PagosController(IPagoService pagoService)
    {
        _pagoService = pagoService;
    }

    /// <summary>Expone los roles del usuario a las vistas (tabs rol-aware).</summary>
    public override void OnActionExecuting(Microsoft.AspNetCore.Mvc.Filters.ActionExecutingContext context)
    {
        ViewData["RolesUsuario"] = string.Join(",", UsuarioActualRoles);
        base.OnActionExecuting(context);
    }

    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index(string? voucher)
    {
        ViewData["Title"] = "09. Pagos y Recibos";
        ViewData["TeamName"] = "Equipo 09";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        if (EsAlumno && !EsAdmin)
        {
            var estudianteId = await ObtenerEstudianteIdAsync();
            return View("Mis", new MisPagosViewModel
            {
                Pagos = await _pagoService.ListarPorEstudianteAsync(estudianteId),
                Conceptos = await _pagoService.ListarConceptosAsync(),
                TiposPago = await _pagoService.ListarTiposPagoAsync()
            });
        }

        return View("Bandeja", new BandejaPagosViewModel
        {
            Pagos = await _pagoService.ListarBandejaAsync(voucher),
            Resumen = await _pagoService.ResumenAsync(),
            FiltroVoucher = voucher,
            FormRecibo = new RegistrarPagoViewModel
            {
                Conceptos = await _pagoService.ListarConceptosAsync(),
                TiposPago = await _pagoService.ListarTiposPagoAsync(),
                Estudiantes = await ListarEstudiantesAsync()
            }
        });
    }

    // ------------------------------------------------------------------
    // ALUMNO: registrar pago con voucher (queda Pendiente para la bandeja)
    // ------------------------------------------------------------------
    [HttpPost("Registrar")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Registrar(string concepto, string tipoPago, string? monto, string? nota)
    {
        if (EsAlumno && !EsAdmin)
        {
            var estudianteId = await ObtenerEstudianteIdAsync();
            var periodoId = await ObtenerPeriodoActivoIdAsync();

            // el monto lo fija el concepto TUPA (se muestra en el form);
            // si viene vacío se toma del catálogo
            decimal montoValor = 0;
            var conceptos = await _pagoService.ListarConceptosAsync();
            var conceptoDto = conceptos.FirstOrDefault(c => c.Codigo == concepto);
            if (!decimal.TryParse(monto, out montoValor) && conceptoDto != null)
                montoValor = conceptoDto.Monto;

            var (ok, mensaje) = await _pagoService.RegistrarPagoEstudianteAsync(
                estudianteId, periodoId, concepto, tipoPago, montoValor, nota);
            if (ok) MostrarAlertaExito(mensaje);
            else MostrarAlertaError(mensaje);
        }
        return RedirectToAction(nameof(Index));
    }

    // ------------------------------------------------------------------
    // TESORERÍA: emitir recibo directo de caja
    // ------------------------------------------------------------------
    [HttpPost("EmitirRecibo")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EmitirRecibo(int estudianteId, string concepto, string tipoPago, decimal monto)
    {
        if (!EsTesoreria && !EsDirector)
            return Forbid();

        var periodoId = await ObtenerPeriodoActivoIdAsync();
        var (ok, mensaje) = await _pagoService.EmitirReciboDirectoAsync(
            estudianteId, periodoId, concepto, tipoPago, monto, UsuarioActualId ?? 0);
        if (ok) MostrarAlertaExito(mensaje);
        else MostrarAlertaError(mensaje);
        return RedirectToAction(nameof(Index));
    }

    // ------------------------------------------------------------------
    // TESORERÍA: validar voucher desde la bandeja (aprobar / rechazar)
    // ------------------------------------------------------------------
    [HttpPost("Validar/{id}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Validar(int id, bool aprobar, string? motivo)
    {
        if (!EsTesoreria && !EsAdmin)
            return Forbid();

        var (ok, mensaje) = await _pagoService.ValidarVoucherAsync(
            id, aprobar, motivo, UsuarioActualId ?? 0);
        if (ok) MostrarAlertaExito(mensaje);
        else MostrarAlertaError(mensaje);
        return RedirectToAction(nameof(Index));
    }

    // ------------------------------------------------------------------
    // Helpers de contexto
    // ------------------------------------------------------------------
    private async Task<int> ObtenerEstudianteIdAsync()
    {
        var factory = HttpContext.RequestServices.GetRequiredService<Intranet.Core.Contracts.IModuleDbConnectionFactory>();
        using var conn = factory.CreateConnection("09");
        var id = await conn.ExecuteScalarAsync<int?>(
            "SELECT e.id FROM core.estudiantes e WHERE e.persona_id = @PersonaId;",
            new { PersonaId = PersonaActualId ?? 0 });
        return id ?? 0;
    }

    private async Task<int> ObtenerPeriodoActivoIdAsync()
    {
        var factory = HttpContext.RequestServices.GetRequiredService<Intranet.Core.Contracts.IModuleDbConnectionFactory>();
        using var conn = factory.CreateConnection("09");
        return await conn.ExecuteScalarAsync<int>(
            "SELECT id FROM core.periodos_academicos WHERE es_activo ORDER BY id DESC LIMIT 1;");
    }

    private async Task<IEnumerable<EstudianteSelectDto>> ListarEstudiantesAsync()
    {
        var factory = HttpContext.RequestServices.GetRequiredService<Intranet.Core.Contracts.IModuleDbConnectionFactory>();
        using var conn = factory.CreateConnection("09");
        return await conn.QueryAsync<EstudianteSelectDto>("""
            SELECT e.id, e.codigo_estudiante AS CodigoEstudiante,
                   p.nombres || ' ' || p.apellidos AS NombreCompleto
            FROM core.estudiantes e
            JOIN core.personas p ON p.id = e.persona_id
            ORDER BY e.codigo_estudiante;
            """);
    }
}

// ---------------------------------------------------------------------
// ViewModels
// ---------------------------------------------------------------------
public class MisPagosViewModel
{
    public IEnumerable<PagoListaDto> Pagos { get; set; } = [];
    public IEnumerable<ConceptoPagoDto> Conceptos { get; set; } = [];
    public IEnumerable<TipoPagoDto> TiposPago { get; set; } = [];
}

public class BandejaPagosViewModel
{
    public IEnumerable<PagoBandejaDto> Pagos { get; set; } = [];
    public PagosResumenDto Resumen { get; set; } = new();
    public string? FiltroVoucher { get; set; }
    public RegistrarPagoViewModel FormRecibo { get; set; } = new();
}
