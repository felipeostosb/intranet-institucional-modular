# 🏛️ Manual de Instalación y Onboarding para Desarrolladores (IESTP "Argentina")

> 📌 **Objetivo:** Guía práctica paso a paso para que los **36 desarrolladores (9 equipos de 4)** preparen su entorno de trabajo en Windows o Linux, descarguen el repositorio y empiecen a programar su módulo en **menos de 5 minutos**.

---

## 🧭 ¿Qué camino elegir según tu computadora?

* ⭐ **RUTA A: Visual Studio Code (Recomendada / Ultraligera):** Si tu computadora tiene **4 GB a 8 GB de RAM** o es una laptop de estudio. Pesa menos de 400 MB en total y consume solo 250 MB de RAM.
* 💼 **RUTA B: Visual Studio 2026 / 2022 Community (Entorno Completo):** Si tienes una PC de escritorio o Gamer con **16 GB de RAM o más**.

---

# ⭐ RUTA A: Instalación Ligera con Visual Studio Code (Recomendada)

### 1️⃣ Paso 1: Descargar los 3 Programas Base (Solo una vez)
1. **Git para Windows:** 👉 [Descargar Git x64](https://git-scm.com/download/win) *(Instalar con opciones predeterminadas).*
2. **SDK de .NET 10 (Oficial de Microsoft):** 👉 [Descargar .NET 10 SDK x64](https://dotnet.microsoft.com/download/dotnet/10.0) *(Instalar el archivo `dotnet-sdk-10.0.xxx-win-x64.exe`).*
3. **Visual Studio Code:** 👉 [Descargar VS Code](https://code.visualstudio.com/)

### 2️⃣ Paso 2: Instalar la Extensión de C# en VS Code
1. Abre **VS Code**.
2. Ve al icono de extensiones a la izquierda *(o presiona `Ctrl + Shift + X`)*.
3. Busca e instala: **C# Dev Kit** *(o la extensión oficial **C#** de Microsoft `ms-dotnettools.csharp`)*.

### 3️⃣ Paso 3: Clonar y Abrir el Repositorio
1. Abre **PowerShell** en tu carpeta de proyectos y ejecuta:
   ```powershell
   git clone https://github.com/felipeostosb/intranet-institucional-modular.git
   cd intranet-institucional-modular
   code .
   ```

### 4️⃣ Paso 4: Lanzar el Asistente Interactivo
1. Dentro de VS Code, abre la terminal integrada con: `Ctrl + Ñ` *(o Menú $\rightarrow$ Terminal $\rightarrow$ Nueva Terminal)*.
2. Si es tu primera vez en PowerShell, ejecuta este permiso de ejecución:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
3. Ejecuta el asistente:
   ```powershell
   .\dev.ps1
   ```
4. Presiona la **Opción 1** (`1`) para abrir la Intranet en tu navegador con Hot-Reload en `http://localhost:5000`.

---

# 💼 RUTA B: Instalación Completa con Visual Studio 2026 / 2022

> ⚠️ **No uses Visual Studio 2019:** VS 2019 no tiene soporte para .NET 10 y bloqueará la carga de proyectos. Usa **Visual Studio 2022 (v17.12+) o Visual Studio 2026 Community**.

### 1️⃣ Paso 1: Instalar Visual Studio con la Carga de Trabajo Correcta
1. Descarga **Visual Studio Community** (Gratuito): 👉 [Descargar Visual Studio](https://visualstudio.microsoft.com/).
2. En el *Visual Studio Installer*, marca obligatoriamente la casilla:
   * ☑️ **Desarrollo web y de ASP.NET** *(ASP.NET and web development)*.
   * En la pestaña *"Componentes individuales"*, asegúrate de que esté marcado **SDK de .NET 10**.
3. Clic en **Instalar**.

### 2️⃣ Paso 2: Clonar y Abrir la Solución
1. Abre Visual Studio.
2. En la pantalla inicial, haz clic en **Clonar un repositorio**.
3. Pega la URL del repositorio:
   ```text
   https://github.com/felipeostosb/intranet-institucional-modular.git
   ```
4. Una vez clonado, abre el archivo de solución: `IntranetInstitucional.sln`.

### 3️⃣ Paso 3: Configurar Proyecto de Inicio y Ejecutar
1. En el panel derecho (*Explorador de soluciones*), busca la carpeta `03_Web` y haz **clic derecho en `Intranet.Web`** $\rightarrow$ **Establecer como proyecto de inicio**.
2. Presiona **F5** (o el botón verde de reproducción en la barra superior).
3. Se abrirá la Intranet en tu navegador en `http://localhost:5000`.

---

# 🔄 Flujo Diario de Trabajo (Las 4 Opciones del Asistente)

En PowerShell ejecuta `.\dev.ps1` (en Linux/Mac `./dev.sh`):

1. **`1` 🚀 Iniciar Intranet:** Compila y ejecuta el servidor local en `http://localhost:5000` con Hot-Reload.
2. **`2` 🌿 Crear / Cambiar Rama:** Eliges tu equipo (1 al 9) y tu tarea (ej: `modulo04/formulario-actas`).
3. **`3` ⚡ Generar Formulario / Tabla:** Scaffolding automático de Modelo, Controlador y Vista Razor estilo Apple en 1 segundo.
4. **`4` 📤 Subir mi Trabajo a GitHub:** Guarda cambios, sincroniza con `main` y te da el enlace directo para tu Pull Request.

---

# 🗄️ Base de Datos en la Nube (MariaDB 10.11 + phpMyAdmin)

* 🌐 **Panel Web phpMyAdmin:** [http://35.208.213.59:8080](http://35.208.213.59:8080)
* 👤 **Usuario:** `user_equipo[XX]` *(ej: user_equipo01 al user_equipo09)*
* 🔑 **Contraseña:** `Equipo[XX]_Pass2026!`
* 📊 **Base de datos propia:** `db_modulo[XX]` (Usa siempre `CREATE TABLE IF NOT EXISTS`).

---

# 🛡️ Poka-Yoke: Preguntas Frecuentes y Solución de Problemas

| Problema / Error | Causa | Solución Inmediata |
| :--- | :--- | :--- |
| **"La ejecución de scripts está deshabilitada en este sistema"** | Política restrictiva por defecto de Windows PowerShell | Ejecuta: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` y luego vuelve a correr `.\dev.ps1`. |
| **"git push rechazado: No puedes hacer push directo a main"** | Guardián Git Poka-Yoke bloqueando sobrescrituras | Usa la **Opción 2** de `.\dev.ps1` para cambiar a la rama de tu equipo antes de subir cambios. |
| **"No se reconoce el comando 'dotnet'"** | La terminal se abrió antes de terminar de instalar el SDK | Cierra y vuelve a abrir PowerShell o VS Code. |
| **"Los proyectos no cargan o dan error de SDK"** | Estás intentando usar Visual Studio 2019 | Usa **VS Code** o actualiza a **Visual Studio 2022 (v17.12+) / 2026**. |
