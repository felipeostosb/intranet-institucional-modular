using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo06.Repositories;
using Intranet.Modulo06.Models;

namespace Intranet.Modulo06.Controllers
{
    [Route("Modulo06")]
    public class Modulo06Controller : ModuloBaseController
    {
        private readonly IExpedienteRepository _expedienteRepository;

        public Modulo06Controller(IExpedienteRepository expedienteRepository)
        {
            _expedienteRepository = expedienteRepository;
        }

        [HttpGet("")]
        public async Task<IActionResult> Index(string dniBusqueda)
        {
            // 1. Cargamos la lista para la tabla principal (Dashboard)
            var expedientes = await _expedienteRepository.ObtenerExpedientesRecientesAsync();

            EgresadoDetalleDto? egresadoEncontrado = null;

            // 2. Si el usuario ingresó un DNI en el buscador, filtramos
            if (!string.IsNullOrEmpty(dniBusqueda))
            {
                egresadoEncontrado = await _expedienteRepository.BuscarEgresadoPorDniAsync(dniBusqueda.Trim());

                if (egresadoEncontrado == null)
                {
                    TempData["MensajeError"] = "Egresado no encontrado con el DNI ingresado.";
                }
            }

            // Pasamos el resultado y el DNI actual a la vista mediante ViewBag o Modelo combinado
            ViewBag.EgresadoBuscado = egresadoEncontrado;
            ViewBag.DniBuscado = dniBusqueda;

            return View(expedientes);
        }
    }
}
