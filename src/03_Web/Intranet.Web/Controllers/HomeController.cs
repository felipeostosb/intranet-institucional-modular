using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;

namespace Intranet.Web.Controllers;

[Authorize]
public class HomeController : ModuloBaseController
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Panel Principal";
        return View();
    }

    [AllowAnonymous]
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error(int? statusCode = null)
    {
        ViewData["StatusCode"] = statusCode ?? 500;
        ViewData["Title"] = $"Error {statusCode ?? 500}";
        return View();
    }
}

