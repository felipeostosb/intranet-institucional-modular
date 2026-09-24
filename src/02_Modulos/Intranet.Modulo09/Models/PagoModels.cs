namespace Intranet.Modulo09.Models;

/// <summary>Pago del alumno (vista "Mis pagos").</summary>
public class PagoListaDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public decimal Monto { get; set; }
    public DateTime FechaPago { get; set; }
    public string VoucherEstado { get; set; } = "";
    public string? MotivoRechazo { get; set; }
    public string ConceptoCodigo { get; set; } = "";
    public string ConceptoNombre { get; set; } = "";
    public string TipoPago { get; set; } = "";
    public string Periodo { get; set; } = "";
}

/// <summary>Fila de la bandeja de vouchers de Tesorería.</summary>
public class PagoBandejaDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public decimal Monto { get; set; }
    public DateTime FechaPago { get; set; }
    public string VoucherEstado { get; set; } = "";
    public string? MotivoRechazo { get; set; }
    public DateTime? FechaValidacion { get; set; }
    public int Intentos { get; set; }
    public string ConceptoCodigo { get; set; } = "";
    public string ConceptoNombre { get; set; } = "";
    public string TipoPago { get; set; } = "";
    public string CodigoEstudiante { get; set; } = "";
    public string Estudiante { get; set; } = "";
}

/// <summary>Métricas de pagos del módulo.</summary>
public class PagosResumenDto
{
    public int PorValidar { get; set; }
    public int Validados { get; set; }
    public int Rechazados { get; set; }
    public decimal Recaudado { get; set; }
}

/// <summary>Concepto del catálogo TUPA para el formulario.</summary>
public class ConceptoPagoDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Nombre { get; set; } = "";
    public decimal Monto { get; set; }
}

/// <summary>Tipo de pago (Efectivo, Yape, Plin...).</summary>
public class TipoPagoDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string Nombre { get; set; } = "";
}

/// <summary>ViewModel del formulario de recibo/registro de pago.</summary>
public class RegistrarPagoViewModel
{
    public IEnumerable<ConceptoPagoDto> Conceptos { get; set; } = [];
    public IEnumerable<TipoPagoDto> TiposPago { get; set; } = [];
    public IEnumerable<EstudianteSelectDto> Estudiantes { get; set; } = [];
}

/// <summary>Estudiante para el select de Tesorería (recibo directo).</summary>
public class EstudianteSelectDto
{
    public int Id { get; set; }
    public string CodigoEstudiante { get; set; } = "";
    public string NombreCompleto { get; set; } = "";
}
