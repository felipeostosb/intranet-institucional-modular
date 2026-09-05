using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;

namespace Intranet.Modulo02.Controllers;

[Route("Modulo02")]
public class Modulo02Controller : ModuloBaseController
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 02 - Matrícula Académica";
        ViewData["TeamName"] = "Equipo 02";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        return View();
    }
}
