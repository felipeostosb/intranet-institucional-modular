using Intranet.Modulo06.Models;

namespace Intranet.Modulo06.Repositories
{
    public interface IExpedienteRepository
    {
        Task<IEnumerable<ExpedienteDashboardDto>> ObtenerExpedientesRecientesAsync();
        Task<EgresadoDetalleDto?> BuscarEgresadoPorDniAsync(string dni); // Nuevo método
    }
}
