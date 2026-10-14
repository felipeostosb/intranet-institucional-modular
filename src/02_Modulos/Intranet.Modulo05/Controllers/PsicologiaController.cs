using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;
using Intranet.Core.Controllers;
using Intranet.Modulo05.Models;
using System.Collections.Generic;

namespace Intranet.Modulo05.Controllers;

[Route("Modulo05/[controller]")]
public class PsicologiaController : ModuloBaseController
{
    // GET: /Modulo05/Psicologia   o   /Modulo05/Psicologia/Panel
    [HttpGet("")]
    [HttpGet("Panel")]
    [HttpGet("PanelPsicologia")]
    public IActionResult Panel()
    {
        ViewData["Title"]        = "Psicología / Bienestar Estudiantil";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        return View("~/Views/psicologia/panel_psicologia.cshtml");
    }

    // GET: /Modulo05/Psicologia/FormSesion
    [HttpGet("Create")]
    [HttpGet("FormSesion")]
    public IActionResult FormSesion()
    {
        ViewData["Title"]        = "Registro de Sesión Psicológica";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        return View("~/Views/psicologia/form_sesion.cshtml");
    }

    // GET: /Modulo05/Psicologia/ExpedienteAlumno
    [HttpGet("ExpedienteAlumno")]
    public async Task<IActionResult> ExpedienteAlumno(string? dni = null)
    {
        ViewData["Title"]        = "Expediente Confidencial del Alumno";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var lista = new List<SesionPsicologicaItem>();
        if (!string.IsNullOrWhiteSpace(dni))
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            lista = (await conn.QueryAsync<SesionPsicologicaItem>(
                @"SELECT a.id AS IdAtencionPsico, a.persona_id AS PersonaId, a.psicologo_id AS PsicologoId,
                         a.fecha_hora AS FechaHora, a.motivo_consulta AS MotivoConsulta,
                         a.observacion_notas AS ObservacionNotas, a.estado_atencion AS EstadoAtencion,
                         p.dni AS NumeroDocumento,
                         p.nombres AS EstudianteNombres, p.apellidos AS EstudianteApellidos
                  FROM mod05.atenciones_psicologia a
                  INNER JOIN core.personas p ON a.persona_id = p.id
                  WHERE p.dni = @dni
                  ORDER BY a.fecha_hora DESC",
                new { dni = dni.Trim() })).AsList();
        }

        ViewBag.DniBuscado = dni;
        return View("~/Views/psicologia/expediente_alumno.cshtml", lista);
    }

    // GET: /Modulo05/Psicologia/BuscarPaciente?dni=...
    [HttpGet("BuscarPaciente")]
    public async Task<IActionResult> BuscarPaciente(string dni)
    {
        if (string.IsNullOrWhiteSpace(dni))
            return Json(new { success = false, message = "Por favor ingrese un número de DNI válido." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            var alumno = await conn.QueryFirstOrDefaultAsync<EstudianteBusquedaDto>(
                @"SELECT p.id AS PersonaId, p.dni AS NumeroDocumento,
                         p.nombres AS EstudianteNombres, p.apellidos AS EstudianteApellidos,
                         c.nombre AS Carrera
                  FROM core.personas p
                  LEFT JOIN core.estudiantes e ON e.persona_id = p.id
                  LEFT JOIN core.carreras c ON c.id = e.carrera_id
                  WHERE p.dni = @dni LIMIT 1",
                new { dni = dni.Trim() });

            if (alumno != null)
                return Json(new
                {
                    success       = true,
                    personaId     = alumno.PersonaId,
                    dni           = alumno.NumeroDocumento,
                    nombres       = alumno.EstudianteNombres,
                    apellidos     = alumno.EstudianteApellidos,
                    nombreCompleto = $"{alumno.EstudianteNombres} {alumno.EstudianteApellidos}".Trim(),
                    carrera       = alumno.Carrera ?? "Sin carrera asignada",
                    cicloTurno    = "Ver expediente"
                });

            return Json(new { success = false, message = $"No se encontró registro para el DNI {dni}." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al consultar estudiante: " + ex.Message });
        }
    }

    // POST: /Modulo05/Psicologia/GuardarSesion
    [HttpPost("GuardarAtencion")]
    [HttpPost("GuardarSesion")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> GuardarSesion(
        string? dniBusqueda, string? motivoConsulta, string? fechaHora,
        string? estadoClinico, string? diagnosticoNotas)
    {
        try
        {
            var dni    = dniBusqueda?.Trim();
            var motivo = motivoConsulta?.Trim();

            if (string.IsNullOrWhiteSpace(dni))
                return Json(new { success = false, message = "Debe buscar y seleccionar el estudiante mediante su DNI." });
            if (string.IsNullOrWhiteSpace(motivo))
                return Json(new { success = false, message = "El motivo de consulta y contexto es obligatorio." });

            DateTime fecha = DateTime.Now;
            if (!string.IsNullOrEmpty(fechaHora) && DateTime.TryParse(fechaHora, out var p)) fecha = p;

            string estado = string.IsNullOrWhiteSpace(estadoClinico) ? "Pendiente" : estadoClinico.Trim();

            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            var personaId = await conn.ExecuteScalarAsync<int?>(
                "SELECT id FROM core.personas WHERE dni = @dni LIMIT 1", new { dni });
            if (personaId == null)
                return Json(new { success = false, message = "El DNI ingresado no corresponde a ninguna persona en el sistema." });

            int psicologoId = UsuarioActualId ?? 1;

            int rows = await conn.ExecuteAsync(
                @"INSERT INTO mod05.atenciones_psicologia
                    (persona_id, psicologo_id, fecha_hora, motivo_consulta, observacion_notas, estado_atencion)
                  VALUES (@personaId, @psicologoId, @fecha, @motivo, @notas, @estado)",
                new
                {
                    personaId,
                    psicologoId,
                    fecha,
                    motivo,
                    notas  = string.IsNullOrWhiteSpace(diagnosticoNotas) ? (object)null! : diagnosticoNotas.Trim(),
                    estado
                });

            if (rows > 0)
            {
                MostrarAlertaExito("¡Sesión psicológica registrada exitosamente!");
                return Json(new { success = true, message = "¡Sesión psicológica registrada exitosamente en la base de datos!" });
            }
            return Json(new { success = false, message = "No se pudo registrar la sesión en la base de datos." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al procesar el registro: " + ex.Message });
        }
    }

    // GET: /Modulo05/Psicologia/Historial?dni=...   (API JSON)
    [HttpGet("Historial")]
    public async Task<IActionResult> Historial(string dni)
    {
        if (string.IsNullOrWhiteSpace(dni))
            return Json(new { success = false, message = "DNI no proporcionado." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            var sesiones = await conn.QueryAsync(
                @"SELECT a.id AS idAtencion, a.fecha_hora AS fechaHora, a.motivo_consulta AS motivo,
                         a.estado_atencion AS estado, a.observacion_notas AS notas
                  FROM mod05.atenciones_psicologia a
                  INNER JOIN core.personas p ON a.persona_id = p.id
                  WHERE p.dni = @dni ORDER BY a.fecha_hora DESC",
                new { dni = dni.Trim() });
            return Json(new { success = true, data = sesiones });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al consultar historial: " + ex.Message });
        }
    }
}
