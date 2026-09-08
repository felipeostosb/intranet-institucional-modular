using Microsoft.AspNetCore.Mvc;

namespace Intranet.Web.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Panel Principal";
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error(int? statusCode = null)
    {
        ViewData["StatusCode"] = statusCode ?? 500;
        ViewData["Title"] = $"Error {statusCode ?? 500}";
        return View();
    }
}
