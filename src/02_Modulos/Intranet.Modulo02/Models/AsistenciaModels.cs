using System.ComponentModel.DataAnnotations;

namespace Intranet.Modulo02.Models;

/// <summary>
/// Detección inteligente de la clase activa en curso para el docente (Toma en 1 Clic)
/// </summary>
public class ClaseActivaDocenteDto
{
    public int SesionId { get; set; }
    public int ClaseDocenteId { get; set; }
    public int UnidadDidacticaId { get; set; }
    public string UnidadDidacticaCodigo { get; set; } = string.Empty;
    public string UnidadDidacticaNombre { get; set; } = string.Empty;
    public string CarreraNombre { get; set; } = string.Empty;
    public string Ciclo { get; set; } = "I";
    public string Turno { get; set; } = "Noche";
    public string Seccion { get; set; } = "A";
    public string? AulaCodigo { get; set; } = "LAB-302";
    public int NumeroSemana { get; set; } = 1;
    public int NumeroSesion { get; set; } = 1;
    public bool EsSemana17Recuperacion { get; set; }
    public bool EsSemana18Cierre { get; set; }
    public DateTime FechaClase { get; set; }
    public TimeSpan HoraInicio { get; set; }
    public TimeSpan HoraFin { get; set; }
    public int TotalAlumnos { get; set; }
    public string EstadoSesion { get; set; } = "ABIERTA"; // ABIERTA, CERRADA, PROGRAMADA
}

/// <summary>
/// Tarjeta de Clase/Curso asignado al Docente (Agrupador de Horarios y Sesiones)
/// </summary>
public class ClaseDocenteCardDto
{
    public int ClaseId { get; set; }
    public int UnidadDidacticaId { get; set; }
    public string UnidadDidacticaCodigo { get; set; } = string.Empty;
    public string UnidadDidacticaNombre { get; set; } = string.Empty;
    public int CarreraId { get; set; }
    public string CarreraNombre { get; set; } = string.Empty;
    public string Ciclo { get; set; } = "I";
    public string Turno { get; set; } = "Noche";
    public string Seccion { get; set; } = "A";
    public int? AulaId { get; set; }
    public string? AulaCodigo { get; set; }
    public int TotalSesionesSemanales { get; set; } = 1;
    public int HorasSemanales { get; set; } = 4;
    public int TotalAlumnosMatriculados { get; set; }
    public int SemanasRegistradas { get; set; }
    public int TotalSemanasRegulares { get; set; } = 18;
    public int UltimaSemanaRegistrada { get; set; }
    public int? ProximaSesionId { get; set; }
}

/// <summary>
/// Navegador de Semanas (1 a 16 Regulares + Semana 17 Recuperación + Semana 18 Cierre REGISTRA)
/// </summary>
public class SemanaSelectorDto
{
    public int NumeroSemana { get; set; }
    public bool EsSemana17Recuperacion { get; set; }
    public bool EsSemana18Cierre { get; set; }
    public string TituloSemana => EsSemana17Recuperacion 
        ? "Semana 17 (Evaluación de Recuperación Ordinaria)" 
        : EsSemana18Cierre 
            ? "Semana 18 (Subsanación y Cierre REGISTRA)" 
            : $"Semana {NumeroSemana}";
    public string EstadoSemana { get; set; } = "PROGRAMADA"; // CERRADA, ABIERTA, PROGRAMADA
    public List<SesionClaseDto> Sesiones { get; set; } = new();
    public bool EsSemanaActual { get; set; }
}

/// <summary>
/// Sesión individual de clase (Fecha, Horario, Horas y Estado)
/// </summary>
public class SesionClaseDto
{
    public int Id { get; set; }
    public int? ClaseDocenteId { get; set; }
    public int UnidadDidacticaId { get; set; }
    public string UnidadDidacticaCodigo { get; set; } = string.Empty;
    public string UnidadDidacticaNombre { get; set; } = string.Empty;
    public string CarreraNombre { get; set; } = string.Empty;
    public string Ciclo { get; set; } = string.Empty;
    public string Turno { get; set; } = string.Empty;
    public string Seccion { get; set; } = string.Empty;
    public int DocenteId { get; set; }
    public string DocenteNombreCompleto { get; set; } = string.Empty;
    public int PeriodoId { get; set; }
    public string PeriodoCodigo { get; set; } = string.Empty;
    public int? AulaId { get; set; }
    public string? AulaCodigo { get; set; }
    public DateTime FechaClase { get; set; }
    public TimeSpan HoraInicio { get; set; }
    public TimeSpan HoraFin { get; set; }
    public int HorasPedagogicas { get; set; }
    public int NumeroSemana { get; set; }
    public int NumeroSesion { get; set; } = 1;
    public bool EsSemana17Recuperacion => NumeroSemana == 17;
    public bool EsSemana18Cierre => NumeroSemana == 18;
    public string? TemaDesarrollado { get; set; }
    public string? ObservacionesDocente { get; set; }
    public string Estado { get; set; } = "ABIERTA"; // PROGRAMADA, ABIERTA, CERRADA, CANCELADA
    public DateTime? CerradaEn { get; set; }
    public int TotalAlumnos { get; set; }
    public int TotalPresentes { get; set; }
    public int TotalTardanzas { get; set; }
    public int TotalFaltas { get; set; }
    public int TotalJustificadas { get; set; }
}

/// <summary>
/// Fila de Alumno para la Toma de Asistencia en el Aula
/// </summary>
public class AlumnoAsistenciaItemDto
{
    public int EstudianteId { get; set; }
    public int PersonaId { get; set; }
    public string CodigoEstudiante { get; set; } = string.Empty;
    public string Dni { get; set; } = string.Empty;
    public string Nombres { get; set; } = string.Empty;
    public string Apellidos { get; set; } = string.Empty;
    public string NombreCompleto => $"{Apellidos}, {Nombres}";
    public string? FotoUrl { get; set; }
    public string Turno { get; set; } = "Noche";
    
    // Asistencia actual (Por defecto 'PRESENTE' para velocidad 1-clic)
    public int? AsistenciaId { get; set; }
    public string EstadoAsistencia { get; set; } = "PRESENTE"; // PRESENTE, TARDANZA, FALTA_INJUSTIFICADA, FALTA_JUSTIFICADA
    public int MinutosTardanza { get; set; } = 0;
    public string? Observacion { get; set; }

    // Métricas para cálculo de DPI en vivo (Ley 30512 / MPA 2024 Art. 8.8.1)
    public int HorasFaltaAcumuladasPrevias { get; set; }
    public int TotalHorasSemestrales { get; set; } = 72;
    public decimal PorcentajeInasistenciaPrevio { get; set; }
    public bool EnRiesgoDpi => PorcentajeInasistenciaPrevio >= 20.00m;
    public bool EsDpi => PorcentajeInasistenciaPrevio >= 30.00m;
    public int HorasFaltaDisponibles { get; set; }
}

/// <summary>
/// Matriz Completa Tipo "Sábana Excel Institucional" de 18 Semanas para el Docente
/// </summary>
public class MatrizAsistenciaViewModel
{
    public int ClaseId { get; set; }
    public int UnidadDidacticaId { get; set; }
    public string UnidadDidacticaCodigo { get; set; } = string.Empty;
    public string UnidadDidacticaNombre { get; set; } = string.Empty;
    public string CarreraNombre { get; set; } = string.Empty;
    public string Ciclo { get; set; } = string.Empty;
    public string Turno { get; set; } = string.Empty;
    public string Seccion { get; set; } = string.Empty;
    public string DocenteNombre { get; set; } = string.Empty;
    public int PeriodoId { get; set; }
    public string PeriodoCodigo { get; set; } = "2026-I";

    // Columnas de la Matriz (Sesiones Dictadas de 1 a 18 semanas)
    public List<ColumnaSesionMatrizDto> ColumnasSesiones { get; set; } = new();

    // Filas de la Matriz (Alumnos)
    public List<FilaAlumnoMatrizDto> FilasAlumnos { get; set; } = new();
}

public class ColumnaSesionMatrizDto
{
    public int SesionId { get; set; }
    public int NumeroSemana { get; set; }
    public int NumeroSesion { get; set; }
    public DateTime FechaClase { get; set; }
    public int HorasPedagogicas { get; set; }
    public string Estado { get; set; } = "CERRADA";
    public bool EsSemana17Recuperacion => NumeroSemana == 17;
    public bool EsSemana18Cierre => NumeroSemana == 18;
}

public class FilaAlumnoMatrizDto
{
    public int EstudianteId { get; set; }
    public string CodigoEstudiante { get; set; } = string.Empty;
    public string Dni { get; set; } = string.Empty;
    public string NombreCompleto { get; set; } = string.Empty;
    
    // Mapeo: SesionId -> Estado ("PRESENTE", "TARDANZA", "FALTA_INJUSTIFICADA", "FALTA_JUSTIFICADA", "SIN_REGISTRO")
    public Dictionary<int, string> EstadosPorSesion { get; set; } = new();

    // Estadísticas
    public int TotalPresentes { get; set; }
    public int TotalTardanzas { get; set; }
    public int TotalFaltasInjustificadas { get; set; }
    public int TotalFaltasJustificadas { get; set; }
    public int HorasFaltaAcumuladas { get; set; }
    public int TotalHorasAsignatura { get; set; } = 72;
    public decimal PorcentajeInasistencia { get; set; }
    public string SemaforoEstado { get; set; } = "REGULAR"; // REGULAR, ALERTA, RIESGO_ALTO, DPI
    public bool EsDpiInhabilitado => PorcentajeInasistencia >= 30.00m;
    public int HorasMargenDpi { get; set; }
}

/// <summary>
/// Solicitud de guardado focalizado de asistencia en una sesión
/// </summary>
public class GuardarAsistenciaRequestDto
{
    [Required]
    public int SesionClaseId { get; set; }
    public string? TemaDesarrollado { get; set; }
    public string? ObservacionesDocente { get; set; }
    public bool CerrarSesion { get; set; } = false;
    public List<GuardarItemAsistenciaDto> Alumnos { get; set; } = new();
}

public class GuardarItemAsistenciaDto
{
    public int EstudianteId { get; set; }
    public string Estado { get; set; } = "PRESENTE";
    public int MinutosTardanza { get; set; } = 0;
    public string? Observacion { get; set; }
}

/// <summary>
/// Solicitud de guardado masivo de la Matriz completa (Sábana Live Grid o Smart Copy-Paste)
/// </summary>
public class GuardarMatrizRequestDto
{
    [Required]
    public int ClaseId { get; set; }
    public List<GuardarCeldaMatrizDto> Celdas { get; set; } = new();
}

public class GuardarCeldaMatrizDto
{
    public int EstudianteId { get; set; }
    public int SesionId { get; set; }
    public string Estado { get; set; } = "PRESENTE"; // PRESENTE, TARDANZA, FALTA_INJUSTIFICADA, FALTA_JUSTIFICADA
}

/// <summary>
/// DTO para reprogramación elástica de horarios futuros
/// </summary>
public class ReprogramarHorarioDto
{
    [Required]
    public int ClaseDocenteId { get; set; }
    [Required]
    public int DesdeSemana { get; set; } = 4;
    public int NuevoDiaSemana { get; set; } = 1; // 1: Lunes .. 6: Sábado
    public TimeSpan NuevaHoraInicio { get; set; } = new TimeSpan(18, 30, 0);
    public TimeSpan NuevaHoraFin { get; set; } = new TimeSpan(21, 30, 0);
    public int? NuevoAulaId { get; set; }
    public string MotivoReprogramacion { get; set; } = string.Empty;
}

/// <summary>
/// Resumen del estudiante para su portal
/// </summary>
public class ResumenAsistenciaEstudianteDto
{
    public int EstudianteId { get; set; }
    public int UnidadDidacticaId { get; set; }
    public int PeriodoId { get; set; }
    public string UnidadDidacticaNombre { get; set; } = string.Empty;
    public string UnidadDidacticaCodigo { get; set; } = string.Empty;
    public string CarreraNombre { get; set; } = string.Empty;
    public string Ciclo { get; set; } = string.Empty;
    public string Turno { get; set; } = string.Empty;
    public int TotalHorasSemestre { get; set; }
    public int CantPresentes { get; set; }
    public int CantTardanzas { get; set; }
    public int CantFaltasJustificadas { get; set; }
    public int CantFaltasInjustificadas { get; set; }
    public int HorasFaltaInjustificada { get; set; }
    public int HorasAsistidas { get; set; }
    public int TotalSesionesRegistradas { get; set; }
    public decimal PorcentajeInasistencia { get; set; }
    public string SemaforoEstado { get; set; } = "REGULAR";
    public int HorasFaltaDisponibles { get; set; }
    public bool InhabilitadoRecuperacionSemana17 => PorcentajeInasistencia >= 30.00m;
}

/// <summary>
/// Detalle histórico sesión por sesión para el estudiante
/// </summary>
public class AsistenciaHistorialItemDto
{
    public int AsistenciaId { get; set; }
    public int SesionId { get; set; }
    public DateTime FechaClase { get; set; }
    public int NumeroSemana { get; set; }
    public int NumeroSesion { get; set; } = 1;
    public bool EsSemana17Recuperacion => NumeroSemana == 17;
    public bool EsSemana18Cierre => NumeroSemana == 18;
    public int HorasPedagogicas { get; set; }
    public string? TemaDesarrollado { get; set; }
    public string DocenteNombre { get; set; } = string.Empty;
    public string Estado { get; set; } = "PRESENTE";
    public int MinutosTardanza { get; set; }
    public string? Observacion { get; set; }
    public bool TieneJustificacion { get; set; }
    public string? EstadoJustificacion { get; set; }
    public bool DentroDeVentana72Horas => (DateTime.Now - FechaClase).TotalHours <= 72.0;
}

/// <summary>
/// Trámites de justificación con ventana estricta de 72 horas hábiles
/// </summary>
public class JustificacionDto
{
    public int Id { get; set; }
    public int AsistenciaId { get; set; }
    public int EstudianteId { get; set; }
    public string EstudianteNombre { get; set; } = string.Empty;
    public string EstudianteCodigo { get; set; } = string.Empty;
    public string UnidadDidacticaNombre { get; set; } = string.Empty;
    public DateTime FechaClase { get; set; }
    public int NumeroSemana { get; set; }
    public string Motivo { get; set; } = "Salud_Medica";
    public string Descripcion { get; set; } = string.Empty;
    public string? DocumentoSustentoUrl { get; set; }
    public string Estado { get; set; } = "PENDIENTE";
    public string? DocenteNombre { get; set; }
    public string? RespuestaObservacion { get; set; }
    public DateTime FechaSolicitud { get; set; }
    public DateTime? FechaResolucion { get; set; }
    public bool EsDentroDe72Horas => (DateTime.Now - FechaClase).TotalHours <= 72.0;
}

public class CrearJustificacionDto
{
    [Required]
    public int AsistenciaId { get; set; }
    [Required]
    public string Motivo { get; set; } = "Salud_Medica";
    [Required]
    public string Descripcion { get; set; } = string.Empty;
    public string? DocumentoSustentoUrl { get; set; }
}

public class ResolverJustificacionDto
{
    [Required]
    public int JustificacionId { get; set; }
    [Required]
    public bool Aprobada { get; set; }
    public string? Observacion { get; set; }
}

/// <summary>
/// Alerta institucional DPI para Dirección y Coordinación
/// </summary>
public class AlertaDpiDto
{
    public int EstudianteId { get; set; }
    public string EstudianteNombre { get; set; } = string.Empty;
    public string EstudianteCodigo { get; set; } = string.Empty;
    public string CarreraNombre { get; set; } = string.Empty;
    public string Ciclo { get; set; } = string.Empty;
    public string Turno { get; set; } = string.Empty;
    public int UnidadDidacticaId { get; set; }
    public string UnidadDidacticaNombre { get; set; } = string.Empty;
    public string DocenteNombre { get; set; } = string.Empty;
    public int HorasFalta { get; set; }
    public int TotalHoras { get; set; }
    public decimal PorcentajeInasistencia { get; set; }
    public string SemaforoEstado { get; set; } = "ALERTA";
    public bool InhabilitadoRecuperacionSemana17 => PorcentajeInasistencia >= 30.00m;
}

/// <summary>
/// Dashboard Master View Model
/// </summary>
public class DashboardAsistenciaViewModel
{
    public string RolUsuario { get; set; } = "Docente";
    public string NombreUsuario { get; set; } = string.Empty;
    public bool EsDocente { get; set; }
    public bool EsAlumno { get; set; }
    public bool EsCoordinadorOAdmin { get; set; }

    // Clase activa hoy autodetectada (1 Clic CTA)
    public ClaseActivaDocenteDto? ClaseActivaHoy { get; set; }

    // KPIs Generales
    public int TotalClasesAsignadas { get; set; }
    public int TotalSesionesHoy { get; set; }
    public int TotalAlumnosDpi { get; set; }
    public int TotalJustificacionesPendientes { get; set; }

    // Listas por Rol
    public List<ClaseDocenteCardDto> MisClasesDocente { get; set; } = new();
    public List<SesionClaseDto> SesionesHoy { get; set; } = new();
    public List<ResumenAsistenciaEstudianteDto> ResumenCursosEstudiante { get; set; } = new();
    public List<AlertaDpiDto> CasosCriticosDpi { get; set; } = new();
    public List<JustificacionDto> JustificacionesRecientes { get; set; } = new();
}
