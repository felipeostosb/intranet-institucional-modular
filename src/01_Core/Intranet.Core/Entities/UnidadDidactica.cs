namespace Intranet.Core.Entities;

public class UnidadDidactica
{
    public int Id { get; set; }
    public int CarreraId { get; set; }
    public string Ciclo { get; set; } = "I";
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public int Creditos { get; set; } = 3;
    public int HorasSemanales { get; set; } = 4;
    public string Tipo { get; set; } = "Formativa";

    public Carrera? Carrera { get; set; }
}
