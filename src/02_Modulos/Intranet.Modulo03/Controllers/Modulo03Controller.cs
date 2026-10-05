using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo03.Models;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03/[controller]")]
public class Modulo03Controller : ModuloBaseController
{
    private readonly InventarioService _inventarioService;

    public Modulo03Controller(InventarioService inventarioService)
    {
        _inventarioService = inventarioService;
    }

    [HttpGet("/Modulo03")]
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index([FromQuery] InventarioFiltroModel filtro)
    {
        filtro.Resultados = _inventarioService.ObtenerInventario(filtro);
        filtro.Clasificaciones = _inventarioService.ObtenerClasificaciones();
        filtro.Almacenes = _inventarioService.ObtenerAlmacenes(true);

        ViewData["Title"] = "Módulo 03 - Inventario & Equipos";
        ViewData["TeamName"] = "Equipo 03";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        return View(filtro);
    }
}
