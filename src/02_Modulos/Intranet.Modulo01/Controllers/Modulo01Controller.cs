using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo01.Controllers;

[Route("Modulo01")]
public class Modulo01Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Módulo 01";
        ViewData["TeamName"] = "Equipo 01";
        return View();
    }
}
