namespace Intranet.Modulo05.Models;

/// <summary>
/// DTO de atención médica del Tópico (mod05.atenciones_topico).
/// Los controladores lo consultan via IModuleDbConnectionFactory + Dapper.
/// </summary>
public class AtencionMedicaItem
{
    public int      IdAtencionTop      { get; set; }
    public int      PersonaId          { get; set; }
    public int      AtendidoPorId      { get; set; }
    public DateTime FechaHora          { get; set; } = DateTime.Now;
    public string   Motivo             { get; set; } = string.Empty;
    public int?     MedicamentoId      { get; set; }
    public bool     EsAlergico         { get; set; }
    public string?  DetalleAlergia     { get; set; }
    public string?  SeguroSalud        { get; set; }
    public string?  Observacion        { get; set; }

    // JOIN a core.personas y mod05.botica_medicamentos
    public string?  NumeroDocumento    { get; set; }
    public string?  PacienteNombres    { get; set; }
    public string?  PacienteApellidos  { get; set; }
    public string?  MedicamentoNombre  { get; set; }
}

/// <summary>
/// DTO de un medicamento del botiquín (mod05.botica_medicamentos).
/// </summary>
public class MedicamentoItem
{
    public int      Id               { get; set; }
    public string   Nombre           { get; set; } = string.Empty;
    public string   Presentacion     { get; set; } = string.Empty;
    public int      StockActual      { get; set; }
    public DateTime FechaVencimiento { get; set; }
    public string?  Estado           { get; set; }
}

/// <summary>
/// DTO para búsqueda de paciente en Enfermería.
/// </summary>
public class PacienteBusquedaDto
{
    public int    IdPersona       { get; set; }
    public string NumeroDocumento { get; set; } = string.Empty;
    public string Nombres         { get; set; } = string.Empty;
    public string Apellidos       { get; set; } = string.Empty;
}
