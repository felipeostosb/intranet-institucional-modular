using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03.Controllers;

[Route("Modulo03/[controller]")]
public class ReportesController : ModuloBaseController
{
    private readonly InventarioService _service;
    private readonly ExcelReportService _excel;

    public ReportesController(InventarioService service, ExcelReportService excel)
    {
        _service = service;
        _excel = excel;
    }

    [HttpGet("")]
    public IActionResult Index()
    {
        var bienes = _service.ObtenerInventario();
        return View(bienes);
    }

    [HttpGet("Excel")]
    public IActionResult Excel()
    {
        var bienes = _service.ObtenerInventario();
        var bytes = _excel.GenerarInventarioXlsx(bienes);
        return File(bytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"Inventario_Modulo03_{DateTime.Now:yyyyMMdd_HHmm}.xlsx");
    }
}
