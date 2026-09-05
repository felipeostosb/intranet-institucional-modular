using Microsoft.EntityFrameworkCore;
using Intranet.Core.Entities;

namespace Intranet.Data;

public static class DatabaseInitializer
{
    public static async Task InicializarAsync(ApplicationDbContext context)
    {
        try
        {
            await context.Database.EnsureCreatedAsync();

            if (!await context.Usuarios.AnyAsync())
            {
                var usuariosSemilla = new List<Usuario>
                {
                    new()
                    {
                        Dni = "00000001",
                        CodigoInstitucional = "ADMIN-2026",
                        Nombres = "Administrador",
                        Apellidos = "General",
                        Email = "admin@instituto.edu.pe",
                        Rol = "Admin",
                        Estado = true
                    },
                    new()
                    {
                        Dni = "12345678",
                        CodigoInstitucional = "DOC-2026-01",
                        Nombres = "Profesor",
                        Apellidos = "Pérez",
                        Email = "docente.perez@instituto.edu.pe",
                        Rol = "Docente",
                        Estado = true
                    },
                    new()
                    {
                        Dni = "87654321",
                        CodigoInstitucional = "EST-2026-001",
                        Nombres = "Felipe",
                        Apellidos = "Ostos",
                        Email = "felipe.ostos@instituto.edu.pe",
                        Rol = "Alumno",
                        Estado = true
                    },
                    new()
                    {
                        Dni = "77654321",
                        CodigoInstitucional = "EST-2026-002",
                        Nombres = "Ana",
                        Apellidos = "García",
                        Email = "ana.garcia@instituto.edu.pe",
                        Rol = "Alumno",
                        Estado = true
                    }
                };

                await context.Usuarios.AddRangeAsync(usuariosSemilla);
                await context.SaveChangesAsync();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[DatabaseInitializer] Aviso: {ex.Message}");
        }
    }
}
