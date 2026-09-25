# 🦅 AQUILA A-ERP — Intranet Institucional Modular (.NET 10 LTS + PostgreSQL 16)

Bienvenido a **AQUILA A-ERP** (Intranet Institucional del **IESTP "Argentina"**). Este sistema está construido sobre **.NET 10 LTS (Soporte Oficial a Largo Plazo hasta Noviembre 2028)**, **PostgreSQL 16 LTS** y una **Arquitectura de Monolito Modular Desacoplado** diseñada para que **36 desarrolladores (10 equipos de trabajo: Módulo 00 al 09)** trabajen en paralelo con total autonomía y cero colisiones (*Zero-Blast-Radius*).

---

> 📖 **¿Primera vez configurando tu entorno?**  
> 1. Consulta el [**Manual Completo de Instalación y Onboarding (VS Code vs Visual Studio 2026)**](docs/GUIA_INSTALACION.md).  
> 2. O inicia la aplicación y entra directamente al **[Centro de Documentación & Manuales Interactivos](http://localhost:5000/Docs)** con guías de rol, videotutoriales HD y prompts para IA.

---

## ⚡ Guía de Inicio Rápido (The Golden Path - 1 Solo Clic)

Hemos creado un **CLI Interactivo** que automatiza todo el flujo de Git, nombres de ramas, validaciones locales y conexiones a la base de datos para que **no cometas ningún error de principiante**:

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

El asistente te ofrece **6 opciones indispensables de alta frecuencia**:

1. **🚀 Iniciar Intranet:** Lanza la aplicación local en `http://localhost:5000` con **Hot-Reload** (se actualiza sola en ~100ms al guardar cambios en cualquier archivo C# o Razor).
2. **🌿 Mi Rama de Equipo:** Te pide tu número de equipo (00 al 09) y crea automáticamente ramas estandarizadas como `modulo02/asistencia-semanas` sincronizadas con `main`.
3. **🔄 Sincronizar con 'main':** Descarga los últimos cambios que otros equipos hayan fusionado a producción (`main`), integrándolos en tu rama de forma segura y **sin borrar ni perder tu trabajo local**.
4. **🧪 Compilar y Validar:** Ejecuta `dotnet build` localmente para verificar que tu código compile con 0 errores antes de subirlo.
5. **📤 Subir a GitHub:** Guarda automáticamente tus cambios, descarga actualizaciones con `git pull --rebase`, valida la compilación y publica tu rama en GitHub con el enlace directo para abrir tu Pull Request.
6. **🗄️ Base de Datos PostgreSQL:** Muestra los datos de conexión de Adminer / Cloud DB y te permite configurar tu contraseña privada local en `appsettings.Local.json` a 1 clic.

> [!NOTE]
> **🛡️ Guardianes Git Poka-Yoke:** Al ejecutar el asistente, se instalan automáticamente *hooks* locales que bloquean cualquier intento de hacer `git push` o `git commit` accidental directo a `main`, y te protegen para que solo puedas modificar la carpeta de tu propio módulo (*Zero-Blast-Radius*).

---

## 👥 Distribución Soberana de los 10 Módulos y Esquemas PostgreSQL

El sistema opera sobre una **Base de Datos Unificada (`db_intranet_iestp`)** en **PostgreSQL 16 LTS** con aislamiento nativo por **`SCHEMAS` (Espacios de Nombres)** y gestión unificada de personas (**Patrón Party-Role**):

* **🌐 Esquema Central (`core`):** `core.personas`, `core.usuarios`, `core.roles`, `core.usuario_roles`, `core.carreras`, `core.periodos_academicos`, `core.aulas`, `core.unidades_didacticas`, `core.estudiantes`, `core.docentes`, `core.administrativos`, `core.auditoria_logs`.
* **📦 Esquemas Soberanos por Módulo (`mod00` .. `mod09`):**

| Equipo | Módulo Institucional Real | Carpeta Soberana | Esquema PostgreSQL | Usuario DB | Responsable BD / Líder |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **00** | **00. Seguridad Core & Auditoría** | `src/02_Modulos/Intranet.Modulo00/` | `mod00` | `user_equipo00` | 🛡️ DevOps / Core |
| **01** | **01. Matrícula Académica & Admisión** | `src/02_Modulos/Intranet.Modulo01/` | `mod01` | `user_equipo01` | 📝 Ismael |
| **02** | **02. Asistencia 18 Semanas & DPI** | `src/02_Modulos/Intranet.Modulo02/` | `mod02` | `user_equipo02` | 📅 Sheyla |
| **03** | **03. Inventario & Equipos** | `src/02_Modulos/Intranet.Modulo03/` | `mod03` | `user_equipo03` | 📦 Brenda |
| **04** | **04. Horarios, Aulas & Turnos** | `src/02_Modulos/Intranet.Modulo04/` | `mod04` | `user_equipo04` | ⏰ Equipo 04 (Morales) |
| **05** | **05. Incidencias & Requerimientos TI** | `src/02_Modulos/Intranet.Modulo05/` | `mod05` | `user_equipo05` | 🛠️ Oliva |
| **06** | **06. Egresados & Titulación** | `src/02_Modulos/Intranet.Modulo06/` | `mod06` | `user_equipo06` | 🎓 Sandra |
| **07** | **07. Encuestas & Calidad Docente** | `src/02_Modulos/Intranet.Modulo07/` | `mod07` | `user_equipo07` | 📊 Brayan |
| **08** | **08. Login, Seguridad & Roles** | `src/02_Modulos/Intranet.Modulo08/` | `mod08` | `user_equipo08` | 🔐 Toro |
| **09** | **09. Tesorería & Pagos TUPA** | `src/02_Modulos/Intranet.Modulo09/` | `mod09` | `user_equipo09` | 💳 Equipo 09 (Vargas) |

> [!TIP]
> **🛡️ Blindaje RBAC en PostgreSQL:** Cada usuario `user_equipoXX` tiene permisos de control total (`CREATE`, `INSERT`, `UPDATE`, `DELETE`, `DROP`) **únicamente en su esquema `modXX`**, y permisos de **SOLO LECTURA (`SELECT`)** sobre `core` y los demás esquemas. Si un equipo intenta modificar datos de otro, el motor PostgreSQL rechaza la operación automáticamente.

---

## 🤝 Sinergia de Roles & Ciclo de Vida de 4 Pasos

Para que los 10 equipos avancen sin fricción y con roles bien delimitados:

1. **👑 Product Owner (PO) + 🗄️ Especialista BD (DBA) [Día 1 - Definición]:**
   * El **PO** escribe las historias de usuario en formato `Como... Quiero... Para...` y criterios de aceptación Gherkin. *(Nota: El PO NO hace de QA)*.
   * El **DBA** modela las tablas dentro de su esquema `modXX`, enlaza Foreign Keys hacia `core.*` y guarda los scripts en `scripts/modXX/01_crear_tablas.sql`.
2. **🏃 Scrum Master (SM) + 💻 Desarrolladores [Día 2 - Construcción]:**
   * El **SM** asiste en la creación de la rama protegida `moduloXX/tarea` con `./dev.sh`.
   * Los **Desarrolladores** implementan el Controller en .NET 10 y la vista Razor Zen con DaisyUI y Tailwind CSS.
3. **🧪 Especialista QA (Tester) [Día 3 - Validación Técnica]:**
   * El **QA** prueba validaciones de formulario, casos borde, persistencia en PostgreSQL (vía Adminer) y compatibilidad con **Modo Claro / Modo Oscuro**.
4. **👑 Product Owner (UAT) + 🏃 Scrum Master [Día 4 - Entrega]:**
   * El **PO** realiza la Aceptación Final de Usuario (UAT).
   * El **SM** verifica que `dotnet build` compile con **0 Warnings y 0 Errors**, abre el Pull Request hacia `main` y el equipo graba un video demo de 2 minutos para `/Docs`.

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
* **Conexión:** Inyecta `IModuleDbConnectionFactory` para obtener la conexión SQL hacia PostgreSQL (`factory.CreateConnection("04")`).
* **Search Path Automático:** Tu conexión viene preconfigurada con `search_path=modXX,core,public`, lo que te permite consultar tus tablas directamente como `SELECT * FROM horarios` o `SELECT * FROM core.personas`.
* **Migraciones SQL:** Guarda tus scripts versionados en `scripts/modXX/01_crear_tablas.sql`, `02_crear_indices.sql` y `03_datos_prueba.sql`.
* **Relaciones Foráneas Seguras:** Puedes hacer `FOREIGN KEY` directa a `core.personas(id)`, `core.estudiantes(id)`, `core.docentes(id)`, `core.carreras(id)` o `core.periodos_academicos(id)`.

### 3. ⚙️ Inyección de Dependencias Modular (`IModuloStartup`)
Cada módulo registra sus propios servicios en su archivo `ModuloXXStartup.cs` implementando `IModuloStartup`. El sistema los descubre y registra automáticamente al arrancar.

### 4. 🎭 Selector de Roles en Caliente (Party Model)
Para personas con múltiples roles simultáneos (ej: Docente y Alumno, o Director y Docente), el Topbar incluye un selector inteligente (`[ 👨‍🏫 Modo Docente ▾ ]`) que permite alternar de sombrero en 1 clic sin cerrar sesión, adaptando el Dashboard dinámicamente.

---

## 🛡️ Reglas de Oro del Proyecto (Poka-Yoke)

1. **Aislamiento Estricto:** Programa **únicamente** dentro de tu carpeta `src/02_Modulos/Intranet.ModuloXX/`.
2. **Esquemas PostgreSQL:** Toda tabla que crees debe pertenecer a tu esquema `modXX` (ej: `CREATE TABLE IF NOT EXISTS mod04.horarios (...)`).
3. **Prohibido Push directo a `main`:** Todo cambio se entrega mediante **Pull Request** desde tu rama `moduloXX/tu-tarea`.
4. **Controladores con Seguridad:** Haz que tus controladores hereden de `ModuloBaseController` para tener acceso a `UsuarioActualRol`, `UsuarioActualRoles`, `UsuarioActualNombre`, `PersonaActualId` y métodos Toast (`MostrarAlertaExito`, `MostrarAlertaError`).
5. **Validación Automática en CI/CD:** Si tu PR modifica solo tu módulo y compila con 0 errores, **GitHub Actions lo fusiona a producción en ~45 segundos**.
6. **Cero JOINs entre Módulos:** Prohibido hacer `JOIN` SQL cruzado entre esquemas `mod01`..`mod09`. Para cruzar datos, haz `JOIN` con `core.*` o solicita al DBA del módulo vecino que cree una **Vista (`VIEW`)** pública de solo lectura.

---

## 🌐 Enlaces de Producción & Base de Datos

* 🚀 **Intranet en Vivo (.NET 10 en Docker):** [http://35.209.228.150](http://35.209.228.150)
* 📚 **Centro de Documentación & Manuales:** [http://localhost:5000/Docs](http://localhost:5000/Docs)
* 🗄️ **Adminer BD PostgreSQL 16 (GUI Web Ligera):** [http://35.206.81.32:8080](http://35.206.81.32:8080)
  * **Sistema:** `PostgreSQL`
  * **Servidor:** `postgres` *(o `35.206.81.32` desde tu cliente local)*
  * **Base de Datos:** `db_intranet_iestp`
  * **Usuario:** `user_equipo[XX]` *(ej: `user_equipo01` al `user_equipo09`)*
  * **Contraseña:** *(Consulta la Ficha de Acceso Privada entregada por el Administrador)*
  * **Esquema:** Selecciona `mod[XX]` en el menú superior para ver tus tablas.

---

## 🤖 Prompts Maestros para Asistentes de IA (ChatGPT / Claude / DeepSeek / Cursor)

Para garantizar que la IA respete la arquitectura y no invente esquemas monolíticos ni rompa dependencias, consulta los **Prompts Maestros** con botón de copia en 1 clic disponibles en el portal: **[http://localhost:5000/Docs#prompts-ia](http://localhost:5000/Docs#prompts-ia)**.

### Plantilla Rápida para Desarrolladores .NET:
```text
Actúa como Desarrollador Senior .NET 10 y PostgreSQL 16.
Estoy desarrollando el MÓDULO [XX] (del Equipo [XX]) de la Intranet Institucional del IESTP Argentina.

REGLAS DE ACERO ARQUITECTÓNICAS (Zero-Blast-Radius):
1. Mi carpeta soberana es ÚNICAMENTE: src/02_Modulos/Intranet.Modulo[XX]/
2. La base de datos es PostgreSQL 16: db_intranet_iestp (Usuario: user_equipo[XX]).
3. Mi esquema exclusivo de base de datos es: mod[XX]
4. Todas las tablas de mi módulo DEBEN crearse dentro de mi esquema: `mod[XX].mi_tabla` (ej: CREATE TABLE IF NOT EXISTS mod[XX].matriculas (id SERIAL PRIMARY KEY, ...)).
5. Mis controladores C# deben heredar de `ModuloBaseController` (en `Intranet.Core.Controllers`) y usar la ruta `[Route("Modulo[XX]/[controller]")]`.
6. Puedo hacer FOREIGN KEY y SELECT a tablas del esquema core como: core.personas(id), core.estudiantes(id), core.docentes(id), core.carreras(id), core.semestres(id).
7. Tengo prohibido modificar archivos fuera de mi carpeta (no tocar src/01_Core/, src/03_Web/ o appsettings.json).
8. Si necesito inyectar servicios, hazlo dentro de mi archivo `Modulo[XX]Startup.cs` implementando `IModuloStartup`.
9. Para acceso a datos rápido usa Dapper o Npgsql con `IModuleDbConnectionFactory`.
10. La interfaz visual debe seguir el estándar Zen Minimalista con Tailwind CSS y DaisyUI, con soporte para Modo Oscuro nativo (dark:bg-[#111827]).

Requerimiento de mi equipo para hoy:
[Describe aquí lo que necesitas, ej: Crear tabla de items y vista con formulario y listado]
```

> Sincronizado 2026-09-25 (2): despliegue pendiente de módulos 01 y 09.
