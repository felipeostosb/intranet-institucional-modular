using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo08.Controllers;

[Route("Modulo08")]
public class Modulo08Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 08";
        ViewData["TeamName"] = "Equipo 08";
        return View();
    }
}
