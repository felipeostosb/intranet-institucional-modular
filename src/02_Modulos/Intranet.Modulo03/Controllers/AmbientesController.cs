using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03/[controller]")]
public class AmbientesController : ModuloBaseController
{
    private readonly InventarioService _service;

    public AmbientesController(InventarioService service) => _service = service;

    [HttpGet("")]
    public IActionResult Index() => View(_service.ObtenerAmbientes(false));
}
