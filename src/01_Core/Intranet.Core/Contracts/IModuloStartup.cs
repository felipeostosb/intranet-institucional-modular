using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Intranet.Core.Contracts;

/// <summary>
/// Contrato para que cada uno de los 9 módulos registre sus propios servicios,
/// repositorios o dependencias SIN necesidad de modificar Program.cs.
/// El sistema escaneará automáticamente todas las clases que implementen esta interfaz.
/// </summary>
public interface IModuloStartup
{
    void ConfigureServices(IServiceCollection services, IConfiguration configuration);
}
