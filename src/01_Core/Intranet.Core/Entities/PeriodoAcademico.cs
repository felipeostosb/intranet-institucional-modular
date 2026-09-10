namespace Intranet.Core.Entities;

public class PeriodoAcademico
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public DateTime FechaInicio { get; set; }
    public DateTime FechaFin { get; set; }
    public bool EsActivo { get; set; }
    public bool PermiteMatricula { get; set; }
}
