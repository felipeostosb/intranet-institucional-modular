namespace Intranet.Core.DTOs;

public record UsuarioDto(
    int Id,
    string Dni,
    string CodigoInstitucional,
    string NombreCompleto,
    string Email,
    string Rol
);
