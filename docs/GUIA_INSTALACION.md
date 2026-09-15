# 🏛️ Manual Oficial de Onboarding y Experiencia de Desarrollador (DX)
## Intranet Institucional Modular (.NET 10 LTS + PostgreSQL 16) — IESTP "Argentina"

> 📌 **Propósito:** Guía completa paso a paso para que los **36 desarrolladores (9 equipos de 4 integrantes)** configuren su entorno en **Visual Studio Code**, **Visual Studio 2022/2026**, **Máquinas Virtuales** o **Codespaces**, y comiencen a desarrollar su módulo con **cero fricción y cero errores**.

---

## 🧭 1. Elige tu Entorno de Desarrollo

```
+--------------------------------------------------------------------------------------------------+
| ¿QUÉ COMPUTADORA O ENTORNO UTILIZAS?                                                             |
+--------------------------------------------------------------------------------------------------+
| 💻 RUTA A: VS Code (Ultraligero)        -> Para Laptops / PCs de 4 GB a 8 GB RAM (Recomendado)   |
| 💼 RUTA B: Visual Studio 2022 / 2026    -> Para PCs de escritorio / Gaming (16 GB+ RAM)          |
| ☁️ RUTA C: Máquinas Virtuales / Linux   -> Para VirtualBox, VMware, WSL2 o GitHub Codespaces     |
+--------------------------------------------------------------------------------------------------+
```

---

# ⭐ RUTA A: Visual Studio Code (Recomendado / Máxima Agilidad)

Ideal para cualquier sistema operativo (**Windows, Linux, macOS**). Consume menos de **250 MB de RAM**.

### 1️⃣ Paso 1: Instalar los Prerrequisitos Base (Solo 1 vez)
1. **Git:** 👉 [Descargar Git](https://git-scm.com/download/win) *(Instalar con opciones predeterminadas).*
2. **SDK Oficial de .NET 10:** 👉 [Descargar .NET 10 SDK x64](https://dotnet.microsoft.com/download/dotnet/10.0) *(Instalar el archivo ejecutable).*
3. **Visual Studio Code:** 👉 [Descargar VS Code](https://code.visualstudio.com/)

### 2️⃣ Paso 2: Extensiones Esenciales en VS Code
Abre VS Code, ve a Extensiones (`Ctrl + Shift + X`) e instala:
* **C# Dev Kit** (`ms-dotnettools.csdevkit`) o **C#** (`ms-dotnettools.csharp`).
* *(Opcional)* **Database Client** o **PostgreSQL** para consultar la base de datos dentro de VS Code.

### 3️⃣ Paso 3: Clonar el Proyecto y Abrir
Abre tu terminal (**PowerShell** o **Bash**) y ejecuta:
```bash
git clone https://github.com/felipeostosb/intranet-institucional-modular.git
cd intranet-institucional-modular
code .
```

### 4️⃣ Paso 4: Depuración y Ejecución con 1 Tecla (F5) o CLI
* **Opción F5:** Presiona **F5** dentro de VS Code para compilar y abrir la app con el depurador conectado.
* **Opción CLI Asistente:** Abre la terminal integrada (`Ctrl + Ñ`) y ejecuta:
  * En Windows: `.\dev.ps1`
  * En Linux/Mac: `./dev.sh`
  * Presiona `1` para lanzar la app con **Hot-Reload en vivo** en `http://localhost:5000`.

---

# 💼 RUTA B: Visual Studio 2022 / 2026 Community (Windows)

> ⚠️ **Importante:** Visual Studio 2019 **NO** es compatible con .NET 10. Debes usar **Visual Studio 2022 (v17.12 o superior)** o **Visual Studio 2026**.

### 1️⃣ Paso 1: Cargas de Trabajo en Visual Studio Installer
1. Abre el instalador de Visual Studio.
2. Asegúrate de marcar la casilla:
   * ☑️ **Desarrollo web y de ASP.NET** *(ASP.NET and web development)*.
   * En *"Componentes individuales"*, verifica que esté instalado **SDK de .NET 10**.

### 2️⃣ Paso 2: Abrir la Solución
1. Abre Visual Studio $\rightarrow$ **Clonar un repositorio**:
   ```text
   https://github.com/felipeostosb/intranet-institucional-modular.git
   ```
2. Abre el archivo de solución [`IntranetInstitucional.sln`](file:///home/prozac/dev/intranet-institucional-modular/IntranetInstitucional.sln).

### 3️⃣ Paso 3: Configurar Proyecto de Inicio y Ejecutar
1. En el *Explorador de Soluciones*, despliega `03_Web`.
2. Haz **clic derecho en `Intranet.Web`** $\rightarrow$ **Establecer como proyecto de inicio**.
3. Presiona **F5** (o el botón verde de Play). El navegador abrirá automáticamente `http://localhost:5000`.

---

# ☁️ RUTA C: Máquinas Virtuales (VirtualBox / VMware / WSL2 / Codespaces)

Si desarrollas dentro de una máquina virtual ligera (Debian, Ubuntu, Linux Mint o Windows VM):

### 1️⃣ En Linux / WSL2:
```bash
# Instalar SDK .NET 10
sudo apt update && sudo apt install -y dotnet-sdk-10.0 git

# Clonar y entrar al proyecto
git clone https://github.com/felipeostosb/intranet-institucional-modular.git
cd intranet-institucional-modular

# Dar permisos al asistente e iniciar
chmod +x dev.sh
./dev.sh
```

### 2️⃣ En GitHub Codespaces (Desarrollo 100% en la Nube):
1. Entra al repositorio en GitHub: `https://github.com/felipeostosb/intranet-institucional-modular`.
2. Haz clic en el botón verde **Code** $\rightarrow$ Pestaña **Codespaces** $\rightarrow$ **Create codespace on main**.
3. Tendrás un VS Code completo en tu navegador con .NET 10 preconfigurado.
4. En la terminal escribe `./dev.sh` y presiona `1`.

---

## 🖥️ 2. Guía Maestra del Asistente Interactivo (`dev.sh` / `dev.ps1`)

El asistente interactivo automatiza el 100% de las operaciones para evitar errores de Git y base de datos:

| Opción | Nombre | ¿Qué hace por ti? |
| :---: | :--- | :--- |
| **`1`** | **🚀 Iniciar Intranet** | Compila y levanta `http://localhost:5000` con **Hot-Reload** (~100ms). |
| **`2`** | **🌿 Crear / Cambiar a mi Rama** | Te pide tu número de equipo (01 al 09) y crea la rama `moduloXX/nombre-tarea` sincronizada con `main`. |
| **`3`** | **⚡ Generar Formulario / Tabla** | Genera en 1 segundo: Modelo C#, Controlador con `ModuloBaseController`, Vista Razor moderna con DaisyUI y script SQL en PostgreSQL 16. |
| **`4`** | **🧪 Compilar y Validar mi Módulo** | Ejecuta `dotnet build` localmente para garantizar **0 errores y 0 warnings**. |
| **`5`** | **📤 Subir mi Trabajo a GitHub** | Guarda cambios, previene conflictos con `git pull --rebase` y genera el enlace directo de Pull Request. |
| **`6`** | **🗄️ Credenciales PostgreSQL 16** | Muestra los accesos a la base de datos `db_intranet_iestp` y el panel Adminer. |

---

## 🗄️ 3. Acceso a la Base de Datos PostgreSQL 16

La base de datos unificada se encuentra alojada en el servidor cloud `postgres` y cuenta con un panel web Adminer para administración visual:

* 🌐 **Panel Web Adminer (GUI Ligera):** [http://35.206.81.32:8080](http://35.206.81.32:8080)
* ⚙️ **Sistema:** `PostgreSQL`
* 🖥️ **Servidor:** `postgres` *(desde el navegador en Adminer)* o `35.206.81.32:5432` *(desde DBeaver/VS Code)*
* 📊 **Base de datos:** `db_intranet_iestp`
* 👤 **Usuario de tu equipo:** `user_equipo[XX]` *(ej: `user_equipo01` al `user_equipo09`)*
* 🔑 **Contraseña:** *(Solicitar credencial criptográfica única y privada al Administrador / Líder de Arquitectura)*
* 🛡️ **Esquema Soberano:** `mod[XX]`

### 💡 Ejemplo de Script SQL para tu Módulo:
Guarda tus scripts en `src/02_Modulos/Intranet.ModuloXX/Sql/schema.sql`. Se ejecutarán automáticamente al iniciar la app:

```sql
-- Creación de tabla para tu módulo
CREATE TABLE IF NOT EXISTS mod04.aulas (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    pabellon VARCHAR(50) NOT NULL,
    capacidad INT NOT NULL DEFAULT 30,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Inserción de datos iniciales (Seed)
INSERT INTO mod04.aulas (codigo, pabellon, capacidad)
VALUES ('LAB-301', 'Pabellón A', 35)
ON CONFLICT (codigo) DO NOTHING;
```

---

## 🛡️ 4. Preguntas Frecuentes y Solución de Problemas (Poka-Yoke)

| Error / Síntoma | Causa | Solución Rápida |
| :--- | :--- | :--- |
| **"La ejecución de scripts está deshabilitada en este sistema"** | Política por defecto de PowerShell en Windows | Ejecuta una sola vez: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` y vuelve a correr `.\dev.ps1`. |
| **"git push rechazado: No puedes hacer push directo a main"** | Guardián Git protegiendo la rama principal | Usa la **Opción 2** de `dev.ps1`/`dev.sh` para crear tu rama `moduloXX/tu-tarea` y luego la **Opción 5** para subir. |
| **"No se reconoce el comando 'dotnet'"** | La terminal se abrió antes de instalar el SDK | Cierra y vuelve a abrir VS Code o tu terminal. |
| **"permission denied for table ..." en PostgreSQL** | Intentaste modificar una tabla fuera de tu esquema `modXX` | Recuerda que solo puedes crear/editar tablas en `modXX.tabla`. Las tablas de `core` son de solo lectura (`SELECT`). |
