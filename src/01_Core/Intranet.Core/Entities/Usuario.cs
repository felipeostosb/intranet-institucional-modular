namespace Intranet.Core.Entities;

public class Usuario
{
    public int Id { get; set; }
    public string Dni { get; set; } = string.Empty;
    public string CodigoInstitucional { get; set; } = string.Empty;
    public string Nombres { get; set; } = string.Empty;
    public string Apellidos { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = "Alumno";
    public bool Estado { get; set; } = true;
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
}
