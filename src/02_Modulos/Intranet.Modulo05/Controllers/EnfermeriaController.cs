using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;
using Intranet.Core.Controllers;
using Intranet.Modulo05.Models;
using System.Collections.Generic;

namespace Intranet.Modulo05.Controllers;

[Route("Modulo05/[controller]")]
public class EnfermeriaController : ModuloBaseController
{
    // GET: /Modulo05/Enfermeria   o   /Modulo05/Enfermeria/Panel
    [HttpGet("")]
    [HttpGet("Panel")]
    [HttpGet("PanelEnfermeria")]
    public IActionResult Panel()
    {
        ViewData["Title"]        = "Tópico / Enfermería";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        return View("~/Views/enfermeria/panel_enfermeria.cshtml");
    }

    // GET: /Modulo05/Enfermeria/FormAtencion
    [HttpGet("Create")]
    [HttpGet("FormAtencion")]
    public async Task<IActionResult> FormAtencion()
    {
        ViewData["Title"]        = "Registro de Atención Médica";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
        using var conn = fabrica.CreateConnection("05");
        var medicamentos = (await conn.QueryAsync<MedicamentoItem>(
            "SELECT id, nombre, presentacion, stock_actual, fecha_vencimiento, estado " +
            "FROM mod05.botica_medicamentos WHERE estado = 'Disponible' ORDER BY nombre")).AsList();
        ViewBag.Medicamentos = medicamentos;

        return View("~/Views/enfermeria/form_atencion.cshtml");
    }

    // GET: /Modulo05/Enfermeria/HistorialPaciente
    [HttpGet("HistorialPaciente")]
    public async Task<IActionResult> HistorialPaciente(string? dni = null)
    {
        ViewData["Title"]        = "Historial Clínico del Paciente";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var lista = new List<AtencionMedicaItem>();
        if (!string.IsNullOrWhiteSpace(dni))
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            lista = (await conn.QueryAsync<AtencionMedicaItem>(
                @"SELECT a.id AS IdAtencionTop, a.persona_id AS PersonaId, a.atendido_por AS AtendidoPorId,
                         a.fecha_hora AS FechaHora, a.motivo AS Motivo,
                         a.medicamento_id AS MedicamentoId, a.es_alergico AS EsAlergico,
                         a.detalle_alergia AS DetalleAlergia, a.seguro_salud AS SeguroSalud,
                         a.observacion AS Observacion,
                         p.dni AS NumeroDocumento,
                         p.nombres AS PacienteNombres, p.apellidos AS PacienteApellidos,
                         m.nombre AS MedicamentoNombre
                  FROM mod05.atenciones_topico a
                  INNER JOIN core.personas p ON a.persona_id = p.id
                  LEFT JOIN mod05.botica_medicamentos m ON a.medicamento_id = m.id
                  WHERE p.dni = @dni
                  ORDER BY a.fecha_hora DESC",
                new { dni = dni.Trim() })).AsList();
        }

        ViewBag.DniBuscado = dni;
        return View("~/Views/enfermeria/historial_paciente.cshtml", lista);
    }

    // GET: /Modulo05/Enfermeria/BuscarPaciente?dni=...
    [HttpGet("BuscarPaciente")]
    public async Task<IActionResult> BuscarPaciente(string dni)
    {
        if (string.IsNullOrWhiteSpace(dni))
            return Json(new { success = false, message = "Ingrese un número de DNI válido." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            var paciente = await conn.QueryFirstOrDefaultAsync<PacienteBusquedaDto>(
                "SELECT id AS IdPersona, dni AS NumeroDocumento, nombres AS Nombres, apellidos AS Apellidos " +
                "FROM core.personas WHERE dni = @dni LIMIT 1",
                new { dni = dni.Trim() });

            if (paciente != null)
                return Json(new
                {
                    success    = true,
                    idPersona  = paciente.IdPersona,
                    nombres    = paciente.Nombres,
                    apellidos  = paciente.Apellidos,
                    tipoSeguro = "SIS Gratuito / EsSalud",
                    alergiasConocidas = "Ninguna reportada en el padrón"
                });

            return Json(new { success = false, message = $"No se encontró paciente con DNI {dni}." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al consultar paciente: " + ex.Message });
        }
    }

    // POST: /Modulo05/Enfermeria/GuardarAtencion
    [HttpPost("GuardarAtencion")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> GuardarAtencion(
        string? buscarDni, string? motivoAtencion, string? fechaHora,
        string? medicamentosAdministrados, string? observacionesTratamiento,
        string? tipoSeguroSalud, string? reportaAlergias, string? especificarAlergias,
        int? medicamentoId)
    {
        try
        {
            var dni    = buscarDni?.Trim();
            var motivo = motivoAtencion?.Trim();

            if (string.IsNullOrWhiteSpace(dni))
                return Json(new { success = false, message = "Debe buscar y validar un DNI primero." });
            if (string.IsNullOrWhiteSpace(motivo))
                return Json(new { success = false, message = "El motivo de atención es obligatorio." });

            DateTime fecha = DateTime.Now;
            if (!string.IsNullOrEmpty(fechaHora) && DateTime.TryParse(fechaHora, out var p)) fecha = p;

            bool esAlergico    = !string.IsNullOrEmpty(reportaAlergias);
            string obsCompleta = observacionesTratamiento ?? "";
            if (!string.IsNullOrWhiteSpace(medicamentosAdministrados))
                obsCompleta = $"Medicamento recetado: {medicamentosAdministrados}\n{obsCompleta}".Trim();

            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            var personaId = await conn.ExecuteScalarAsync<int?>(
                "SELECT id FROM core.personas WHERE dni = @dni LIMIT 1", new { dni });
            if (personaId == null)
                return Json(new { success = false, message = "El DNI no está registrado en el sistema." });

            int atendidoPorId = UsuarioActualId ?? 1;

            int rows = await conn.ExecuteAsync(
                @"INSERT INTO mod05.atenciones_topico
                    (persona_id, atendido_por, fecha_hora, motivo, medicamento_id,
                     es_alergico, detalle_alergia, seguro_salud, observacion)
                  VALUES (@personaId, @atendidoPor, @fecha, @motivo, @medId,
                          @esAlergico, @detalle, @seguro, @obs)",
                new
                {
                    personaId,
                    atendidoPor = atendidoPorId,
                    fecha,
                    motivo,
                    medId      = medicamentoId.HasValue && medicamentoId > 0 ? (object)medicamentoId.Value : null!,
                    esAlergico,
                    detalle    = string.IsNullOrEmpty(especificarAlergias) ? (object)null! : especificarAlergias,
                    seguro     = string.IsNullOrEmpty(tipoSeguroSalud) ? "NINGUNO" : tipoSeguroSalud.ToUpper(),
                    obs        = string.IsNullOrEmpty(obsCompleta) ? (object)null! : obsCompleta
                });

            if (rows > 0 && medicamentoId.HasValue && medicamentoId > 0)
            {
                await conn.ExecuteAsync(
                    "UPDATE mod05.botica_medicamentos SET stock_actual = GREATEST(stock_actual - 1, 0) WHERE id = @id",
                    new { id = medicamentoId.Value });
            }

            MostrarAlertaExito("¡Atención clínica registrada exitosamente en el sistema de Tópico!");
            return Json(new { success = true, message = "¡Atención clínica registrada exitosamente!" });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al procesar registro: " + ex.Message });
        }
    }

    // GET: /Modulo05/Enfermeria/Historial?dni=...   (API JSON)
    [HttpGet("Historial")]
    public async Task<IActionResult> Historial(string dni)
    {
        if (string.IsNullOrWhiteSpace(dni))
            return Json(new { success = false, message = "DNI no proporcionado." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            var lista = await conn.QueryAsync(
                @"SELECT a.fecha_hora, a.motivo, a.seguro_salud, a.observacion, a.es_alergico, a.detalle_alergia
                  FROM mod05.atenciones_topico a
                  INNER JOIN core.personas p ON a.persona_id = p.id
                  WHERE p.dni = @dni ORDER BY a.fecha_hora DESC",
                new { dni = dni.Trim() });
            return Json(new { success = true, data = lista });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al consultar historial: " + ex.Message });
        }
    }

    // GET: /Modulo05/Enfermeria/Medicamentos   (API JSON)
    [HttpGet("Medicamentos")]
    public async Task<IActionResult> Medicamentos()
    {
        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            var lista = await conn.QueryAsync(
                "SELECT id, nombre, presentacion, stock_actual, fecha_vencimiento, estado " +
                "FROM mod05.botica_medicamentos WHERE estado = 'Disponible' ORDER BY nombre");
            return Json(new { success = true, data = lista });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al listar botica: " + ex.Message });
        }
    }
}
