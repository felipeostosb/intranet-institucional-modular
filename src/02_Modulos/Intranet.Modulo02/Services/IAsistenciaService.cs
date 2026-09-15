using Intranet.Modulo02.Models;

namespace Intranet.Modulo02.Services;

public interface IAsistenciaService
{
    Task<DashboardAsistenciaViewModel> GetDashboardAsync(int? personaId, string rol);
    Task<IEnumerable<ClaseDocenteCardDto>> GetClasesDocenteAsync(int docenteId, int? periodoId = null);
    Task<IEnumerable<SemanaSelectorDto>> GetSemanasDeClaseAsync(int claseId);
    Task<MatrizAsistenciaViewModel?> GetMatrizAsistenciaClaseAsync(int claseId);
    Task<IEnumerable<SesionClaseDto>> GetSesionesDocenteAsync(int docenteId, int? periodoId = null);
    Task<IEnumerable<SesionClaseDto>> GetSesionesRecientesAsync(int limite = 10);
    Task<SesionClaseDto?> GetSesionPorIdAsync(int sesionId);
    Task<IEnumerable<AlumnoAsistenciaItemDto>> GetAlumnosParaSesionAsync(int sesionId, int unidadDidacticaId);
    Task<bool> GuardarAsistenciaSesionAsync(GuardarAsistenciaRequestDto request, int? usuarioId);
    Task<IEnumerable<ResumenAsistenciaEstudianteDto>> GetResumenEstudianteAsync(int estudianteId, int? periodoId = null);
    Task<IEnumerable<AsistenciaHistorialItemDto>> GetHistorialDetalladoEstudianteAsync(int estudianteId, int unidadDidacticaId);
    Task<IEnumerable<JustificacionDto>> GetJustificacionesAsync(int? estudianteId = null, string? estado = null);
    Task<bool> SolicitarJustificacionAsync(CrearJustificacionDto dto, int estudianteId);
    Task<bool> ResolverJustificacionAsync(ResolverJustificacionDto dto, int docenteId);
    Task<IEnumerable<AlertaDpiDto>> GetAlertasDpiAsync(int? carreraId = null, int? periodoId = null);
    Task<int?> GetDocenteIdPorPersonaAsync(int personaId);
    Task<int?> GetEstudianteIdPorPersonaAsync(int personaId);
}
