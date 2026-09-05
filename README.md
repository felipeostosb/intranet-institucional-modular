# 🏛️ Intranet Institucional Modular (.NET 10 LTS + Tailwind CSS + MariaDB)

Bienvenido al proyecto integrador de la Intranet Institucional. Este sistema está construido sobre **.NET 10 LTS (Soporte Oficial a Largo Plazo hasta Noviembre 2028)** y una **Arquitectura Modular Desacoplada** diseñada para que **36 desarrolladores (9 equipos de 4 personas)** trabajen en paralelo con total autonomía y cero colisiones (*Zero-Blast-Radius*).

---

## 📋 Requisitos Previos (Instalación en 1 Clic)
Antes de comenzar, asegúrate de tener instalado el SDK oficial de **.NET 10**:
* 👉 **[Descargar .NET 10 SDK Oficial de Microsoft](https://dotnet.microsoft.com/download/dotnet/10.0)** (Disponible para Windows, Mac y Linux).

---

## 🚀 Guía de Inicio Rápido para Desarrolladores

### 💜 Si usas Visual Studio 2022 (el morado en Windows):
1. Clona el repositorio:
   ```bash
   git clone https://github.com/felipeostosb/intranet-institucional-modular.git
   ```
2. Haz doble clic en el archivo **`IntranetInstitucional.sln`**.
3. Presiona **`F5`** (o clic en el botón verde de reproducir ▶).
4. ¡Listo! Tu navegador abrirá automáticamente la Intranet en `http://localhost:5000`.

### 💙 Si usas Visual Studio Code (en Windows, Mac o Linux):
1. Clona el repositorio y abre la carpeta del proyecto en VS Code.
2. Abre la terminal integrada (`Ctrl + \``) y ejecuta:
   ```bash
   dotnet watch run --project src/03_Web/Intranet.Web
   ```
3. Cada vez que modifiques código en tu módulo y guardes (`Ctrl + S`), la web se actualizará sola en **100 milisegundos (Hot Reload)** sin reiniciar el servidor.

---

## 👥 Asignación de Carpetas y Bases de Datos por Equipo (9 Módulos):
Cada equipo tiene su propia carpeta soberana dentro de `src/02_Modulos/` y su base de datos aislada:

| Equipo | Carpeta del Proyecto | Ruta en Navegador | Base de Datos MariaDB | Cadena de Conexión en `appsettings.json` |
| :--- | :--- | :--- | :--- | :--- |
| **Equipo 01** | `src/02_Modulos/Intranet.Modulo01/` | `/Modulo01` | `db_modulo01` | `Modulo01Connection` |
| **Equipo 02** | `src/02_Modulos/Intranet.Modulo02/` | `/Modulo02` | `db_modulo02` | `Modulo02Connection` |
| **Equipo 03** | `src/02_Modulos/Intranet.Modulo03/` | `/Modulo03` | `db_modulo03` | `Modulo03Connection` |
| **Equipo 04** | `src/02_Modulos/Intranet.Modulo04/` | `/Modulo04` | `db_modulo04` | `Modulo04Connection` |
| **Equipo 05** | `src/02_Modulos/Intranet.Modulo05/` | `/Modulo05` | `db_modulo05` | `Modulo05Connection` |
| **Equipo 06** | `src/02_Modulos/Intranet.Modulo06/` | `/Modulo06` | `db_modulo06` | `Modulo06Connection` |
| **Equipo 07** | `src/02_Modulos/Intranet.Modulo07/` | `/Modulo07` | `db_modulo07` | `Modulo07Connection` |
| **Equipo 08** | `src/02_Modulos/Intranet.Modulo08/` | `/Modulo08` | `db_modulo08` | `Modulo08Connection` |
| **Equipo 09** | `src/02_Modulos/Intranet.Modulo09/` | `/Modulo09` | `db_modulo09` | `Modulo09Connection` |

> 🛡️ **Seguridad Zero-Blast-Radius:** Tu usuario de base de datos solo tiene permisos sobre la base de datos de tu equipo y acceso de solo lectura (`SELECT`) a la tabla maestra `db_core.core_usuarios`. Ningún equipo puede alterar o borrar datos de otro equipo.

---

## 🌿 Flujo de Trabajo en Git (Pull Requests)
1. Crea tu rama de trabajo:
   ```bash
   git checkout -b feature/modulo-01-nombre-tarea
   ```
2. Realiza tus cambios dentro de la carpeta de tu módulo (`src/02_Modulos/Intranet.ModuloXX/`).
3. Sube tu rama y abre un Pull Request en GitHub:
   ```bash
   git push origin feature/modulo-01-nombre-tarea
   ```

---

## 🎨 Estilos y Diseño (Tailwind CSS + DaisyUI)
La Intranet ya viene con **Tailwind CSS y DaisyUI** preconfigurados en el Layout maestro:
* **Botones modernos:** `<button class="btn btn-primary">Guardar</button>`
* **Tarjetas:** `<div class="card bg-base-100 shadow-xl p-6">...</div>`
* **Tablas:** `<table class="table table-zebra w-full">...</table>`
* **Modales:** `<dialog class="modal">...</dialog>`
* **Badges:** `<span class="badge badge-accent">Nuevo</span>`
