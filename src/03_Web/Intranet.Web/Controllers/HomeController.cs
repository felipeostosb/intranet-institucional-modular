using Microsoft.AspNetCore.Mvc;

namespace Intranet.Web.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Panel Principal";
        return View();
    }

    public IActionResult Error()
    {
        return View();
    }
}
