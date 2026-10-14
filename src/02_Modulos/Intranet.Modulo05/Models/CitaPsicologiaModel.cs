using System.ComponentModel.DataAnnotations;

namespace Intranet.Modulo05.Models;

/// <summary>
/// Modelo de entidad/DTO para las citas psicológicas (mod05.citas_psicologia).
/// Basado en el esquema soberano de base de datos de Modulo 05.
/// </summary>
public class CitaPsicologiaItem
{
    public int       Id                { get; set; }
    public int?      PersonaId         { get; set; }
    public string    Nombres           { get; set; } = string.Empty;
    public string    Apellidos         { get; set; } = string.Empty;
    public string    Email             { get; set; } = string.Empty;
    public DateTime  Inicio            { get; set; }
    public DateTime  Fin               { get; set; }
    public string?   Motivo            { get; set; }
    public string    Estado            { get; set; } = "Programada";
    public string    Origen            { get; set; } = "Sistema";
    public string?   GoogleEventId     { get; set; }
    public int?      PsicologoId       { get; set; }
    public string?   MotivoCancelacion { get; set; }
    public DateTime  CreadoEn          { get; set; } = DateTime.UtcNow;

    // Campos de apoyo y lectura desde joins
    public string    NombreCompleto    => $"{Nombres} {Apellidos}".Trim();
    public string?   PsicologoNombre   { get; set; }
    public string?   Dni               { get; set; }
    public string?   Carrera           { get; set; }
}

/// <summary>
/// DTO de entrada para registrar o agendar una nueva cita psicológica.
/// </summary>
public class RegistrarCitaInputDto
{
    [Required(ErrorMessage = "Los nombres del solicitante son obligatorios.")]
    [StringLength(100, ErrorMessage = "Los nombres no pueden exceder 100 caracteres.")]
    public string Nombres { get; set; } = string.Empty;

    [Required(ErrorMessage = "Los apellidos del solicitante son obligatorios.")]
    [StringLength(100, ErrorMessage = "Los apellidos no pueden exceder 100 caracteres.")]
    public string Apellidos { get; set; } = string.Empty;

    [Required(ErrorMessage = "El correo electrónico es obligatorio.")]
    [EmailAddress(ErrorMessage = "El formato de correo no es válido.")]
    [StringLength(150, ErrorMessage = "El correo no puede exceder 150 caracteres.")]
    public string Email { get; set; } = string.Empty;

    public string? Dni { get; set; }

    [Required(ErrorMessage = "La fecha de la cita es obligatoria.")]
    public string Fecha { get; set; } = string.Empty;

    [Required(ErrorMessage = "La hora de inicio es obligatoria.")]
    public string HoraInicio { get; set; } = "09:00";

    public int DuracionMinutos { get; set; } = 30;

    [StringLength(250, ErrorMessage = "El motivo no puede exceder los 250 caracteres.")]
    public string? Motivo { get; set; }

    public string Origen { get; set; } = "Sistema";

    public int? PsicologoId { get; set; }
}

/// <summary>
/// DTO para el listado de psicólogos disponibles.
/// </summary>
public class PsicologoItemDto
{
    public int    UsuarioId      { get; set; }
    public string NombreCompleto { get; set; } = string.Empty;
    public string Email          { get; set; } = string.Empty;
}
