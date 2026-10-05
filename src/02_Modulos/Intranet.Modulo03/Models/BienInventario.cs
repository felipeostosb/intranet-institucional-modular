namespace Intranet.Modulo03.Models;

public class BienInventario
{
    public int IdBien { get; set; }
    public int IdAlmacen { get; set; }
    public int IdClasificacion { get; set; }
    public string Cbi { get; set; } = "";
    public string? CodigoInventario { get; set; }
    public string Descripcion { get; set; } = "";
    public string Clasificacion { get; set; } = "";
    public string? Marca { get; set; }
    public string? Modelo { get; set; }
    public string? Serie { get; set; }
    public string Procedencia { get; set; } = "";
    public DateTime FechaIngreso { get; set; }
    public string Estado { get; set; } = "";
    public string AlmacenActual { get; set; } = "";
    public string? UbicacionAlmacen { get; set; }
    public string? AmbienteActual { get; set; }
    public string? Responsable { get; set; }
    public string? Observacion { get; set; }
}
