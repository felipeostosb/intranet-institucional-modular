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

        var rolInicial = usuario.RolPrincipal;
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new(ClaimTypes.Name, usuario.NombreCompleto),
            new(ClaimTypes.Email, usuario.Email),
            new("Dni", usuario.Dni),
            new("CodigoInstitucional", usuario.CodigoInstitucional),
            new("PersonaId", usuario.PersonaId.ToString()),
            new("RolPrincipal", rolInicial),
            new("ActiveRole", rolInicial)
        };

        // Multi-rol soportado nativamente en Claims
        foreach (var rol in usuario.Roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, rol));
        }

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

    [HttpGet]
    public async Task<IActionResult> CambiarRol(string rol, string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated != true || string.IsNullOrWhiteSpace(rol))
        {
            return RedirectToAction("Index", "Home");
        }

        var rolesUsuario = User.FindAll(ClaimTypes.Role).Select(r => r.Value).ToList();
        var esDirectorOAdmin = User.IsInRole("Director") || User.IsInRole("Admin");

        // Validar que el usuario posea ese rol o tenga privilegios de dirección
        if (!rolesUsuario.Contains(rol, StringComparer.OrdinalIgnoreCase) && !esDirectorOAdmin)
        {
            return RedirectToAction("Index", "Home");
        }

        // Reconstruir claims actualizando ActiveRole
        var currentClaims = User.Claims.Where(c => c.Type != "ActiveRole").ToList();
        currentClaims.Add(new Claim("ActiveRole", rol));

        var identity = new ClaimsIdentity(currentClaims, CookieAuthenticationDefaults.AuthenticationScheme);
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
