using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using System.Text.RegularExpressions;

namespace Intranet.Web.Controllers;

public class TutorialItem
{
    public int Id { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string YoutubeUrl { get; set; } = string.Empty;
    public string YoutubeVideoId { get; set; } = string.Empty;
    public string ModuloCodigo { get; set; } = "General"; // "General", "Modulo00", ..., "Modulo09"
    public string ModuloNombre { get; set; } = "General / Inducción";
    public string Autor { get; set; } = string.Empty;
    public string Nivel { get; set; } = "Intermedio"; // "Básico", "Intermedio", "Avanzado"
    public DateTime FechaPublicacion { get; set; } = DateTime.Now;
    public int Vistas { get; set; } = 0;
}

[AllowAnonymous]
[Route("Docs")]
[Route("Tutoriales")]
[Route("Documentacion")]
public class DocsController : ModuloBaseController
{
    private static readonly List<TutorialItem> _tutoriales = new()
    {
        new TutorialItem
        {
            Id = 1,
            Titulo = "Inducción Rápida: Cómo Clonar, Usar dev.sh y Configurar PostgreSQL",
            Descripcion = "Guía completa de 5 minutos para nuevos desarrolladores: clonar repositorio, ejecutar dev.sh, crear rama propia y configurar appsettings.Local.json con la base de datos de la nube.",
            YoutubeUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            YoutubeVideoId = "dQw4w9WgXcQ",
            ModuloCodigo = "General",
            ModuloNombre = "General / Onboarding Dev",
            Autor = "Felipe (PM & Lead)",
            Nivel = "Básico",
            FechaPublicacion = DateTime.Now.AddDays(-2),
            Vistas = 48
        },
        new TutorialItem
        {
            Id = 2,
            Titulo = "Módulo 00: Arquitectura de Seguridad, Roles y Protección de Rutas",
            Descripcion = "Explicación del flujo de autenticación, claims de rol, manejo de contraseñas y consultas soberanas al esquema mod00 en PostgreSQL.",
            YoutubeUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            YoutubeVideoId = "dQw4w9WgXcQ",
            ModuloCodigo = "Modulo00",
            ModuloNombre = "Módulo 00 (Seguridad & Roles)",
            Autor = "Toro (Líder Mod 00)",
            Nivel = "Intermedio",
            FechaPublicacion = DateTime.Now.AddDays(-1),
            Vistas = 32
        },
        new TutorialItem
        {
            Id = 3,
            Titulo = "Módulo 02: Registro de Asistencias de 18 Semanas y Alertas DPI",
            Descripcion = "Cómo funciona el registro de asistencia por sesión de clase, cálculo automático de inasistencias (>30% DPI) y diseño de la sábana de 18 semanas en Razor.",
            YoutubeUrl = "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            YoutubeVideoId = "dQw4w9WgXcQ",
            ModuloCodigo = "Modulo02",
            ModuloNombre = "Módulo 02 (Asistencia)",
            Autor = "Sheyla (Líder Mod 02)",
            Nivel = "Avanzado",
            FechaPublicacion = DateTime.Now,
            Vistas = 29
        }
    };

    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index(string? modulo = null, string? buscar = null)
    {
        ViewData["Title"] = "Centro de Documentación & Tutoriales";
        ViewData["ModuloSeleccionado"] = modulo ?? "Todos";
        ViewData["Buscar"] = buscar ?? "";

        var query = _tutoriales.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(modulo) && modulo != "Todos")
        {
            query = query.Where(t => t.ModuloCodigo.Equals(modulo, StringComparison.OrdinalIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(buscar))
        {
            var b = buscar.ToLowerInvariant();
            query = query.Where(t => t.Titulo.ToLowerInvariant().Contains(b) || 
                                     t.Descripcion.ToLowerInvariant().Contains(b) ||
                                     t.Autor.ToLowerInvariant().Contains(b));
        }

        return View(query.OrderByDescending(t => t.FechaPublicacion).ToList());
    }

    [HttpGet("ProductOwner")]
    [HttpGet("FichaPO")]
    [HttpGet("Requerimientos")]
    public IActionResult ProductOwner()
    {
        ViewData["Title"] = "Ficha Rápida de Requerimiento PO & Generador A4";
        return View();
    }

    [HttpPost("Agregar")]
    [ValidateAntiForgeryToken]
    public IActionResult Agregar(string titulo, string descripcion, string youtubeUrl, string moduloCodigo, string autor, string nivel)
    {
        if (string.IsNullOrWhiteSpace(titulo) || string.IsNullOrWhiteSpace(youtubeUrl))
        {
            MostrarAlertaError("El título y el enlace de YouTube son obligatorios.");
            return RedirectToAction(nameof(Index));
        }

        var videoId = ExtractYoutubeId(youtubeUrl);
        if (string.IsNullOrWhiteSpace(videoId))
        {
            MostrarAlertaError("El enlace de YouTube no parece ser válido. Usa formatos como https://youtube.com/watch?v=... o https://youtu.be/...");
            return RedirectToAction(nameof(Index));
        }

        var nombreModulo = moduloCodigo switch
        {
            "Modulo00" => "Módulo 00 (Seguridad & Roles)",
            "Modulo01" => "Módulo 01 (Admisión & Matrícula)",
            "Modulo02" => "Módulo 02 (Asistencia 18 Semanas)",
            "Modulo03" => "Módulo 03 (Calificaciones & Actas)",
            "Modulo04" => "Módulo 04 (Horarios & Aulas)",
            "Modulo05" => "Módulo 05 (Docentes & Carga)",
            "Modulo06" => "Módulo 06 (Trámites & Mesa de Partes)",
            "Modulo07" => "Módulo 07 (Bolsa de Trabajo & Prácticas)",
            "Modulo08" => "Módulo 08 (Encuestas & Tutoría)",
            "Modulo09" => "Módulo 09 (Tesorería & Pagos)",
            _ => "General / Onboarding Dev"
        };

        var nuevo = new TutorialItem
        {
            Id = _tutoriales.Count > 0 ? _tutoriales.Max(t => t.Id) + 1 : 1,
            Titulo = titulo.Trim(),
            Descripcion = descripcion?.Trim() ?? string.Empty,
            YoutubeUrl = youtubeUrl.Trim(),
            YoutubeVideoId = videoId,
            ModuloCodigo = moduloCodigo ?? "General",
            ModuloNombre = nombreModulo,
            Autor = string.IsNullOrWhiteSpace(autor) ? (UsuarioActualNombre ?? "Desarrollador") : autor.Trim(),
            Nivel = nivel ?? "Intermedio",
            FechaPublicacion = DateTime.Now,
            Vistas = 1
        };

        _tutoriales.Insert(0, nuevo);
        MostrarAlertaExito("¡Videotutorial publicado con éxito en el Centro de Documentación!");
        return RedirectToAction(nameof(Index), new { modulo = moduloCodigo });
    }

    private static string ExtractYoutubeId(string url)
    {
        if (string.IsNullOrWhiteSpace(url)) return string.Empty;

        // Match formats:
        // https://www.youtube.com/watch?v=VIDEO_ID
        // https://youtu.be/VIDEO_ID
        // https://www.youtube.com/embed/VIDEO_ID
        var match = Regex.Match(url, @"(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([\w-]{11})");
        if (match.Success && match.Groups.Count > 1)
        {
            return match.Groups[1].Value;
        }

        // Si ya es un ID de 11 caracteres
        if (url.Trim().Length == 11 && !url.Contains("/") && !url.Contains("."))
        {
            return url.Trim();
        }

        return string.Empty;
    }
}
