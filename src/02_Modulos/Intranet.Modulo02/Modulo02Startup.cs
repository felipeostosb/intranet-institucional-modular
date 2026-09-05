using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;

namespace Intranet.Modulo02;

/// <summary>
/// Registrador de Servicios del Módulo 02.
/// Agrega aquí tus servicios o repositorios propios. El sistema los cargará automáticamente.
/// </summary>
public class Modulo02Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        // Ejemplo:
        // services.AddScoped<IModulo02Service, Modulo02Service>();
    }
}
