using Microsoft.EntityFrameworkCore;
using Intranet.Core.Contracts;
using Intranet.Core.DTOs;

namespace Intranet.Data.Services;

public class UsuarioService : IUsuarioService
{
    private readonly ApplicationDbContext _db;

    public UsuarioService(ApplicationDbContext db)
    {
        _db = db;
    }

    public async Task<UsuarioDto?> ObtenerPorIdAsync(int id)
    {
        var u = await _db.Usuarios.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
        return u == null ? null : MapToDto(u);
    }

    public async Task<UsuarioDto?> ObtenerPorDniAsync(string dni)
    {
        var u = await _db.Usuarios.AsNoTracking().FirstOrDefaultAsync(x => x.Dni == dni);
        return u == null ? null : MapToDto(u);
    }

    public async Task<UsuarioDto?> ObtenerPorCodigoAsync(string codigoInstitucional)
    {
        var u = await _db.Usuarios.AsNoTracking().FirstOrDefaultAsync(x => x.CodigoInstitucional == codigoInstitucional);
        return u == null ? null : MapToDto(u);
    }

    public async Task<List<UsuarioDto>> ListarPorRolAsync(string rol)
    {
        return await _db.Usuarios
            .AsNoTracking()
            .Where(x => x.Rol == rol && x.Estado)
            .OrderBy(x => x.Apellidos)
            .Select(u => new UsuarioDto(
                u.Id,
                u.Dni,
                u.CodigoInstitucional,
                $"{u.Nombres} {u.Apellidos}",
                u.Email,
                u.Rol
            ))
            .ToListAsync();
    }

    public async Task<bool> ValidarCredencialesAsync(string dniOCodigo, string password)
    {
        // En entorno institucional / demo: clave por defecto o DNI
        var u = await _db.Usuarios.FirstOrDefaultAsync(x => (x.Dni == dniOCodigo || x.CodigoInstitucional == dniOCodigo) && x.Estado);
        if (u == null) return false;

        // Si password coincide con su DNI o password universal '123456' / '@2026'
        return password == u.Dni || password == "123456" || password == "@2026";
    }

    private static UsuarioDto MapToDto(Core.Entities.Usuario u)
    {
        return new UsuarioDto(
            u.Id,
            u.Dni,
            u.CodigoInstitucional,
            $"{u.Nombres} {u.Apellidos}",
            u.Email,
            u.Rol
        );
    }
}
