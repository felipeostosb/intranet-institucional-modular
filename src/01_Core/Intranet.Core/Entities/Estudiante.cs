namespace Intranet.Core.Entities;

public class Estudiante
{
    public int Id { get; set; }
    public int PersonaId { get; set; }
    public string CodigoEstudiante { get; set; } = string.Empty;
    public int CarreraId { get; set; }
    public int PeriodoIngresoId { get; set; }
    public string CicloActual { get; set; } = "I";
    public string Turno { get; set; } = "Manana";
    public string Condicion { get; set; } = "Regular";

    public Persona? Persona { get; set; }
    public Carrera? Carrera { get; set; }
    public PeriodoAcademico? PeriodoIngreso { get; set; }
}
