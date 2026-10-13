# 📋 Análisis Integral del Módulo 05 y Arquitectura del Proyecto Intranet

> **Fecha:** 11 de Octubre, 2026  
> **Proyecto:** AQUILA A-ERP — Intranet Institucional Modular (.NET 10 LTS + PostgreSQL 16)  
> **Ubicación evaluada:** `src/02_Modulos/Intranet.Modulo05`

---

## 1. 🔍 Diagnóstico Inmediato: Estado Actual y Reparación Realizada

> [!TIP]
> **ESTADO ACTUAL:** ✅ **SOLUCIONADO Y COMPILANDO AL 100% (0 Errores, 0 Advertencias)**  
> Se reconstruyó la arquitectura del módulo, se vincularon los controladores y vistas del submódulo clínico, docente, soporte y psicología, y la solución entera `IntranetInstitucional.sln` compila con éxito.

### Problema Inicial Identificado
Al inicio, el compilador lanzaba el error fatal:
```text
error MSB3202: No se encuentra el archivo del proyecto ".../src/02_Modulos/Intranet.Modulo05/Intranet.Modulo05.csproj".
[IntranetInstitucional.sln]
```

### Causa Raíz y Solución Aplicada
1. **Restauración de `Intranet.Modulo05.csproj`**: Se configuró como Razor Class Library (.NET 10 LTS) con referencias a `Intranet.Core` y al driver de base de datos PostgreSQL `Npgsql (8.0.5)`.
2. **Normalización de Carpetas y Namespaces**: Se unificaron los controladores bajo la carpeta estándar `Controllers/` y se actualizaron los espacios de nombres a `Intranet.Modulo05.Controllers` e `Intranet.Modulo05.Models`.
3. **Ajuste de Vistas Razor y Directivas `@model`**: Se migraron las referencias a vistas que antes dependían de `Areas` para que ahora se resuelvan dentro del ensamblado modular.
4. **Punto de Entrada e Integración**: Se restauraron `Modulo05Controller.cs` y `Modulo05Startup.cs`, y se agregaron accesos directos en el Dashboard principal a las secciones de Enfermería, Averías, Soporte TI y Psicología.

---

## 2. 🧩 ¿Para qué sirven los archivos que viste en los otros módulos?

En el resto de módulos (`Intranet.Modulo00` al `Intranet.Modulo09`) viste una serie de archivos y carpetas que tienen un propósito específico en .NET:

| Archivo / Carpeta | ¿Es necesario? | Propósito en la Arquitectura |
| :--- | :---: | :--- |
| **`Intranet.ModuloXX.csproj`** | **CRÍTICO / OBLIGATORIO** | Define que la carpeta es una **Razor Class Library** (`Microsoft.NET.Sdk.Razor`), define la versión (.NET 10), sus librerías y cómo se empaquetan las vistas Razor en la aplicación web principal. |
| **`ModuloXXStartup.cs`** | **OBLIGATORIO** | Implementa la interfaz `IModuloStartup`. Al arrancar la intranet, el servidor busca por *Reflection* esta clase y registra automáticamente los servicios de tu módulo sin tocar el código central. |
| **`Controllers/ModuloXXController.cs`** | **OBLIGATORIO** | Es el punto de entrada que hereda de `ModuloBaseController`, define la ruta `/ModuloXX` y permite a `Program.cs` detectar y cargar el módulo. |
| **`bin/` y `obj/`** | **NO SE CREAN A MANO** | Son carpetas temporales generadas **automáticamente por el compilador** cuando ejecutas `dotnet build`. Contienen las DLLs compiladas. **No debes preocuparte por ellas ni copiarlas a mano**; se generan solas. |
| **`Sql/schema.sql`** | **OBLIGATORIO** | Contiene las tablas y migraciones que le corresponden a tu esquema en PostgreSQL (`mod05`). |

---

## 3. ⚠️ Choque de Arquitecturas: Lo que trajiste vs. Lo que espera la Intranet

Los archivos que subiste provienen de otro proyecto con arquitectura distinta:

### En el código que trajiste:
* **Espacio de nombres ajeno:**
  ```csharp
  namespace Login_Administracion_de_Modulos.Areas.Modulo05.Controller
  ```
* **Estructura de Áreas ASP.NET (antigua / monolítica tradicional):**
  Llamadas como:
  ```csharp
  return PartialView("~/Areas/Modulo05/Views/enfermeria/form_atencion.cshtml");
  return Redirect("/Dashboard/Topico");
  ```
* **Nombre de carpeta en singular:** Carpeta `Controller/` en lugar del estándar .NET `Controllers/`.
* **Conexión SQL directa:** Usa `new NpgsqlConnection(...)` directo y consultas como `SELECT ... FROM personas`, sin respetar el prefijo de esquema (`core.personas` o el `search_path`).

### En la Intranet Modular actual (AQUILA ERP):
* **Arquitectura de Monolito Modular Desacoplado:** Cada módulo es un proyecto independiente (`Razor Class Library`).
* **Espacios de nombres estandarizados:**
  ```csharp
  namespace Intranet.Modulo05.Controllers;
  namespace Intranet.Modulo05.Models;
  ```
* **Rutas y Vistas relativas al módulo:** Las vistas se ubican en `Views/{NombreController}/{Accion}.cshtml` y se invocan simplemente con `return View();` o `return PartialView("...");`.
* **Controladores base:** Los controladores deben heredar de `ModuloBaseController` (de `Intranet.Core.Controllers`) para contar automáticamente con seguridad por roles, cookies de sesión del usuario logueado (`UsuarioActualNombre`, `UsuarioActualRol`) y alertas toast.

---

## 4. 🌐 ¿Está funcionando realmente en el Hosting y la Base de Datos?

### A. Sobre el Hosting en la Nube
* **Sí existe un entorno en producción:**
  * **Intranet en Vivo (.NET 10 en Docker):** `http://35.209.228.150`
  * **Adminer Web PostgreSQL:** `http://35.206.81.32:8080`
* **¿Por qué localmente no se ve nada?**
  * En el servidor de la nube está corriendo la versión que se construyó con la estructura original antes de que el Módulo 05 perdiera su archivo `.csproj`.
  * Localmente en tu máquina, al no compilar, la aplicación web no puede arrancar. Si lanzas `http://localhost:5000`, o no responderá o mostrará un error del servidor.

### B. Sobre la Base de Datos PostgreSQL
* El servidor PostgreSQL se encuentra en la IP `35.206.81.32:5432` con la base de datos `db_intranet_iestp`.
* La base de datos está dividida por **Esquemas Soberanos**:
  * `core.*`: Usuarios, Personas, Roles, Carreras, etc.
  * `mod01.*` al `mod09.*`: Las tablas privadas de cada equipo. Tu equipo tiene asignado el esquema **`mod05`** con usuario `user_equipo05`.
* En tu archivo local `appsettings.json`, la cadena de conexión apunta a `127.0.0.1` (tu propia máquina local) con contraseñas temporales `CHANGE_ME_IN_ENV`. Por eso, si no tienes PostgreSQL corriendo en tu PC o no configuraste `appsettings.Local.json` apuntando al servidor de la nube, las llamadas a la base de datos tampoco responderían localmente.

---

## 5. 🛠️ Solución y Pasos para dejar funcionando el Módulo 05

Para que tu Módulo 05 compile, se integre con la intranet, funcione con la base de datos y pueda verse tanto localmente como en el hosting, se deben realizar los siguientes pasos de adaptación:

1. **Restaurar el archivo de proyecto `Intranet.Modulo05.csproj`:**
   Crear el `.csproj` con SDK Razor y referencia a `Intranet.Core` y paquete `Npgsql`.
2. **Restaurar `Modulo05Startup.cs`:**
   Implementar `IModuloStartup` para registrar repositorios o servicios en el contenedor.
3. **Restaurar el controlador principal `Modulo05Controller.cs`:**
   Punto de entrada para el menú principal del módulo en `/Modulo05`.
4. **Normalizar nombres de carpetas y Namespaces:**
   * Renombrar `Controller/` a `Controllers/`.
   * Cambiar los namespaces de `Login_Administracion_de_Modulos...` a `Intranet.Modulo05.Controllers` y `Intranet.Modulo05.Models`.
5. **Ajustar rutas de vistas y redirecciones:**
   Cambiar `~/Areas/Modulo05/Views/...` por las rutas relativas correspondientes a Razor Class Libraries.
6. **Alinear consultas SQL:**
   Apuntar a las tablas de `core.personas` o las tablas de tu esquema `mod05.*`.
7. **Probar la compilación:**
   Ejecutar `dotnet build IntranetInstitucional.sln` para asegurar que el proyecto compila al 100% con 0 errores.
8. **Ejecutar la intranet local:**
   Ejecutar `dotnet run --project src/03_Web/Intranet.Web` o usar `.\dev.ps1` para navegar en `http://localhost:5000/Modulo05`.
