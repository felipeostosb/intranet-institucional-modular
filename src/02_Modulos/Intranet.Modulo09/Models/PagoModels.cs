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
    public bool TieneVoucher { get; set; }
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
    public bool TieneVoucher { get; set; }
}

/// <summary>Voucher PDF adjunto a un pago (evidencia para Tesorería).</summary>
public class ArchivoVoucherDto
{
    public string Nombre { get; set; } = "";
    public string Tipo { get; set; } = "";
    public byte[] Contenido { get; set; } = [];
}

/// <summary>Métricas de pagos del módulo.</summary>
public class PagosResumenDto
{
    public int PorValidar { get; set; }
    public int Validados { get; set; }
    public int Rechazados { get; set; }
    public decimal Recaudado { get; set; }
}

/// <summary>Panel del puesto de Tesorería (vouchers y recaudación).</summary>
public class ResumenTesoreriaDto
{
    public int VouchersPendientes { get; set; }      // esperando validación
    public int VouchersRechazados { get; set; }      // el alumno debe re-subir
    public int VouchersValidadosHoy { get; set; }
    public decimal RecaudadoHoy { get; set; }
    public decimal RecaudadoPeriodo { get; set; }
    public int RecibosValidados { get; set; }
    /// <summary>Top 5 conceptos por recaudación validada.</summary>
    public List<RecaudacionPorConceptoDto> PorConcepto { get; set; } = [];
}

/// <summary>Fila del desglose de recaudación por concepto TUPA.</summary>
public class RecaudacionPorConceptoDto
{
    public string Codigo { get; set; } = "";
    public string Nombre { get; set; } = "";
    public decimal Monto { get; set; }
    public int Recibos { get; set; }
}

/// <summary>Panel personal del alumno (sus trámites, pagos y voucher pendiente).</summary>
public class ResumenAlumnoDto
{
    public int TramitesActivos { get; set; }    // Recibido / En evaluación / Observado
    public int TramitesObservados { get; set; } // requieren corrección del alumno
    public int TramitesCerrados { get; set; }  // Aprobado / Entregado
    public int VouchersPorSubir { get; set; }  // pagos sin voucher PDF adjunto
    public decimal TotalPagado { get; set; }   // vouchers validados del alumno
    public List<MiTramiteCardDto> Ultimos { get; set; } = [];
}

/// <summary>Fila del listado de trámites del alumno en su panel.</summary>
public class MiTramiteCardDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = "";
    public string TipoNombre { get; set; } = "";
    public string Estado { get; set; } = "";
    /// <summary>Estado del voucher del pago vinculado ('' si no tiene pago).</summary>
    public string VoucherEstado { get; set; } = "";
    public DateTime FechaSolicitud { get; set; }
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
