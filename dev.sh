#!/usr/bin/env bash
# ==============================================================================
# 🏛️ IESTP ARGENTINA - ASISTENTE DE DESARROLLO (CLI RESILIENTE Y SENCILLO)
# ==============================================================================

set -e

BLUE='\033[1;34m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# 1. Instalar guardián local contra push directo a 'main'
if [ -d .git ]; then
    mkdir -p .git/hooks
    cat << 'HOOK_EOF' > .git/hooks/pre-push
#!/usr/bin/env bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer push directo a 'main'. Usa una rama de equipo (moduloXX/tarea).\033[0m"
    exit 1
fi
exit 0
HOOK_EOF
    chmod +x .git/hooks/pre-push

    # 2. Instalar guardián local de aislamiento modular (Pre-Commit Hook)
    cat << 'COMMIT_HOOK_EOF' > .git/hooks/pre-commit
#!/usr/bin/env bash
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Si está en main, bloquear commit directo
if [ "$BRANCH" = "main" ]; then
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer commit directo en 'main'. Usa la opción 2 de dev.sh para crear tu rama.\033[0m"
    exit 1
fi

# Detectar si la rama corresponde a un módulo (ej: modulo02/avance o modulo-02-asistencia)
MOD_NUM=$(echo "$BRANCH" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | tr '[:upper:]' '[:lower:]' | grep -o -E '[0-9]{2}' || true)

if [ -n "$MOD_NUM" ]; then
    ALLOWED_DIR="src/02_Modulos/Intranet.Modulo${MOD_NUM}/"
    STAGED_FILES=$(git diff --cached --name-only)
    
    VIOLATIONS=0
    for file in $STAGED_FILES; do
        # Permitir archivos de su propio módulo, documentación general o scripts locales
        if [[ "$file" != "$ALLOWED_DIR"* ]] && [[ "$file" != "docs/"* ]] && [[ "$file" != *.md ]]; then
            echo -e "\033[1;31m❌ VIOLACIÓN DE LÍMITES MODULARES (Zero-Blast-Radius):\033[0m"
            echo -e "   El archivo '\033[1;33m$file\033[0m' está fuera de tu módulo asignado '\033[1;32m$ALLOWED_DIR\033[0m'."
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    done
    
    if [ $VIOLATIONS -gt 0 ]; then
        echo -e "\033[1;31m======================================================================\033[0m"
        echo -e "\033[1;31m⛔ COMMIT BLOQUEADO: Solo puedes modificar archivos en $ALLOWED_DIR\033[0m"
        echo -e "\033[1;36m💡 Para desmarcar los cambios ajenos ejecuta:\033[0m"
        echo -e "   git reset HEAD <archivo-ajeno>"
        echo -e "   git checkout -- <archivo-ajeno>"
        echo -e "\033[1;31m======================================================================\033[0m"
        exit 1
    fi
fi
exit 0
COMMIT_HOOK_EOF
    chmod +x .git/hooks/pre-commit
fi

show_menu() {
    clear
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "desconocida")
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🏛️  INTRANET INSTITUCIONAL IESTP ARGENTINA — ASISTENTE DEV${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "  ${CYAN}Plataforma .NET 10 LTS • PostgreSQL 16 • 9 Módulos Desacoplados${NC}"
    echo -e "  🌿 Rama actual: ${YELLOW}${CURRENT_BRANCH}${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}\n"
    echo -e "  ${GREEN}1)${NC} 🚀 ${CYAN}Iniciar Intranet${NC} (Ver cambios en vivo en tu navegador con Hot-Reload)"
    echo -e "  ${GREEN}2)${NC} 🌿 ${CYAN}Crear / Cambiar a mi Rama de Equipo${NC} (Elige tu equipo 01 al 09)"
    echo -e "  ${GREEN}3)${NC} ⚡ ${CYAN}Generar Formulario / Tabla${NC} (Modelo, Controlador, Vista y SQL Postgres)"
    echo -e "  ${GREEN}4)${NC} 🧪 ${CYAN}Compilar y Validar mi Módulo${NC} (Verifica 0 errores localmente)"
    echo -e "  ${GREEN}5)${NC} 📤 ${CYAN}Subir mi Trabajo a GitHub${NC} (Guarda, sincroniza y genera enlace de PR)"
    echo -e "  ${GREEN}6)${NC} ⚙️  ${CYAN}Configurar Base de Datos de mi Equipo${NC} (Permisos de Escritura PostgreSQL)"
    echo -e "  ${GREEN}7)${NC} 🗄️  ${CYAN}Credenciales y Guía PostgreSQL 16${NC} (Ver accesos de Adminer / DB)"
    echo -e "  ${GREEN}8)${NC} 🤖 ${CYAN}Preguntar al Asistente IA de Arquitectura${NC} (RAG Gemini + Qdrant)"
    echo -e "  ${GREEN}0)${NC} 🚪 ${YELLOW}Salir${NC}\n"
}

start_app() {
    echo -e "\n${BLUE}🚀 Iniciando la Intranet en tu navegador (http://localhost:5000)...${NC}\n"
    
    # Intentar con dotnet watch (Hot-Reload), y si falla por inotify en Linux, fallback a dotnet run
    if ! dotnet watch --project src/03_Web/Intranet.Web --urls http://localhost:5000 2>/tmp/watch_err.log; then
        if grep -q "inotify" /tmp/watch_err.log 2>/dev/null; then
            echo -e "\n${YELLOW}⚠️  Límite de inotify de Linux alcanzado. Iniciando en modo estándar con 'dotnet run'...${NC}"
            echo -e "${CYAN}💡 Tip para activar Hot-Reload permanente:${NC}"
            echo -e "   Ejecuta: ${GREEN}sudo sysctl -w fs.inotify.max_user_instances=1024${NC}\n"
        fi
        dotnet run --project src/03_Web/Intranet.Web --urls http://localhost:5000
    fi
}

create_branch() {
    echo -e "\n${BLUE}🌿 CONFIGURAR RAMA DE TRABAJO${NC}"
    read -p "👉 ¿Qué número de equipo eres? (1 al 9): " num
    num=$(printf "%02d" $((10#$num)))
    
    if [ "$num" -lt 1 ] || [ "$num" -gt 9 ]; then
        echo -e "${RED}❌ Número no válido. Debe ser entre 1 y 9.${NC}"
        return
    fi
    
    read -p "👉 ¿Qué tarea vas a hacer? (ej: formulario-registro): " tarea
    if [ -z "$tarea" ]; then
        tarea="avance"
    fi
    tarea=$(echo "$tarea" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    
    branch="modulo${num}/${tarea}"
    
    # Verificar si la rama ya existe localmente
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        echo -e "\n${CYAN}Cambiando a tu rama existente: ${branch}...${NC}"
        git checkout "$branch"
    else
        echo -e "\n${CYAN}Sincronizando con 'main' antes de crear la rama...${NC}"
        git checkout main >/dev/null 2>&1 || true
        git pull origin main >/dev/null 2>&1 || true
        git checkout -b "$branch"
        echo -e "\n${GREEN}✅ ¡Rama creada con éxito: ${CYAN}${branch}${NC}!"
    fi
    
    echo -e "${YELLOW}🔒 Guardián Activado: Solo puedes modificar archivos en 'src/02_Modulos/Intranet.Modulo${num}/'${NC}"
}

scaffold_code() {
    echo -e "\n${BLUE}⚡ GENERAR PLANTILLA PARA TU MÓDULO (PostgreSQL 16 + Razor + C#)${NC}"
    read -p "👉 ¿Qué número de equipo eres? (1 al 9): " num
    num=$(printf "%02d" $((10#$num)))
    
    read -p "👉 Nombre del registro (ej: Alumno, Horario, Pago): " entidad
    if [ -z "$entidad" ]; then
        echo -e "${RED}❌ El nombre de la entidad es obligatorio.${NC}"
        return
    fi
    
    entidad_raw="$entidad"
    entidad=$(echo "$entidad" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-')
    if ! echo "$entidad" | grep -qE '^[a-zA-Z][a-zA-Z0-9-]*$'; then
        echo -e "${RED}❌ '$entidad_raw' no es un nombre válido. Debe empezar por una letra (ej: Matricula, PagoMensual).${NC}"
        return
    fi
    
    entidad=$(echo "$entidad" | awk -F'-' '{out=""; for(i=1;i<=NF;i++){s=$i; if(toupper(s)==s) s=tolower(s); out=out toupper(substr(s,1,1)) substr(s,2)}; print out}')
    if [ "$entidad_raw" != "$entidad" ]; then
        echo -e "${CYAN}ℹ️ Nombre normalizado a identificador C#: '${entidad}'${NC}"
    fi
    
    mod_path="src/02_Modulos/Intranet.Modulo${num}"
    if [ ! -d "$mod_path" ]; then
        echo -e "${RED}❌ No se encontró la carpeta del módulo: ${mod_path}${NC}"
        return
    fi
    
    for existing in "$mod_path/Models/${entidad}.cs" "$mod_path/Controllers/${entidad}Controller.cs" "$mod_path/Views/${entidad}/Index.cshtml"; do
        if [ -f "$existing" ]; then
            cp "$existing" "$existing.bak"
            echo -e "${YELLOW}📦 Existente respaldado: ${existing}.bak${NC}"
        fi
    done
    
    mkdir -p "$mod_path/Controllers" "$mod_path/Models" "$mod_path/Sql" "$mod_path/Views/${entidad}"
    
    entidad_sql=$(echo "$entidad" | tr '[:upper:]' '[:lower:]')
    schema_file="$mod_path/Sql/schema.sql"
    
    cat << SQL_EOF >> "$schema_file"
-- Esquema y Tabla para Módulo ${num} en PostgreSQL 16
CREATE TABLE IF NOT EXISTS mod${num}.${entidad_sql} (
  id SERIAL PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT NULL,
  fecha_registro TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

SQL_EOF

    cat << MODEL_EOF > "$mod_path/Models/${entidad}.cs"
namespace Intranet.Modulo${num}.Models;

public class ${entidad}
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public DateTime FechaRegistro { get; set; } = DateTime.Now;
}
MODEL_EOF

    cat << CTRL_EOF > "$mod_path/Controllers/${entidad}Controller.cs"
using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo${num}.Models;

namespace Intranet.Modulo${num}.Controllers;

[Route("Modulo${num}/[controller]")]
public class ${entidad}Controller : ModuloBaseController
{
    private static readonly List<${entidad}> _lista = new()
    {
        new ${entidad} { Id = 1, Codigo = "REG-001", Nombre = "Registro de Prueba 1", Descripcion = "Demostración inicial" },
        new ${entidad} { Id = 2, Codigo = "REG-002", Nombre = "Registro de Prueba 2", Descripcion = "Segundo elemento" }
    };

    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Gestión de ${entidad}";
        ViewData["TeamName"] = "Equipo ${num}";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        return View(_lista);
    }

    [HttpPost("Crear")]
    public IActionResult Crear(${entidad} item)
    {
        if (string.IsNullOrWhiteSpace(item.Nombre))
        {
            MostrarAlertaError("El nombre no puede estar vacío.");
            return RedirectToAction(nameof(Index));
        }

        item.Id = _lista.Count + 1;
        item.FechaRegistro = DateTime.Now;
        _lista.Add(item);

        MostrarAlertaExito("${entidad} guardado con éxito.");
        return RedirectToAction(nameof(Index));
    }
}
CTRL_EOF

    cat << VIEW_EOF > "$mod_path/Views/${entidad}/Index.cshtml"
@model IEnumerable<Intranet.Modulo${num}.Models.${entidad}>
@{
    ViewData["Title"] = "Gestión de ${entidad}";
}

<div class="space-y-6">
    <div class="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <a href="/Modulo${num}" class="text-xs text-blue-600 font-semibold hover:underline">← Módulo ${num}</a>
                <span class="text-slate-300">•</span>
                <span class="badge badge-primary font-bold text-[10px]">Equipo ${num}</span>
            </div>
            <h1 class="text-2xl font-extrabold text-slate-900">Listado de ${entidad}s</h1>
            <p class="text-xs text-slate-500">Módulo del Equipo ${num}. Usuario actual: @ViewData["UsuarioNombre"]</p>
        </div>
        <div class="flex gap-2">
            <a href="/Modulo${num}" class="btn btn-ghost btn-sm rounded-xl text-xs">Volver</a>
            <button class="btn btn-primary btn-sm rounded-xl text-xs font-bold" onclick="modal_nuevo.showModal()">+ Nuevo ${entidad}</button>
        </div>
    </div>

    <div class="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <table class="table table-zebra w-full text-xs">
            <thead>
                <tr class="bg-slate-100 text-slate-700 font-bold">
                    <th>#</th>
                    <th>Código</th>
                    <th>Nombre</th>
                    <th>Descripción</th>
                    <th>Fecha</th>
                </tr>
            </thead>
            <tbody>
                @foreach (var item in Model)
                {
                    <tr>
                        <td class="font-bold">@item.Id</td>
                        <td><span class="badge badge-ghost font-mono">@item.Codigo</span></td>
                        <td class="font-semibold">@item.Nombre</td>
                        <td class="text-slate-500">@item.Descripcion</td>
                        <td>@item.FechaRegistro.ToString("dd/MM/yyyy")</td>
                    </tr>
                }
            </tbody>
        </table>
    </div>
</div>

<dialog id="modal_nuevo" class="modal">
    <div class="modal-box rounded-3xl">
        <h3 class="font-bold text-base mb-3">Nuevo ${entidad}</h3>
        <form asp-action="Crear" method="post" class="space-y-3 text-xs">
            <div>
                <label class="font-bold block mb-1">Código</label>
                <input type="text" name="Codigo" required placeholder="Ej: COD-100" class="input input-sm input-bordered w-full rounded-xl" />
            </div>
            <div>
                <label class="font-bold block mb-1">Nombre</label>
                <input type="text" name="Nombre" required placeholder="Nombre del elemento" class="input input-sm input-bordered w-full rounded-xl" />
            </div>
            <div>
                <label class="font-bold block mb-1">Descripción</label>
                <textarea name="Descripcion" rows="2" placeholder="Detalle..." class="textarea textarea-bordered w-full rounded-xl"></textarea>
            </div>
            <div class="modal-action">
                <button type="button" onclick="modal_nuevo.close()" class="btn btn-ghost btn-sm">Cancelar</button>
                <button type="submit" class="btn btn-primary btn-sm">Guardar</button>
            </div>
        </form>
    </div>
</dialog>
VIEW_EOF

    echo -e "\n${GREEN}🎉 ¡Plantilla para '${entidad}' creada con éxito!${NC}"
    echo -e "Ruta web: ${CYAN}http://localhost:5000/Modulo${num}/${entidad}${NC}"
    echo -e "Script SQL añadido en: ${CYAN}${schema_file}${NC}"
}

validate_code() {
    echo -e "\n${BLUE}🧪 VALIDANDO COMPILACIÓN Y CALIDAD DE CÓDIGO...${NC}\n"
    if ! command -v dotnet >/dev/null 2>&1; then
        echo -e "${RED}❌ El SDK de .NET no está instalado o no se encuentra en el PATH.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Ejecutando: dotnet build IntranetInstitucional.sln${NC}"
    if dotnet build "IntranetInstitucional.sln" --nologo -c Release; then
        echo -e "\n${GREEN}======================================================================${NC}"
        echo -e "${GREEN}✅ ¡TODO EL PROYECTO COMPILA CON 0 ERRORES Y 0 WARNINGS!${NC}"
        echo -e "${GREEN}======================================================================${NC}"
    else
        echo -e "\n${RED}⛔ Se encontraron errores de compilación. Revisa los mensajes de arriba.${NC}"
        return 1
    fi
}

push_work() {
    echo -e "\n${BLUE}📤 SUBIR Y SINCRONIZAR MI TRABAJO CON GITHUB${NC}"
    branch=$(git rev-parse --abbrev-ref HEAD)
    
    if [ "$branch" = "main" ]; then
        echo -e "${RED}⛔ Estás en 'main'. Usa la opción 2 para crear o cambiar a tu rama antes de subir.${NC}"
        return
    fi
    
    echo -e "🌿 Rama de trabajo: ${CYAN}${branch}${NC}"
    
    # 1. Comprobar si hay cambios pendientes por guardar
    STATUS=$(git status --porcelain)
    if [ -n "$STATUS" ]; then
        MOD_NUM=$(echo "$branch" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | tr '[:upper:]' '[:lower:]' | grep -o -E '[0-9]{2}' || true)
        if [ -n "$MOD_NUM" ]; then
            ALLOWED_DIR="src/02_Modulos/Intranet.Modulo${MOD_NUM}/"
            OUTSIDE_FILES=$(git status --porcelain | awk '{print $2}' | grep -v "^${ALLOWED_DIR}" | grep -v "^docs/" | grep -v "\.md$" || true)
            if [ -n "$OUTSIDE_FILES" ]; then
                echo -e "\n${RED}⛔ ERROR DE AISLAMIENTO MODULAR:${NC}"
                echo -e "Detectamos cambios en archivos fuera de tu módulo '${ALLOWED_DIR}':"
                echo -e "${YELLOW}${OUTSIDE_FILES}${NC}\n"
                echo -e "${CYAN}💡 Para no bloquear tu Pull Request, revierte los cambios ajenos antes de subir.${NC}\n"
                return 1
            fi
        fi

        read -p "👉 Describe qué cambiaste (ej: agregue formulario): " msg
        if [ -z "$msg" ]; then
            msg="feat(${branch}): actualizacion de avance"
        fi
        git add .
        git commit -m "$msg"
        echo -e "${GREEN}✓ Cambios guardados localmente.${NC}"
    else
        echo -e "${YELLOW}ℹ️ No hay archivos nuevos por guardar, sincronizando con GitHub...${NC}"
    fi
    
    # 2. Descargar posibles cambios remotos de compañeros de equipo
    echo -e "${CYAN}Sincronizando con GitHub...${NC}"
    if ! git pull --rebase origin "$branch" 2>/dev/null; then
        if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
            git rebase --abort 2>/dev/null || true
            echo -e "\n${RED}⚠️  CONFLICTO DETECTADO: Un compañero de tu equipo subió cambios que chocan con los tuyos.${NC}"
            echo -e "${YELLOW}💡 Solución Recomendada (Poka-Yoke):${NC}"
            echo -e "   1. Usa la opción 2 para crear una rama personal: ${CYAN}${branch}-$(date +%s | tail -c 4)${NC}"
            echo -e "   2. Sube tus cambios con la opción 5 y abre tu propio Pull Request.\n"
            return 1
        fi
    fi
    
    # 2.5 Compilar ANTES de pushear
    echo -e "${CYAN}🔨 Compilando tu módulo antes de subir (verificación local)...${NC}"
    if command -v dotnet >/dev/null 2>&1; then
        if ! dotnet build "IntranetInstitucional.sln" -v q --nologo 2>&1 | tail -20; then
            echo -e "\n${RED}⛔ EL CÓDIGO NO COMPILÓ. No se subió nada a GitHub.${NC}"
            echo -e "${YELLOW}💡 Corrige los errores de arriba y vuelve a intentar.${NC}"
            return 1
        fi
    fi
    
    # 3. Publicar en GitHub
    echo -e "${CYAN}Publicando rama '${branch}' en GitHub...${NC}"
    if git push -u origin "$branch"; then
        echo -e "\n${GREEN}======================================================================${NC}"
        echo -e "${GREEN}🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!${NC}"
        echo -e "${GREEN}======================================================================${NC}"
        echo -e "👉 Crea o revisa tu Pull Request aquí:\n   ${CYAN}https://github.com/felipeostosb/intranet-institucional-modular/compare/main...${branch}${NC}"
    else
        echo -e "\n${RED}❌ Hubo un inconveniente al subir a GitHub. Revisa tu conexión o permisos.${NC}"
    fi
}

configure_db() {
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}⚙️  CONFIGURACIÓN DE BASE DE DATOS DE TU EQUIPO (PostgreSQL 16)${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "  Al configurar tu equipo, la aplicación tendrá permisos de escritura"
    echo -e "  exclusivos en tu esquema soberano ${CYAN}mod[XX]${NC}.\n"
    
    read -p "👉 ¿Qué número de equipo eres? (1 al 9): " num
    num=$(printf "%02d" $((10#$num)))
    
    if [ "$num" -lt 1 ] || [ "$num" -gt 9 ]; then
        echo -e "${RED}❌ Número no válido. Debe ser entre 1 y 9.${NC}"
        return
    fi
    
    echo -e "👤 Usuario PostgreSQL asignado: ${CYAN}user_equipo${num}${NC}"
    read -sp "🔑 Ingresa la contraseña de tu equipo (entregada en tu Ficha Privada): " pass
    echo ""
    
    if [ -z "$pass" ]; then
        echo -e "${RED}❌ La contraseña no puede estar vacía.${NC}"
        return
    fi
    
    read -p "🌐 Host de BD [ENTER para usar '35.206.81.32' en la nube o escribe '127.0.0.1']: " dbhost
    if [ -z "$dbhost" ]; then
        dbhost="35.206.81.32"
    fi
    
    LOCAL_CONFIG="src/03_Web/Intranet.Web/appsettings.Local.json"
    
    cat << JSON_EOF > "$LOCAL_CONFIG"
{
  "// LOCAL OVERRIDE": "Configuracion de conexion para Equipo ${num}. Este archivo esta en .gitignore.",
  "ConnectionStrings": {
    "Modulo${num}Connection": "Host=${dbhost};Port=5432;Database=db_intranet_iestp;Username=user_equipo${num};Password=${pass};SearchPath=mod${num},core,public;Pooling=true;MinPoolSize=2;MaxPoolSize=15;"
  }
}
JSON_EOF

    echo -e "\n${GREEN}======================================================================${NC}"
    echo -e "${GREEN}✅ ¡CONFIGURACIÓN LOCAL COMPLETADA CON ÉXITO!${NC}"
    echo -e "${GREEN}======================================================================${NC}"
    echo -e "📄 Archivo creado: ${CYAN}${LOCAL_CONFIG}${NC} (Protegido en .gitignore)"
    echo -e "🛡️  ${YELLOW}Seguridad de BD Activa:${NC}"
    echo -e "   - Tu equipo tiene control ${GREEN}TOTAL (INSERT/UPDATE/DELETE)${NC} en su esquema ${CYAN}mod${num}${NC}."
    echo -e "   - La base de datos protege a ${CYAN}core${NC} y los demás esquemas en ${YELLOW}SOLO LECTURA (SELECT)${NC}."
    echo -e "${GREEN}======================================================================${NC}\n"
}

show_db_info() {
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🗄️  INFORMACIÓN DE BASE DE DATOS POSTGRESQL 16 & ADMINER${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "  🌐 ${CYAN}Panel Web Adminer:${NC} http://35.206.81.32:8080"
    echo -e "  ⚙️  ${CYAN}Motor:${NC} PostgreSQL 16"
    echo -e "  🖥️  ${CYAN}Servidor:${NC} postgres (o 35.206.81.32 desde DBeaver/VS Code)"
    echo -e "  📊 ${CYAN}Base de Datos:${NC} db_intranet_iestp"
    echo -e "  👤 ${CYAN}Usuario:${NC} user_equipo[XX] (Tu usuario asignado)"
    echo -e "  🔑 ${CYAN}Contraseña:${NC} (Consulta tu Ficha Privada entregada por el Administrador)"
    echo -e "  🛡️  ${CYAN}Esquema Soberano:${NC} mod[XX] (Tu espacio aislado de tablas)"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}"
    echo -e "  💡 ${YELLOW}Permisos RBAC:${NC} Control total en 'modXX' y lectura (SELECT) en 'core'."
    echo -e "  💡 ${CYAN}Configuración Local:${NC} Usa la opción 6 de dev.sh para configurar tu clave."
    echo -e "${BLUE}======================================================================${NC}\n"
}

ask_ai_assistant() {
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🤖  ASISTENTE IA DE ARQUITECTURA & REGLAMENTO (RAG GEMINI + QDRANT)${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "  ${CYAN}Pregunta lo que necesites sobre C#, PostgreSQL 16, CI/CD o el Reglamento.${NC}\n"
    read -p "💬 Escribe tu pregunta técnica: " pregunta
    if [ -n "$pregunta" ]; then
        echo ""
        python3 scripts/rag/ingest_and_query_rag.py --query "$pregunta"
    fi
}

while true; do
    show_menu
    read -p "👉 Elige una opción [0-8]: " op
    case $op in
        1) start_app ;;
        2) create_branch ;;
        3) scaffold_code ;;
        4) validate_code ;;
        5) push_work ;;
        6) configure_db ;;
        7) show_db_info ;;
        8) ask_ai_assistant ;;
        0) echo -e "\n${GREEN}¡Buen trabajo! Hasta luego.${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción no válida.${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona ENTER para volver al menú...${NC}"
    read
done
