namespace Intranet.Modulo03.Models;

public class AlmacenModel
{
    public int IdAlmacen { get; set; }
    public int? IdEspecialidad { get; set; }
    public string? Especialidad { get; set; }
    public string Nombre { get; set; } = "";
    public string? Ubicacion { get; set; }
    public string? Responsable { get; set; }
    public string Estado { get; set; } = "Activo";
}

public class ClasificacionModel
{
    public int IdClasificacion { get; set; }
    public string Nombre { get; set; } = "";
    public string Estado { get; set; } = "Activo";
}

public class AmbienteModel
{
    public int IdAmbiente { get; set; }
    public int? IdEspecialidad { get; set; }
    public string? Especialidad { get; set; }
    public string Nombre { get; set; } = "";
    public string Estado { get; set; } = "Activo";
}
