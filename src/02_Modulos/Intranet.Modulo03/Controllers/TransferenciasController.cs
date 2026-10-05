using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo03.Models;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03/[controller]")]
public class TransferenciasController : ModuloBaseController
{
    private readonly InventarioService _service;

    public TransferenciasController(InventarioService service) => _service = service;

    [HttpGet("")]
    public IActionResult Index() => View(_service.ObtenerTransferencias());

    [HttpGet("Crear")]
    public IActionResult Crear()
    {
        return View(Cargar(new TransferenciaFormModel()));
    }

    [HttpPost("Crear")]
    [ValidateAntiForgeryToken]
    public IActionResult Crear(TransferenciaFormModel model)
    {
        try
        {
            if (!ModelState.IsValid) return View(Cargar(model));
            _service.CrearTransferencia(model);
            TempData["Ok"] = "Transferencia registrada como 'Pendiente de recepción'.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", ex.Message);
            return View(Cargar(model));
        }
    }

    [HttpPost("Recepcionar/{id:int}")]
    [ValidateAntiForgeryToken]
    public IActionResult Recepcionar(int id)
    {
        try
        {
            _service.RecepcionarTransferencia(id);
            TempData["Ok"] = "Transferencia recepcionada y almacén del bien actualizado.";
        }
        catch (Exception ex) { TempData["Error"] = ex.Message; }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost("Cancelar/{id:int}")]
    [ValidateAntiForgeryToken]
    public IActionResult Cancelar(int id)
    {
        try
        {
            _service.CancelarTransferencia(id);
            TempData["Ok"] = "Transferencia cancelada.";
        }
        catch (Exception ex) { TempData["Error"] = ex.Message; }
        return RedirectToAction(nameof(Index));
    }

    private TransferenciaFormModel Cargar(TransferenciaFormModel model)
    {
        model.Bienes = _service.ObtenerInventario();
        model.Almacenes = _service.ObtenerAlmacenes(true);
        return model;
    }
}
