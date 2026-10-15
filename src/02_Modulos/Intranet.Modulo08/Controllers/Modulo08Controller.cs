using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo08.Controllers;

/// <summary>
/// Controlador principal de entrada para el Módulo 08 (Seguridad, Roles y Control de Acceso).
/// Permite el descubrimiento en Intranet.Web y la redirección unificada al flujo de login/dashboard.
/// </summary>
[Route("Modulo08")]
public class Modulo08Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        return RedirectToAction("Index", "Login");
    }
}
