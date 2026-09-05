using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Contracts;

namespace Intranet.Web.Controllers;

public class AccountController : Controller
{
    private readonly IUsuarioService _usuarioService;

    public AccountController(IUsuarioService usuarioService)
    {
        _usuarioService = usuarioService;
    }

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction("Index", "Home");
        }

        ViewData["ReturnUrl"] = returnUrl;
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(string identificador, string password, string? returnUrl = null)
    {
        if (string.IsNullOrWhiteSpace(identificador) || string.IsNullOrWhiteSpace(password))
        {
            ViewBag.Error = "Por favor ingrese su DNI / Código y contraseña.";
            return View();
        }

        var esValido = await _usuarioService.ValidarCredencialesAsync(identificador.Trim(), password.Trim());
        if (!esValido)
        {
            ViewBag.Error = "Credenciales incorrectas. Verifique su DNI o contraseña.";
            return View();
        }

        var usuario = await _usuarioService.ObtenerPorDniAsync(identificador.Trim())
                      ?? await _usuarioService.ObtenerPorCodigoAsync(identificador.Trim());

        if (usuario == null)
        {
            ViewBag.Error = "Usuario no encontrado.";
            return View();
        }

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new(ClaimTypes.Name, usuario.NombreCompleto),
            new(ClaimTypes.Email, usuario.Email),
            new(ClaimTypes.Role, usuario.Rol),
            new("Dni", usuario.Dni),
            new("CodigoInstitucional", usuario.CodigoInstitucional)
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var principal = new ClaimsPrincipal(identity);

        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal, new AuthenticationProperties
        {
            IsPersistent = true,
            ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7)
        });

        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
        {
            return Redirect(returnUrl);
        }

        return RedirectToAction("Index", "Home");
    }

    [HttpPost]
    [HttpGet]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction("Login", "Account");
    }

    [HttpGet]
    public IActionResult AccessDenied()
    {
        return View();
    }
}
