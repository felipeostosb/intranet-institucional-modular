using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace Intranet.Core.Controllers;

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

    public string UsuarioActualDni => User.FindFirst("Dni")?.Value ?? string.Empty;
    public string UsuarioActualCodigo => User.FindFirst("CodigoInstitucional")?.Value ?? string.Empty;
    public string UsuarioActualNombre => User.FindFirst(ClaimTypes.Name)?.Value ?? "Invitado";
    public string UsuarioActualRol => User.FindFirst(ClaimTypes.Role)?.Value ?? "Alumno";

    public bool EstaAutenticado => User.Identity?.IsAuthenticated ?? false;
    
    // Roles Institucionales IESTP Argentina
    public bool EsAdmin => User.IsInRole("Admin");
    public bool EsDirector => User.IsInRole("Director") || EsAdmin;
    public bool EsCoordinador => User.IsInRole("Coordinador") || EsAdmin;
    public bool EsSecretaria => User.IsInRole("Secretaria") || EsAdmin;
    public bool EsTesoreria => User.IsInRole("Tesoreria") || EsAdmin;
    public bool EsDocente => User.IsInRole("Docente") || EsCoordinador || EsAdmin;
    public bool EsAlumno => User.IsInRole("Alumno");

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
