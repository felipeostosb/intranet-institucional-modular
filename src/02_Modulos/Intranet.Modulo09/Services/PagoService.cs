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
    Task<(bool Ok, string Mensaje)> SubirVoucherAsync(int pagoId, int estudianteId, string nombre, string tipo, byte[] contenido);
    Task<ArchivoVoucherDto?> ObtenerVoucherAsync(int pagoId);
    Task<PagosResumenDto> ResumenAsync();
    Task<ResumenTesoreriaDto> ResumenTesoreriaAsync();
    Task<ResumenAlumnoDto> ResumenAlumnoAsync(int estudianteId);
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
                   pa.codigo AS Periodo,
                   (SELECT count(*) FROM voucher_archivos va WHERE va.pago_id = p.id) > 0 AS TieneVoucher
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
                   pe.nombres || ' ' || pe.apellidos AS Estudiante,
                   (SELECT count(*) FROM voucher_archivos va WHERE va.pago_id = p.id) > 0 AS TieneVoucher
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
                   pe.nombres || ' ' || pe.apellidos AS Estudiante,
                   (SELECT count(*) FROM voucher_archivos va WHERE va.pago_id = p.id) > 0 AS TieneVoucher
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

        var tabla = TablaPagos(db);
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
            """.Replace("{TABLA}", tabla), new { Id = pagoId, Estado = aprobar ? "Validado" : "Rechazado",
                       Motivo = motivo, Validador = validadorId });

        if (filas == 0) return (false, "El pago no existe o ya fue validado.");

        // ------------------------------------------------------------------
        // Propagación trámite↔pago: si el pago pertenece a un trámite en curso
        // (p. ej. Reserva de Matrícula TM05), la validación de Tesorería
        // impulsa su avance: rechazo → trámite Observado con el motivo;
        // aprobación → el trámite queda listo para que Mesa lo cierre
        // (Aprobado/Entregado sigue siendo decisión de Secretaría).
        // La vinculación se resuelve SOLO por tramites.pago_id, presente en
        // producción (pagos_v2) y en espejos (pagos); la columna inversa
        // pagos.tramite_id solo existe en algunos espejos y NO en producción.
        // ------------------------------------------------------------------
        var tablaPagos = TablaPagos(db);
        var sqlTramite = "SELECT t.id FROM mod09.tramites t " +
                         "WHERE t.pago_id = @Id LIMIT 1;";
        var tramiteAfectado = await db.ExecuteScalarAsync<int?>(sqlTramite, new { Id = pagoId });
        if (tramiteAfectado is int tid)
        {
            await db.ExecuteAsync("""
                UPDATE mod09.tramites
                SET estado = CASE WHEN @Aprobado THEN 'En evaluación' ELSE 'Observado' END,
                    resolucion = CASE WHEN @Aprobado
                                THEN 'Voucher validado por Tesorería.'
                                ELSE 'Voucher rechazado: ' || @Motivo END,
                    fecha_resolucion = CURRENT_DATE,
                    actualizado_en = CURRENT_TIMESTAMP
                WHERE id = @Tid AND estado NOT IN ('Aprobado','Entregado','Rechazado');
                """, new { Aprobado = aprobar, Motivo = motivo, Tid = tid });
        }

        return (true, aprobar
            ? "Voucher validado. La matrícula/trámite queda habilitado para conformidad."
            : "Voucher rechazado con motivo. El estudiante debe corregirlo.");
    }

    // ------------------------------------------------------------------
    // ALUMNO: adjuntar el voucher PDF de su pago. Verifica que el pago sea
    // del estudiante (Zero-Blast-Radius: no se puede adjuntar a pagos ajenos).
    // ------------------------------------------------------------------
    public async Task<(bool, string)> SubirVoucherAsync(
        int pagoId, int estudianteId, string nombre, string tipo, byte[] contenido)
    {
        using var db = CreateConnection();
        var dueno = await db.ExecuteScalarAsync<int?>(
            "SELECT estudiante_id FROM " + TablaPagos(db) + " WHERE id = @Id;", new { Id = pagoId });
        if (dueno != estudianteId)
            return (false, "El recibo no existe o no es tuyo.");

        var filas = await db.ExecuteAsync("""
            INSERT INTO voucher_archivos (pago_id, archivo_nombre, archivo_tipo, archivo_contenido)
            VALUES (@Id, @Nombre, @Tipo, @Contenido)
            ON CONFLICT (pago_id) DO UPDATE SET
                archivo_nombre = EXCLUDED.archivo_nombre,
                archivo_tipo = EXCLUDED.archivo_tipo,
                archivo_contenido = EXCLUDED.archivo_contenido,
                subido_en = CURRENT_TIMESTAMP;
            """, new { Id = pagoId, Nombre = nombre, Tipo = tipo, Contenido = contenido });
        return filas > 0
            ? (true, "Voucher adjuntado. Tesorería lo validará desde su bandeja.")
            : (false, "No se pudo guardar el voucher.");
    }

    // ------------------------------------------------------------------
    // PERSONAL: leer el voucher PDF de un pago (validación con evidencia)
    // ------------------------------------------------------------------
    public async Task<ArchivoVoucherDto?> ObtenerVoucherAsync(int pagoId)
    {
        using var db = CreateConnection();
        return await db.QueryFirstOrDefaultAsync<ArchivoVoucherDto>("""
            SELECT archivo_nombre AS Nombre,
                   archivo_tipo AS Tipo,
                   archivo_contenido AS Contenido
            FROM voucher_archivos WHERE pago_id = @Id;
            """, new { Id = pagoId });
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

    // ------------------------------------------------------------------
    // Panel del puesto de TESORERÍA (Resumen del módulo): vouchers y
    // recaudación — sin nada de la mesa de trámites (eso es de Secretaría).
    // ------------------------------------------------------------------
    public async Task<ResumenTesoreriaDto> ResumenTesoreriaAsync()
    {
        using var db = CreateConnection();
        var t = TablaPagos(db);
        var dto = await db.QueryFirstOrDefaultAsync<ResumenTesoreriaDto>("""
            SELECT count(*) FILTER (WHERE voucher_estado = 'Pendiente')   AS VouchersPendientes,
                   count(*) FILTER (WHERE voucher_estado = 'Rechazado')   AS VouchersRechazados,
                   count(*) FILTER (WHERE voucher_estado = 'Validado'
                                      AND fecha_validacion = CURRENT_DATE) AS VouchersValidadosHoy,
                   COALESCE(sum(monto) FILTER (WHERE voucher_estado = 'Validado'
                                      AND fecha_validacion = CURRENT_DATE), 0) AS RecaudadoHoy,
                   COALESCE(sum(monto) FILTER (WHERE voucher_estado = 'Validado'), 0) AS RecaudadoPeriodo,
                   count(*) FILTER (WHERE voucher_estado = 'Validado')   AS RecibosValidados
            FROM {TABLA};
            """.Replace("{TABLA}", t)) ?? new ResumenTesoreriaDto();

        const string porConceptoSql = """
            SELECT cp.codigo AS Codigo,
                   cp.nombre AS Nombre,
                   COALESCE(sum(p.monto), 0) AS Monto,
                   count(p.id) AS Recibos
            FROM conceptos_pago cp
            LEFT JOIN {TABLA} p ON p.concepto_pago_id = cp.id AND p.voucher_estado = 'Validado'
            GROUP BY cp.codigo, cp.nombre
            HAVING count(p.id) > 0
            ORDER BY 3 DESC
            LIMIT 5;
            """;
        dto.PorConcepto = (await db.QueryAsync<RecaudacionPorConceptoDto>(
            porConceptoSql.Replace("{TABLA}", t))).ToList();
        return dto;
    }

    // ------------------------------------------------------------------
    // Panel personal del ALUMNO (Resumen del módulo): SUS trámites,
    // pagos y vouchers — cero cifras globales del instituto.
    // ------------------------------------------------------------------
    public async Task<ResumenAlumnoDto> ResumenAlumnoAsync(int estudianteId)
    {
        using var db = CreateConnection();
        var t = TablaPagos(db);
        var dto = new ResumenAlumnoDto();

        // Contadores de SUS trámites por estado (mesa de mod09)
        dto = await db.QueryFirstOrDefaultAsync<ResumenAlumnoDto>("""
            SELECT count(*) FILTER (WHERE tr.estado IN ('Recibido', 'En evaluación')) AS TramitesActivos,
                   count(*) FILTER (WHERE tr.estado = 'Observado')                    AS TramitesObservados,
                   count(*) FILTER (WHERE tr.estado IN ('Aprobado', 'Entregado'))     AS TramitesCerrados
            FROM mod09.tramites tr
            WHERE tr.estudiante_id = @Id;
            """, new { Id = estudianteId }) ?? dto;

        // Pagos del alumno: total validado + vouchers pendientes SIN adjunto
        var pagos = await db.QueryFirstOrDefaultAsync<(decimal Total, int PorSubir)>($"""
            SELECT COALESCE(sum(monto) FILTER (WHERE p.voucher_estado = 'Validado'), 0),
                   count(*) FILTER (WHERE p.voucher_estado <> 'Validado'
                       AND NOT EXISTS (SELECT 1 FROM mod09.voucher_archivos va
                                       WHERE va.pago_id = p.id))
            FROM {t} p
            WHERE p.estudiante_id = @Id;
            """, new { Id = estudianteId });
        dto.TotalPagado = pagos.Total;
        dto.VouchersPorSubir = pagos.PorSubir;

        // Últimos trámites con el voucher de su pago vinculado
        const string ultimosSql = """
            SELECT tr.id AS Id,
                   tr.codigo AS Codigo,
                   tt.nombre AS TipoNombre,
                   tr.estado AS Estado,
                   COALESCE(p.voucher_estado, '') AS VoucherEstado,
                   tr.creado_en AS FechaSolicitud
            FROM mod09.tramites tr
            JOIN mod09.tipos_tramite tt ON tt.id = tr.tipo_tramite_id
            LEFT JOIN {TABLA} p ON p.id = tr.pago_id
            WHERE tr.estudiante_id = @Id
            ORDER BY tr.creado_en DESC
            LIMIT 5;
            """;
        dto.Ultimos = (await db.QueryAsync<MiTramiteCardDto>(
            ultimosSql.Replace("{TABLA}", t), new { Id = estudianteId })).ToList();
        return dto;
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
