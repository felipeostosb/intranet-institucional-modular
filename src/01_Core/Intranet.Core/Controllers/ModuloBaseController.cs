using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Intranet.Core.Controllers;

[Authorize]
public abstract class ModuloBaseController : Controller
{
    public int? UsuarioActualId
    {
        get
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(idClaim, out var id) ? id : null;
        }
    }

    public int? PersonaActualId
    {
        get
        {
            var idClaim = User.FindFirst("PersonaId")?.Value;
            return int.TryParse(idClaim, out var id) ? id : null;
        }
    }

    public string UsuarioActualDni => User.FindFirst("Dni")?.Value ?? string.Empty;
    public string UsuarioActualCodigo => User.FindFirst("CodigoInstitucional")?.Value ?? string.Empty;
    public string UsuarioActualNombre => User.FindFirst(ClaimTypes.Name)?.Value ?? "Invitado";
    public string UsuarioActualRol => User.FindFirst("ActiveRole")?.Value ?? User.FindFirst(ClaimTypes.Role)?.Value ?? "Alumno";
    public IEnumerable<string> UsuarioActualRoles => User.FindAll(ClaimTypes.Role).Select(c => c.Value);

    public bool EstaAutenticado => User.Identity?.IsAuthenticated ?? false;
    
    // Roles Institucionales IESTP Argentina
    public bool EsAdmin => User.IsInRole("Admin");
    public bool EsDirector => User.IsInRole("Director") || UsuarioActualRol.Equals("Director", StringComparison.OrdinalIgnoreCase) || EsAdmin;
    public bool EsCoordinador => User.IsInRole("Coordinador") || UsuarioActualRol.Equals("Coordinador", StringComparison.OrdinalIgnoreCase) || EsAdmin;
    public bool EsSecretaria => User.IsInRole("Secretaria") || UsuarioActualRol.Equals("Secretaria", StringComparison.OrdinalIgnoreCase) || EsAdmin;
    public bool EsTesoreria => User.IsInRole("Tesoreria") || UsuarioActualRol.Equals("Tesoreria", StringComparison.OrdinalIgnoreCase) || EsAdmin;
    public bool EsDocente => User.IsInRole("Docente") || UsuarioActualRol.Equals("Docente", StringComparison.OrdinalIgnoreCase) || EsCoordinador || EsAdmin;
    public bool EsAlumno => User.IsInRole("Alumno") || UsuarioActualRol.Equals("Alumno", StringComparison.OrdinalIgnoreCase);

    public bool TieneRol(string rol) => User.IsInRole(rol) || UsuarioActualRol.Equals(rol, StringComparison.OrdinalIgnoreCase);

    protected void MostrarAlertaExito(string mensaje)
    {
        TempData["AlertaTipo"] = "success";
        TempData["AlertaMensaje"] = mensaje;
    }

    protected void MostrarAlertaError(string mensaje)
    {
        TempData["AlertaTipo"] = "error";
        TempData["AlertaMensaje"] = mensaje;
    }

    protected void MostrarAlertaInfo(string mensaje)
    {
        TempData["AlertaTipo"] = "info";
        TempData["AlertaMensaje"] = mensaje;
    }
}
