namespace Intranet.Core.Entities;

public class Docente
{
    public int Id { get; set; }
    public int PersonaId { get; set; }
    public string CodigoDocente { get; set; } = string.Empty;
    public int? CarreraPrincipalId { get; set; }
    public string Profesion { get; set; } = string.Empty;
    public string GradoAcademico { get; set; } = "Licenciado / Ingeniero";
    public string Condicion { get; set; } = "Contratado";

    public Persona? Persona { get; set; }
    public Carrera? CarreraPrincipal { get; set; }
}
