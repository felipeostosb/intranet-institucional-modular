namespace Intranet.Core.Entities;

public class UsuarioRol
{
    public int Id { get; set; }
    public int UsuarioId { get; set; }
    public int RolId { get; set; }
    public DateTime AsignadoEn { get; set; } = DateTime.Now;
    public bool EsActivo { get; set; } = true;

    public Usuario? Usuario { get; set; }
    public Rol? Rol { get; set; }
}
