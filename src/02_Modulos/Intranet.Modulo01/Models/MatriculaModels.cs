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
