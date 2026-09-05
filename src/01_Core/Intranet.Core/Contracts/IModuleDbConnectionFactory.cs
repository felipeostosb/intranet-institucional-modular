using System.Data;

namespace Intranet.Core.Contracts;

/// <summary>
/// Proveedor centralizado de conexiones seguras a las bases de datos aisladas de cada módulo.
/// Evita que los alumnos tengan que configurar cadenas de conexión manualmente.
/// </summary>
public interface IModuleDbConnectionFactory
{
    IDbConnection CreateConnection(string moduloNumero);
}
