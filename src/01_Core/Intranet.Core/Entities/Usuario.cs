namespace Intranet.Core.Entities;

public class Usuario
{
    public int Id { get; set; }
    public int PersonaId { get; set; }
    public string CodigoInstitucional { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = "123456";
    public DateTime? UltimoAcceso { get; set; }
    public bool Estado { get; set; } = true;
    public DateTime CreadoEn { get; set; } = DateTime.Now;

    public Persona? Persona { get; set; }
    public ICollection<UsuarioRol> UsuarioRoles { get; set; } = new List<UsuarioRol>();
}
