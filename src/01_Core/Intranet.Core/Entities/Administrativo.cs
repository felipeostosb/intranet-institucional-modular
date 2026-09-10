namespace Intranet.Core.Entities;

public class Administrativo
{
    public int Id { get; set; }
    public int PersonaId { get; set; }
    public string CodigoStaff { get; set; } = string.Empty;
    public string Cargo { get; set; } = string.Empty;
    public string Area { get; set; } = string.Empty;

    public Persona? Persona { get; set; }
}
