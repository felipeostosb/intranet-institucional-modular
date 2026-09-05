using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;

namespace Intranet.Modulo01.Controllers;

[Route("Modulo01")]
public class Modulo01Controller : ModuloBaseController
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 01 - Admisión y Matrícula";
        ViewData["TeamName"] = "Equipo 01";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        return View();
    }
}
