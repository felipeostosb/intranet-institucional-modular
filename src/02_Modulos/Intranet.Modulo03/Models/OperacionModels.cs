using System.ComponentModel.DataAnnotations;

namespace Intranet.Modulo03.Models;

public class AsignacionModel
{
    public int IdAsignacion { get; set; }
    public int IdBien { get; set; }
    public string Cbi { get; set; } = "";
    public string Descripcion { get; set; } = "";
    public int IdAmbiente { get; set; }
    public string Ambiente { get; set; } = "";
    public string? Especialidad { get; set; }
    public string? Responsable { get; set; }
    public DateTime FechaAsignacion { get; set; }
    public DateTime? FechaFin { get; set; }
    public string Estado { get; set; } = "Activa";
    public string? Observacion { get; set; }
}

public class AsignacionFormModel
{
    [Required]
    public int IdBien { get; set; }
    [Required]
    public int IdAmbiente { get; set; }
    public string? Responsable { get; set; }
    [Required]
    [Display(Name = "Fecha de asignación")]
    public DateTime FechaAsignacion { get; set; } = DateTime.Today;
    public string? Observacion { get; set; }
    public List<BienInventario> Bienes { get; set; } = [];
    public List<AmbienteModel> Ambientes { get; set; } = [];
}

public class TransferenciaModel
{
    public int IdTransferencia { get; set; }
    public int IdBien { get; set; }
    public string Cbi { get; set; } = "";
    public string Descripcion { get; set; } = "";
    public int IdAlmacenOrigen { get; set; }
    public string AlmacenOrigen { get; set; } = "";
    public int IdAlmacenDestino { get; set; }
    public string AlmacenDestino { get; set; } = "";
    public DateTime FechaSolicitud { get; set; }
    public DateTime? FechaSalida { get; set; }
    public DateTime? FechaRecepcion { get; set; }
    public string EstadoMovimiento { get; set; } = "Pendiente de recepción";
    public string Motivo { get; set; } = "";
    public string? ResponsableOrigen { get; set; }
    public string? ResponsableDestino { get; set; }
    public string? Documento { get; set; }
    public string? Observacion { get; set; }
}

public class TransferenciaFormModel
{
    [Required]
    public int IdBien { get; set; }
    [Required]
    public int IdAlmacenOrigen { get; set; }
    [Required]
    public int IdAlmacenDestino { get; set; }
    [Required]
    public string Motivo { get; set; } = "";
    public string? ResponsableOrigen { get; set; }
    public string? ResponsableDestino { get; set; }
    public string? Documento { get; set; }
    public string? Observacion { get; set; }
    public List<BienInventario> Bienes { get; set; } = [];
    public List<AlmacenModel> Almacenes { get; set; } = [];
}

public class InventarioAnualModel
{
    public int IdInventario { get; set; }
    public int IdBien { get; set; }
    public string Cbi { get; set; } = "";
    public string Descripcion { get; set; } = "";
    public string? Serie { get; set; }
    public string Almacen { get; set; } = "";
    public int Anio { get; set; }
    public DateTime FechaVerificacion { get; set; }
    public string Resultado { get; set; } = "Físico";
    public string? Observacion { get; set; }
}

public class InventarioAnualFormModel
{
    [Required]
    public int IdBien { get; set; }
    [Range(2000, 2100)]
    public int Anio { get; set; } = DateTime.Today.Year;
    [Required]
    [Display(Name = "Fecha de verificación")]
    public DateTime FechaVerificacion { get; set; } = DateTime.Today;
    [Required]
    public string Resultado { get; set; } = "Físico";
    public string? Observacion { get; set; }
    public List<BienInventario> Bienes { get; set; } = [];
}
