using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;

namespace Intranet.Modulo06;

/// <summary>
/// Registrador de Servicios del Módulo 06.
/// Agrega aquí tus servicios o repositorios propios. El sistema los cargará automáticamente.
/// </summary>
public class Modulo06Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        // Ejemplo:
        // services.AddScoped<IModulo06Service, Modulo06Service>();
    }
}
