using System.Data;
using Dapper;
using Intranet.Core.Contracts;
using Intranet.Modulo02.Models;

namespace Intranet.Modulo02.Services;

public class AsistenciaService : IAsistenciaService
{
    private readonly IModuleDbConnectionFactory _connectionFactory;

    public AsistenciaService(IModuleDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    private IDbConnection CreateConnection() => _connectionFactory.CreateConnection("02");

    public async Task<int?> GetDocenteIdPorPersonaAsync(int personaId)
    {
        using var db = CreateConnection();
        const string sql = "SELECT id FROM core.docentes WHERE persona_id = @PersonaId LIMIT 1;";
        return await db.QueryFirstOrDefaultAsync<int?>(sql, new { PersonaId = personaId });
    }

    public async Task<int?> GetEstudianteIdPorPersonaAsync(int personaId)
    {
        using var db = CreateConnection();
        const string sql = "SELECT id FROM core.estudiantes WHERE persona_id = @PersonaId LIMIT 1;";
        return await db.QueryFirstOrDefaultAsync<int?>(sql, new { PersonaId = personaId });
    }

    public async Task<DashboardAsistenciaViewModel> GetDashboardAsync(int? personaId, string rol)
    {
        using var db = CreateConnection();
        var vm = new DashboardAsistenciaViewModel
        {
            RolUsuario = rol,
            EsDocente = rol.Contains("Docente", StringComparison.OrdinalIgnoreCase) || rol.Contains("Admin", StringComparison.OrdinalIgnoreCase),
            EsAlumno = rol.Equals("Alumno", StringComparison.OrdinalIgnoreCase),
            EsCoordinadorOAdmin = rol.Contains("Coordinador", StringComparison.OrdinalIgnoreCase) || rol.Contains("Admin", StringComparison.OrdinalIgnoreCase) || rol.Contains("Director", StringComparison.OrdinalIgnoreCase)
        };

        // 1. KPIs Generales
        const string sqlKpis = @"
            SELECT 
                (SELECT COUNT(1) FROM mod02.clases_docente WHERE estado = TRUE) AS total_clases,
                (SELECT COUNT(1) FROM mod02.sesiones_clase WHERE fecha_clase = CURRENT_DATE) AS total_hoy,
                (SELECT COUNT(DISTINCT estudiante_id) FROM mod02.v_resumen_asistencia_estudiante WHERE semaforo_estado = 'DPI') AS total_dpi,
                (SELECT COUNT(1) FROM mod02.justificaciones WHERE estado = 'PENDIENTE') AS total_justif_pend;
        ";

        try
        {
            var kpiResult = await db.QueryFirstOrDefaultAsync<dynamic>(sqlKpis);
            if (kpiResult != null)
            {
                vm.TotalClasesAsignadas = (int)(kpiResult.total_clases ?? 0);
                vm.TotalSesionesHoy = (int)(kpiResult.total_hoy ?? 0);
                vm.TotalAlumnosDpi = (int)(kpiResult.total_dpi ?? 0);
                vm.TotalJustificacionesPendientes = (int)(kpiResult.total_justif_pend ?? 0);
            }
        }
        catch { }

        // 2. Si es Docente o Admin, cargar sus Clases Asignadas
        if (vm.EsDocente)
        {
            int docenteId = 1;
            if (personaId.HasValue)
            {
                var docId = await GetDocenteIdPorPersonaAsync(personaId.Value);
                if (docId.HasValue) docenteId = docId.Value;
            }
            vm.MisClasesDocente = (await GetClasesDocenteAsync(docenteId)).ToList();
            vm.SesionesHoy = (await GetSesionesRecientesAsync(6)).ToList();
        }

        // 3. Si es Alumno, cargar sus asignaturas y semáforos
        if (vm.EsAlumno || personaId.HasValue)
        {
            var estId = personaId.HasValue ? await GetEstudianteIdPorPersonaAsync(personaId.Value) : 1;
            estId ??= 1;
            vm.ResumenCursosEstudiante = (await GetResumenEstudianteAsync(estId.Value)).ToList();
        }

        // 4. Casos Críticos DPI y Justificaciones Recientes
        vm.CasosCriticosDpi = (await GetAlertasDpiAsync()).Take(5).ToList();
        vm.JustificacionesRecientes = (await GetJustificacionesAsync(null, null)).Take(5).ToList();

        return vm;
    }

    public async Task<IEnumerable<ClaseDocenteCardDto>> GetClasesDocenteAsync(int docenteId, int? periodoId = null)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                cd.id AS ClaseId,
                cd.unidad_didactica_id AS UnidadDidacticaId,
                ud.codigo AS UnidadDidacticaCodigo,
                ud.nombre AS UnidadDidacticaNombre,
                cd.carrera_id AS CarreraId,
                c.nombre AS CarreraNombre,
                cd.ciclo AS Ciclo,
                cd.turno AS Turno,
                cd.seccion AS Seccion,
                cd.aula_id AS AulaId,
                a.codigo AS AulaCodigo,
                cd.total_sesiones_semanales AS TotalSesionesSemanales,
                ud.horas_semanales AS HorasSemanales,
                (SELECT COUNT(1) FROM core.estudiantes e WHERE e.carrera_id = cd.carrera_id AND e.ciclo_actual = cd.ciclo AND e.turno = cd.turno) AS TotalAlumnosMatriculados,
                (SELECT COUNT(DISTINCT s.numero_semana) FROM mod02.sesiones_clase s WHERE s.clase_docente_id = cd.id AND s.estado = 'CERRADA') AS SemanasRegistradas,
                (SELECT COALESCE(MAX(s.numero_semana), 0) FROM mod02.sesiones_clase s WHERE s.clase_docente_id = cd.id AND s.estado = 'CERRADA') AS UltimaSemanaRegistrada,
                (SELECT s.id FROM mod02.sesiones_clase s WHERE s.clase_docente_id = cd.id AND s.estado = 'ABIERTA' ORDER BY s.fecha_clase ASC, s.hora_inicio ASC LIMIT 1) AS ProximaSesionId
            FROM mod02.clases_docente cd
            JOIN core.unidades_didacticas ud ON ud.id = cd.unidad_didactica_id
            JOIN core.carreras c ON c.id = cd.carrera_id
            LEFT JOIN core.aulas a ON a.id = cd.aula_id
            WHERE cd.docente_id = @DocenteId AND (@PeriodoId IS NULL OR cd.periodo_id = @PeriodoId) AND cd.estado = TRUE
            ORDER BY ud.nombre ASC;
        ";

        try
        {
            var res = await db.QueryAsync<ClaseDocenteCardDto>(sql, new { DocenteId = docenteId, PeriodoId = periodoId });
            return res;
        }
        catch
        {
            return Enumerable.Empty<ClaseDocenteCardDto>();
        }
    }

    public async Task<IEnumerable<SemanaSelectorDto>> GetSemanasDeClaseAsync(int claseId)
    {
        using var db = CreateConnection();
        const string sqlSesiones = @"
            SELECT 
                s.id,
                s.clase_docente_id AS ClaseDocenteId,
                s.unidad_didactica_id AS UnidadDidacticaId,
                ud.codigo AS UnidadDidacticaCodigo,
                ud.nombre AS UnidadDidacticaNombre,
                s.docente_id AS DocenteId,
                s.aula_id AS AulaId,
                a.codigo AS AulaCodigo,
                s.fecha_clase AS FechaClase,
                s.hora_inicio AS HoraInicio,
                s.hora_fin AS HoraFin,
                s.horas_pedagogicas AS HorasPedagogicas,
                s.numero_semana AS NumeroSemana,
                s.numero_sesion AS NumeroSesion,
                s.es_semana_recuperacion AS EsSemanaRecuperacion,
                s.tema_desarrollado AS TemaDesarrollado,
                s.observaciones_docente AS ObservacionesDocente,
                s.estado AS Estado,
                s.cerrada_en AS CerradaEn,
                COUNT(ast.id) AS TotalAlumnos,
                COUNT(CASE WHEN ast.estado = 'PRESENTE' THEN 1 END) AS TotalPresentes,
                COUNT(CASE WHEN ast.estado = 'TARDANZA' THEN 1 END) AS TotalTardanzas,
                COUNT(CASE WHEN ast.estado = 'FALTA_INJUSTIFICADA' THEN 1 END) AS TotalFaltas,
                COUNT(CASE WHEN ast.estado = 'FALTA_JUSTIFICADA' THEN 1 END) AS TotalJustificadas
            FROM mod02.sesiones_clase s
            JOIN core.unidades_didacticas ud ON ud.id = s.unidad_didactica_id
            LEFT JOIN core.aulas a ON a.id = s.aula_id
            LEFT JOIN mod02.asistencias ast ON ast.sesion_clase_id = s.id
            WHERE s.clase_docente_id = @ClaseId
            GROUP BY s.id, ud.codigo, ud.nombre, a.codigo
            ORDER BY s.numero_semana ASC, s.numero_sesion ASC, s.fecha_clase ASC;
        ";

        var sesiones = (await db.QueryAsync<SesionClaseDto>(sqlSesiones, new { ClaseId = claseId })).ToList();
        var listaSemanas = new List<SemanaSelectorDto>();

        // Generar las 18 semanas oficiales (1 a 17 regulares + 18 recuperación)
        for (int sem = 1; sem <= 18; sem++)
        {
            var sesionesSemana = sesiones.Where(x => x.NumeroSemana == sem).ToList();
            string estadoSemana = "PROGRAMADA";
            if (sesionesSemana.Any(x => x.Estado == "CERRADA")) estadoSemana = "CERRADA";
            else if (sesionesSemana.Any(x => x.Estado == "ABIERTA")) estadoSemana = "ABIERTA";

            listaSemanas.Add(new SemanaSelectorDto
            {
                NumeroSemana = sem,
                EsRecuperacion = (sem == 18),
                EstadoSemana = estadoSemana,
                Sesiones = sesionesSemana,
                EsSemanaActual = sesionesSemana.Any(s => s.FechaClase.Date == DateTime.Today) || (estadoSemana == "ABIERTA")
            });
        }

        return listaSemanas;
    }

    public async Task<MatrizAsistenciaViewModel?> GetMatrizAsistenciaClaseAsync(int claseId)
    {
        using var db = CreateConnection();

        // 1. Obtener datos de la cabecera de la clase
        const string sqlClase = @"
            SELECT 
                cd.id AS ClaseId,
                cd.unidad_didactica_id AS UnidadDidacticaId,
                ud.codigo AS UnidadDidacticaCodigo,
                ud.nombre AS UnidadDidacticaNombre,
                c.nombre AS CarreraNombre,
                cd.ciclo AS Ciclo,
                cd.turno AS Turno,
                cd.seccion AS Seccion,
                CONCAT(p.apellidos, ', ', p.nombres) AS DocenteNombre,
                cd.periodo_id AS PeriodoId,
                pa.codigo AS PeriodoCodigo
            FROM mod02.clases_docente cd
            JOIN core.unidades_didacticas ud ON ud.id = cd.unidad_didactica_id
            JOIN core.carreras c ON c.id = cd.carrera_id
            JOIN core.docentes d ON d.id = cd.docente_id
            JOIN core.personas p ON p.id = d.persona_id
            JOIN core.periodos_academicos pa ON pa.id = cd.periodo_id
            WHERE cd.id = @ClaseId;
        ";

        var vm = await db.QueryFirstOrDefaultAsync<MatrizAsistenciaViewModel>(sqlClase, new { ClaseId = claseId });
        if (vm == null) return null;

        // 2. Obtener Columnas (Sesiones de clase dictadas o programadas)
        const string sqlColumnas = @"
            SELECT 
                s.id AS SesionId,
                s.numero_semana AS NumeroSemana,
                s.numero_sesion AS NumeroSesion,
                s.fecha_clase AS FechaClase,
                s.horas_pedagogicas AS HorasPedagogicas,
                s.estado AS Estado,
                s.es_semana_recuperacion AS EsRecuperacion
            FROM mod02.sesiones_clase s
            WHERE s.clase_docente_id = @ClaseId
            ORDER BY s.numero_semana ASC, s.numero_sesion ASC, s.fecha_clase ASC;
        ";
        vm.ColumnasSesiones = (await db.QueryAsync<ColumnaSesionMatrizDto>(sqlColumnas, new { ClaseId = claseId })).ToList();

        // 3. Obtener Alumnos matriculados en la sección
        const string sqlAlumnos = @"
            SELECT 
                e.id AS EstudianteId,
                e.codigo_estudiante AS CodigoEstudiante,
                p.dni AS Dni,
                CONCAT(p.apellidos, ', ', p.nombres) AS NombreCompleto,
                COALESCE(r.horas_falta_injustificada, 0) AS HorasFaltaAcumuladas,
                COALESCE(r.total_horas_semestre, 72) AS TotalHorasAsignatura,
                COALESCE(r.porcentaje_inasistencia, 0.00) AS PorcentajeInasistencia,
                COALESCE(r.semaforo_estado, 'REGULAR') AS SemaforoEstado,
                COALESCE(r.cant_presentes, 0) AS TotalPresentes,
                COALESCE(r.cant_tardanzas, 0) AS TotalTardanzas,
                COALESCE(r.cant_faltas_injustificadas, 0) AS TotalFaltasInjustificadas,
                COALESCE(r.cant_faltas_justificadas, 0) AS TotalFaltasJustificadas
            FROM core.estudiantes e
            JOIN core.personas p ON p.id = e.persona_id
            JOIN mod02.clases_docente cd ON cd.id = @ClaseId AND cd.carrera_id = e.carrera_id AND cd.ciclo = e.ciclo_actual AND cd.turno = e.turno
            LEFT JOIN mod02.v_resumen_asistencia_estudiante r ON r.estudiante_id = e.id AND r.unidad_didactica_id = cd.unidad_didactica_id
            ORDER BY p.apellidos ASC, p.nombres ASC;
        ";
        vm.FilasAlumnos = (await db.QueryAsync<FilaAlumnoMatrizDto>(sqlAlumnos, new { ClaseId = claseId })).ToList();

        // 4. Obtener todos los registros individuales de asistencia para poblar las celdas
        const string sqlCeldas = @"
            SELECT 
                a.estudiante_id,
                a.sesion_clase_id,
                a.estado
            FROM mod02.asistencias a
            JOIN mod02.sesiones_clase s ON s.id = a.sesion_clase_id
            WHERE s.clase_docente_id = @ClaseId;
        ";
        var celdas = await db.QueryAsync<dynamic>(sqlCeldas, new { ClaseId = claseId });

        var lookup = new Dictionary<(int EstudianteId, int SesionId), string>();
        foreach (var c in celdas)
        {
            lookup[((int)c.estudiante_id, (int)c.sesion_clase_id)] = (string)c.estado;
        }

        foreach (var alumno in vm.FilasAlumnos)
        {
            foreach (var col in vm.ColumnasSesiones)
            {
                if (lookup.TryGetValue((alumno.EstudianteId, col.SesionId), out var estado))
                {
                    alumno.EstadosPorSesion[col.SesionId] = estado;
                }
                else
                {
                    alumno.EstadosPorSesion[col.SesionId] = "SIN_REGISTRO";
                }
            }
        }

        return vm;
    }

    public async Task<IEnumerable<SesionClaseDto>> GetSesionesRecientesAsync(int limite = 10)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                s.id,
                s.clase_docente_id AS ClaseDocenteId,
                s.unidad_didactica_id AS UnidadDidacticaId,
                ud.codigo AS UnidadDidacticaCodigo,
                ud.nombre AS UnidadDidacticaNombre,
                c.nombre AS CarreraNombre,
                ud.ciclo AS Ciclo,
                s.docente_id AS DocenteId,
                CONCAT(p.apellidos, ', ', p.nombres) AS DocenteNombreCompleto,
                s.periodo_id AS PeriodoId,
                pa.codigo AS PeriodoCodigo,
                s.aula_id AS AulaId,
                a.codigo AS AulaCodigo,
                s.fecha_clase AS FechaClase,
                s.hora_inicio AS HoraInicio,
                s.hora_fin AS HoraFin,
                s.horas_pedagogicas AS HorasPedagogicas,
                s.numero_semana AS NumeroSemana,
                s.numero_sesion AS NumeroSesion,
                s.es_semana_recuperacion AS EsSemanaRecuperacion,
                s.tema_desarrollado AS TemaDesarrollado,
                s.observaciones_docente AS ObservacionesDocente,
                s.estado AS Estado,
                s.cerrada_en AS CerradaEn,
                COUNT(ast.id) AS TotalAlumnos,
                COUNT(CASE WHEN ast.estado = 'PRESENTE' THEN 1 END) AS TotalPresentes,
                COUNT(CASE WHEN ast.estado = 'TARDANZA' THEN 1 END) AS TotalTardanzas,
                COUNT(CASE WHEN ast.estado = 'FALTA_INJUSTIFICADA' THEN 1 END) AS TotalFaltas,
                COUNT(CASE WHEN ast.estado = 'FALTA_JUSTIFICADA' THEN 1 END) AS TotalJustificadas
            FROM mod02.sesiones_clase s
            JOIN core.unidades_didacticas ud ON ud.id = s.unidad_didactica_id
            JOIN core.carreras c ON c.id = ud.carrera_id
            JOIN core.docentes d ON d.id = s.docente_id
            JOIN core.personas p ON p.id = d.persona_id
            JOIN core.periodos_academicos pa ON pa.id = s.periodo_id
            LEFT JOIN core.aulas a ON a.id = s.aula_id
            LEFT JOIN mod02.asistencias ast ON ast.sesion_clase_id = s.id
            GROUP BY s.id, ud.codigo, ud.nombre, c.nombre, ud.ciclo, p.apellidos, p.nombres, pa.codigo, a.codigo
            ORDER BY s.fecha_clase DESC, s.hora_inicio DESC
            LIMIT @Limite;
        ";

        try
        {
            return await db.QueryAsync<SesionClaseDto>(sql, new { Limite = limite });
        }
        catch
        {
            return Enumerable.Empty<SesionClaseDto>();
        }
    }

    public async Task<IEnumerable<SesionClaseDto>> GetSesionesDocenteAsync(int docenteId, int? periodoId = null)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                s.id,
                s.clase_docente_id AS ClaseDocenteId,
                s.unidad_didactica_id AS UnidadDidacticaId,
                ud.codigo AS UnidadDidacticaCodigo,
                ud.nombre AS UnidadDidacticaNombre,
                c.nombre AS CarreraNombre,
                ud.ciclo AS Ciclo,
                s.docente_id AS DocenteId,
                CONCAT(p.apellidos, ', ', p.nombres) AS DocenteNombreCompleto,
                s.periodo_id AS PeriodoId,
                pa.codigo AS PeriodoCodigo,
                s.aula_id AS AulaId,
                a.codigo AS AulaCodigo,
                s.fecha_clase AS FechaClase,
                s.hora_inicio AS HoraInicio,
                s.hora_fin AS HoraFin,
                s.horas_pedagogicas AS HorasPedagogicas,
                s.numero_semana AS NumeroSemana,
                s.numero_sesion AS NumeroSesion,
                s.es_semana_recuperacion AS EsSemanaRecuperacion,
                s.tema_desarrollado AS TemaDesarrollado,
                s.observaciones_docente AS ObservacionesDocente,
                s.estado AS Estado,
                s.cerrada_en AS CerradaEn,
                COUNT(ast.id) AS TotalAlumnos,
                COUNT(CASE WHEN ast.estado = 'PRESENTE' THEN 1 END) AS TotalPresentes,
                COUNT(CASE WHEN ast.estado = 'TARDANZA' THEN 1 END) AS TotalTardanzas,
                COUNT(CASE WHEN ast.estado = 'FALTA_INJUSTIFICADA' THEN 1 END) AS TotalFaltas,
                COUNT(CASE WHEN ast.estado = 'FALTA_JUSTIFICADA' THEN 1 END) AS TotalJustificadas
            FROM mod02.sesiones_clase s
            JOIN core.unidades_didacticas ud ON ud.id = s.unidad_didactica_id
            JOIN core.carreras c ON c.id = ud.carrera_id
            JOIN core.docentes d ON d.id = s.docente_id
            JOIN core.personas p ON p.id = d.persona_id
            JOIN core.periodos_academicos pa ON pa.id = s.periodo_id
            LEFT JOIN core.aulas a ON a.id = s.aula_id
            LEFT JOIN mod02.asistencias ast ON ast.sesion_clase_id = s.id
            WHERE s.docente_id = @DocenteId AND (@PeriodoId IS NULL OR s.periodo_id = @PeriodoId)
            GROUP BY s.id, ud.codigo, ud.nombre, c.nombre, ud.ciclo, p.apellidos, p.nombres, pa.codigo, a.codigo
            ORDER BY s.fecha_clase DESC, s.hora_inicio DESC;
        ";

        return await db.QueryAsync<SesionClaseDto>(sql, new { DocenteId = docenteId, PeriodoId = periodoId });
    }

    public async Task<SesionClaseDto?> GetSesionPorIdAsync(int sesionId)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                s.id,
                s.clase_docente_id AS ClaseDocenteId,
                s.unidad_didactica_id AS UnidadDidacticaId,
                ud.codigo AS UnidadDidacticaCodigo,
                ud.nombre AS UnidadDidacticaNombre,
                c.nombre AS CarreraNombre,
                cd.ciclo AS Ciclo,
                cd.turno AS Turno,
                cd.seccion AS Seccion,
                s.docente_id AS DocenteId,
                CONCAT(p.apellidos, ', ', p.nombres) AS DocenteNombreCompleto,
                s.periodo_id AS PeriodoId,
                pa.codigo AS PeriodoCodigo,
                s.aula_id AS AulaId,
                a.codigo AS AulaCodigo,
                s.fecha_clase AS FechaClase,
                s.hora_inicio AS HoraInicio,
                s.hora_fin AS HoraFin,
                s.horas_pedagogicas AS HorasPedagogicas,
                s.numero_semana AS NumeroSemana,
                s.numero_sesion AS NumeroSesion,
                s.es_semana_recuperacion AS EsSemanaRecuperacion,
                s.tema_desarrollado AS TemaDesarrollado,
                s.observaciones_docente AS ObservacionesDocente,
                s.estado AS Estado,
                s.cerrada_en AS CerradaEn
            FROM mod02.sesiones_clase s
            JOIN core.unidades_didacticas ud ON ud.id = s.unidad_didactica_id
            JOIN core.carreras c ON c.id = ud.carrera_id
            JOIN core.docentes d ON d.id = s.docente_id
            JOIN core.personas p ON p.id = d.persona_id
            JOIN core.periodos_academicos pa ON pa.id = s.periodo_id
            LEFT JOIN mod02.clases_docente cd ON cd.id = s.clase_docente_id
            LEFT JOIN core.aulas a ON a.id = s.aula_id
            WHERE s.id = @SesionId;
        ";

        return await db.QueryFirstOrDefaultAsync<SesionClaseDto>(sql, new { SesionId = sesionId });
    }

    public async Task<IEnumerable<AlumnoAsistenciaItemDto>> GetAlumnosParaSesionAsync(int sesionId, int unidadDidacticaId)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                e.id AS EstudianteId,
                p.id AS PersonaId,
                e.codigo_estudiante AS CodigoEstudiante,
                p.dni AS Dni,
                p.nombres AS Nombres,
                p.apellidos AS Apellidos,
                p.foto_url AS FotoUrl,
                e.turno AS Turno,
                ast.id AS AsistenciaId,
                COALESCE(ast.estado, 'PRESENTE') AS EstadoAsistencia,
                COALESCE(ast.minutos_tardanza, 0) AS MinutosTardanza,
                ast.observacion AS Observacion,
                COALESCE(r.horas_falta_injustificada, 0) AS HorasFaltaAcumuladasPrevias,
                COALESCE(r.total_horas_semestre, (ud.horas_semanales * 18)) AS TotalHorasSemestrales,
                COALESCE(r.porcentaje_inasistencia, 0.00) AS PorcentajeInasistenciaPrevio,
                COALESCE(r.horas_falta_disponibles, 21) AS HorasFaltaDisponibles
            FROM core.estudiantes e
            JOIN core.personas p ON p.id = e.persona_id
            CROSS JOIN core.unidades_didacticas ud
            LEFT JOIN mod02.asistencias ast ON ast.estudiante_id = e.id AND ast.sesion_clase_id = @SesionId
            LEFT JOIN mod02.v_resumen_asistencia_estudiante r ON r.estudiante_id = e.id AND r.unidad_didactica_id = @UnidadDidacticaId
            WHERE ud.id = @UnidadDidacticaId
            ORDER BY p.apellidos ASC, p.nombres ASC;
        ";

        return await db.QueryAsync<AlumnoAsistenciaItemDto>(sql, new { SesionId = sesionId, UnidadDidacticaId = unidadDidacticaId });
    }

    public async Task<bool> GuardarAsistenciaSesionAsync(GuardarAsistenciaRequestDto request, int? usuarioId)
    {
        using var db = CreateConnection();
        db.Open();
        using var transaction = db.BeginTransaction();

        try
        {
            // 1. Actualizar datos de la sesión
            const string sqlSesion = @"
                UPDATE mod02.sesiones_clase
                SET 
                    tema_desarrollado = @TemaDesarrollado,
                    observaciones_docente = @ObservacionesDocente,
                    estado = CASE WHEN @CerrarSesion = TRUE THEN 'CERRADA' ELSE estado END,
                    cerrada_en = CASE WHEN @CerrarSesion = TRUE THEN CURRENT_TIMESTAMP ELSE cerrada_en END
                WHERE id = @SesionClaseId;
            ";

            await db.ExecuteAsync(sqlSesion, new
            {
                request.SesionClaseId,
                request.TemaDesarrollado,
                request.ObservacionesDocente,
                request.CerrarSesion
            }, transaction);

            // 2. Upsert asistencias de los alumnos
            const string sqlUpsertAsistencia = @"
                INSERT INTO mod02.asistencias (
                    sesion_clase_id, estudiante_id, estado, minutos_tardanza, observacion, registrado_por_usuario_id, registrado_en, modificado_en
                )
                VALUES (
                    @SesionClaseId, @EstudianteId, @Estado, @MinutosTardanza, @Observacion, @UsuarioId, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
                )
                ON CONFLICT (sesion_clase_id, estudiante_id) DO UPDATE SET
                    estado = EXCLUDED.estado,
                    minutos_tardanza = EXCLUDED.minutos_tardanza,
                    observacion = EXCLUDED.observacion,
                    modificado_en = CURRENT_TIMESTAMP;
            ";

            foreach (var item in request.Alumnos)
            {
                await db.ExecuteAsync(sqlUpsertAsistencia, new
                {
                    request.SesionClaseId,
                    item.EstudianteId,
                    item.Estado,
                    item.MinutosTardanza,
                    item.Observacion,
                    UsuarioId = usuarioId
                }, transaction);
            }

            transaction.Commit();
            return true;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<IEnumerable<ResumenAsistenciaEstudianteDto>> GetResumenEstudianteAsync(int estudianteId, int? periodoId = null)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                r.estudiante_id AS EstudianteId,
                r.unidad_didactica_id AS UnidadDidacticaId,
                r.periodo_id AS PeriodoId,
                r.unidad_didactica_nombre AS UnidadDidacticaNombre,
                r.unidad_didactica_codigo AS UnidadDidacticaCodigo,
                r.carrera_nombre AS CarreraNombre,
                r.ciclo AS Ciclo,
                r.turno AS Turno,
                r.total_horas_semestre AS TotalHorasSemestre,
                r.cant_presentes AS CantPresentes,
                r.cant_tardanzas AS CantTardanzas,
                r.cant_faltas_justificadas AS CantFaltasJustificadas,
                r.cant_faltas_injustificadas AS CantFaltasInjustificadas,
                r.horas_falta_injustificada AS HorasFaltaInjustificada,
                r.horas_asistidas AS HorasAsistidas,
                r.total_sesiones_registradas AS TotalSesionesRegistradas,
                r.porcentaje_inasistencia AS PorcentajeInasistencia,
                r.semaforo_estado AS SemaforoEstado,
                r.horas_falta_disponibles AS HorasFaltaDisponibles
            FROM mod02.v_resumen_asistencia_estudiante r
            WHERE r.estudiante_id = @EstudianteId AND (@PeriodoId IS NULL OR r.periodo_id = @PeriodoId)
            ORDER BY r.unidad_didactica_nombre ASC;
        ";

        try
        {
            return await db.QueryAsync<ResumenAsistenciaEstudianteDto>(sql, new { EstudianteId = estudianteId, PeriodoId = periodoId });
        }
        catch
        {
            return Enumerable.Empty<ResumenAsistenciaEstudianteDto>();
        }
    }

    public async Task<IEnumerable<AsistenciaHistorialItemDto>> GetHistorialDetalladoEstudianteAsync(int estudianteId, int unidadDidacticaId)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                a.id AS AsistenciaId,
                s.id AS SesionId,
                s.fecha_clase AS FechaClase,
                s.numero_semana AS NumeroSemana,
                s.numero_sesion AS NumeroSesion,
                s.horas_pedagogicas AS HorasPedagogicas,
                s.tema_desarrollado AS TemaDesarrollado,
                CONCAT(p.apellidos, ', ', p.nombres) AS DocenteNombre,
                a.estado AS Estado,
                a.minutos_tardanza AS MinutosTardanza,
                a.observacion AS Observacion,
                CASE WHEN j.id IS NOT NULL THEN TRUE ELSE FALSE END AS TieneJustificacion,
                j.estado AS EstadoJustificacion
            FROM mod02.asistencias a
            JOIN mod02.sesiones_clase s ON s.id = a.sesion_clase_id
            JOIN core.docentes d ON d.id = s.docente_id
            JOIN core.personas p ON p.id = d.persona_id
            LEFT JOIN mod02.justificaciones j ON j.asistencia_id = a.id
            WHERE a.estudiante_id = @EstudianteId AND s.unidad_didactica_id = @UnidadDidacticaId
            ORDER BY s.numero_semana ASC, s.fecha_clase ASC;
        ";

        return await db.QueryAsync<AsistenciaHistorialItemDto>(sql, new { EstudianteId = estudianteId, UnidadDidacticaId = unidadDidacticaId });
    }

    public async Task<IEnumerable<JustificacionDto>> GetJustificacionesAsync(int? estudianteId = null, string? estado = null)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                j.id,
                j.asistencia_id AS AsistenciaId,
                j.estudiante_id AS EstudianteId,
                CONCAT(p.apellidos, ', ', p.nombres) AS EstudianteNombre,
                e.codigo_estudiante AS EstudianteCodigo,
                ud.nombre AS UnidadDidacticaNombre,
                s.fecha_clase AS FechaClase,
                s.numero_semana AS NumeroSemana,
                j.motivo AS Motivo,
                j.descripcion AS Descripcion,
                j.documento_sustento_url AS DocumentoSustentoUrl,
                j.estado AS Estado,
                CONCAT(pdoc.apellidos, ', ', pdoc.nombres) AS DocenteNombre,
                j.respuesta_observacion AS RespuestaObservacion,
                j.fecha_solicitud AS FechaSolicitud,
                j.fecha_resolucion AS FechaResolucion
            FROM mod02.justificaciones j
            JOIN core.estudiantes e ON e.id = j.estudiante_id
            JOIN core.personas p ON p.id = e.persona_id
            JOIN mod02.asistencias a ON a.id = j.asistencia_id
            JOIN mod02.sesiones_clase s ON s.id = a.sesion_clase_id
            JOIN core.unidades_didacticas ud ON ud.id = s.unidad_didactica_id
            LEFT JOIN core.docentes d ON d.id = j.revisado_por_docente_id
            LEFT JOIN core.personas pdoc ON pdoc.id = d.persona_id
            WHERE (@EstudianteId IS NULL OR j.estudiante_id = @EstudianteId)
              AND (@Estado IS NULL OR j.estado = @Estado)
            ORDER BY j.fecha_solicitud DESC;
        ";

        try
        {
            return await db.QueryAsync<JustificacionDto>(sql, new { EstudianteId = estudianteId, Estado = estado });
        }
        catch
        {
            return Enumerable.Empty<JustificacionDto>();
        }
    }

    public async Task<bool> SolicitarJustificacionAsync(CrearJustificacionDto dto, int estudianteId)
    {
        using var db = CreateConnection();
        const string sql = @"
            INSERT INTO mod02.justificaciones (
                asistencia_id, estudiante_id, motivo, descripcion, documento_sustento_url, estado, fecha_solicitud
            )
            VALUES (
                @AsistenciaId, @EstudianteId, @Motivo, @Descripcion, @DocumentoSustentoUrl, 'PENDIENTE', CURRENT_TIMESTAMP
            )
            ON CONFLICT (asistencia_id) DO UPDATE SET
                motivo = EXCLUDED.motivo,
                descripcion = EXCLUDED.descripcion,
                documento_sustento_url = EXCLUDED.documento_sustento_url,
                estado = 'PENDIENTE',
                fecha_solicitud = CURRENT_TIMESTAMP;
        ";

        var rows = await db.ExecuteAsync(sql, new
        {
            dto.AsistenciaId,
            EstudianteId = estudianteId,
            dto.Motivo,
            dto.Descripcion,
            dto.DocumentoSustentoUrl
        });

        return rows > 0;
    }

    public async Task<bool> ResolverJustificacionAsync(ResolverJustificacionDto dto, int docenteId)
    {
        using var db = CreateConnection();
        db.Open();
        using var tx = db.BeginTransaction();

        try
        {
            var nuevoEstado = dto.Aprobada ? "APROBADA" : "RECHAZADA";

            const string sqlJust = @"
                UPDATE mod02.justificaciones
                SET 
                    estado = @NuevoEstado,
                    revisado_por_docente_id = @DocenteId,
                    respuesta_observacion = @Observacion,
                    fecha_resolucion = CURRENT_TIMESTAMP
                WHERE id = @JustificacionId
                RETURNING asistencia_id;
            ";

            var asistenciaId = await db.ExecuteScalarAsync<int?>(sqlJust, new
            {
                NuevoEstado = nuevoEstado,
                DocenteId = docenteId,
                dto.Observacion,
                dto.JustificacionId
            }, tx);

            if (asistenciaId.HasValue && dto.Aprobada)
            {
                const string sqlAsistencia = @"
                    UPDATE mod02.asistencias
                    SET estado = 'FALTA_JUSTIFICADA', modificado_en = CURRENT_TIMESTAMP
                    WHERE id = @AsistenciaId;
                ";

                await db.ExecuteAsync(sqlAsistencia, new { AsistenciaId = asistenciaId.Value }, tx);
            }

            tx.Commit();
            return true;
        }
        catch
        {
            tx.Rollback();
            throw;
        }
    }

    public async Task<IEnumerable<AlertaDpiDto>> GetAlertasDpiAsync(int? carreraId = null, int? periodoId = null)
    {
        using var db = CreateConnection();
        const string sql = @"
            SELECT 
                r.estudiante_id AS EstudianteId,
                CONCAT(p.apellidos, ', ', p.nombres) AS EstudianteNombre,
                e.codigo_estudiante AS EstudianteCodigo,
                c.nombre AS CarreraNombre,
                e.ciclo_actual AS Ciclo,
                e.turno AS Turno,
                r.unidad_didactica_nombre AS UnidadDidacticaNombre,
                CONCAT(pdoc.apellidos, ', ', pdoc.nombres) AS DocenteNombre,
                r.horas_falta_injustificada AS HorasFalta,
                r.total_horas_semestre AS TotalHoras,
                r.porcentaje_inasistencia AS PorcentajeInasistencia,
                r.semaforo_estado AS SemaforoEstado
            FROM mod02.v_resumen_asistencia_estudiante r
            JOIN core.estudiantes e ON e.id = r.estudiante_id
            JOIN core.personas p ON p.id = e.persona_id
            JOIN core.carreras c ON c.id = e.carrera_id
            JOIN core.unidades_didacticas ud ON ud.id = r.unidad_didactica_id
            LEFT JOIN mod02.sesiones_clase s ON s.unidad_didactica_id = ud.id
            LEFT JOIN core.docentes d ON d.id = s.docente_id
            LEFT JOIN core.personas pdoc ON pdoc.id = d.persona_id
            WHERE r.semaforo_estado IN ('RIESGO_ALTO', 'DPI', 'ALERTA')
              AND (@CarreraId IS NULL OR e.carrera_id = @CarreraId)
              AND (@PeriodoId IS NULL OR r.periodo_id = @PeriodoId)
            GROUP BY r.estudiante_id, p.apellidos, p.nombres, e.codigo_estudiante, c.nombre, e.ciclo_actual, e.turno, r.unidad_didactica_nombre, pdoc.apellidos, pdoc.nombres, r.horas_falta_injustificada, r.total_horas_semestre, r.porcentaje_inasistencia, r.semaforo_estado
            ORDER BY r.porcentaje_inasistencia DESC;
        ";

        try
        {
            return await db.QueryAsync<AlertaDpiDto>(sql, new { CarreraId = carreraId, PeriodoId = periodoId });
        }
        catch
        {
            return Enumerable.Empty<AlertaDpiDto>();
        }
    }
}
