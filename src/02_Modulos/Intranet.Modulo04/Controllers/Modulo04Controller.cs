using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo04.Controllers;

[Route("Modulo04")]
public class Modulo04Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 04";
        ViewData["TeamName"] = "Equipo 04";
        return View();
    }
}
