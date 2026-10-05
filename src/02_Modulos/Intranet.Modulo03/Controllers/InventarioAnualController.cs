using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo03.Models;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03/[controller]")]
public class InventarioAnualController : ModuloBaseController
{
    private readonly InventarioService _service;

    public InventarioAnualController(InventarioService service) => _service = service;

    [HttpGet("")]
    public IActionResult Index() => View(_service.ObtenerInventarioAnual());

    [HttpGet("Crear")]
    public IActionResult Crear() => View(Cargar(new InventarioAnualFormModel()));

    [HttpPost("Crear")]
    [ValidateAntiForgeryToken]
    public IActionResult Crear(InventarioAnualFormModel model)
    {
        try
        {
            if (!ModelState.IsValid) return View(Cargar(model));
            _service.RegistrarInventarioAnual(model);
            TempData["Ok"] = "Verificación anual registrada.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", ex.Message.Contains("duplicate", StringComparison.OrdinalIgnoreCase)
                ? "Ese bien ya tiene una verificación registrada para ese año."
                : ex.Message);
            return View(Cargar(model));
        }
    }

    private InventarioAnualFormModel Cargar(InventarioAnualFormModel model)
    {
        model.Bienes = _service.ObtenerInventario();
        return model;
    }
}
