namespace Intranet.Modulo05.Models;

/// <summary>
/// DTO de una incidencia/ticket de avería (mod05.incidencias y mod05.reportes_incidencia).
/// Los controladores lo consultan via IModuleDbConnectionFactory + Dapper.
/// </summary>
public class TicketAveriaItem
{
    public int       IdIncidencia      { get; set; }
    public int       IdBien            { get; set; }
    public int       ReportadorId      { get; set; }
    public int?      TecnicoId         { get; set; }
    public DateTime  FechaReporte      { get; set; } = DateTime.Now;
    public DateTime? FechaCierre       { get; set; }
    public string    TipoFalla         { get; set; } = string.Empty;
    public string    Gravedad          { get; set; } = "Media";
    public string    Descripcion       { get; set; } = string.Empty;
    public string?   SolucionAplicada  { get; set; }
    public string    Estado            { get; set; } = "Pendiente";

    // Campos relacionales del bien (JOIN a mod03.bien)
    public string?   CodigoBien        { get; set; }
    public string?   DescripcionBien   { get; set; }
    public string?   Marca             { get; set; }
    public string?   Modelo            { get; set; }
    public string?   Ambiente          { get; set; }
    public string?   NombreReportador  { get; set; }
    public string?   NombreTecnico     { get; set; }

    // Calculado en el controlador
    public string?   MarcaModelo       { get; set; }
}
