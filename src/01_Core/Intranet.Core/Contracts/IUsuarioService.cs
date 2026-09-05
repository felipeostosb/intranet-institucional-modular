using Intranet.Core.DTOs;

namespace Intranet.Core.Contracts;

public interface IUsuarioService
{
    Task<UsuarioDto?> ObtenerPorIdAsync(int id);
    Task<UsuarioDto?> ObtenerPorDniAsync(string dni);
    Task<UsuarioDto?> ObtenerPorCodigoAsync(string codigoInstitucional);
    Task<List<UsuarioDto>> ListarPorRolAsync(string rol);
    Task<bool> ValidarCredencialesAsync(string dniOCodigo, string password);
}
