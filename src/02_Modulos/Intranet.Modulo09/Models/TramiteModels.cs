namespace Intranet.Modulo09.Models;

/// <summary>Fila de "Mis trámites" del alumno.</summary>
public class TramiteListaDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Estado { get; set; } = "";
    public DateTime FechaSolicitud { get; set; }
    public DateTime? FechaLimite { get; set; }
    public int Dias { get; set; }
    public string TipoCodigo { get; set; } = "";
    public string TipoNombre { get; set; } = "";
    public string PagoCodigo { get; set; } = "";
    public string PagoNombre { get; set; } = "";
    public decimal PagoMonto { get; set; }
    public int RequisitosOk { get; set; }
    public int RequisitosTotal { get; set; }

    public string ColorChip => Estado switch
    {
        "Aprobado" => "badge-success",
        "Recibido" => "badge-warning",
        "En evaluación" => "badge-info",
        "Observado" => "badge-warning",
        "Rechazado" => "badge-error",
        "Entregado" => "badge-accent",
        _ => "badge-ghost"
    };
}

/// <summary>Fila de la Mesa de trámites (Secretaría).</summary>
public class TramiteMesaDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Estado { get; set; } = "";
    public DateTime FechaSolicitud { get; set; }
    public string TipoCodigo { get; set; } = "";
    public string TipoNombre { get; set; } = "";
    public string Estudiante { get; set; } = "";
    public string CodigoEstudiante { get; set; } = "";
    public string? Resolucion { get; set; }
    public string? VoucherEstado { get; set; }
}

/// <summary>Ficha TUPA del tipo de trámite.</summary>
public class TipoTramiteDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Nombre { get; set; } = "";
    public int DiasHabiles { get; set; }
    public int? ConceptoPagoId { get; set; }
    public string PagoCodigo { get; set; } = "";
    public string PagoNombre { get; set; } = "";
    public decimal PagoMonto { get; set; }
}

/// <summary>Requisito del catálogo (por tipo de trámite).</summary>
public class RequisitoDto
{
    public int Id { get; set; }
    public int Orden { get; set; }
    public string Requisito { get; set; } = "";
}

/// <summary>Requisito de un trámite con su estado de presentación.</summary>
public class RequisitoEstadoDto
{
    public int Id { get; set; }
    public int Orden { get; set; }
    public string Requisito { get; set; } = "";
    public bool Presentado { get; set; }
    public string? Observacion { get; set; }
}

/// <summary>Detalle completo del trámite (ficha + requisitos).</summary>
public class TramiteDetalleDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Estado { get; set; } = "";
    public DateTime FechaSolicitud { get; set; }
    public DateTime? FechaLimite { get; set; }
    public string? Resolucion { get; set; }
    public DateTime? FechaResolucion { get; set; }
    public string? DatosJson { get; set; }
    public string TipoCodigo { get; set; } = "";
    public string TipoNombre { get; set; } = "";
    public int DiasHabiles { get; set; }
    public string PagoCodigo { get; set; } = "";
    public string PagoNombre { get; set; } = "";
    public decimal PagoMonto { get; set; }
    public string Estudiante { get; set; } = "";
    public string CodigoEstudiante { get; set; } = "";
    public IEnumerable<RequisitoEstadoDto> Requisitos { get; set; } = [];
}

/// <summary>Panel del puesto de Secretaría (mesa de partes TUPA).</summary>
public class ResumenSecretariaDto
{
    public int Recibidos { get; set; }                     // en mesa esperando evaluación
    public int EnEvaluacion { get; set; }
    public int AprobadosPendientesEntrega { get; set; }    // falta entregar al alumno
    public int Entregados { get; set; }
    public int Observados { get; set; }                    // el alumno debe corregir
    /// <summary>Top 5 tipos de trámite por volumen en mesa.</summary>
    public List<TramitesPorTipoDto> PorTipo { get; set; } = [];
}

/// <summary>Fila del desglose de trámites por tipo TUPA.</summary>
public class TramitesPorTipoDto
{
    public string Codigo { get; set; } = "";
    public string Nombre { get; set; } = "";
    public int Cantidad { get; set; }
}
