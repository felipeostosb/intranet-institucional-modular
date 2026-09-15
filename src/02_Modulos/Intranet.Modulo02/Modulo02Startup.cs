using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;
using Intranet.Modulo02.Services;

namespace Intranet.Modulo02;

/// <summary>
/// Registrador de Servicios del Módulo 02 (Asistencia Estudiantil & Docente).
/// </summary>
public class Modulo02Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<IAsistenciaService, AsistenciaService>();
    }
}
