using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;
using Intranet.Modulo03.Services;

namespace Intranet.Modulo03;

public class Modulo03Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<InventarioService>();
        services.AddScoped<ExcelReportService>();
    }
}
