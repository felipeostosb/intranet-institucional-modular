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

    // =========================================================================
    // GESTIÓN DE CITAS PSICOLÓGICAS (mod05.citas_psicologia)
    // =========================================================================

    // GET: /Modulo05/Psicologia/Citas   o   /Modulo05/Psicologia/FormCita
    [HttpGet("Citas")]
    [HttpGet("FormCita")]
    [HttpGet("AgendarCita")]
    public async Task<IActionResult> Citas()
    {
        ViewData["Title"]         = "Agendamiento de Citas Psicológicas";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]    = UsuarioActualRol;
        ViewData["RolesUsuario"]  = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var citas = new List<CitaPsicologiaItem>();
        var psicologos = new List<PsicologoItemDto>();

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            citas = (await conn.QueryAsync<CitaPsicologiaItem>(
                @"SELECT c.id AS Id, c.persona_id AS PersonaId, c.nombres AS Nombres, c.apellidos AS Apellidos,
                         c.email AS Email, c.inicio AS Inicio, c.fin AS Fin, c.motivo AS Motivo,
                         c.estado AS Estado, c.origen AS Origen, c.google_event_id AS GoogleEventId,
                         c.psicologo_id AS PsicologoId, c.motivo_cancelacion AS MotivoCancelacion,
                         c.creado_en AS CreadoEn,
                         p.dni AS Dni,
                         CONCAT(pp.nombres, ' ', pp.apellidos) AS PsicologoNombre
                  FROM mod05.citas_psicologia c
                  LEFT JOIN core.personas p ON c.persona_id = p.id
                  LEFT JOIN core.usuarios u ON c.psicologo_id = u.id
                  LEFT JOIN core.personas pp ON u.persona_id = pp.id
                  ORDER BY c.inicio DESC
                  LIMIT 50")).AsList();

            psicologos = (await conn.QueryAsync<PsicologoItemDto>(
                @"SELECT u.id AS UsuarioId,
                         CONCAT(p.nombres, ' ', p.apellidos) AS NombreCompleto,
                         u.email AS Email
                  FROM core.usuarios u
                  JOIN core.personas p ON u.persona_id = p.id
                  WHERE u.estado = TRUE
                  ORDER BY p.apellidos, p.nombres
                  LIMIT 20")).AsList();
        }
        catch (Exception ex)
        {
            ViewBag.ErrorMessage = "Nota de base de datos: " + ex.Message;
        }

        ViewBag.Psicologos = psicologos;
        return View("~/Views/psicologia/form_cita.cshtml", citas);
    }

    // POST: /Modulo05/Psicologia/GuardarCita
    [HttpPost("GuardarCita")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> GuardarCita(RegistrarCitaInputDto input)
    {
        if (input == null)
            return Json(new { success = false, message = "Datos del formulario no recibidos." });

        if (string.IsNullOrWhiteSpace(input.Nombres))
            return Json(new { success = false, message = "El nombre del estudiante es obligatorio." });
        if (string.IsNullOrWhiteSpace(input.Apellidos))
            return Json(new { success = false, message = "Los apellidos del estudiante son obligatorios." });
        if (string.IsNullOrWhiteSpace(input.Email))
            return Json(new { success = false, message = "El correo electrónico es obligatorio." });
        if (string.IsNullOrWhiteSpace(input.Fecha) || string.IsNullOrWhiteSpace(input.HoraInicio))
            return Json(new { success = false, message = "La fecha y hora de la cita son obligatorias." });

        if (!DateTime.TryParse($"{input.Fecha.Trim()} {input.HoraInicio.Trim()}", out var fechaHoraInicio))
            return Json(new { success = false, message = "La fecha u hora ingresada no tienen un formato válido." });

        var inicioUtc = DateTime.SpecifyKind(fechaHoraInicio, DateTimeKind.Utc);
        int duracion = input.DuracionMinutos > 0 ? input.DuracionMinutos : 30;
        var finUtc = inicioUtc.AddMinutes(duracion);

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            // Validar si ya existe una cita activa en ese mismo bloque (índice único uq_cita_franja_activa)
            var existeConflicto = await conn.ExecuteScalarAsync<bool>(
                @"SELECT EXISTS (
                    SELECT 1 FROM mod05.citas_psicologia
                    WHERE inicio = @inicioUtc AND estado IN ('Programada', 'Confirmada')
                  )",
                new { inicioUtc });

            if (existeConflicto)
            {
                return Json(new
                {
                    success = false,
                    message = "El horario seleccionado ya se encuentra ocupado por otra cita activa. Por favor seleccione otro bloque o fecha."
                });
            }

            // Buscar persona_id por DNI o correo
            int? personaId = null;
            if (!string.IsNullOrWhiteSpace(input.Dni))
            {
                personaId = await conn.ExecuteScalarAsync<int?>(
                    "SELECT id FROM core.personas WHERE dni = @dni LIMIT 1",
                    new { dni = input.Dni.Trim() });
            }
            if (personaId == null)
            {
                personaId = await conn.ExecuteScalarAsync<int?>(
                    @"SELECT u.persona_id FROM core.usuarios u
                      WHERE lower(u.email) = lower(@email) LIMIT 1",
                    new { email = input.Email.Trim() });
            }

            string origen = string.IsNullOrWhiteSpace(input.Origen) ? "Sistema" : input.Origen.Trim();
            if (origen != "Google Calendar" && origen != "Presencial" && origen != "Sistema")
                origen = "Sistema";

            int? psicologoId = input.PsicologoId.HasValue && input.PsicologoId > 0
                ? input.PsicologoId
                : UsuarioActualId;

            int nuevoId = await conn.ExecuteScalarAsync<int>(
                @"INSERT INTO mod05.citas_psicologia
                    (persona_id, nombres, apellidos, email, inicio, fin, motivo, estado, origen, psicologo_id, creado_en)
                  VALUES
                    (@personaId, @nombres, @apellidos, @email, @inicioUtc, @finUtc, @motivo, 'Programada', @origen, @psicologoId, CURRENT_TIMESTAMP)
                  RETURNING id",
                new
                {
                    personaId,
                    nombres = input.Nombres.Trim(),
                    apellidos = input.Apellidos.Trim(),
                    email = input.Email.Trim(),
                    inicioUtc,
                    finUtc,
                    motivo = string.IsNullOrWhiteSpace(input.Motivo) ? null : input.Motivo.Trim(),
                    origen,
                    psicologoId
                });

            MostrarAlertaExito("¡Cita agendada exitosamente!");
            return Json(new
            {
                success = true,
                id = nuevoId,
                message = $"¡Cita #{nuevoId} agendada exitosamente para {input.Nombres} {input.Apellidos}!"
            });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al agendar cita: " + ex.Message });
        }
    }

    // POST: /Modulo05/Psicologia/CancelarCita
    [HttpPost("CancelarCita")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CancelarCita(int id, string? motivoCancelacion)
    {
        if (id <= 0)
            return Json(new { success = false, message = "ID de cita inválido." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            int affected = await conn.ExecuteAsync(
                @"UPDATE mod05.citas_psicologia
                  SET estado = 'Cancelada',
                      motivo_cancelacion = @motivo
                  WHERE id = @id",
                new { id, motivo = string.IsNullOrWhiteSpace(motivoCancelacion) ? "Cancelado por el usuario" : motivoCancelacion.Trim() });

            if (affected > 0)
                return Json(new { success = true, message = "La cita fue cancelada correctamente." });

            return Json(new { success = false, message = "No se encontró la cita especificada." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al cancelar cita: " + ex.Message });
        }
    }

    // POST: /Modulo05/Psicologia/CambiarEstadoCita
    [HttpPost("CambiarEstadoCita")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CambiarEstadoCita(int id, string nuevoEstado)
    {
        if (id <= 0 || string.IsNullOrWhiteSpace(nuevoEstado))
            return Json(new { success = false, message = "Parámetros inválidos." });

        var estadosValidos = new[] { "Programada", "Confirmada", "Atendida", "Cancelada", "No asistió" };
        if (!estadosValidos.Contains(nuevoEstado))
            return Json(new { success = false, message = "Estado no permitido." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            int affected = await conn.ExecuteAsync(
                "UPDATE mod05.citas_psicologia SET estado = @nuevoEstado WHERE id = @id",
                new { id, nuevoEstado });

            if (affected > 0)
                return Json(new { success = true, message = $"Estado de la cita actualizado a '{nuevoEstado}'." });

            return Json(new { success = false, message = "No se encontró la cita especificada." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al actualizar estado: " + ex.Message });
        }
    }

    // GET: /Modulo05/Psicologia/BuscarEstudianteParaCita?dni=...
    [HttpGet("BuscarEstudianteParaCita")]
    public async Task<IActionResult> BuscarEstudianteParaCita(string dni)
    {
        if (string.IsNullOrWhiteSpace(dni))
            return Json(new { success = false, message = "DNI no proporcionado." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            var datos = await conn.QueryFirstOrDefaultAsync(
                @"SELECT p.id AS PersonaId, p.dni, p.nombres, p.apellidos,
                         COALESCE(u.email, p.email_personal, CONCAT(lower(replace(p.dni, ' ', '')), '@iestpargentina.edu.pe')) AS email,
                         c.nombre AS Carrera
                  FROM core.personas p
                  LEFT JOIN core.usuarios u ON u.persona_id = p.id
                  LEFT JOIN core.estudiantes e ON e.persona_id = p.id
                  LEFT JOIN core.carreras c ON c.id = e.carrera_id
                  WHERE p.dni = @dni
                  LIMIT 1",
                new { dni = dni.Trim() });

            if (datos != null)
            {
                return Json(new
                {
                    success = true,
                    personaId = (int)datos.personaid,
                    dni = (string)datos.dni,
                    nombres = (string)datos.nombres,
                    apellidos = (string)datos.apellidos,
                    email = (string)datos.email,
                    carrera = (string)(datos.carrera ?? "Estudiante General")
                });
            }

            return Json(new { success = false, message = $"No se encontró registro con el DNI {dni}." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al buscar estudiante: " + ex.Message });
        }
    }
}
