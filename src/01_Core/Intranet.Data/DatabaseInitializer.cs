using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using MySqlConnector;
using Intranet.Core.Entities;

namespace Intranet.Data;

public static class DatabaseInitializer
{
    public static async Task InicializarAsync(ApplicationDbContext context, IConfiguration? configuration = null)
    {
        try
        {
            // 1. Ejecutar Schema Maestro de Core si está configurado
            if (configuration != null)
            {
                await EjecutarEsquemaCoreAsync(configuration);
                await EjecutarEsquemasModularesAsync(configuration);
            }
            else
            {
                await context.Database.EnsureCreatedAsync();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[DatabaseInitializer] Aviso inicializando DB: {ex.Message}");
        }
    }

    private static async Task EjecutarEsquemaCoreAsync(IConfiguration configuration)
    {
        var defaultConn = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrEmpty(defaultConn)) return;

        var baseDir = AppContext.BaseDirectory;
        var currentDir = Directory.GetCurrentDirectory();

        var possiblePaths = new[]
        {
            Path.Combine(baseDir, "Sql", "core_schema.sql"),
            Path.Combine(currentDir, "src", "01_Core", "Sql", "core_schema.sql"),
            Path.Combine(currentDir, "01_Core", "Sql", "core_schema.sql"),
            Path.Combine(baseDir, "..", "..", "..", "..", "01_Core", "Sql", "core_schema.sql"),
            Path.Combine(baseDir, "src", "01_Core", "Sql", "core_schema.sql")
        };

        foreach (var path in possiblePaths)
        {
            if (File.Exists(path))
            {
                try
                {
                    var sql = await File.ReadAllTextAsync(path);
                    if (!string.IsNullOrWhiteSpace(sql))
                    {
                        using var conn = new MySqlConnection(defaultConn);
                        await conn.OpenAsync();
                        using var cmd = new MySqlCommand(sql, conn);
                        await cmd.ExecuteNonQueryAsync();
                        Console.WriteLine("[DatabaseInitializer] ✓ Esquema Maestro Core y datos semilla ejecutados correctamente.");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[DatabaseInitializer] Aviso al ejecutar core_schema.sql: {ex.Message}");
                }
                break;
            }
        }
    }

    private static async Task EjecutarEsquemasModularesAsync(IConfiguration configuration)
    {
        var defaultConn = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrEmpty(defaultConn)) return;

        var baseDir = AppContext.BaseDirectory;
        var currentDir = Directory.GetCurrentDirectory();

        for (int i = 1; i <= 9; i++)
        {
            var num = i.ToString("D2");
            var modName = $"Intranet.Modulo{num}";

            var possiblePaths = new[]
            {
                Path.Combine(baseDir, "Sql", $"modulo{num}_schema.sql"),
                Path.Combine(currentDir, "src", "02_Modulos", modName, "Sql", "schema.sql"),
                Path.Combine(currentDir, "02_Modulos", modName, "Sql", "schema.sql"),
                Path.Combine(baseDir, "..", "..", "..", "..", "02_Modulos", modName, "Sql", "schema.sql"),
                Path.Combine(baseDir, "src", "02_Modulos", modName, "Sql", "schema.sql")
            };

            foreach (var path in possiblePaths)
            {
                if (File.Exists(path))
                {
                    try
                    {
                        var sql = await File.ReadAllTextAsync(path);
                        if (!string.IsNullOrWhiteSpace(sql))
                        {
                            var moduleConn = configuration.GetConnectionString($"Modulo{num}Connection");
                            var connStr = !string.IsNullOrWhiteSpace(moduleConn) ? moduleConn : defaultConn;

                            using var conn = new MySqlConnection(connStr);
                            await conn.OpenAsync();
                            using var cmd = new MySqlCommand(sql, conn);
                            await cmd.ExecuteNonQueryAsync();
                            Console.WriteLine($"[DatabaseInitializer] ✓ Script SQL modular ejecutado para Módulo {num}");
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[DatabaseInitializer] Aviso al ejecutar SQL de Módulo {num}: {ex.Message}");
                    }
                    break;
                }
            }
        }
    }
}
