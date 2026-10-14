using Dapper;
using Intranet.Core.Contracts;
using Intranet.Modulo01.Models;

namespace Intranet.Modulo01.Services;

/// <summary>
/// Pestaña "Académico" del alumno (Equipo 01).
/// Rendimiento por ciclo (barras), record académico por período con promedio
/// ponderado y créditos, siguiendo el formato del SIGA institucional.
/// Solo consulta SU historial (mod01.historial_academico × core.unidades_didacticas).
/// </summary>
public class AcademicoServicio
{
    private readonly IModuleDbConnectionFactory _factory;

    public AcademicoServicio(IModuleDbConnectionFactory factory)
    {
        _factory = factory;
    }

    // (resolución del estudiante movida al controller: PersonaActualId del base,
    //  patrón de MatriculasController — el service solo consulta por estudianteId)

    // ---------------------------------------------------------------
    // 1) Rendimiento por ciclo — barras (promedio vigesimal por ciclo I-VI)
    // ---------------------------------------------------------------
    public async Task<List<RendimientoCiclo>> RendimientoPorCicloAsync(int estudianteId)
    {
        using var connection = _factory.CreateConnection("01");
        const string sql = """
            SELECT ud.ciclo              AS Ciclo,
                   ROUND(AVG(h.nota), 1) AS Promedio,
                   COUNT(*)              AS Cursos,
                   SUM(CASE WHEN h.estado = 'Aprobado' THEN 1 ELSE 0 END) AS Aprobados
            FROM mod01.historial_academico h
            JOIN core.unidades_didacticas ud ON ud.id = h.unidad_didactica_id
            WHERE h.estudiante_id = @EstudianteId
            GROUP BY ud.ciclo
            ORDER BY MIN(ud.id)
            """;
        var filas = await connection.QueryAsync<RendimientoCiclo>(sql, new { EstudianteId = estudianteId });
        return filas.ToList();
    }

    // ---------------------------------------------------------------
    // 2) Record académico por período (tabla del SIGA)
    //    Trayectoria COMPLETA desde el período de ingreso del estudiante:
    //    todos sus períodos aparecen (aunque aún no tengan notas) para que
    //    el filtro por período siempre tenga opciones. Cursos con código,
    //    créditos, nota, estado; al pie: promedio ponderado (Σ nota×créditos /
    //    Σ créditos), créditos matriculados y aprobados.
    // ---------------------------------------------------------------
    public async Task<List<PeriodoAcademico>> RecordPorPeriodoAsync(int estudianteId)
    {
        using var connection = _factory.CreateConnection("01");
        // Períodos de la trayectoria: desde el de ingreso hasta el último con notas
        // (el estudiante no debe ver períodos anteriores a su ingreso).
        const string sqlPeriodos = """
            SELECT p.id     AS PeriodoId,
                   p.codigo AS Codigo
            FROM core.periodos_academicos p
            WHERE p.id >= COALESCE((SELECT e.periodo_ingreso_id FROM core.estudiantes e WHERE e.id = @EstudianteId), 1)
              AND (p.es_activo
                   OR EXISTS (SELECT 1 FROM mod01.historial_academico h
                              WHERE h.periodo_id = p.id AND h.estudiante_id = @EstudianteId))
            ORDER BY p.id
            """;
        var periodos = (await connection.QueryAsync<(int PeriodoId, string Codigo)>(
            sqlPeriodos, new { EstudianteId = estudianteId })).ToList();

        const string sqlCursos = """
            SELECT ud.codigo   AS Codigo,
                   ud.nombre   AS UnidadNombre,
                   ud.creditos AS Creditos,
                   h.nota      AS Nota,
                   h.estado    AS Estado,
                   h.creado_en AS Fecha
            FROM mod01.historial_academico h
            JOIN core.unidades_didacticas ud ON ud.id = h.unidad_didactica_id
            WHERE h.estudiante_id = @EstudianteId AND h.periodo_id = @PeriodoId
            ORDER BY ud.id
            """;

        var resultado = new List<PeriodoAcademico>();
        foreach (var (periodoId, codigo) in periodos)
        {
            var cursos = (await connection.QueryAsync<CursoRecord>(
                sqlCursos, new { EstudianteId = estudianteId, PeriodoId = periodoId })).ToList();

            var creditosMatriculados = cursos.Sum(c => c.Creditos);
            resultado.Add(new PeriodoAcademico
            {
                PeriodoId = periodoId,
                Codigo = codigo,
                Cursos = cursos,
                TieneNotas = cursos.Count > 0,
                CreditosMatriculados = creditosMatriculados,
                CreditosAprobados = cursos.Where(c => c.Estado == "Aprobado").Sum(c => c.Creditos),
                PromedioPonderado = creditosMatriculados > 0
                    ? Math.Round(cursos.Sum(c => c.Nota * c.Creditos) / creditosMatriculados, 2)
                    : 0
            });
        }
        return resultado;
    }

    /// <summary>Resumen académico global del alumno (cards de arriba).</summary>
    public async Task<ResumenAcademico> ResumenAcademicoAsync(int estudianteId)
    {
        using var connection = _factory.CreateConnection("01");
        const string sql = """
            SELECT ROUND(AVG(h.nota), 1) AS PromedioGeneral,
                   COUNT(*) AS CursosTotales,
                   SUM(CASE WHEN h.estado = 'Aprobado' THEN 1 ELSE 0 END) AS CursosAprobados,
                   SUM(CASE WHEN h.estado = 'Desaprobado' THEN 1 ELSE 0 END) AS CursosDesaprobados
            FROM mod01.historial_academico h
            WHERE h.estudiante_id = @EstudianteId
            """;
        var r = await connection.QuerySingleOrDefaultAsync<ResumenAcademico>(sql, new { EstudianteId = estudianteId });
        return r ?? new ResumenAcademico();
    }
}
