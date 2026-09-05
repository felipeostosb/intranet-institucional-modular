using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;

namespace Intranet.Modulo08.Controllers;

[Route("Modulo08")]
public class Modulo08Controller : ModuloBaseController
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 08 - Bolsa de Trabajo";
        ViewData["TeamName"] = "Equipo 08";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        return View();
    }
}
