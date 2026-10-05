using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo03.Models;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03/[controller]")]
public class AsignacionesController : ModuloBaseController
{
    private readonly InventarioService _service;

    public AsignacionesController(InventarioService service) => _service = service;

    [HttpGet("")]
    public IActionResult Index() => View(_service.ObtenerAsignaciones());

    [HttpGet("Crear")]
    public IActionResult Crear()
    {
        return View(Cargar(new AsignacionFormModel()));
    }

    [HttpPost("Crear")]
    [ValidateAntiForgeryToken]
    public IActionResult Crear(AsignacionFormModel model)
    {
        try
        {
            if (!ModelState.IsValid) return View(Cargar(model));
            _service.CrearAsignacion(model);
            TempData["Ok"] = "Asignación creada correctamente.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", ex.Message);
            return View(Cargar(model));
        }
    }

    [HttpPost("Finalizar/{id:int}")]
    [ValidateAntiForgeryToken]
    public IActionResult Finalizar(int id)
    {
        try
        {
            _service.FinalizarAsignacion(id);
            TempData["Ok"] = "Asignación finalizada.";
        }
        catch (Exception ex) { TempData["Error"] = ex.Message; }
        return RedirectToAction(nameof(Index));
    }

    private AsignacionFormModel Cargar(AsignacionFormModel model)
    {
        model.Bienes = _service.ObtenerBienesDisponiblesAsignacion();
        model.Ambientes = _service.ObtenerAmbientes(true);
        return model;
    }
}
