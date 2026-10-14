using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;

namespace Intranet.Modulo05.Controllers;

[Route("Modulo05")]
public class Modulo05Controller : ModuloBaseController
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"]        = "05. Incidencias & Requerimientos";
        ViewData["TeamName"]     = "Equipo 05";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        return View();
    }
}
