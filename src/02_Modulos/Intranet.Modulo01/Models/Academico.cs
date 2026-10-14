namespace Intranet.Modulo01.Models;

/// <summary>DTOs de la pestaña "Académico" (Equipo 01) — formato SIGA.</summary>

/// <summary>Promedio por ciclo (barras del gráfico de rendimiento).</summary>
public class RendimientoCiclo
{
    public string Ciclo { get; set; } = "";
    public decimal Promedio { get; set; }
    public int Cursos { get; set; }
    public int Aprobados { get; set; }
}

/// <summary>Un curso dentro del record académico (fila de la tabla SIGA).</summary>
public class CursoRecord
{
    public string Codigo { get; set; } = "";
    public string UnidadNombre { get; set; } = "";
    public decimal Creditos { get; set; }
    public decimal Nota { get; set; }
    public string Estado { get; set; } = "";
    public DateTime Fecha { get; set; }
}

/// <summary>Un período con sus cursos y totales (bloque del record académico).</summary>
public class PeriodoAcademico
{
    public int PeriodoId { get; set; }
    public string Codigo { get; set; } = "";
    public List<CursoRecord> Cursos { get; set; } = new();
    public decimal CreditosMatriculados { get; set; }
    public decimal CreditosAprobados { get; set; }
    public decimal PromedioPonderado { get; set; }
}

/// <summary>Cards de resumen de la pestaña Académico.</summary>
public class ResumenAcademico
{
    public decimal? PromedioGeneral { get; set; }
    public int? CursosTotales { get; set; }
    public int? CursosAprobados { get; set; }
    public int? CursosDesaprobados { get; set; }
}

/// <summary>Modelo completo de la vista Academico.</summary>
public class AcademicoVista
{
    public ResumenAcademico Resumen { get; set; } = new();
    public List<RendimientoCiclo> Rendimiento { get; set; } = new();
    public List<PeriodoAcademico> Record { get; set; } = new();
    public string EstudianteNombre { get; set; } = "";
}
