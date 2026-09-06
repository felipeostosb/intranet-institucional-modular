# 🏛️ Intranet Institucional Modular (.NET 10 LTS + MariaDB)

Bienvenido al proyecto integrador de la Intranet Institucional del **IESTP "Argentina"**. Este sistema está construido sobre **.NET 10 LTS (Soporte Oficial a Largo Plazo hasta Noviembre 2028)** y una **Arquitectura de Monolito Modular Desacoplado** diseñada para que **36 desarrolladores (9 equipos de 4 personas)** trabajen en paralelo con total autonomía y cero colisiones (*Zero-Blast-Radius*).

---

## ⚡ Guía de Inicio Rápido (The Golden Path - 1 Solo Clic)

Hemos creado un **CLI Interactivo** que automatiza todo el flujo de Git, nombres de ramas, scaffolding de código y validaciones locales para que **no cometas ningún error de principiante**:

### 🐧 En Linux, macOS o Git Bash:
```bash
# 1. Clonar el repositorio
git clone https://github.com/felipeostosb/intranet-institucional-modular.git
cd intranet-institucional-modular

# 2. Ejecutar el Asistente Interactivo
./dev.sh
```

### 🪟 En Windows (PowerShell):
```powershell
# 1. Clonar el repositorio
git clone https://github.com/felipeostosb/intranet-institucional-modular.git
cd intranet-institucional-modular

# 2. Ejecutar el Asistente Interactivo
.\dev.ps1
```

---

## 🖥️ ¿Qué hace el Asistente Interactivo (`./dev.sh` / `.\dev.ps1`) por ti?

El asistente te ofrece **4 opciones claras y directas**:

1. **🚀 Iniciar Intranet:** Lanza la aplicación local en `http://localhost:5000` con **Hot-Reload** (se actualiza sola en ~100ms al guardar cambios en cualquier archivo).
2. **🌿 Crear / Cambiar a mi Rama de Equipo:** Te pide tu número de equipo y crea automáticamente ramas estandarizadas como `modulo04/formulario-registro` sincronizadas con `main`.
3. **⚡ Generar Formulario / Tabla:** En 1 segundo genera un Modelo C#, un Controlador con `ModuloBaseController` y una Vista Razor con diseño Apple / DaisyUI 100% responsiva y lista para usar.
4. **📤 Subir mi Trabajo a GitHub:** Guarda automáticamente tus cambios, descarga actualizaciones remotas con `git pull --rebase` y publica tu rama en GitHub con el enlace directo para abrir tu Pull Request.

> [!NOTE]
> **🛡️ Guardián Git Poka-Yoke:** Al ejecutar el asistente, se instala automáticamente un *hook* local que bloquea de forma preventiva cualquier intento de hacer `git push` accidental directo a la rama `main`.

---

## 👥 Distribución Soberana de los 9 Módulos y Bases de Datos

Cada equipo cuenta con su propia carpeta de código y esquema de base de datos aislado:

| Equipo | Módulo | Carpeta Soberana | Base de Datos MariaDB | Usuario DB | Color Distintivo |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **01** | **Módulo 01** | `src/02_Modulos/Intranet.Modulo01/` | `db_modulo01` | `user_equipo01` | 🩵 Sky Pastel |
| **02** | **Módulo 02** | `src/02_Modulos/Intranet.Modulo02/` | `db_modulo02` | `user_equipo02` | 💙 Indigo Pastel |
| **03** | **Módulo 03** | `src/02_Modulos/Intranet.Modulo03/` | `db_modulo03` | `user_equipo03` | 💚 Emerald Pastel |
| **04** | **Módulo 04** | `src/02_Modulos/Intranet.Modulo04/` | `db_modulo04` | `user_equipo04` | 💛 Amber Pastel |
| **05** | **Módulo 05** | `src/02_Modulos/Intranet.Modulo05/` | `db_modulo05` | `user_equipo05` | 💜 Purple Pastel |
| **06** | **Módulo 06** | `src/02_Modulos/Intranet.Modulo06/` | `db_modulo06` | `user_equipo06` | 🩷 Rose Pastel |
| **07** | **Módulo 07** | `src/02_Modulos/Intranet.Modulo07/` | `db_modulo07` | `user_equipo07` | 🩵 Teal Pastel |
| **08** | **Módulo 08** | `src/02_Modulos/Intranet.Modulo08/` | `db_modulo08` | `user_equipo08` | 🧡 Orange Pastel |
| **09** | **Módulo 09** | `src/02_Modulos/Intranet.Modulo09/` | `db_modulo09` | `user_equipo09` | 🌐 Cyan Pastel |

---

## 🏗️ Arquitectura & Comunicación Intermodular

### 1. 🔄 Bus de Eventos en Memoria (`InMemoryEventBus`)
Para comunicar módulos sin acoplar código ni dependencias circulares:
* **Emitir un evento:**
  ```csharp
  await _eventBus.PublishAsync(new RegistroCreadoEvent { Codigo = "REG-01", Equipo = 4 });
  ```
* **Escuchar un evento desde tu módulo:**
  ```csharp
  public class NotificarRegistroHandler : IEventHandler<RegistroCreadoEvent>
  {
      public Task HandleAsync(RegistroCreadoEvent @event, CancellationToken cancellationToken = default)
      {
          // Lógica de reacción en tu módulo
          return Task.CompletedTask;
      }
  }
  ```

### 2. 🗄️ Acceso a Datos & Migraciones Automáticas
* **Conexión:** Inyecta `IModuleDbConnectionFactory` para obtener la conexión SQL hacia MariaDB (`factory.CreateConnection()`).
* **Migraciones SQL Automáticas:** Todo archivo `.sql` colocado dentro de `src/02_Modulos/Intranet.ModuloXX/Sql/schema.sql` se ejecuta automáticamente al iniciar la aplicación (usa siempre `CREATE TABLE IF NOT EXISTS`).

### 3. ⚙️ Inyección de Dependencias Modular (`IModuloStartup`)
Cada módulo registra sus propios servicios en su archivo `ModuloXXStartup.cs` implementando `IModuloStartup`. El sistema los descubre y registra automáticamente al arrancar.

---

## 🛡️ Reglas de Oro del Proyecto (Poka-Yoke)

1. **Aislamiento Estricto:** Programa **únicamente** dentro de tu carpeta `src/02_Modulos/Intranet.ModuloXX/`.
2. **Prohibido Push a `main`:** Todo cambio se entrega mediante **Pull Request** desde tu rama `moduloXX/tu-tarea`.
3. **Controladores con Seguridad:** Haz que tus controladores hereden de `ModuloBaseController` para tener acceso a `UsuarioActualRol`, `UsuarioActualNombre` y métodos Toast (`MostrarAlertaExito`, `MostrarAlertaError`).
4. **Validación Automática en CI/CD:** Si tu PR modifica solo tu módulo y compila con 0 errores, **GitHub Actions lo fusiona a producción en ~45 segundos**.

---

## 🌐 Enlaces de Producción & Base de Datos

* 🚀 **Intranet en Vivo (.NET 10 en Docker):** [http://35.209.228.150](http://35.209.228.150)
* 🗄️ **phpMyAdmin BD MariaDB:** [http://35.208.213.59:8080](http://35.208.213.59:8080)
  * **Usuario:** `user_equipo[XX]` *(ej: user_equipo01 al user_equipo09)*
  * **Contraseña:** `Equipo[XX]_Pass2026!` *(ej: Equipo01_Pass2026!)*
  * **Permisos:** Control total de escritura en `db_modulo[XX]` y lectura `SELECT` sobre los demás esquemas.

---

## 🤖 Plantilla Maestra de Prompt para la IA (ChatGPT / Claude / DeepSeek / Cursor)

Si tú o tu equipo usan Inteligencia Artificial para programar o modelar su base de datos, **copia y pega esta plantilla exacta** al iniciar tu chat con la IA para que te genere código 100% compatible y sin errores:

```text
Actúa como Desarrollador Senior .NET 10 y MariaDB.
Estoy desarrollando el MÓDULO [XX] (del Equipo [XX]) de la Intranet Institucional del IESTP Argentina.

REGLAS DE ACERO ARQUITECTÓNICAS (Cero Conflictos):
1. Mi carpeta soberana es ÚNICAMENTE: src/02_Modulos/Intranet.Modulo[XX]/
2. Mi base de datos asignada es: db_modulo[XX] (Usuario: user_equipo[XX]).
3. Mis controladores C# deben heredar de `ModuloBaseController` (en `Intranet.Core.Controllers`) y usar la ruta `[Route("Modulo[XX]/[controller]")]`.
4. NO modifiques ni me pidas modificar archivos fuera de mi carpeta (está prohibido tocar src/01_Core/, src/03_Web/Program.cs o appsettings.json).
5. Si necesito inyectar servicios, hazlo dentro de mi archivo `Modulo[XX]Startup.cs` implementando `IModuloStartup`.
6. Para la base de datos en phpMyAdmin o en `Sql/schema.sql`, genera sentencias SQL con `CREATE TABLE IF NOT EXISTS`.
7. Si necesito publicar o escuchar eventos de otros módulos, uso `IEventBus` y `IEventHandler<T>` de `Intranet.Core.Events`.

Requerimiento de mi equipo para hoy:
[Describe aquí lo que necesitas, ej: Crear tabla de items y vista con formulario y listado]
```
