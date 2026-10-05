namespace Intranet.Modulo03.Models;

public class InventarioFiltroModel
{
    public string? Q { get; set; }
    public string? Estado { get; set; }
    public int? IdClasificacion { get; set; }
    public int? IdAlmacen { get; set; }

    public List<BienInventario> Resultados { get; set; } = [];
    public List<ClasificacionModel> Clasificaciones { get; set; } = [];
    public List<AlmacenModel> Almacenes { get; set; } = [];
}
