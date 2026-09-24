using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;

namespace Intranet.Modulo01.Controllers;

/// <summary>
/// Entrada del Módulo 01. El botón "01. Matrícula" del menú global
/// aterriza aquí y redirige a la pantalla real del equipo:
///   Alumno   → Mi Matrícula (proceso Cero Filas)
///   Personal → Panel de trabajo (4 zonas)
/// </summary>
[Route("Modulo01")]
public class Modulo01Controller : ModuloBaseController
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        return RedirectToAction("Index", "Matriculas");
    }
}
