using System.Data;
using Dapper;
using Intranet.Core.Contracts;
using Intranet.Modulo01.Models;

namespace Intranet.Modulo01.Services;

/// <summary>
/// Matriculatura de Secretaría — CU del flujo real "Reserva de Matrícula":
/// el estudiante inicia el trámite TM05 (TUPA 4.8), paga el CT13, sube el
/// voucher y Tesorería lo valida. Con eso, Secretaría busca al alumno por
/// DNI, ve su semestre culminado / próximo, carrera, turno, condición
/// (Promovido / Promovido con curso a cargo / Repitente según el
/// historial académico) y elige las unidades didácticas del nuevo
/// semestre para cerrar la matrícula y emitir la ficha PDF.
/// Domina las tablas mod01: matriculas[_v2], historial_academico,
/// oferta_ciclo, detalles_matricula, fichas_enviadas + mod09 solo-lectura.
/// </summary>
public interface IMatriculaturaService
{
    /// <summary>Busca al estudiante por DNI con su situación académica para matricular.</summary>
    Task<ExpedienteMatriculaDto?> BuscarPorDniAsync(string dni);

    /// <summary>Matricula: crea/actualiza la matrícula con las UDs elegidas del próximo ciclo.</summary>
    Task<(bool Ok, string Mensaje, int MatriculaId)> MatricularAsync(
        MatricularCommand cmd, int usuarioId);

    /// <summary> Datos de la ficha PDF de una matrícula cerrada (para descargar/reenviar).</summary>
    Task<FichaMatriculaDto?> ObtenerFichaAsync(int matriculaId);

    /// <summary>Mini-dashboard personal del alumno para el Resumen del módulo.</summary>
    Task<PanelAlumnoDto?> PanelAlumnoAsync(int estudianteId);
}

/// <summary>Comando de matrícula desde el puesto de Secretaría.</summary>
public record MatricularCommand(
    string Dni,
    int? MatriculaId,          // matrícula "En trámite" existente (reserva), si la hay
    int? TramiteId,            // o el trámite TM05 del módulo 09 (matrícula se crea aquí)
    string CicloProximo,        // ciclo al que se matricula (para el carril de vacantes)
    int TurnoId,
    int TipoMatriculaId,
    string Condicion,           // Promovido | Promovido con curso a cargo | Repitente
    string CursosDesaprobadosNombres,  // para observaciones de la ficha
    IEnumerable<string> UnidadesDidacticasIds);  // "core:5" | "espejo:1"

public class MatriculaturaService : IMatriculaturaService
{
    private readonly IModuleDbConnectionFactory _connectionFactory;

    public MatriculaturaService(IModuleDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    private IDbConnection CreateConnection() => _connectionFactory.CreateConnection("01");

    // Mismo patrón que MatriculaService: en producción "matriculas" es
    // legacy de otro dueño y la tabla real es "matriculas_v2".
    private static string? _tablaMatriculas;
    private static string TablaMatriculas(IDbConnection db)
    {
        if (_tablaMatriculas != null) return _tablaMatriculas;
        try
        {
            var tieneCol = db.ExecuteScalar<int?>(
                "SELECT 1 FROM information_schema.columns WHERE table_schema = 'mod01' AND table_name = 'matriculas' AND column_name = 'voucher_ok';");
            _tablaMatriculas = tieneCol == 1 ? "matriculas" : "matriculas_v2";
        }
        catch { _tablaMatriculas = "matriculas"; }
        return _tablaMatriculas;
    }

    // ------------------------------------------------------------------
    // BUSCAR POR DNI: ficha del alumno lista para matricular
    // ------------------------------------------------------------------
    public async Task<ExpedienteMatriculaDto?> BuscarPorDniAsync(string dni)
    {
        using var db = CreateConnection();
        var sql = """
            SELECT e.id AS EstudianteId,
                   e.codigo_estudiante AS CodigoEstudiante,
                   p.nombres || ' ' || p.apellidos AS Estudiante,
                   p.dni AS Dni,
                   p.email_personal AS EmailPersonal,
                   u.email AS EmailInstitucional,
                   c.id AS CarreraId,
                   c.nombre AS Carrera,
                   c.codigo AS CarreraCodigo,
                   e.ciclo_actual AS CicloActual
            FROM estudiantes e
            JOIN personas p ON p.id = e.persona_id
            LEFT JOIN usuarios u ON u.persona_id = p.id
            JOIN carreras c ON c.id = e.carrera_id
            WHERE p.dni = @Dni
            LIMIT 1;
            """;
        var dto = await db.QueryFirstOrDefaultAsync<ExpedienteMatriculaDto>(sql, new { Dni = dni.Trim() });
        if (dto == null) return null;

        // Historial académico del último período cursado → aprobados/desaprobados
        const string histSql = """
            SELECT ud.codigo AS UnidadCodigo,
                   ud.nombre AS UnidadNombre,
                   ud.ciclo AS Ciclo,
                   h.nota AS Nota,
                   h.estado AS Estado
            FROM historial_academico h
            JOIN unidades_didacticas ud ON ud.id = h.unidad_didactica_id
            WHERE h.estudiante_id = @EstudianteId
            ORDER BY ud.ciclo, ud.codigo;
            """;
        var hist = (await db.QueryAsync<HistorialFilaDto>(histSql,
            new { dto.EstudianteId })).ToList();
        dto.Historial = hist;

        var desprobados = hist.Where(h => h.Estado == "Desaprobado").ToList();
        dto.CursosDesaprobados = desprobados.Count;
        // Condición según el RI: sin desaprobados → Promovido; con
        // desaprobados → "Promovido con curso a cargo" (lleva los cursos
        // retrasados además de los del nuevo ciclo).
        dto.Condicion = desprobados.Count == 0 ? "Promovido"
            : hist.All(h => h.Estado == "Desaprobado") ? "Repitente"
            : "Promovido con curso a cargo";
        dto.CursosDesaprobadosNombres = string.Join(", ",
            desprobados.Select(h => $"{h.UnidadCodigo} ({h.Nota:0.0})"));

        // Próximo ciclo: el que sigue al último con historial (o al actual)
        var ordenCiclo = new[] { "I", "II", "III", "IV", "V", "VI" };
        var ultimoCiclo = hist.Select(h => h.Ciclo).Distinct()
            .OrderByDescending(x => Array.IndexOf(ordenCiclo, x)).FirstOrDefault()
            ?? dto.CicloActual;
        var idx = Array.IndexOf(ordenCiclo, ultimoCiclo);
        dto.CicloCulminado = ultimoCiclo;
        dto.CicloProximo = idx < 0 || idx >= ordenCiclo.Length - 1
            ? ultimoCiclo : ordenCiclo[idx + 1];

        // Oferta del próximo ciclo: primero core.unidades_didacticas (oficial);
        // si el ciclo aún no existe ahí, cae al espejo mod01.oferta_ciclo.
        const string ofertaCore = """
            SELECT ud.id AS Id,
                   'core' AS Origen,
                   ud.codigo AS Codigo,
                   ud.nombre AS Nombre,
                   ud.creditos AS Creditos,
                   ud.tipo AS Tipo,
                   ud.ciclo AS Ciclo,
                   TRUE AS Obligatoria
            FROM unidades_didacticas ud
            WHERE ud.carrera_id = @CarreraId AND ud.ciclo = @Ciclo
            ORDER BY ud.codigo;
            """;
        var oferta = (await db.QueryAsync<UnidadOfertaDto>(ofertaCore,
            new { dto.CarreraId, Ciclo = dto.CicloProximo })).ToList();
        if (oferta.Count == 0)
        {
            const string ofertaEspejo = """
                SELECT oc.id AS Id,
                       'espejo' AS Origen,
                       oc.codigo AS Codigo,
                       oc.nombre AS Nombre,
                       oc.creditos AS Creditos,
                       oc.tipo AS Tipo,
                       oc.ciclo AS Ciclo,
                       oc.obligatoria AS Obligatoria
                FROM oferta_ciclo oc
                WHERE oc.carrera_id = @CarreraId AND oc.ciclo = @Ciclo
                ORDER BY oc.codigo;
                """;
            oferta = (await db.QueryAsync<UnidadOfertaDto>(ofertaEspejo,
                new { dto.CarreraId, Ciclo = dto.CicloProximo })).ToList();
        }

        // Los cursos desaprobados se matriculan también (curso a cargo):
        // se marcan como "Curso a cargo (repitencia)" en la oferta.
        foreach (var o in oferta.Where(o =>
                     desprobados.Any(d => d.UnidadCodigo == o.Codigo)))
        {
            o.EsCursoACargo = true;
        }
        // y se AGREGAN los desaprobados de ciclos previos si no están en la oferta
        foreach (var d in desprobados.Where(d =>
                     oferta.All(o => o.Codigo != d.UnidadCodigo)))
        {
            var udId = await db.ExecuteScalarAsync<int?>(
                "SELECT id FROM unidades_didacticas WHERE codigo = @Cod LIMIT 1;",
                new { Cod = d.UnidadCodigo });
            oferta.Add(new UnidadOfertaDto
            {
                Id = udId ?? 0,
                Origen = "core",
                Codigo = d.UnidadCodigo,
                Nombre = d.UnidadNombre + " (curso a cargo)",
                Creditos = 4,
                Tipo = "Formativa",
                Ciclo = dto.CicloProximo,
                Obligatoria = true,
                EsCursoACargo = true
            });
        }
        dto.OfertaProximoCiclo = oferta;

        // Voucher del trámite de reserva: TM05 con pago Validado habilita a matricular.
        // Solo importan las matrículas ABIERTAS (En trámite); una matrícula vieja ya
        // cerrada no es una reserva pendiente de Secretaría.
        const string voucherSql = """
            SELECT m.id AS MatriculaId,
                   m.codigo_matricula AS CodigoMatricula,
                   m.estado AS Estado,
                   m.voucher_ok AS VoucherOk,
                   t.id AS TramiteId,
                   t.codigo AS TramiteCodigo,
                   t.estado AS TramiteEstado,
                   pg.voucher_estado AS VoucherEstado,
                   pg.monto AS VoucherMonto,
                   (pm.permite_matricula OR pm.id IS NULL) AS PeriodoHabilitado
            FROM matriculas_v2 m
            LEFT JOIN mod09.tramites t ON t.id = m.tramite_reserva_id
            LEFT JOIN mod09.pagos_v2 pg ON pg.id = t.pago_id
            LEFT JOIN periodos_academicos pm ON pm.id = m.periodo_id
            WHERE m.estudiante_id = @EstudianteId
              AND m.estado = 'En trámite'
            ORDER BY m.creado_en DESC
            LIMIT 1;
            """;
        var tabla = TablaMatriculas(db);
        var voucher = await db.QueryFirstOrDefaultAsync<ReservaDto>(
            voucherSql.Replace("matriculas_v2", tabla)
                      .Replace("pagos_v2", tabla == "matriculas" ? "pagos" : "pagos_v2"),
            new { dto.EstudianteId });

        // Sin matrícula registrada: el alumno puede tener el TRÁMITE TM05 en
        // curso (módulo 09) sin que exista aún su matrícula en mod01 — mostrarlo
        // igual para que Secretaría sepa que el alumno SÍ tramitó su reserva.
        if (voucher == null)
        {
            var tramiteSql = """
                SELECT 0 AS MatriculaId,
                       '' AS CodigoMatricula,
                       'En trámite' AS Estado,
                       FALSE AS VoucherOk,
                       t.id AS TramiteId,
                       t.codigo AS TramiteCodigo,
                       t.estado AS TramiteEstado,
                       pg.voucher_estado AS VoucherEstado,
                       pg.monto AS VoucherMonto,
                       FALSE AS PeriodoHabilitado
                FROM mod09.tramites t
                JOIN mod09.tipos_tramite tt ON tt.id = t.tipo_tramite_id
                LEFT JOIN mod09.pagos_v2 pg ON pg.id = t.pago_id
                WHERE t.estudiante_id = @EstudianteId AND tt.codigo = 'TM05'
                  AND t.estado NOT IN ('Rechazado', 'Entregado')
                ORDER BY t.creado_en DESC
                LIMIT 1;
                """.Replace("pagos_v2", tabla == "matriculas" ? "pagos" : "pagos_v2");
            voucher = await db.QueryFirstOrDefaultAsync<ReservaDto>(
                tramiteSql, new { dto.EstudianteId });
        }

        dto.Reserva = voucher;

        // Regla del sistema (uq_matricula_vigente): un estudiante tiene UNA sola
        // matrícula no anulada por período. Si ya está Matriculado en un período
        // habilitado, no se abre otra — esa es SU matrícula del período.
        var yaMatriculado = await db.QueryFirstOrDefaultAsync<ReservaDto>("""
            SELECT m.id AS MatriculaId,
                   m.codigo_matricula AS CodigoMatricula,
                   'Matriculado' AS Estado
            FROM matriculas_v2 m
            WHERE m.estudiante_id = @EstudianteId
              AND m.estado = 'Matriculado'
              AND m.periodo_id IN (SELECT id FROM periodos_academicos WHERE permite_matricula)
            ORDER BY m.creado_en DESC
            LIMIT 1;
            """.Replace("matriculas_v2", tabla), new { dto.EstudianteId });

        // La matrícula se puede cerrar si el voucher del trámite fue Validado por
        // Tesorería Y el período destino está habilitado para matrícula. Sin
        // matrícula aún, el periodo destino es el que tenga permite_matricula.
        if (voucher == null)
        {
            dto.PuedeMatricular = false;
        }
        else if (voucher.MatriculaId > 0)
        {
            dto.PuedeMatricular = voucher.VoucherEstado == "Validado" && voucher.PeriodoHabilitado;
        }
        else
        {
            var hayPeriodo = await db.ExecuteScalarAsync<int>(
                "SELECT count(*) FROM periodos_academicos WHERE permite_matricula;");
            dto.PuedeMatricular = voucher.VoucherEstado == "Validado" && hayPeriodo > 0;
            voucher.PeriodoHabilitado = hayPeriodo > 0;
        }

        // Ya matriculado en el período destino: no hay nada que cerrar
        if (yaMatriculado != null)
        {
            dto.PuedeMatricular = false;
            dto.YaMatriculadoId = yaMatriculado.MatriculaId;
            // La matrícula ya cerrada del período habilitado gana a cualquier
            // reserva abierta vieja en el expediente: es SU matrícula vigente.
            dto.Reserva = yaMatriculado;
        }

        return dto;
    }

    // ------------------------------------------------------------------
    // MATRICULAR: cierra la matrícula del período con las UDs elegidas
    // ------------------------------------------------------------------
    public async Task<(bool, string, int)> MatricularAsync(MatricularCommand cmd, int usuarioId)
    {
        using var db = CreateConnection();
        db.Open();
        using var tx = db.BeginTransaction();
        var tabla = TablaMatriculas(db);
        var tablaPagos = tabla == "matriculas" ? "pagos" : "pagos_v2";

        // 0) El estudiante existe
        var estudiante = await db.QueryFirstOrDefaultAsync<(int Id, int CarreraId)>(
            "SELECT e.id, e.carrera_id FROM estudiantes e JOIN personas p ON p.id = e.persona_id WHERE p.dni = @Dni;",
            new { cmd.Dni }, tx);
        if (estudiante.Id == 0)
        {
            tx.Rollback();
            return (false, "No se encontró estudiante con ese DNI.", 0);
        }

        // 1) La reserva: matrícula "En trámite" existente, o el propio trámite TM05
        //    con voucher Validado (la matrícula se crea aquí mismo en la transacción).
        MatriculaCierreDto? fila = null;
        if (cmd.MatriculaId is int mid)
        {
            var upd = """
                UPDATE {TABLA}
                SET turno_id = @TurnoId,
                    tipo_matricula_id = @TipoMatriculaId,
                    condicion = @Condicion,
                    observaciones_cursos = @Obs,
                    voucher_ok = TRUE,
                    fecha_matricula = CURRENT_DATE,
                    conforme_por = @UsuarioId,
                    actualizado_en = CURRENT_TIMESTAMP
                WHERE id = @Id AND estado = 'En trámite'
                  AND EXISTS (SELECT 1 FROM mod09.tramites t JOIN mod09.pagos_v2 pg ON pg.id = t.pago_id
                              WHERE t.id = {TABLA}.tramite_reserva_id AND pg.voucher_estado = 'Validado')
                RETURNING id,
                          estudiante_id AS EstudianteId,
                          carrera_id AS CarreraId,
                          ciclo_id AS CicloId,
                          turno_id AS TurnoId,
                          periodo_id AS PeriodoId;
                """.Replace("{TABLA}", tabla).Replace("pagos_v2", tablaPagos);
            fila = await db.QueryFirstOrDefaultAsync<MatriculaCierreDto>(upd, new
            {
                Id = mid,
                TurnoId = cmd.TurnoId,
                TipoMatriculaId = cmd.TipoMatriculaId,
                Condicion = cmd.Condicion,
                Obs = cmd.CursosDesaprobadosNombres,
                UsuarioId = usuarioId
            }, tx);
        }
        else if (cmd.TramiteId is int tramId)
        {
            // Creación desde el trámite: el alumno hizo su Reserva TM05 en el
            // módulo 09 pero aún no existe matrícula en mod01. Validar que el
            // trámite sea suyo, sea TM05, su voucher esté Validado y que el
            // período destino (el activo para matrícula) exista.
            var tramite = await db.QueryFirstOrDefaultAsync<(int EstudianteId, string Tipo, int? PagoId, string VoucherEstado)>("""
                SELECT t.estudiante_id AS EstudianteId,
                       tt.codigo AS Tipo,
                       t.pago_id AS PagoId,
                       COALESCE(pg.voucher_estado, 'Pendiente') AS VoucherEstado
                FROM mod09.tramites t
                JOIN mod09.tipos_tramite tt ON tt.id = t.tipo_tramite_id
                LEFT JOIN mod09.pagos_v2 pg ON pg.id = t.pago_id
                WHERE t.id = @Id AND t.estado NOT IN ('Rechazado', 'Entregado');
                """.Replace("pagos_v2", tablaPagos), new { Id = tramId }, tx);
            if (tramite.EstudianteId != estudiante.Id)
            {
                tx.Rollback();
                return (false, "El trámite indicado no pertenece a ese estudiante.", 0);
            }
            if (tramite.Tipo != "TM05")
            {
                tx.Rollback();
                return (false, "El trámite indicado no es una Reserva de Matrícula (TM05).", 0);
            }
            if (tramite.VoucherEstado != "Validado")
            {
                tx.Rollback();
                return (false, "El voucher de la reserva aún no está validado por Tesorería.", 0);
            }

            var periodoId = await db.ExecuteScalarAsync<int?>(
                "SELECT id FROM periodos_academicos WHERE permite_matricula ORDER BY id DESC LIMIT 1;", tx);
            if (periodoId == null)
            {
                tx.Rollback();
                return (false, "No hay período académico habilitado para matrícula.", 0);
            }

            // Regla del sistema (uq_matricula_vigente): no puede existir otra
            // matrícula no anulada del mismo estudiante en el mismo período.
            var yaExiste = await db.ExecuteScalarAsync<int?>(
                $"SELECT id FROM {tabla} WHERE estudiante_id = @EstudianteId AND periodo_id = @PeriodoId AND estado <> 'Anulada';",
                new { EstudianteId = estudiante.Id, PeriodoId = periodoId }, tx);
            if (yaExiste != null)
            {
                tx.Rollback();
                return (false, "El estudiante ya tiene una matrícula en el período habilitado.", 0);
            }

            // datos del estudiante para el carril (carrera/ciclo/turno)
            var cicloId = await db.ExecuteScalarAsync<int?>(
                "SELECT id FROM ciclos WHERE codigo = @Ciclo;", new { Ciclo = cmd.CicloProximo }, tx);
            if (cicloId == null)
            {
                tx.Rollback();
                return (false, $"El ciclo {cmd.CicloProximo} no existe en el catálogo.", 0);
            }

            var codigoMat = await db.ExecuteScalarAsync<string>($"""
                SELECT 'MAT-' || (SELECT codigo FROM periodos_academicos WHERE id = @PeriodoId)
                       || '-' || lpad((count(*) + 90)::text, 3, '0')
                FROM {tabla} WHERE periodo_id = @PeriodoId;
                """, new { PeriodoId = periodoId }, tx);

            var nuevoId = await db.ExecuteScalarAsync<int>($"""
                INSERT INTO {tabla} (codigo_matricula, estudiante_id, periodo_id, carrera_id,
                                     ciclo_id, turno_id, tipo_matricula_id, condicion, estado, etapa,
                                     voucher_ok, fecha_matricula, conforme_por, observaciones_cursos,
                                     tramite_reserva_id)
                VALUES (@Codigo, @EstudianteId, @PeriodoId, @CarreraId,
                        @CicloId, @TurnoId, @TipoMatriculaId, @Condicion, 'Matriculado', 'Cerrada',
                        TRUE, CURRENT_DATE, @UsuarioId, @Obs, @TramiteId)
                RETURNING id;
                """, new
            {
                Codigo = codigoMat,
                EstudianteId = estudiante.Id,
                PeriodoId = periodoId,
                CarreraId = estudiante.CarreraId,
                CicloId = cicloId,
                TurnoId = cmd.TurnoId,
                TipoMatriculaId = cmd.TipoMatriculaId,
                Condicion = cmd.Condicion,
                Obs = cmd.CursosDesaprobadosNombres,
                UsuarioId = usuarioId,
                TramiteId = tramId
            }, tx);
            fila = new MatriculaCierreDto
            {
                Id = nuevoId,
                EstudianteId = estudiante.Id,
                CarreraId = estudiante.CarreraId,
                CicloId = cicloId.Value,
                TurnoId = cmd.TurnoId,
                PeriodoId = periodoId.Value
            };
        }
        if (fila == null)
        {
            tx.Rollback();
            return (false, "La matrícula no existe, ya fue cerrada o su voucher de reserva no está validado por Tesorería.", 0);
        }

        // 2) Reemplazar el detalle de UDs por las elegidas.
        //    Cada value llega como "core:5" o "espejo:1" (origen explícito para
        //    evitar colisiones de ids entre core.unidades_didacticas y el espejo).
        await db.ExecuteAsync("DELETE FROM detalles_matricula WHERE matricula_id = @Id;",
            new { fila.Id }, tx);
        foreach (var raw in cmd.UnidadesDidacticasIds.Distinct())
        {
            var partes = raw.Split(':', 2);
            if (partes.Length != 2 || !int.TryParse(partes[1], out var udId)) continue;
            var origen = partes[0];
            if (origen == "core")
            {
                var existe = await db.ExecuteScalarAsync<int?>(
                    "SELECT id FROM unidades_didacticas WHERE id = @UdId;", new { UdId = udId }, tx);
                if (existe != null)
                {
                    await db.ExecuteAsync("""
                        INSERT INTO detalles_matricula (matricula_id, unidad_didactica_id, estado)
                        VALUES (@MatId, @UdId, 'Inscrito');
                        """, new { MatId = fila.Id, UdId = udId }, tx);
                }
            }
            else // espejo: mod01.oferta_ciclo (core aún no tiene el ciclo)
            {
                var existe = await db.ExecuteScalarAsync<int?>(
                    "SELECT id FROM oferta_ciclo WHERE id = @UdId;", new { UdId = udId }, tx);
                if (existe != null)
                {
                    await db.ExecuteAsync("""
                        INSERT INTO detalles_matricula (matricula_id, oferta_ciclo_id, estado)
                        VALUES (@MatId, @UdId, 'Inscrito');
                        """, new { MatId = fila.Id, UdId = udId }, tx);
                }
            }
        }
        var inscritas = await db.ExecuteScalarAsync<int>(
            "SELECT count(*) FROM detalles_matricula WHERE matricula_id = @Id;", new { fila.Id }, tx);
        if (inscritas == 0)
        {
            tx.Rollback();
            return (false, "Selecciona al menos una unidad didáctica.", 0);
        }

        // 3) Consumir vacante del carril (carrera/turno/ciclo/periodo) y cerrar
        const string vac = """
            UPDATE vacantes
            SET vacantes = vacantes - 1
            WHERE periodo_id = @PeriodoId AND carrera_id = @CarreraId
              AND turno_id = @TurnoId AND ciclo_id = @CicloId AND vacantes > 0;
            """;
        var consumidas = await db.ExecuteAsync(vac, new
        {
            fila.PeriodoId, fila.CarreraId, fila.TurnoId, fila.CicloId
        }, tx);
        if (consumidas == 0)
        {
            tx.Rollback();
            return (false, "No hay vacantes en ese carril (carrera/turno/ciclo).", 0);
        }

        var cerrar = """
            UPDATE {TABLA}
            SET estado = 'Matriculado', etapa = 'Cerrada', actualizado_en = CURRENT_TIMESTAMP
            WHERE id = @Id;
            """.Replace("{TABLA}", tabla);
        await db.ExecuteAsync(cerrar, new { fila.Id }, tx);

        tx.Commit();
        return (true, $"Matrícula cerrada: {inscritas} unidad(es) inscritas y vacante consumida.", fila.Id);
    }

    // ------------------------------------------------------------------
    // FICHA PDF: datos de la matrícula cerrada para el PDF y el reenvío
    // ------------------------------------------------------------------
    public async Task<FichaMatriculaDto?> ObtenerFichaAsync(int matriculaId)
    {
        using var db = CreateConnection();
        var tabla = TablaMatriculas(db);

        var sql = """
            SELECT m.codigo_matricula AS CodigoMatricula,
                   per.codigo AS Periodo,
                   p.nombres || ' ' || p.apellidos AS Estudiante,
                   e.codigo_estudiante AS CodigoEstudiante,
                   p.dni AS Dni,
                   c.nombre AS Carrera,
                   c.codigo AS CarreraCodigo,
                   m.condicion AS Condicion,
                   m.observaciones_cursos AS CursosDesaprobadosNombres,
                   m.fecha_matricula AS FechaMatricula,
                   m.estado AS Estado,
                   t.nombre AS Turno,
                   tm.nombre AS TipoMatricula
            FROM {TABLA} m
            JOIN estudiantes e ON e.id = m.estudiante_id
            JOIN personas p ON p.id = e.persona_id
            JOIN carreras c ON c.id = m.carrera_id
            JOIN periodos_academicos per ON per.id = m.periodo_id
            LEFT JOIN turnos t ON t.id = m.turno_id
            LEFT JOIN tipos_matricula tm ON tm.id = m.tipo_matricula_id
            WHERE m.id = @Id;
            """.Replace("{TABLA}", tabla);
        var ficha = await db.QueryFirstOrDefaultAsync<FichaMatriculaDto>(sql, new { Id = matriculaId });
        if (ficha == null) return null;

        // UDs inscritas: de core (unidad_didactica_id) o del espejo mod01.oferta_ciclo
        var uds = """
            SELECT x.Id, x.Origen, x.Codigo, x.Nombre, x.Creditos, x.Tipo, x.Ciclo, TRUE AS Obligatoria
            FROM (
                SELECT ud.id AS Id, 'core' AS Origen, ud.codigo AS Codigo, ud.nombre AS Nombre,
                       ud.creditos AS Creditos, ud.tipo AS Tipo, ud.ciclo AS Ciclo
                FROM detalles_matricula d
                JOIN unidades_didacticas ud ON ud.id = d.unidad_didactica_id
                WHERE d.matricula_id = @Id
                UNION ALL
                SELECT oc.id AS Id, 'espejo' AS Origen, oc.codigo AS Codigo, oc.nombre AS Nombre,
                       oc.creditos AS Creditos, oc.tipo AS Tipo, oc.ciclo AS Ciclo
                FROM detalles_matricula d
                JOIN oferta_ciclo oc ON oc.id = d.oferta_ciclo_id
                WHERE d.matricula_id = @Id
            ) x
            ORDER BY x.Codigo;
            """;
        ficha.Unidades = (await db.QueryAsync<UnidadOfertaDto>(uds, new { Id = matriculaId })).ToList();

        // Ciclo culminado/próximo: el mayor ciclo de las UDs inscritas menos uno,
        // o el del historial del estudiante
        var orden = new[] { "I", "II", "III", "IV", "V", "VI" };
        var maxCiclo = ficha.Unidades.Select(u => Array.IndexOf(orden, u.Ciclo)).DefaultIfEmpty(-1).Max();
        ficha.CicloProximo = maxCiclo >= 0 ? orden[maxCiclo] : "";
        ficha.CicloCulminado = maxCiclo > 0 ? orden[maxCiclo - 1] : "";

        return ficha;
    }

    // ------------------------------------------------------------------
    // PANEL DEL ALUMNO (pestaña Resumen): mini-dashboard con datos reales
    // del propio estudiante — historial con notas, promedio, condición y
    // el estado de SU flujo de reserva (trámite → voucher → matrícula).
    // ------------------------------------------------------------------
    public async Task<PanelAlumnoDto?> PanelAlumnoAsync(int estudianteId)
    {
        using var db = CreateConnection();

        // Datos base del estudiante
        var dto = await db.QueryFirstOrDefaultAsync<PanelAlumnoDto>("""
            SELECT e.codigo_estudiante AS CodigoEstudiante,
                   p.nombres || ' ' || p.apellidos AS Estudiante,
                   c.nombre AS Carrera,
                   c.codigo AS CarreraCodigo
            FROM estudiantes e
            JOIN personas p ON p.id = e.persona_id
            JOIN carreras c ON c.id = e.carrera_id
            WHERE e.id = @Id;
            """, new { Id = estudianteId });
        if (dto == null) return null;

        // Historial académico completo (mismas columnas que el expediente)
        const string histSql = """
            SELECT ud.codigo AS UnidadCodigo,
                   ud.nombre AS UnidadNombre,
                   ud.ciclo AS Ciclo,
                   h.nota AS Nota,
                   h.estado AS Estado
            FROM historial_academico h
            JOIN unidades_didacticas ud ON ud.id = h.unidad_didactica_id
            WHERE h.estudiante_id = @Id
            ORDER BY ud.ciclo, ud.codigo;
            """;
        dto.Historial = (await db.QueryAsync<HistorialFilaDto>(histSql,
            new { Id = estudianteId })).ToList();

        // Promedio ponderado y créditos aprobados (del historial + UDs oficiales)
        if (dto.Historial.Count > 0)
        {
            dto.Promedio = dto.Historial.Average(h => h.Nota);
            dto.CreditosAprobados = await db.ExecuteScalarAsync<int>("""
                SELECT COALESCE(SUM(ud.creditos), 0)
                FROM historial_academico h
                JOIN unidades_didacticas ud ON ud.id = h.unidad_didactica_id
                WHERE h.estudiante_id = @Id AND h.estado = 'Aprobado';
                """, new { Id = estudianteId });
        }

        // Condición según el RI + ciclo culminado/próximo (misma lógica del expediente)
        var desprobados = dto.Historial.Where(h => h.Estado == "Desaprobado").ToList();
        dto.Condicion = desprobados.Count == 0 ? "Promovido"
            : dto.Historial.All(h => h.Estado == "Desaprobado") ? "Repitente"
            : "Promovido con curso a cargo";
        dto.CursosDesaprobadosNombres = string.Join(", ",
            desprobados.Select(h => $"{h.UnidadCodigo} ({h.Nota:0.0})"));

        var orden = new[] { "I", "II", "III", "IV", "V", "VI" };
        var ultimo = dto.Historial.Select(h => h.Ciclo).Distinct()
            .OrderByDescending(x => Array.IndexOf(orden, x)).FirstOrDefault();
        dto.CicloActual = ultimo ?? "";
        var idx = string.IsNullOrEmpty(ultimo) ? -1 : Array.IndexOf(orden, ultimo);
        dto.CicloProximo = idx >= 0 && idx < orden.Length - 1 ? orden[idx + 1] : ultimo ?? "";

        // ---- Timeline del flujo: trámite TM05 → voucher → matrícula ----
        var tabla = TablaMatriculas(db);
        var reserva = await db.QueryFirstOrDefaultAsync<ReservaAlumnoRow>("""
            SELECT m.id AS MatriculaId,
                   m.codigo_matricula AS Codigo,
                   m.estado AS Estado,
                   COALESCE(pg.voucher_estado, '') AS Voucher,
                   COALESCE(t.estado, '') AS TramiteEstado,
                   COALESCE(t.codigo, '') AS TramiteCodigo
            FROM matriculas_v2 m
            LEFT JOIN mod09.tramites t ON t.id = m.tramite_reserva_id
            LEFT JOIN mod09.pagos_v2 pg ON pg.id = t.pago_id
            WHERE m.estudiante_id = @Id
            ORDER BY m.creado_en DESC
            LIMIT 1;
            """.Replace("matriculas_v2", tabla)
                .Replace("pagos_v2", tabla == "matriculas" ? "pagos" : "pagos_v2"),
            new { Id = estudianteId }) ?? new ReservaAlumnoRow();

        var pasos = new List<PasoFlujoDto>();
        // Paso 1: trámite TM05 (mod09) — existe si hay reserva o trámite directo
        var tramiteExiste = reserva.TramiteCodigo != "" || reserva.MatriculaId > 0;
        pasos.Add(new PasoFlujoDto
        {
            Titulo = "Trámite de Reserva (TM05)",
            Detalle = reserva.TramiteCodigo != "" ? $"{reserva.TramiteCodigo} — {reserva.TramiteEstado}"
                : tramiteExiste ? "Vinculado a tu matrícula" : "Aún no iniciado — hazlo en Trámites TUPA",
            Estado = tramiteExiste ? "Completado" : "Pendiente"
        });
        // Paso 2: voucher validado por Tesorería
        var voucherOk = reserva.Voucher == "Validado" || reserva.Estado == "Matriculado";
        pasos.Add(new PasoFlujoDto
        {
            Titulo = "Voucher validado por Tesorería",
            Detalle = voucherOk ? "Tu voucher fue validado ✅"
                : reserva.Voucher == "Rechazado" ? "Rechazado — revisa el motivo y sube otro"
                : tramiteExiste ? "En revisión por Tesorería" : "Pendiente de iniciar el trámite",
            Estado = voucherOk ? "Completado"
                : tramiteExiste ? "Actual" : "Pendiente"
        });
        // Paso 3: matrícula cerrada por Secretaría
        var cerrada = reserva.Estado == "Matriculado";
        pasos.Add(new PasoFlujoDto
        {
            Titulo = "Matrícula cerrada por Secretaría",
            Detalle = cerrada ? $"{reserva.Codigo} — matriculado en el ciclo {dto.CicloProximo}"
                : reserva.MatriculaId > 0 ? $"{reserva.Codigo} — en trámite"
                : "Se cierra cuando el período esté habilitado",
            Estado = cerrada ? "Completado" : voucherOk ? "Actual" : "Pendiente"
        });
        dto.PasosFlujo = pasos;
        return dto;
    }
}
