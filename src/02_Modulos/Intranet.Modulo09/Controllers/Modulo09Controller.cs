using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo09.Controllers;

[Route("Modulo09")]
public class Modulo09Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 09";
        ViewData["TeamName"] = "Equipo 09";
        return View();
    }
}
