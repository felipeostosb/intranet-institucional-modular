namespace Intranet.Core.Entities;

public class Carrera
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public int TotalSemestres { get; set; } = 6;
    public string Modalidad { get; set; } = "Presencial";
    public bool Estado { get; set; } = true;
}
