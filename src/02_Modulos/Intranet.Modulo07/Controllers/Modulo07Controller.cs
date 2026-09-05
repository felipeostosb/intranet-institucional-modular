using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo07.Controllers;

[Route("Modulo07")]
public class Modulo07Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 07";
        ViewData["TeamName"] = "Equipo 07";
        return View();
    }
}
