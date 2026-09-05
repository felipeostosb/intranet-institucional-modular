using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo06.Controllers;

[Route("Modulo06")]
public class Modulo06Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 06";
        ViewData["TeamName"] = "Equipo 06";
        return View();
    }
}
