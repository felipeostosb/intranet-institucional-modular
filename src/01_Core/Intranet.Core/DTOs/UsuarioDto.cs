namespace Intranet.Core.DTOs;

public record UsuarioDto(
    int Id,
    int PersonaId,
    string Dni,
    string CodigoInstitucional,
    string NombreCompleto,
    string Email,
    string RolPrincipal,
    List<string> Roles
);
