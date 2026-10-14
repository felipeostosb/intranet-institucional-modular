using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;

namespace Intranet.Modulo05.Controllers;

/// <summary>
/// AtencionClinica fue una ruta duplicada de Enfermería que se dejó por
/// compatibilidad. Redirige a los endpoints canónicos de EnfermeriaController.
/// </summary>
[Route("Modulo05/[controller]")]
public class AtencionClinicaController : ModuloBaseController
{
    [HttpGet("")]
    [HttpGet("Create")]
    public IActionResult Create() => RedirectToAction("FormAtencion", "Enfermeria");

    [HttpGet("Historial")]
    public IActionResult Historial(string? dni) =>
        RedirectToAction("HistorialPaciente", "Enfermeria", new { dni });

    [HttpGet("BuscarPaciente")]
    public IActionResult BuscarPaciente(string? dni) =>
        RedirectToAction("BuscarPaciente", "Enfermeria", new { dni });
}
