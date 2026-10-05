using System.ComponentModel.DataAnnotations;

namespace Intranet.Modulo03.Models;

public class BienFormModel
{
    public int IdBien { get; set; }

    [Required(ErrorMessage = "El CBI es obligatorio.")]
    [Display(Name = "CBI")]
    public string Cbi { get; set; } = "";

    [Display(Name = "Código de inventario")]
    public string? CodigoInventario { get; set; }

    [Required(ErrorMessage = "La descripción es obligatoria.")]
    public string Descripcion { get; set; } = "";

    [Required(ErrorMessage = "Seleccione una clasificación.")]
    public int IdClasificacion { get; set; }

    [Display(Name = "Marca")]
    public string? Marca { get; set; }

    [Display(Name = "Modelo")]
    public string? Modelo { get; set; }

    [Display(Name = "Serie")]
    public string? Serie { get; set; }

    [Required]
    public string Procedencia { get; set; } = "Donación";

    [Required]
    [Display(Name = "Fecha de ingreso")]
    public DateTime FechaIngreso { get; set; } = DateTime.Today;

    [Required]
    public string Estado { get; set; } = "Bueno";

    [Required(ErrorMessage = "Seleccione un almacén.")]
    [Display(Name = "Almacén")]
    public int IdAlmacen { get; set; }

    public string? Observacion { get; set; }

    public List<AlmacenModel> Almacenes { get; set; } = [];
    public List<ClasificacionModel> Clasificaciones { get; set; } = [];
}
