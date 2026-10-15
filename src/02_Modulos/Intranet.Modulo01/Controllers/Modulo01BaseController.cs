using System.Security.Claims;
using Intranet.Core.Controllers;

namespace Intranet.Modulo01.Controllers;

/// <summary>
/// Base local del Módulo 01: decide por el ROL ACTIVO (el "sombrero" elegido en el
/// selector de contexto), no por la lista completa de roles.
///
/// El core (ModuloBaseController) define p. ej. EsAlumno => IsInRole("Alumno") || ActiveRole:
/// el primer término mira la LISTA de roles, así que un usuario multi-rol (p. ej. el demo
/// Admin+Docente+Alumno) es "alumno" en TODOS los modos y el sombrero queda decorativo —
/// bug verificado E2E: en Modo Tesorería la portada seguía mostrando "Mi Matrícula".
/// Aquí el sombrero manda: vistas y guards siguen al rol activo, y el sombrero Admin
/// actúa como superusuario. El core queda intacto (los 8 módulos lo comparten).
/// </summary>
public abstract class Modulo01BaseController : ModuloBaseController
{
    /// <summary>Rol activo (sombrero elegido). Fuente única para vistas y guards.</summary>
    public new string UsuarioActualRol =>
        User.FindFirst("ActiveRole")?.Value
        ?? User.FindFirst(ClaimTypes.Role)?.Value ?? "Alumno";

    // Sombrero manda: SOLO el rol activo decide. Admin (sombrero) = superusuario.
    public new bool EsAdmin => UsuarioActualRol.Equals("Admin", StringComparison.OrdinalIgnoreCase);
    public new bool EsDirector => EsAdmin || UsuarioActualRol.Equals("Director", StringComparison.OrdinalIgnoreCase);
    public new bool EsSecretaria => EsAdmin || UsuarioActualRol.Equals("Secretaria", StringComparison.OrdinalIgnoreCase);
    public new bool EsTesoreria => EsAdmin || UsuarioActualRol.Equals("Tesoreria", StringComparison.OrdinalIgnoreCase);
    public new bool EsAlumno => UsuarioActualRol.Equals("Alumno", StringComparison.OrdinalIgnoreCase);

    /// <summary>
    /// ¿El rol ACTIVO tiene funciones en este módulo? Decide la puerta de entrada:
    /// un rol fuera de la lista recibe la vista SinAcceso (antes veía datos de
    /// terceros: un Docente por URL directa leía matrículas ajenas — fuga E2E).
    /// </summary>
    public bool AccedeAlModulo => EsAlumno || EsSecretaria || EsTesoreria || EsDirector || EsAdmin;
}
