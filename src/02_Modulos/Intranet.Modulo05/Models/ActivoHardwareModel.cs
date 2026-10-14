namespace Intranet.Modulo05.Models;

/// <summary>
/// DTO de un activo de hardware / bien patrimonial del inventario (mod03.bien).
/// Los controladores de Soporte lo consultan via IModuleDbConnectionFactory + Dapper.
/// </summary>
public class ActivoHardwareItem
{
    public int     IdBien                { get; set; }
    public string? Cbi                   { get; set; }
    public string  Descripcion           { get; set; } = string.Empty;
    public string  TipoBien              { get; set; } = string.Empty;
    public string? Marca                 { get; set; }
    public string? Modelo                { get; set; }
    public string? Serie                 { get; set; }
    public string  Estado                { get; set; } = "Operativo";
    public string? AmbienteAsignado      { get; set; }
    public int     TotalFallasRegistradas { get; set; }

    // Calculado en el controlador
    public string MarcaModelo => $"{Marca} {Modelo}".Trim();
}
