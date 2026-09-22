using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Intranet.Core.Contracts;
using Intranet.Modulo06.Repositories;

namespace Intranet.Modulo06
{
    public class Modulo06Startup : IModuloStartup
    {
        // Esta es la firma exacta que espera la arquitectura del líder técnico
        public void ConfigureServices(IServiceCollection services, IConfiguration configuration)
        {
            // Registramos tu repositorio de Dapper
            services.AddScoped<IExpedienteRepository, ExpedienteRepository>();
        }
    }
}
