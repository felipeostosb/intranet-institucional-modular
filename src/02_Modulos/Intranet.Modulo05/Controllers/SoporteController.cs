using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;
using Intranet.Core.Controllers;
using Intranet.Modulo05.Models;
using System.Collections.Generic;

namespace Intranet.Modulo05.Controllers;

[Route("Modulo05/[controller]")]
public class SoporteController : ModuloBaseController
{
    // GET: /Modulo05/Soporte   o   /Modulo05/Soporte/Consola
    [HttpGet("")]
    [HttpGet("Consola")]
    [HttpGet("ConsolaPrincipal")]
    public async Task<IActionResult> ConsolaPrincipal(string? estado = null)
    {
        ViewData["Title"]        = "Consola Técnica de Soporte TI";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
        using var conn = fabrica.CreateConnection("05");

        string sql = @"
            SELECT i.id AS IdIncidencia, i.bien_id AS IdBien, i.registrada_por AS ReportadorId,
                   i.tecnico_id AS TecnicoId, i.fecha_registro AS FechaReporte,
                   i.fecha_cierre AS FechaCierre, i.tipo_falla AS TipoFalla,
                   i.gravedad AS Gravedad, i.descripcion AS Descripcion,
                   i.solucion_aplicada AS SolucionAplicada, i.estado AS Estado,
                   b.codigo_inventario AS CodigoBien,
                   b.descripcion AS DescripcionBien,
                   b.marca AS Marca, b.modelo AS Modelo
            FROM mod05.incidencias i
            LEFT JOIN mod03.bien b ON b.id_bien = i.bien_id";

        if (!string.IsNullOrEmpty(estado)) sql += " WHERE i.estado = @estado";
        sql += " ORDER BY i.fecha_registro DESC";

        var tickets = (await conn.QueryAsync<TicketAveriaItem>(sql,
            string.IsNullOrEmpty(estado) ? null : new { estado })).AsList();

        // Calculamos MarcaModelo para la vista
        foreach (var t in tickets)
            t.MarcaModelo = $"{t.Marca} {t.Modelo}".Trim();

        ViewBag.FiltroEstado = estado;
        return View("~/Views/soporte_tecnico/consola_principal.cshtml", tickets);
    }

    // GET: /Modulo05/Soporte/FormAtenderTicket?id=...
    [HttpGet("FormAtenderTicket")]
    [HttpGet("Atender/{id:int}")]
    public async Task<IActionResult> FormAtenderTicket(int id)
    {
        ViewData["Title"]        = "Atención y Reparación de Ticket";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
        using var conn = fabrica.CreateConnection("05");

        var ticket = await conn.QueryFirstOrDefaultAsync<TicketAveriaItem>(
            @"SELECT i.id AS IdIncidencia, i.bien_id AS IdBien, i.registrada_por AS ReportadorId,
                     i.tecnico_id AS TecnicoId, i.fecha_registro AS FechaReporte,
                     i.fecha_cierre AS FechaCierre, i.tipo_falla AS TipoFalla,
                     i.gravedad AS Gravedad, i.descripcion AS Descripcion,
                     i.solucion_aplicada AS SolucionAplicada, i.estado AS Estado,
                     b.codigo_inventario AS CodigoBien,
                     b.descripcion AS DescripcionBien,
                     b.marca AS Marca, b.modelo AS Modelo
              FROM mod05.incidencias i
              LEFT JOIN mod03.bien b ON b.id_bien = i.bien_id
              WHERE i.id = @id LIMIT 1",
            new { id });

        if (ticket == null) return NotFound("El ticket solicitado no existe.");
        ticket.MarcaModelo = $"{ticket.Marca} {ticket.Modelo}".Trim();

        return View("~/Views/soporte_tecnico/form_atender_ticket.cshtml", ticket);
    }

    // GET: /Modulo05/Soporte/HistorialEquipos
    [HttpGet("HistorialEquipos")]
    public async Task<IActionResult> HistorialEquipos(string? filtro = null)
    {
        ViewData["Title"]        = "Historial y Trazabilidad de Equipos";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
        using var conn = fabrica.CreateConnection("05");

        string sql = @"
            SELECT b.id_bien AS IdBien, b.codigo_inventario AS Cbi, b.descripcion AS Descripcion,
                   cb.nombre AS TipoBien, b.marca AS Marca, b.modelo AS Modelo,
                   b.serie AS Serie, b.estado AS Estado,
                   am.nombre AS AmbienteAsignado,
                   COUNT(i.id) AS TotalFallasRegistradas
            FROM mod03.bien b
            LEFT JOIN mod03.clasificaciones_bien cb ON cb.id_clasificacion = b.id_clasificacion
            LEFT JOIN mod03.asignacion asig ON asig.id_bien = b.id_bien AND asig.estado = 'Activa'
            LEFT JOIN mod03.ambiente am ON am.id_ambiente = asig.id_ambiente
            LEFT JOIN mod05.incidencias i ON i.bien_id = b.id_bien";

        if (!string.IsNullOrEmpty(filtro))
            sql += " WHERE b.codigo_inventario ILIKE @filtro OR b.serie ILIKE @filtro OR b.descripcion ILIKE @filtro";

        sql += " GROUP BY b.id_bien, b.codigo_inventario, b.descripcion, cb.nombre, b.marca, b.modelo, b.serie, b.estado, am.nombre ORDER BY b.codigo_inventario";

        var equipos = (await conn.QueryAsync<ActivoHardwareItem>(sql,
            string.IsNullOrEmpty(filtro) ? null : new { filtro = $"%{filtro}%" })).AsList();

        ViewBag.Filtro = filtro;
        return View("~/Views/soporte_tecnico/historial_equipos.cshtml", equipos);
    }

    // GET: /Modulo05/Soporte/EscanearActivo?codigo=...
    [HttpGet("EscanearActivo")]
    public async Task<IActionResult> EscanearActivo(string codigo)
    {
        if (string.IsNullOrWhiteSpace(codigo))
            return Json(new { success = false, message = "Ingrese o escanee un código de activo." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            var activo = await conn.QueryFirstOrDefaultAsync<ActivoHardwareItem>(
                @"SELECT b.id_bien AS IdBien, b.codigo_inventario AS Cbi, b.descripcion AS Descripcion,
                         cb.nombre AS TipoBien, b.marca AS Marca, b.modelo AS Modelo,
                         b.serie AS Serie, b.estado AS Estado,
                         am.nombre AS AmbienteAsignado,
                         COUNT(i.id) AS TotalFallasRegistradas
                  FROM mod03.bien b
                  LEFT JOIN mod03.clasificaciones_bien cb ON cb.id_clasificacion = b.id_clasificacion
                  LEFT JOIN mod03.asignacion asig ON asig.id_bien = b.id_bien AND asig.estado = 'Activa'
                  LEFT JOIN mod03.ambiente am ON am.id_ambiente = asig.id_ambiente
                  LEFT JOIN mod05.incidencias i ON i.bien_id = b.id_bien
                  WHERE b.codigo_inventario = @codigo OR b.serie = @codigo
                  GROUP BY b.id_bien, b.codigo_inventario, b.descripcion, cb.nombre, b.marca, b.modelo, b.serie, b.estado, am.nombre
                  LIMIT 1",
                new { codigo = codigo.Trim() });

            if (activo != null)
                return Json(new
                {
                    success       = true,
                    idBien        = activo.IdBien,
                    cbi           = activo.Cbi,
                    descripcion   = activo.Descripcion,
                    tipo          = activo.TipoBien,
                    marca         = activo.Marca,
                    modelo        = activo.Modelo,
                    serie         = activo.Serie,
                    estado        = activo.Estado,
                    ambiente      = activo.AmbienteAsignado,
                    totalFallas   = activo.TotalFallasRegistradas
                });

            return Json(new { success = false, message = $"No se encontró equipo con código/serie '{codigo}'." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al escanear activo: " + ex.Message });
        }
    }

    // POST: /Modulo05/Soporte/ActualizarTicket
    [HttpPost("ActualizarTicket")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ActualizarTicket(int idIncidencia, string estado, string? solucionAplicada)
    {
        try
        {
            if (idIncidencia <= 0)
                return Json(new { success = false, message = "ID de incidencia inválido." });
            if (string.IsNullOrWhiteSpace(estado))
                return Json(new { success = false, message = "Debe seleccionar un estado." });

            int tecnicoId = UsuarioActualId ?? 1;

            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            int rows = await conn.ExecuteAsync(
                @"UPDATE mod05.incidencias
                  SET estado = @estado,
                      solucion_aplicada = @solucion,
                      tecnico_id = @tecnicoId,
                      fecha_cierre = CASE WHEN @estado IN ('Reparado','Baja Definitiva','Descartada') THEN NOW() ELSE fecha_cierre END
                  WHERE id = @id",
                new { id = idIncidencia, estado, solucion = solucionAplicada, tecnicoId });

            if (rows > 0)
            {
                MostrarAlertaExito($"Ticket #{idIncidencia} actualizado a '{estado}' correctamente.");
                return Json(new { success = true, message = $"Ticket #{idIncidencia} actualizado a estado '{estado}' correctamente." });
            }

            return Json(new { success = false, message = "No se pudo actualizar el ticket." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al actualizar ticket: " + ex.Message });
        }
    }
}
