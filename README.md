# 🏛️ Intranet Institucional Modular (.NET 10 LTS + Apple Minimalist + MariaDB)

Bienvenido al proyecto integrador de la Intranet Institucional del **IESTP "Argentina"**. Este sistema está construido sobre **.NET 10 LTS (Soporte Oficial a Largo Plazo hasta Noviembre 2028)** y una **Arquitectura Modular Desacoplada** diseñada para que **36 desarrolladores (9 equipos de 4 personas)** trabajen en paralelo con total autonomía y cero colisiones (*Zero-Blast-Radius*).

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

## 🖥️ ¿Qué hace el Asistente `./dev.sh` por ti?

1. **🚀 Iniciar Intranet Local:** Lanza la aplicación en `http://localhost:5000` con **Hot-Reload** (se actualiza sola en 100ms al guardar cambios).
2. **🌿 Crear Rama Estandarizada:** Te pide tu número de equipo y crea automáticamente ramas seguras como `modulo04/formulario-actas`.
3. **⚡ Generar Plantilla CRUD Apple:** En 1 segundo genera un Modelo C#, un Controlador y una Vista Razor con diseño Apple 100% responsivo y funcional.
4. **🔍 Validar mi Código (Local Check):** Audita que no hayas tocado archivos fuera de tu módulo y compila la solución completa.
5. **📤 Subir Cambios Seguros:** Realiza commit y push directamente a tu rama para abrir tu Pull Request.
6. **🔧 Instalar Guardián Git (Poka-Yoke):** Bloquea que cualquier persona haga push por error a `main`.

---

## 👥 Asignación de Módulos y Bases de Datos (9 Equipos):

| Equipo | Módulo | Carpeta Soberana | Base de Datos MariaDB | Color Distintivo |
| :---: | :--- | :--- | :--- | :--- |
| **01** | **Admisión & Postulantes** | `src/02_Modulos/Intranet.Modulo01/` | `db_modulo01` | 🩵 Sky Pastel |
| **02** | **Matrícula & Registros Académicos** | `src/02_Modulos/Intranet.Modulo02/` | `db_modulo02` | 💙 Indigo Pastel |
| **03** | **Gestión Docente & Carga Horaria** | `src/02_Modulos/Intranet.Modulo03/` | `db_modulo03` | 💚 Emerald Pastel |
| **04** | **Calificaciones & Actas Oficiales** | `src/02_Modulos/Intranet.Modulo04/` | `db_modulo04` | 💛 Amber Pastel |
| **05** | **Tesorería & Control de Pagos** | `src/02_Modulos/Intranet.Modulo05/` | `db_modulo05` | 💜 Purple Pastel |
| **06** | **Mesa de Partes Virtual & FUT** | `src/02_Modulos/Intranet.Modulo06/` | `db_modulo06` | 🩷 Rose Pastel |
| **07** | **Biblioteca Virtual & Recursos** | `src/02_Modulos/Intranet.Modulo07/` | `db_modulo07` | 🩵 Teal Pastel |
| **08** | **Bolsa de Trabajo & Prácticas (EFSRT)** | `src/02_Modulos/Intranet.Modulo08/` | `db_modulo08` | 🧡 Orange Pastel |
| **09** | **Mesa de Ayuda TI & Soporte** | `src/02_Modulos/Intranet.Modulo09/` | `db_modulo09` | 🌐 Cyan Pastel |

---

## 🛡️ Reglas de Oro del Proyecto (Poka-Yoke)

1. **Aislamiento Estricto:** Programa **únicamente** dentro de tu carpeta `src/02_Modulos/Intranet.ModuloXX/`.
2. **Prohibido Push a `main`:** Todo cambio se entrega mediante **Pull Request** desde tu rama `moduloXX/tu-tarea`.
3. **Controladores con Seguridad:** Haz que tus controladores hereden de `ModuloBaseController` para tener acceso a `UsuarioActualRol`, `UsuarioActualNombre`, etc.
4. **Validación Automática:** Si tu PR modifica solo tu módulo y compila con 0 errores, **GitHub Actions lo fusiona a producción en 45 segundos**.

---

## 🌐 Enlaces de Producción

* 🚀 **Intranet en Vivo:** [http://35.209.228.150](http://35.209.228.150)
* 🗄️ **phpMyAdmin BD:** [http://35.208.213.59:8080](http://35.208.213.59:8080)
