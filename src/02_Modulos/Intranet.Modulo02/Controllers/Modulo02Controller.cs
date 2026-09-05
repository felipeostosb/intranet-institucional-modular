using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo02.Controllers;

[Route("Modulo02")]
public class Modulo02Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 02";
        ViewData["TeamName"] = "Equipo 02";
        return View();
    }
}
