using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;
using Intranet.Core.Controllers;
using Intranet.Modulo05.Models;

namespace Intranet.Modulo05.Controllers;

[Route("Modulo05/[controller]")]
public class AveriaDocenteController : ModuloBaseController
{
    // GET: /Modulo05/AveriaDocente   o   /Modulo05/AveriaDocente/Reporte
    [HttpGet("")]
    [HttpGet("Reporte")]
    [HttpGet("Create")]
    public IActionResult FormReporte()
    {
        ViewData["Title"]        = "Reporte Rápido de Averías de Aula";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;
        return View("~/Views/averias_docente/form_reporte.cshtml");
    }

    // GET: /Modulo05/AveriaDocente/MisReportes
    [HttpGet("MisReportes")]
    public async Task<IActionResult> MisReportes()
    {
        ViewData["Title"]        = "Mis Reportes de Averías";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"]   = UsuarioActualRol;
        ViewData["RolesUsuario"] = User.FindFirst("ActiveRole")?.Value ?? UsuarioActualRol;

        var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
        using var conn = fabrica.CreateConnection("05");

        int usuarioId = UsuarioActualId ?? 0;
        var reportes = (await conn.QueryAsync<TicketAveriaItem>(
            @"SELECT r.id AS IdIncidencia, r.bien_id AS IdBien, r.reportado_por AS ReportadorId,
                     r.fecha_reporte AS FechaReporte, r.tipo_falla AS TipoFalla,
                     r.urgencia AS Gravedad, r.descripcion AS Descripcion,
                     r.estado AS Estado,
                     b.codigo_inventario AS CodigoBien, b.descripcion AS DescripcionBien,
                     b.marca AS Marca, b.modelo AS Modelo
              FROM mod05.reportes_incidencia r
              LEFT JOIN mod03.bien b ON b.id_bien = r.bien_id
              WHERE r.reportado_por = @usuarioId
              ORDER BY r.fecha_reporte DESC",
            new { usuarioId })).AsList();

        foreach (var t in reportes)
            t.MarcaModelo = $"{t.Marca} {t.Modelo}".Trim();

        return View("~/Views/averias_docente/mis_reportes.cshtml", reportes);
    }

    // POST: /Modulo05/AveriaDocente/GuardarReporte
    [HttpPost("GuardarReporte")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> GuardarReporte(
        string? codigoBien, string? ambiente, string? tipoFalla,
        string? gravedad, string? descripcion)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(tipoFalla))
                return Json(new { success = false, message = "Debe indicar el tipo de falla detectada." });
            if (string.IsNullOrWhiteSpace(descripcion))
                return Json(new { success = false, message = "Debe ingresar una descripción detallada de la avería." });

            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");

            // Buscar bien por CBI o serie (si se indicó)
            int? idBien = null;
            if (!string.IsNullOrWhiteSpace(codigoBien))
            {
                idBien = await conn.ExecuteScalarAsync<int?>(
                    "SELECT id_bien FROM mod03.bien WHERE codigo_inventario = @c OR serie = @c LIMIT 1",
                    new { c = codigoBien.Trim() });
            }

            string descCompleta = descripcion.Trim();
            if (!string.IsNullOrWhiteSpace(ambiente))
                descCompleta = $"[Ambiente/Aula: {ambiente.Trim()}] {descCompleta}";

            string urgencia = string.IsNullOrWhiteSpace(gravedad) ? "Media" : gravedad.Trim();
            int usuarioId   = UsuarioActualId ?? 1;

            // Insertar en mod05.reportes_incidencia (tabla correcta del esquema)
            int rows = await conn.ExecuteAsync(
                @"INSERT INTO mod05.reportes_incidencia
                    (reportado_por, bien_id, equipo_descripcion, tipo_falla, descripcion, urgencia)
                  VALUES (@usuarioId, @idBien, @equipoDesc, @tipoFalla, @descripcion, @urgencia)",
                new
                {
                    usuarioId,
                    idBien     = idBien.HasValue ? (object)idBien.Value : null!,
                    equipoDesc = !string.IsNullOrWhiteSpace(codigoBien) ? codigoBien.Trim() : (object)null!,
                    tipoFalla  = tipoFalla.Trim(),
                    descripcion = descCompleta,
                    urgencia
                });

            if (rows > 0)
            {
                MostrarAlertaExito("¡Reporte de avería enviado exitosamente a la Jefatura de Soporte!");
                return Json(new { success = true, message = "¡Reporte de avería enviado exitosamente a la Jefatura de Soporte!" });
            }

            return Json(new { success = false, message = "No se pudo registrar el reporte de avería." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error al registrar reporte: " + ex.Message });
        }
    }

    // GET: /Modulo05/AveriaDocente/BuscarEquipo?criterio=...
    [HttpGet("BuscarEquipo")]
    public async Task<IActionResult> BuscarEquipo(string criterio)
    {
        if (string.IsNullOrWhiteSpace(criterio))
            return Json(new { success = false, message = "Ingrese un código de bien o serie." });

        try
        {
            var fabrica = HttpContext.RequestServices.GetRequiredService<IModuleDbConnectionFactory>();
            using var conn = fabrica.CreateConnection("05");
            var activo = await conn.QueryFirstOrDefaultAsync<ActivoHardwareItem>(
                @"SELECT b.id_bien AS IdBien, b.codigo_inventario AS Cbi, b.descripcion AS Descripcion,
                         b.marca AS Marca, b.modelo AS Modelo, b.serie AS Serie,
                         am.nombre AS AmbienteAsignado
                  FROM mod03.bien b
                  LEFT JOIN mod03.asignacion asig ON asig.id_bien = b.id_bien AND asig.estado = 'Activa'
                  LEFT JOIN mod03.ambiente am ON am.id_ambiente = asig.id_ambiente
                  WHERE b.codigo_inventario = @c OR b.serie = @c
                  LIMIT 1",
                new { c = criterio.Trim() });

            if (activo != null)
                return Json(new
                {
                    success     = true,
                    idBien      = activo.IdBien,
                    cbi         = activo.Cbi,
                    descripcion = activo.Descripcion,
                    marcaModelo = $"{activo.Marca} {activo.Modelo}".Trim(),
                    serie       = activo.Serie,
                    ambiente    = activo.AmbienteAsignado
                });

            return Json(new { success = false, message = "Equipo no encontrado en inventario." });
        }
        catch (Exception ex)
        {
            return Json(new { success = false, message = "Error en búsqueda: " + ex.Message });
        }
    }
}
