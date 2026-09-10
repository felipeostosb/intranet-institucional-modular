namespace Intranet.Core.Entities;

public class Aula
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Pabellon { get; set; } = string.Empty;
    public int Aforo { get; set; } = 35;
    public string Tipo { get; set; } = "Teoria";
}
