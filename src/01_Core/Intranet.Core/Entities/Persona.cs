namespace Intranet.Core.Entities;

public class Persona
{
    public int Id { get; set; }
    public string Dni { get; set; } = string.Empty;
    public string Nombres { get; set; } = string.Empty;
    public string Apellidos { get; set; } = string.Empty;
    public DateTime? FechaNacimiento { get; set; }
    public string Sexo { get; set; } = "M";
    public string? EmailPersonal { get; set; }
    public string? Telefono { get; set; }
    public string? Direccion { get; set; }
    public string? FotoUrl { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.Now;

    public string NombreCompleto => $"{Nombres} {Apellidos}";
}
