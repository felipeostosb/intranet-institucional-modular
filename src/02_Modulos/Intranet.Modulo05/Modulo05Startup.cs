using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;

namespace Intranet.Modulo05;

/// <summary>
/// Registrador de Servicios del Módulo 05.
/// Agrega aquí tus servicios o repositorios propios. El sistema los cargará automáticamente.
/// </summary>
public class Modulo05Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        // Ejemplo:
        // services.AddScoped<IModulo05Service, Modulo05Service>();
    }
}
