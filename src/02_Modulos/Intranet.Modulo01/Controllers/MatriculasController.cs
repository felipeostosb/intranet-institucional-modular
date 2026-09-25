using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Controllers;
using Intranet.Modulo01.Models;
using Intranet.Modulo01.Services;

namespace Intranet.Modulo01.Controllers;

/// <summary>
/// Matrícula Académica — proceso "Cero Filas" del Equipo 01.
/// Vistas duales según rol (patrón del prototipo WebForms):
///   Alumno → "Mi matrícula" (avance del proceso)
///   Secretaría/Admin → puesto de trabajo con las 4 zonas
/// </summary>
[Route("Modulo01/[controller]")]
public class MatriculasController : ModuloBaseController
{
    private readonly IMatriculaService _matriculaService;

    public MatriculasController(IMatriculaService matriculaService)
    {
        _matriculaService = matriculaService;
    }

    /// <summary>Expone los roles del usuario a las vistas (tabs rol-aware).</summary>
    public override void OnActionExecuting(Microsoft.AspNetCore.Mvc.Filters.ActionExecutingContext context)
    {
        ViewData["RolesUsuario"] = string.Join(",", UsuarioActualRoles);
        base.OnActionExecuting(context);
    }

    [HttpGet("")]
    [HttpGet("Index")]
    public async Task<IActionResult> Index(string? estado)
    {
        ViewData["Title"] = "01. Matrícula Académica";
        ViewData["TeamName"] = "Equipo 01";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        if (EsAlumno && !EsAdmin)
        {
            var activa = await _matriculaService.ObtenerMatriculaActivaAsync(await ObtenerEstudianteIdAsync());
            return View("MiMatricula", activa);
        }

        // Vista personal (Secretaría / Admin / Tesorería)
        var model = new MatriculasPanelViewModel
        {
            Resumen = await _matriculaService.ObtenerResumenAsync(),
            ListasParaRegistrar = await _matriculaService.ListarListasParaRegistrarAsync(),
            EnEspera = await _matriculaService.ListarEnEsperaAsync(),
            PorLiberar = await _matriculaService.ListarVacantesPorLiberarAsync(),
            Todas = await _matriculaService.ListarPorPeriodoAsync(estado),
            FiltroEstado = estado
        };
        return View("Panel", model);
    }

    /// <summary>Ruta explícita de "Mi Matrícula" (tab del alumno).</summary>
    [HttpGet("MiMatricula")]
    public async Task<IActionResult> MiMatricula()
    {
        ViewData["Title"] = "Mi Matrícula";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        var activa = await _matriculaService.ObtenerMatriculaActivaAsync(await ObtenerEstudianteIdAsync());
        return View("MiMatricula", activa);
    }

    // ------------------------------------------------------------------
    // Validaciones (Bandejas)
    // ------------------------------------------------------------------
    [HttpPost("ValidarVoucher/{id}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ValidarVoucher(int id, bool aprobar = true)
    {
        if (!EsTesoreria && !EsDirector)
            return Forbid();

        var ok = await _matriculaService.ValidarVoucherAsync(id, aprobar);
        if (ok) MostrarAlertaExito(aprobar
            ? "Voucher validado. Si la foto ya está validada, la matrícula pasa a conformidad."
            : "Voucher rechazado: queda pendiente de corrección del estudiante.");
        else MostrarAlertaError("No se pudo actualizar el voucher (¿matrícula ya cerrada?).");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost("ValidarFoto/{id}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ValidarFoto(int id, bool aprobar = true)
    {
        if (!EsSecretaria && !EsDirector)
            return Forbid();

        var ok = await _matriculaService.ValidarFotoAsync(id, aprobar);
        if (ok) MostrarAlertaExito(aprobar
            ? "Foto validada. Si el voucher ya está validado, la matrícula pasa a conformidad."
            : "Foto rechazada: queda pendiente de que el estudiante la corrija.");
        else MostrarAlertaError("No se pudo actualizar la foto (¿matrícula ya cerrada?).");
        return RedirectToAction(nameof(Index));
    }

    // ------------------------------------------------------------------
    // Conformidad: registrar matrícula (consume vacante, atómico)
    // ------------------------------------------------------------------
    [HttpPost("Registrar/{id}")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Registrar(int id)
    {
        if (!EsSecretaria && !EsAdmin)
            return Forbid();

        var (ok, mensaje) = await _matriculaService.RegistrarMatriculaAsync(id, UsuarioActualId ?? 0);
        if (ok) MostrarAlertaExito(mensaje);
        else MostrarAlertaError(mensaje);
        return RedirectToAction(nameof(Index));
    }

    // ------------------------------------------------------------------
    // Tablero de vacantes
    // ------------------------------------------------------------------
    [HttpGet("Vacantes")]
    public async Task<IActionResult> Vacantes()
    {
        ViewData["Title"] = "01. Vacantes por Carrera";
        var vacantes = await _matriculaService.ListarVacantesAsync();
        return View(vacantes);
    }

    // ------------------------------------------------------------------
    // Helpers de contexto
    // ------------------------------------------------------------------
    private async Task<int> ObtenerEstudianteIdAsync()
    {
        // claim PersonaId → core.estudiantes (UsuarioActualId es id de USUARIO, no de estudiante)
        var factory = HttpContext.RequestServices.GetRequiredService<Intranet.Core.Contracts.IModuleDbConnectionFactory>();
        using var conn = factory.CreateConnection("01");
        var id = await conn.ExecuteScalarAsync<int?>(
            "SELECT e.id FROM core.estudiantes e WHERE e.persona_id = @PersonaId;",
            new { PersonaId = PersonaActualId ?? 0 });
        return id ?? 0;
    }
}

/// <summary>ViewModel del puesto de trabajo del personal.</summary>
public class MatriculasPanelViewModel
{
    public ResumenMatriculaDto Resumen { get; set; } = new();
    public IEnumerable<MatriculaListaDto> ListasParaRegistrar { get; set; } = [];
    public IEnumerable<MatriculaListaDto> EnEspera { get; set; } = [];
    public IEnumerable<MatriculaPorLiberarDto> PorLiberar { get; set; } = [];
    public IEnumerable<MatriculaListaDto> Todas { get; set; } = [];
    public string? FiltroEstado { get; set; }
}
