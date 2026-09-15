# GitHub Copilot Instructions - Intranet Institucional Modular (.NET 10 + PostgreSQL 16)

## Reglas de Arquitectura y Base de Datos para Asistentes de IA

1. **Esquemas Aislados en PostgreSQL 16:**
   - Todo DDL o tabla debe pertenecer al esquema `modXX` (ej: `mod01` al `mod09`).
   - El esquema `core` (`core.personas`, `core.estudiantes`, `core.carreras`, etc.) es de solo lectura (`SELECT`).
   - Guardar scripts SQL en `src/02_Modulos/Intranet.ModuloXX/Sql/schema.sql` con `CREATE TABLE IF NOT EXISTS modXX.tabla (...)`.

2. **Estructura C# .NET 10:**
   - Los controladores deben heredar de `ModuloBaseController` y estar decorados con `[Authorize]`.
   - Utilizar `IModuleDbConnectionFactory` para obtener conexiones SQL hacia PostgreSQL.
   - Registrar dependencias en `ModuloXXStartup.cs` con `IModuloStartup`.
   - No modificar carpetas fuera de `src/02_Modulos/Intranet.ModuloXX/`.
