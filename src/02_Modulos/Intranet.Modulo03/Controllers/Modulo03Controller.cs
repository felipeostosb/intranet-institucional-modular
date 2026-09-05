using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03")]
public class Modulo03Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 03";
        ViewData["TeamName"] = "Equipo 03";
        return View();
    }
}
