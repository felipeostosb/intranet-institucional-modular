# 🏛️ Intranet Institucional Modular (.NET 8 + Tailwind CSS + MariaDB)

Bienvenido al proyecto integrador de la Intranet Institucional. Este sistema está construido con una **Arquitectura Modular Desacoplada** diseñada para que **36 desarrolladores (9 equipos de 4 personas)** trabajen en paralelo con total autonomía y cero colisiones.

---

## 🚀 Guía de Inicio Rápido para Desarrolladores

### 💜 Si usas Visual Studio (el morado en Windows):
1. Clona el repositorio: `git clone https://github.com/felipeostosb/intranet-institucional-modular.git`
2. Haz doble clic en el archivo **`IntranetInstitucional.sln`**.
3. Presiona **`F5`** (o clic en el botón verde de reproducir).
4. ¡Listo! Tu navegador abrirá automáticamente la Intranet en `http://localhost:5000`.

### 💙 Si usas Visual Studio Code (en Windows, Mac o Linux):
1. Clona el repositorio y abre la carpeta del proyecto en VS Code.
2. Abre la terminal integrada (`Ctrl + \``) y ejecuta:
   ```bash
   dotnet watch run --project src/03_Web/Intranet.Web
   ```
3. Cada vez que modifiques código y guardes (`Ctrl + S`), la web se actualizará sola en **100 milisegundos (Hot Reload)**.

---

## 👥 Asignación de Carpetas por Equipo (9 Módulos):
Cada equipo tiene su propia carpeta soberana dentro de `src/02_Modulos/`:
* **Equipo 1:** `src/02_Modulos/Intranet.Modulo01/` (Ruta Web: `/Modulo01`)
* **Equipo 2:** `src/02_Modulos/Intranet.Modulo02/` (Ruta Web: `/Modulo02`)
* **Equipo 3:** `src/02_Modulos/Intranet.Modulo03/` (Ruta Web: `/Modulo03`)
* **Equipo 4:** `src/02_Modulos/Intranet.Modulo04/` (Ruta Web: `/Modulo04`)
* **Equipo 5:** `src/02_Modulos/Intranet.Modulo05/` (Ruta Web: `/Modulo05`)
* **Equipo 6:** `src/02_Modulos/Intranet.Modulo06/` (Ruta Web: `/Modulo06`)
* **Equipo 7:** `src/02_Modulos/Intranet.Modulo07/` (Ruta Web: `/Modulo07`)
* **Equipo 8:** `src/02_Modulos/Intranet.Modulo08/` (Ruta Web: `/Modulo08`)
* **Equipo 9:** `src/02_Modulos/Intranet.Modulo09/` (Ruta Web: `/Modulo09`)

---

## 🎨 Estilos y Diseño (Tailwind CSS + DaisyUI)
La Intranet ya viene con **Tailwind CSS y DaisyUI** preconfigurados en el Layout maestro:
* Botones modernos: `<button class="btn btn-primary">Guardar</button>`
* Tarjetas: `<div class="card bg-base-100 shadow-xl p-6">...</div>`
* Tablas: `<table class="table table-zebra w-full">...</table>`
* Modales: `<dialog class="modal">...</dialog>`
