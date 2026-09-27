namespace Intranet.Modulo01.Models;

/// <summary>Matrícula vigente del alumno (vista "Mi matrícula").</summary>
public class MatriculaActivaDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Estado { get; set; } = "En trámite";
    public string Etapa { get; set; } = "Validación";
    public bool VoucherOk { get; set; }
    public bool FotoOk { get; set; }
    public string Condicion { get; set; } = "";
    public DateTime? FechaMatricula { get; set; }
    public string? Observaciones { get; set; }
    public DateTime CreadoEn { get; set; }
    public string Carrera { get; set; } = "";
    public string CarreraCodigo { get; set; } = "";
    public string Ciclo { get; set; } = "";
    public string Turno { get; set; } = "";
    public string TipoMatricula { get; set; } = "";
    public string Estudiante { get; set; } = "";
    public string CodigoEstudiante { get; set; } = "";

    /// <summary>Progreso del proceso Cero Filas: 1..4 pasos completados.</summary>
    public int PasosCompletados =>
        (Estado == "Matriculado") ? 4
        : (VoucherOk && FotoOk) ? 3
        : (VoucherOk || FotoOk) ? 2
        : 1;

    public string EtapaLegible =>
        Estado == "Matriculado" ? "Proceso completado"
        : (VoucherOk && FotoOk) ? "Listo para conformidad"
        : (VoucherOk || FotoOk) ? "Pendiente " + (FotoOk ? "voucher" : "foto")
        : "Pendiente voucher y foto";
}

/// <summary>Fila de los listados del personal.</summary>
public class MatriculaListaDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Estado { get; set; } = "";
    public string Etapa { get; set; } = "";
    public bool VoucherOk { get; set; }
    public bool FotoOk { get; set; }
    public string Condicion { get; set; } = "";
    public DateTime? FechaMatricula { get; set; }
    public DateTime CreadoEn { get; set; }
    public string CarreraCodigo { get; set; } = "";
    public string Ciclo { get; set; } = "";
    public string Turno { get; set; } = "";
    public string TipoMatricula { get; set; } = "";
    public string Estudiante { get; set; } = "";
    public string CodigoEstudiante { get; set; } = "";
}

/// <summary>Zona C: matrículas trancadas que liberan su vacante (Art. 24 RI).</summary>
public class MatriculaPorLiberarDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public DateTime CreadoEn { get; set; }
    public int DiasTranscurridos { get; set; }
    public string CarreraCodigo { get; set; } = "";
    public string Ciclo { get; set; } = "";
    public string Turno { get; set; } = "";
    public string Estudiante { get; set; } = "";
}

/// <summary>Métricas del módulo.</summary>
public class ResumenMatriculaDto
{
    public int Matriculados { get; set; }
    public int EnTramite { get; set; }
    public int ListasParaRegistrar { get; set; }
    public int EnEspera { get; set; }
    public int Reservadas { get; set; }
}

/// <summary>Tablero de vacantes por carril.</summary>
public class VacanteDto
{
    public string CarreraCodigo { get; set; } = "";
    public string Carrera { get; set; } = "";
    public string Turno { get; set; } = "";
    public string Ciclo { get; set; } = "";
    public int Disponibles { get; set; }
    public int Ocupadas { get; set; }
}

/// <summary>Resultado del RETURNING al registrar conformidad (para consumir vacante).</summary>
public class VacanteConsumoDto
{
    public int CarreraId { get; set; }
    public int CicloId { get; set; }
    public int TurnoId { get; set; }
    public int PeriodoId { get; set; }
}


// =====================================================================
// Matriculatura de Secretaría (flujo Reserva de Matrícula TM05/CT13)
// =====================================================================

/// <summary>Expediente del alumno listo para matricular (búsqueda por DNI).</summary>
public class ExpedienteMatriculaDto
{
    public int EstudianteId { get; set; }
    public string CodigoEstudiante { get; set; } = "";
    public string Estudiante { get; set; } = "";
    public string Dni { get; set; } = "";
    public string EmailPersonal { get; set; } = "";
    public string EmailInstitucional { get; set; } = "";
    public int CarreraId { get; set; }
    public string Carrera { get; set; } = "";
    public string CarreraCodigo { get; set; } = "";
    public string CicloActual { get; set; } = "";

    // situación académica
    public string CicloCulminado { get; set; } = "";
    public string CicloProximo { get; set; } = "";
    public string Condicion { get; set; } = "";          // Promovido | Promovido con curso a cargo | Repitente
    public int CursosDesaprobados { get; set; }
    public string CursosDesaprobadosNombres { get; set; } = "";
    public List<HistorialFilaDto> Historial { get; set; } = [];
    public List<UnidadOfertaDto> OfertaProximoCiclo { get; set; } = [];

    // reserva TUPA y su voucher
    public ReservaDto? Reserva { get; set; }
    public bool PuedeMatricular { get; set; }
}

/// <summary>Fila del historial académico (aprobado/desaprobado por UD).</summary>
public class HistorialFilaDto
{
    public string UnidadCodigo { get; set; } = "";
    public string UnidadNombre { get; set; } = "";
    public string Ciclo { get; set; } = "";
    public decimal Nota { get; set; }
    public string Estado { get; set; } = "";   // Aprobado | Desaprobado | Retirado
}

/// <summary>UD matriculable del próximo ciclo (core o espejo oferta_ciclo).</summary>
public class UnidadOfertaDto
{
    public int Id { get; set; }
    /// <summary>Origen del Id: "core" (unidades_didacticas) o "espejo" (mod01.oferta_ciclo).</summary>
    public string Origen { get; set; } = "core";
    public string Codigo { get; set; } = "";
    public string Nombre { get; set; } = "";
    public int Creditos { get; set; }
    public string Tipo { get; set; } = "";
    public string Ciclo { get; set; } = "";
    public bool Obligatoria { get; set; } = true;
    /// <summary>Curso a cargo: desaprobado que se vuelve a llevar junto al nuevo ciclo.</summary>
    public bool EsCursoACargo { get; set; }
}

/// <summary>Estado del trámite de reserva y su voucher (para Secretaría).</summary>
public class ReservaDto
{
    public int MatriculaId { get; set; }
    public string CodigoMatricula { get; set; } = "";
    public string Estado { get; set; } = "";
    public bool VoucherOk { get; set; }
    public int? TramiteId { get; set; }
    public string TramiteCodigo { get; set; } = "";
    public string TramiteEstado { get; set; } = "";
    public string VoucherEstado { get; set; } = "";   // Pendiente | Validado | Rechazado
    public decimal VoucherMonto { get; set; }
    /// <summary>El período de la reserva tiene permite_matricula (lo habilita el dueño).</summary>
    public bool PeriodoHabilitado { get; set; } = true;
}

/// <summary>RETURNING interno al cerrar la matrícula (consumo de vacante).</summary>
public class MatriculaCierreDto
{
    public int Id { get; set; }
    public int EstudianteId { get; set; }
    public int CarreraId { get; set; }
    public int CicloId { get; set; }
    public int TurnoId { get; set; }
    public int PeriodoId { get; set; }
}

/// <summary>
/// Datos de la ficha de matrícula PDF (QuestPDF) que se envía al estudiante.
/// </summary>
public class FichaMatriculaDto
{
    public string CodigoMatricula { get; set; } = "";
    public string Periodo { get; set; } = "";
    public string Estudiante { get; set; } = "";
    public string CodigoEstudiante { get; set; } = "";
    public string Dni { get; set; } = "";
    public string Carrera { get; set; } = "";
    public string CarreraCodigo { get; set; } = "";
    public string Condicion { get; set; } = "";
    public string CursosDesaprobadosNombres { get; set; } = "";
    public string CicloCulminado { get; set; } = "";
    public string CicloProximo { get; set; } = "";
    public string Turno { get; set; } = "";
    public string TipoMatricula { get; set; } = "";
    public DateTime? FechaMatricula { get; set; }
    public string Estado { get; set; } = "";
    public List<UnidadOfertaDto> Unidades { get; set; } = [];
}
