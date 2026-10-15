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
        services.AddScoped<IMatriculaServicio, MatriculaServicio>();
        // Matriculatura de Secretaría — cierre del flujo Reserva de Matrícula (TM05/CT13)
        services.AddScoped<IMatriculaturaServicio, MatriculaturaServicio>();
        // Envío de la ficha PDF al correo del estudiante (MailKit; bitácora en fichas_enviadas)
        services.AddScoped<IServicioCorreoFicha, ServicioCorreoFicha>();
    }
}
