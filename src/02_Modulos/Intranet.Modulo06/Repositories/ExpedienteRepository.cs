using Dapper;
using Intranet.Core.Contracts;

using Intranet.Modulo06.Models;

namespace Intranet.Modulo06.Repositories
{
    public class ExpedienteRepository : IExpedienteRepository
    {
        private readonly IModuleDbConnectionFactory _dbFactory;

        public ExpedienteRepository(IModuleDbConnectionFactory dbFactory)
        {
            _dbFactory = dbFactory;
        }

        public IModuleDbConnectionFactory DbFactory => _dbFactory;

        public async Task<IEnumerable<ExpedienteDashboardDto>> ObtenerExpedientesRecientesAsync()
        {
            using var connection = _dbFactory.CreateConnection("06");

            string sql = @"
                SELECT 
                    e.numero_expediente AS NumeroExpediente,
                    p.nombres || ' ' || p.apellidos AS NombreCompleto,
                    c.nombre AS Carrera,
                    t.denominacion AS Modalidad,
                    e.estado AS Estado
                FROM mod06.expedientes_06 e
                INNER JOIN core.personas p ON e.solicitante_persona_id = p.id
                INNER JOIN mod06.tramites_tupa_06 t ON e.tramite_tupa_id = t.id
                LEFT JOIN core.estudiantes est ON p.id = est.persona_id
                LEFT JOIN core.carreras c ON est.carrera_id = c.id
                ORDER BY e.fecha_ingreso DESC
                LIMIT 10;";

            return await connection.QueryAsync<ExpedienteDashboardDto>(sql);
        }
        public async Task<EgresadoDetalleDto?> BuscarEgresadoPorDniAsync(string dni)
        {
            using var connection = _dbFactory.CreateConnection("06");

            string sql = @"
                SELECT 
                    p.dni AS Dni,
                    p.nombres || ' ' || p.apellidos AS NombreCompleto,
                    c.nombre AS Carrera,
                    e.estado AS EstadoGeneral,
                    e.id AS IdExpediente
                FROM mod06.expedientes_06 e
                INNER JOIN core.personas p ON e.solicitante_persona_id = p.id
                LEFT JOIN core.estudiantes est ON p.id = est.persona_id
                LEFT JOIN core.carreras c ON est.carrera_id = c.id
                WHERE p.dni = @dni
                LIMIT 1;";

            return await connection.QueryFirstOrDefaultAsync<EgresadoDetalleDto>(sql, new { dni });
        }
    }
}
