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

            // Lista completa de usuarios institucionales representativos del IESTP Argentina
            var usuariosSemilla = new List<Usuario>
            {
                new()
                {
                    Dni = "00000001",
                    CodigoInstitucional = "ADMIN-2026",
                    Nombres = "Administrador",
                    Apellidos = "General de TI",
                    Email = "admin.ti@ieargentina.edu.pe",
                    Rol = "Admin",
                    Estado = true
                },
                new()
                {
                    Dni = "10000001",
                    CodigoInstitucional = "DIR-2026",
                    Nombres = "Manuel",
                    Apellidos = "Alvarado Carranza",
                    Email = "direccion@ieargentina.edu.pe",
                    Rol = "Director",
                    Estado = true
                },
                new()
                {
                    Dni = "20000001",
                    CodigoInstitucional = "COORD-DSI",
                    Nombres = "Carlos",
                    Apellidos = "Mendoza Rivas",
                    Email = "coord.sistemas@ieargentina.edu.pe",
                    Rol = "Coordinador",
                    Estado = true
                },
                new()
                {
                    Dni = "30000001",
                    CodigoInstitucional = "SEC-ACAD",
                    Nombres = "Rosa",
                    Apellidos = "Morales Salazar",
                    Email = "secretaria.academica@ieargentina.edu.pe",
                    Rol = "Secretaria",
                    Estado = true
                },
                new()
                {
                    Dni = "40000001",
                    CodigoInstitucional = "TES-2026",
                    Nombres = "Elena",
                    Apellidos = "Ramos Palacios",
                    Email = "tesoreria@ieargentina.edu.pe",
                    Rol = "Tesoreria",
                    Estado = true
                },
                new()
                {
                    Dni = "12345678",
                    CodigoInstitucional = "DOC-DSI-01",
                    Nombres = "Roberto",
                    Apellidos = "Sánchez Benítez",
                    Email = "rsanchez@ieargentina.edu.pe",
                    Rol = "Docente",
                    Estado = true
                },
                new()
                {
                    Dni = "87654321",
                    CodigoInstitucional = "EST-DSI-001",
                    Nombres = "Felipe",
                    Apellidos = "Ostos",
                    Email = "felipe.ostos@ieargentina.edu.pe",
                    Rol = "Alumno",
                    Estado = true
                },
                new()
                {
                    Dni = "77654321",
                    CodigoInstitucional = "EST-DSI-002",
                    Nombres = "Ana",
                    Apellidos = "García Flores",
                    Email = "ana.garcia@ieargentina.edu.pe",
                    Rol = "Alumno",
                    Estado = true
                },
                new()
                {
                    Dni = "66554433",
                    CodigoInstitucional = "EST-CONT-001",
                    Nombres = "Luis",
                    Apellidos = "Torres Quispe",
                    Email = "luis.torres@ieargentina.edu.pe",
                    Rol = "Alumno",
                    Estado = true
                }
            };

            foreach (var u in usuariosSemilla)
            {
                if (!await context.Usuarios.AnyAsync(x => x.Dni == u.Dni))
                {
                    await context.Usuarios.AddAsync(u);
                }
            }

            await context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[DatabaseInitializer] Aviso: {ex.Message}");
        }
    }
}
