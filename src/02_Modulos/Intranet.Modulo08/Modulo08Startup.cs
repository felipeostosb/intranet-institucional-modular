using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;

namespace Intranet.Modulo08;

/// <summary>
/// Registrador de Servicios del Módulo 08.
/// Agrega aquí tus servicios o repositorios propios. El sistema los cargará automáticamente.
/// </summary>
public class Modulo08Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        // Ejemplo:
        // services.AddScoped<IModulo08Service, Modulo08Service>();
    }
}
