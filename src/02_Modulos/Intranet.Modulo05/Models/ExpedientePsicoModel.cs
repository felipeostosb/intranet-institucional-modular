using System.ComponentModel.DataAnnotations;

namespace Intranet.Modulo05.Models;

/// <summary>
/// DTO de una sesión/atención psicológica (mod05.atenciones_psicologia).
/// Los controladores lo consultan via IModuleDbConnectionFactory + Dapper.
/// </summary>
public class SesionPsicologicaItem
{
    public int      IdAtencionPsico    { get; set; }
    public int      PersonaId          { get; set; }
    public int      PsicologoId        { get; set; }
    public DateTime FechaHora          { get; set; } = DateTime.Now;

    [Required(ErrorMessage = "El motivo de consulta es obligatorio.")]
    [StringLength(250)]
    public string   MotivoConsulta     { get; set; } = string.Empty;

    public string?  ObservacionNotas   { get; set; }

    [StringLength(30)]
    public string   EstadoAtencion     { get; set; } = "Pendiente";

    // Campos complementarios del estudiante (JOIN a core.personas)
    public string?  NumeroDocumento    { get; set; }
    public string?  EstudianteNombres  { get; set; }
    public string?  EstudianteApellidos { get; set; }
    public string   NombreCompleto     => $"{EstudianteApellidos} {EstudianteNombres}".Trim();
    public string?  Carrera            { get; set; }
    public string?  CicloTurno         { get; set; }
}

/// <summary>
/// DTO para la búsqueda de estudiante en Psicología y Enfermería.
/// </summary>
public class EstudianteBusquedaDto
{
    public int    PersonaId           { get; set; }
    public string NumeroDocumento     { get; set; } = string.Empty;
    public string EstudianteNombres   { get; set; } = string.Empty;
    public string EstudianteApellidos { get; set; } = string.Empty;
    public string? Carrera            { get; set; }
    public string? CicloTurno         { get; set; }
}
