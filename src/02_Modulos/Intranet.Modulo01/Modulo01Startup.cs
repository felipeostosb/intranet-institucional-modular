using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Intranet.Core.Contracts;
using Intranet.Modulo01.Services;

namespace Intranet.Modulo01;

/// <summary>
/// Registrador de Servicios del Módulo 01.
/// Agrega aquí tus servicios o repositorios propios. El sistema los cargará automáticamente.
/// </summary>
public class Modulo01Startup : IModuloStartup
{
    public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
    {
        // Matrícula Académica — proceso Cero Filas (Equipo 01)
        services.AddScoped<IMatriculaService, MatriculaService>();
    }
}
