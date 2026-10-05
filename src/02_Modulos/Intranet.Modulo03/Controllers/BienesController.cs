using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo03.Models;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03/[controller]")]
public class BienesController : ModuloBaseController
{
    private readonly InventarioService _service;

    public BienesController(InventarioService service) => _service = service;

    [HttpGet("")]
    public IActionResult Index([FromQuery] InventarioFiltroModel filtro)
    {
        filtro.Resultados = _service.ObtenerInventario(filtro);
        filtro.Clasificaciones = _service.ObtenerClasificaciones();
        filtro.Almacenes = _service.ObtenerAlmacenes(true);
        return View(filtro);
    }

    [HttpGet("Crear")]
    public IActionResult Crear()
    {
        return View(CargarFormulario(new BienFormModel()));
    }

    [HttpPost("Crear")]
    [ValidateAntiForgeryToken]
    public IActionResult Crear(BienFormModel model)
    {
        try
        {
            if (!ModelState.IsValid) return View(CargarFormulario(model));
            _service.RegistrarBien(model);
            TempData["Ok"] = "Bien registrado correctamente.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", MensajeBaseDatos(ex));
            return View(CargarFormulario(model));
        }
    }

    [HttpGet("Editar/{id:int}")]
    public IActionResult Editar(int id)
    {
        var bien = _service.ObtenerBien(id);
        if (bien is null) return NotFound();
        return View(CargarFormulario(new BienFormModel
        {
            IdBien = bien.IdBien,
            Cbi = bien.Cbi,
            CodigoInventario = bien.CodigoInventario,
            Descripcion = bien.Descripcion,
            IdClasificacion = bien.IdClasificacion,
            Marca = bien.Marca,
            Modelo = bien.Modelo,
            Serie = bien.Serie,
            Procedencia = bien.Procedencia,
            FechaIngreso = bien.FechaIngreso,
            Estado = bien.Estado,
            IdAlmacen = bien.IdAlmacen,
            Observacion = bien.Observacion
        }));
    }

    [HttpPost("Editar/{id:int}")]
    [ValidateAntiForgeryToken]
    public IActionResult Editar(int id, BienFormModel model)
    {
        model.IdBien = id;
        try
        {
            if (!ModelState.IsValid) return View(CargarFormulario(model));
            _service.ActualizarBien(model);
            TempData["Ok"] = "Bien actualizado correctamente.";
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", MensajeBaseDatos(ex));
            return View(CargarFormulario(model));
        }
    }

    [HttpGet("Detalle/{id:int}")]
    public IActionResult Detalle(int id)
    {
        var bien = _service.ObtenerBien(id);
        return bien is null ? NotFound() : View(bien);
    }

    [HttpPost("Baja/{id:int}")]
    [ValidateAntiForgeryToken]
    public IActionResult Baja(int id)
    {
        try
        {
            _service.DarDeBaja(id);
            TempData["Ok"] = "El bien fue marcado como 'De baja'.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = MensajeBaseDatos(ex);
        }
        return RedirectToAction(nameof(Index));
    }

    [HttpPost("Eliminar/{id:int}")]
    [ValidateAntiForgeryToken]
    public IActionResult Eliminar(int id)
    {
        try
        {
            _service.EliminarBien(id);
            TempData["Ok"] = "Bien eliminado de la base de datos.";
        }
        catch (Exception ex)
        {
            TempData["Error"] = "No se puede eliminar físicamente este bien porque tiene movimientos relacionados. Usa 'Dar de baja' para conservar el historial. Detalle: " + MensajeBaseDatos(ex);
        }
        return RedirectToAction(nameof(Index));
    }

    private BienFormModel CargarFormulario(BienFormModel model)
    {
        model.Almacenes = _service.ObtenerAlmacenes(true);
        model.Clasificaciones = _service.ObtenerClasificaciones();
        return model;
    }

    private static string MensajeBaseDatos(Exception ex) => ex.Message.Contains("unique", StringComparison.OrdinalIgnoreCase)
        ? "Ya existe un registro con un CBI, código de inventario o serie igual."
        : ex.Message;
}
