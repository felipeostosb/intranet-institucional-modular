using System.Data;
using Dapper;
using Intranet.Core.Contracts;
using Intranet.Modulo09.Models;

namespace Intranet.Modulo09.Services;

/// <summary>
/// Servicio de Pagos del Módulo 09 (Tesorería & Pagos).
/// Flujo del prototipo WebForms (Bandejas.aspx + Pagos.aspx):
///   Estudiante registra su pago con voucher → Tesorería lo valida desde
///   la Bandeja (Aprobar / Rechazar con motivo) → el pago Validado habilita
///   la conformidad de matrícula y la aprobación de trámites TUPA.
///   Tesorería también puede emitir recibos directos (caja).
/// Dominio real de voucher_estado: Pendiente | Validado | Rechazado
/// (CHECK de coherencia: Validado exige fecha_validacion + validado_por).
/// </summary>
public interface IPagoService
{
    Task<IEnumerable<PagoListaDto>> ListarPorEstudianteAsync(int estudianteId);
    Task<IEnumerable<PagoBandejaDto>> ListarBandejaAsync(string? voucherEstado);
    Task<PagoBandejaDto?> ObtenerAsync(int pagoId);
    Task<(bool Ok, string Mensaje)> RegistrarPagoEstudianteAsync(
        int estudianteId, int periodoId, string conceptoCodigo, string tipoPagoCodigo, decimal monto, string? nota);
    Task<(bool Ok, string Mensaje)> EmitirReciboDirectoAsync(
        int estudianteId, int periodoId, string conceptoCodigo, string tipoPagoCodigo, decimal monto, int cajeroId);
    Task<(bool Ok, string Mensaje)> ValidarVoucherAsync(int pagoId, bool aprobar, string? motivo, int validadorId);
    Task<PagosResumenDto> ResumenAsync();
    Task<IEnumerable<ConceptoPagoDto>> ListarConceptosAsync();
    Task<IEnumerable<TipoPagoDto>> ListarTiposPagoAsync();
}

public class PagoService : IPagoService
{
    private readonly IModuleDbConnectionFactory _connectionFactory;

    public PagoService(IModuleDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    private IDbConnection CreateConnection() => _connectionFactory.CreateConnection("09");

    // ------------------------------------------------------------------
    // Resolución del nombre real de la tabla de pagos.
    // En producción el nombre oficial "pagos" está ocupado por una tabla
    // legacy de otro dueño (estructura antigua, sin voucher_estado).
    // Si detectamos ese caso usamos "pagos_v2" (nuestra tabla real);
    // cuando el DBA restaure el esquema oficial, vuelve al nombre canónico.
    // ------------------------------------------------------------------
    private static string? _tablaPagos;
    private static string TablaPagos(IDbConnection db)
    {
        if (_tablaPagos != null) return _tablaPagos;
        try
        {
            var tieneColumnaNueva = db.ExecuteScalar<int?>(
                "SELECT 1 FROM information_schema.columns WHERE table_schema = 'mod09' AND table_name = 'pagos' AND column_name = 'voucher_estado';");
            _tablaPagos = tieneColumnaNueva == 1 ? "pagos" : "pagos_v2";
        }
        catch
        {
            _tablaPagos = "pagos";
        }
        return _tablaPagos;
    }

    private const string SqlNuevoRecibo =
        "SELECT 'REC-' || lpad((count(*) + 1)::text, 4, '0') FROM {TABLA};";

    // ------------------------------------------------------------------
    // ALUMNO: sus pagos con el concepto y estado del voucher
    // ------------------------------------------------------------------
    public async Task<IEnumerable<PagoListaDto>> ListarPorEstudianteAsync(int estudianteId)
    {
        using var db = CreateConnection();
        const string sql = """
            SELECT p.id,
                   p.codigo,
                   p.monto,
                   p.fecha_pago AS FechaPago,
                   p.voucher_estado AS VoucherEstado,
                   p.motivo_rechazo AS MotivoRechazo,
                   cp.codigo AS ConceptoCodigo,
                   cp.nombre AS ConceptoNombre,
                   tp.nombre AS TipoPago,
                   pa.codigo AS Periodo
            FROM {TABLA} p
            JOIN conceptos_pago cp ON cp.id = p.concepto_pago_id
            JOIN tipos_pago tp ON tp.id = p.tipo_pago_id
            JOIN periodos_academicos pa ON pa.id = p.periodo_id
            WHERE p.estudiante_id = @EstudianteId
            ORDER BY p.fecha_pago DESC, p.id DESC;
            """;
        return await db.QueryAsync<PagoListaDto>(sql.Replace("{TABLA}", TablaPagos(db)), new { EstudianteId = estudianteId });
    }

    // ------------------------------------------------------------------
    // BANDEJA DE TESORERÍA: todos los pagos con datos del estudiante
    // ------------------------------------------------------------------
    public async Task<IEnumerable<PagoBandejaDto>> ListarBandejaAsync(string? voucherEstado)
    {
        using var db = CreateConnection();
        const string sql = """
            SELECT p.id,
                   p.codigo,
                   p.monto,
                   p.fecha_pago AS FechaPago,
                   p.voucher_estado AS VoucherEstado,
                   p.motivo_rechazo AS MotivoRechazo,
                   p.fecha_validacion AS FechaValidacion,
                   p.intentos,
                   cp.codigo AS ConceptoCodigo,
                   cp.nombre AS ConceptoNombre,
                   tp.nombre AS TipoPago,
                   e.codigo_estudiante AS CodigoEstudiante,
                   pe.nombres || ' ' || pe.apellidos AS Estudiante
            FROM {TABLA} p
            JOIN conceptos_pago cp ON cp.id = p.concepto_pago_id
            JOIN tipos_pago tp ON tp.id = p.tipo_pago_id
            JOIN estudiantes e ON e.id = p.estudiante_id
            JOIN personas pe ON pe.id = e.persona_id
            WHERE (@Estado IS NULL OR p.voucher_estado = @Estado)
            ORDER BY CASE p.voucher_estado WHEN 'Pendiente' THEN 0 ELSE 1 END,
                     p.fecha_pago DESC;
            """;
        return await db.QueryAsync<PagoBandejaDto>(sql.Replace("{TABLA}", TablaPagos(db)),
            new { Estado = string.IsNullOrWhiteSpace(voucherEstado) ? null : voucherEstado });
    }

    public async Task<PagoBandejaDto?> ObtenerAsync(int pagoId)
    {
        using var db = CreateConnection();
        const string sql = """
            SELECT p.id,
                   p.codigo,
                   p.monto,
                   p.fecha_pago AS FechaPago,
                   p.voucher_estado AS VoucherEstado,
                   p.motivo_rechazo AS MotivoRechazo,
                   p.fecha_validacion AS FechaValidacion,
                   p.intentos,
                   cp.codigo AS ConceptoCodigo,
                   cp.nombre AS ConceptoNombre,
                   tp.nombre AS TipoPago,
                   e.codigo_estudiante AS CodigoEstudiante,
                   pe.nombres || ' ' || pe.apellidos AS Estudiante
            FROM {TABLA} p
            JOIN conceptos_pago cp ON cp.id = p.concepto_pago_id
            JOIN tipos_pago tp ON tp.id = p.tipo_pago_id
            JOIN estudiantes e ON e.id = p.estudiante_id
            JOIN personas pe ON pe.id = e.persona_id
            WHERE p.id = @Id;
            """;
        return await db.QueryFirstOrDefaultAsync<PagoBandejaDto>(sql.Replace("{TABLA}", TablaPagos(db)), new { Id = pagoId });
    }

    // ------------------------------------------------------------------
    // ALUMNO: registrar pago con voucher (queda Pendiente → bandeja)
    // ------------------------------------------------------------------
    public async Task<(bool, string)> RegistrarPagoEstudianteAsync(
        int estudianteId, int periodoId, string conceptoCodigo, string tipoPagoCodigo, decimal monto, string? nota)
    {
        return await InsertarPagoAsync(estudianteId, periodoId, conceptoCodigo,
            tipoPagoCodigo, monto, "Pendiente", null, nota);
    }

    // ------------------------------------------------------------------
    // TESORERÍA: recibo directo de caja (ya validado por quien lo emite)
    // ------------------------------------------------------------------
    public async Task<(bool, string)> EmitirReciboDirectoAsync(
        int estudianteId, int periodoId, string conceptoCodigo, string tipoPagoCodigo, decimal monto, int cajeroId)
    {
        return await InsertarPagoAsync(estudianteId, periodoId, conceptoCodigo,
            tipoPagoCodigo, monto, "Validado", cajeroId, null);
    }

    private async Task<(bool, string)> InsertarPagoAsync(
        int estudianteId, int periodoId, string conceptoCodigo, string tipoPagoCodigo,
        decimal monto, string estadoInicial, int? validadorId, string? nota)
    {
        using var db = CreateConnection();
        db.Open();
        using var tx = db.BeginTransaction();

        var concepto = await db.QueryFirstOrDefaultAsync<(int Id, decimal Monto)>(
            "SELECT id, monto FROM conceptos_pago WHERE codigo = @C;",
            new { C = conceptoCodigo }, tx);
        if (concepto.Id == 0)
        {
            tx.Rollback();
            return (false, "El concepto de pago no existe.");
        }

        var tipoId = await db.ExecuteScalarAsync<int?>(
            "SELECT id FROM tipos_pago WHERE codigo = @C;",
            new { C = tipoPagoCodigo }, tx);
        if (tipoId is null)
        {
            tx.Rollback();
            return (false, "El tipo de pago no existe.");
        }

        if (monto <= 0)
        {
            tx.Rollback();
            return (false, "El monto debe ser mayor que cero.");
        }

        var codigo = await db.ExecuteScalarAsync<string>(SqlNuevoRecibo.Replace("{TABLA}", TablaPagos(db)), transaction: tx);

        var filas = await db.ExecuteAsync("""
            INSERT INTO {TABLA} (codigo, estudiante_id, concepto_pago_id, periodo_id,
                               tipo_pago_id, monto, fecha_pago, voucher_estado,
                               fecha_validacion, validado_por, motivo_rechazo)
            VALUES (@Codigo, @EstudianteId, @ConceptoId, @PeriodoId,
                    @TipoId, @Monto, CURRENT_DATE, @Estado,
                    CASE WHEN @Estado = 'Validado' THEN CURRENT_DATE END,
                    @Validador, @Nota);
            """.Replace("{TABLA}", TablaPagos(db)), new
        {
            Codigo = codigo,
            EstudianteId = estudianteId,
            ConceptoId = concepto.Id,
            PeriodoId = periodoId,
            TipoId = tipoId.Value,
            Monto = monto,
            Estado = estadoInicial,
            Validador = validadorId,
            Nota = nota
        }, tx);

        tx.Commit();
        return filas > 0
            ? (true, $"Recibo {codigo} registrado por S/ {monto:0.00}.")
            : (false, "No se pudo registrar el pago.");
    }

    // ------------------------------------------------------------------
    // BANDEJA: validar voucher — la acción central de Tesorería.
    // Aprobar marca Validado con fecha y validador (CHECK de coherencia
    // de la tabla lo exige); Rechazar exige motivo para el estudiante
    // e incrementa intentos (máx 20 por CHECK).
    // ------------------------------------------------------------------
    public async Task<(bool, string)> ValidarVoucherAsync(int pagoId, bool aprobar, string? motivo, int validadorId)
    {
        using var db = CreateConnection();

        if (!aprobar && string.IsNullOrWhiteSpace(motivo))
            return (false, "Indica el motivo del rechazo (el estudiante lo verá).");

        var filas = await db.ExecuteAsync("""
            UPDATE {TABLA}
            SET voucher_estado = @Estado,
                fecha_validacion = CASE WHEN @Estado = 'Validado' THEN CURRENT_DATE ELSE NULL END,
                validado_por = CASE WHEN @Estado = 'Validado' THEN @Validador ELSE NULL END,
                motivo_rechazo = @Motivo,
                intentos = intentos + 1,
                actualizado_en = CURRENT_TIMESTAMP
            WHERE id = @Id
              AND voucher_estado <> 'Validado';
            """, new { Id = pagoId, Estado = aprobar ? "Validado" : "Rechazado",
                       Motivo = motivo, Validador = validadorId });

        return filas > 0
            ? (true, aprobar
                ? "Voucher validado. La matrícula/trámite queda habilitado para conformidad."
                : "Voucher rechazado con motivo. El estudiante debe corregirlo.")
            : (false, "El pago no existe o ya fue validado.");
    }

    // ------------------------------------------------------------------
    // Métricas del dashboard del módulo
    // ------------------------------------------------------------------
    public async Task<PagosResumenDto> ResumenAsync()
    {
        using var db = CreateConnection();
        const string sql = """
            SELECT count(*) FILTER (WHERE voucher_estado = 'Pendiente')  AS PorValidar,
                   count(*) FILTER (WHERE voucher_estado = 'Validado')  AS Validados,
                   count(*) FILTER (WHERE voucher_estado = 'Rechazado') AS Rechazados,
                   COALESCE(sum(monto) FILTER (WHERE voucher_estado = 'Validado'), 0) AS Recaudado
            FROM {TABLA};
            """;
        return await db.QueryFirstOrDefaultAsync<PagosResumenDto>(sql.Replace("{TABLA}", TablaPagos(db))) ?? new PagosResumenDto();
    }

    public async Task<IEnumerable<ConceptoPagoDto>> ListarConceptosAsync()
    {
        using var db = CreateConnection();
        return await db.QueryAsync<ConceptoPagoDto>("""
            SELECT id, codigo, nombre, monto FROM conceptos_pago WHERE activo ORDER BY codigo;
            """);
    }

    public async Task<IEnumerable<TipoPagoDto>> ListarTiposPagoAsync()
    {
        using var db = CreateConnection();
        return await db.QueryAsync<TipoPagoDto>(
            "SELECT id, codigo, nombre FROM tipos_pago ORDER BY id;");
    }
}
