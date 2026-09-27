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
}

/// <summary>Comando de matrícula desde el puesto de Secretaría.</summary>
public record MatricularCommand(
    string Dni,
    int? MatriculaId,          // matrícula "En trámite" existente (reserva), si la hay
    int PeriodoId,            // período al que se matricula (2026-II)
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

        // Voucher del trámite de reserva: TM05 con pago Validado habilita a matricular
        const string voucherSql = """
            SELECT m.id AS MatriculaId,
                   m.codigo_matricula AS CodigoMatricula,
                   m.estado AS Estado,
                   m.voucher_ok AS VoucherOk,
                   t.id AS TramiteId,
                   t.codigo AS TramiteCodigo,
                   t.estado AS TramiteEstado,
                   pg.voucher_estado AS VoucherEstado,
                   pg.monto AS VoucherMonto
            FROM matriculas_v2 m
            LEFT JOIN mod09.tramites t ON t.id = m.tramite_reserva_id
            LEFT JOIN mod09.pagos_v2 pg ON pg.id = t.pago_id
            WHERE m.estudiante_id = @EstudianteId
              AND m.periodo_id = (SELECT id FROM periodos_academicos WHERE permite_matricula ORDER BY id DESC LIMIT 1)
              AND m.estado <> 'Anulada'
            ORDER BY m.creado_en DESC
            LIMIT 1;
            """;
        var tabla = TablaMatriculas(db);
        var voucher = await db.QueryFirstOrDefaultAsync<ReservaDto>(
            voucherSql.Replace("matriculas_v2", tabla)
                      .Replace("pagos_v2", tabla == "matriculas" ? "pagos" : "pagos_v2"),
            new { dto.EstudianteId });
        dto.Reserva = voucher;
        // La matrícula se puede cerrar si el voucher del trámite fue Validado por Tesorería
        dto.PuedeMatricular = voucher != null && voucher.VoucherEstado == "Validado";

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

        // 1) La matrícula "En trámite" (reserva) con voucher Validado es la puerta
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
}
