using System.Reflection;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Intranet.Modulo08.Controllers;

/// <summary>
/// Controlador principal de entrada para el Módulo 08 (Seguridad, Roles y Control de Acceso).
/// Permite el descubrimiento en Intranet.Web, la redirección al login y la entrega de activos estáticos.
/// </summary>
[AllowAnonymous]
[Route("Modulo08")]
public class Modulo08Controller : Controller
{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        return RedirectToAction("Index", "Login");
    }

    [HttpGet("assets/{**assetPath}")]
    [HttpGet("/Modulo08/assets/{**assetPath}")]
    public IActionResult GetAsset(string? assetPath)
    {
        if (string.IsNullOrWhiteSpace(assetPath))
        {
            return NotFound();
        }

        // Normalizar y sanitizar ruta para evitar directory traversal
        var sanitized = assetPath.Replace('\\', '/').TrimStart('/');
        if (sanitized.Contains(".."))
        {
            return BadRequest("Ruta de archivo no permitida.");
        }

        var contentType = GetContentType(sanitized);

        // 1. Probar rutas físicas del sistema de archivos
        var candidatePaths = new List<string>
        {
            Path.Combine(AppContext.BaseDirectory, "wwwroot", sanitized.Replace('/', Path.DirectorySeparatorChar)),
            Path.Combine(AppContext.BaseDirectory, "wwwroot", "_content", "Intranet.Modulo08", sanitized.Replace('/', Path.DirectorySeparatorChar)),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "02_Modulos", "Intranet.Modulo08", "wwwroot", sanitized.Replace('/', Path.DirectorySeparatorChar)),
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "02_Modulos", "Intranet.Modulo08", "wwwroot", sanitized.Replace('/', Path.DirectorySeparatorChar)),
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "src", "02_Modulos", "Intranet.Modulo08", "wwwroot", sanitized.Replace('/', Path.DirectorySeparatorChar))
        };

        foreach (var path in candidatePaths)
        {
            try
            {
                var fullPath = Path.GetFullPath(path);
                if (System.IO.File.Exists(fullPath))
                {
                    return PhysicalFile(fullPath, contentType);
                }
            }
            catch
            {
                // Ignorar excepciones al resolver rutas candidatas y continuar con la siguiente
            }
        }

        // 2. Fallback a Recursos Embebidos (EmbeddedResource) del ensamblado Intranet.Modulo08
        var assembly = typeof(Modulo08Controller).Assembly;
        var resourceNames = assembly.GetManifestResourceNames();

        var normalizedAssetDot = sanitized.Replace('/', '.');
        var targetResource = resourceNames.FirstOrDefault(rn =>
            rn.EndsWith($".wwwroot.{normalizedAssetDot}", StringComparison.OrdinalIgnoreCase) ||
            rn.EndsWith($".{normalizedAssetDot}", StringComparison.OrdinalIgnoreCase) ||
            rn.Equals($"Intranet.Modulo08.wwwroot.{normalizedAssetDot}", StringComparison.OrdinalIgnoreCase));

        if (targetResource != null)
        {
            var stream = assembly.GetManifestResourceStream(targetResource);
            if (stream != null)
            {
                return File(stream, contentType);
            }
        }

        return NotFound($"Recurso '{sanitized}' no encontrado en activos físicos ni embebidos.");
    }

    private static string GetContentType(string path)
    {
        var ext = Path.GetExtension(path).ToLowerInvariant();
        return ext switch
        {
            ".css" => "text/css; charset=utf-8",
            ".js" => "application/javascript; charset=utf-8",
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".gif" => "image/gif",
            ".svg" => "image/svg+xml",
            ".ico" => "image/x-icon",
            ".woff" => "font/woff",
            ".woff2" => "font/woff2",
            ".ttf" => "font/ttf",
            ".json" => "application/json",
            ".html" => "text/html; charset=utf-8",
            _ => "application/octet-stream"
        };
    }
}
