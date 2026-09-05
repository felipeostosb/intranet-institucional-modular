using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;

namespace Intranet.Modulo04;

/// <summary>
/// Registrador de Servicios del Módulo 04.
/// Agrega aquí tus servicios o repositorios propios. El sistema los cargará automáticamente.
/// </summary>
public class Modulo04Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        // Ejemplo:
        // services.AddScoped<IModulo04Service, Modulo04Service>();
    }
}
