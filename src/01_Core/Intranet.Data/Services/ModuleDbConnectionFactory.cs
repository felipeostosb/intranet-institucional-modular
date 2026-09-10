using System.Data;
using Microsoft.Extensions.Configuration;
using MySqlConnector;
using Intranet.Core.Contracts;

namespace Intranet.Data.Services;

public class ModuleDbConnectionFactory : IModuleDbConnectionFactory
{
    private readonly IConfiguration _configuration;

    public ModuleDbConnectionFactory(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public IDbConnection CreateConnection(string moduloNumero)
    {
        var num = moduloNumero.PadLeft(2, '0');
        var connStr = _configuration.GetConnectionString($"Modulo{num}Connection");

        if (string.IsNullOrEmpty(connStr))
        {
            connStr = _configuration.GetConnectionString("DefaultConnection") ?? "";
        }

        return new MySqlConnection(connStr);
    }
}
