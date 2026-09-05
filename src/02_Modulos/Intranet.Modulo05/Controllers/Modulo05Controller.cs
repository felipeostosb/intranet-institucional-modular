using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo05.Controllers;

[Route("Modulo05")]
public class Modulo05Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 05";
        ViewData["TeamName"] = "Equipo 05";
        return View();
    }
}
