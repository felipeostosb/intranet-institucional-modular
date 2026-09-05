#!/usr/bin/env bash
# ==============================================================================
# 🏛️ IESTP ARGENTINA - CLI DE DESARROLLO & POKA-YOKE (DEV EXPERIENCE)
# ==============================================================================
# Este script guía a los 36 desarrolladores paso a paso para evitar errores de Git,
# nombres de rama inválidos, modificaciones accidentales de archivos y fallos de build.
# ==============================================================================

set -e

# Colores de Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

show_header() {
    clear
    echo -e "${CYAN}${BOLD}======================================================================${NC}"
    echo -e "${CYAN}${BOLD}🏛️  INTRANET INSTITUCIONAL IESTP ARGENTINA - DEVELOPER SUITE (DX)  ${NC}"
    echo -e "${CYAN}${BOLD}======================================================================${NC}"
    echo -e "  ${BOLD}Plataforma Modular .NET 10 LTS • MariaDB 10.11 • Zero-Blast-Radius${NC}"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
}

# 1. Instalar Hooks de Git (Poka-Yoke)
install_git_hooks() {
    echo -e "\n${BLUE}🔧 Configurando Guardián Local de Git (Pre-Push Hook)...${NC}"
    mkdir -p .git/hooks
    cat << 'HOOK_EOF' > .git/hooks/pre-push
#!/usr/bin/env bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "\033[0;31m⛔ ERROR POKA-YOKE: Está PROHIBIDO hacer push directo a 'main'.\033[0m"
    echo -e "\033[1;33m👉 Crea una rama para tu módulo con: ./dev.sh\033[0m"
    exit 1
fi

echo -e "\033[0;34m🔍 [Pre-Push] Validando que la solución compile limpiamente...\033[0m"
dotnet build IntranetInstitucional.sln -v q --nologo
if [ $? -ne 0 ]; then
    echo -e "\033[0;31m❌ ERROR: La solución tiene errores de compilación. Corrige antes de subir.\033[0m"
    exit 1
fi

echo -e "\033[0;32m✅ [Pre-Push] Validación de código exitosa.\033[0m"
exit 0
HOOK_EOF
    chmod +x .git/hooks/pre-push
    echo -e "${GREEN}✅ Guardián de Git instalado. Push directo a 'main' bloqueado y auto-compilación activada.${NC}"
}

# 2. Iniciar Entorno Local con Hot Reload
start_local_dev() {
    echo -e "\n${BLUE}🚀 Iniciando Intranet en modo desarrollo con Hot-Reload (dotnet watch)...${NC}"
    echo -e "${YELLOW}💡 Tip: Al modificar archivos C# o HTML, el navegador se actualizará automáticamente.${NC}"
    echo -e "${CYAN}🌐 Abriendo en: http://localhost:5000${NC}\n"
    dotnet watch --project src/03_Web/Intranet.Web
}

# 3. Crear Rama Estandarizada
create_branch() {
    echo -e "\n${BLUE}🌿 CREAR NUEVA RAMA DE TRABAJO (Estandarizada)${NC}"
    echo -e "${YELLOW}Selecciona tu número de equipo (01 al 09):${NC}"
    read -p "Equipo (ej: 04): " EQUIPO_NUM
    
    EQUIPO_NUM=$(printf "%02d" $((10#$EQUIPO_NUM)))
    
    if [ "$EQUIPO_NUM" -lt 1 ] || [ "$EQUIPO_NUM" -gt 9 ]; then
        echo -e "${RED}❌ Número de equipo inválido. Debe ser entre 01 y 09.${NC}"
        return
    fi
    
    read -p "Nombre breve de la tarea (ej: formulario-actas): " TAREA_NAME
    TAREA_NAME=$(echo "$TAREA_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    
    BRANCH_NAME="modulo${EQUIPO_NUM}/${TAREA_NAME}"
    
    echo -e "\n${CYAN}Sincronizando con 'main'...${NC}"
    git checkout main
    git pull origin main
    
    echo -e "${GREEN}Creando y cambiando a la rama '${BRANCH_NAME}'...${NC}"
    git checkout -b "$BRANCH_NAME"
    echo -e "\n${GREEN}✅ ¡Listo! Ahora estás trabajando de forma segura en: ${BOLD}${BRANCH_NAME}${NC}"
    echo -e "${YELLOW}Recuerda programar ÚNICAMENTE dentro de: src/02_Modulos/Intranet.Modulo${EQUIPO_NUM}/${NC}"
}

# 4. Validar Código Localmente (Zero-Blast-Radius)
validate_local() {
    echo -e "\n${BLUE}🔍 AUDITORÍA LOCAL ZERO-BLAST-RADIUS${NC}"
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo -e "🌿 Rama actual: ${BOLD}${CURRENT_BRANCH}${NC}"
    
    if [ "$CURRENT_BRANCH" = "main" ]; then
        echo -e "${YELLOW}⚠️ Estás en la rama 'main'. Crea una rama con la opción 2 antes de programar.${NC}"
        return
    fi
    
    MODULO_NUM=$(echo "$CURRENT_BRANCH" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | tr '[:upper:]' '[:lower:]')
    
    if [ -z "$MODULO_NUM" ]; then
        echo -e "${RED}❌ Tu rama '${CURRENT_BRANCH}' no tiene el formato estándar (ej: modulo04/mi-tarea).${NC}"
        return
    fi
    
    NUM_SOLO=$(echo "$MODULO_NUM" | grep -o -E '[0-9]{2}')
    ALLOWED_PATH="src/02_Modulos/Intranet.Modulo${NUM_SOLO}/"
    echo -e "🔒 Carpeta autorizada para tu equipo: ${BOLD}${ALLOWED_PATH}${NC}\n"
    
    git fetch origin main >/dev/null 2>&1 || true
    CHANGED_FILES=$(git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only main...HEAD)
    
    VIOLATIONS=0
    for file in $CHANGED_FILES; do
        if [[ "$file" != "$ALLOWED_PATH"* ]]; then
            echo -e "  ${RED}❌ VIOLACIÓN: Modificaste '${file}' (Fuera de tu carpeta).${NC}"
            VIOLATIONS=$((VIOLATIONS + 1))
        else
            echo -e "  ${GREEN}✅ Archivo permitido: ${file}${NC}"
        fi
    done
    
    if [ $VIOLATIONS -gt 0 ]; then
        echo -e "\n${RED}⛔ ALERTA: Tienes ${VIOLATIONS} archivo(s) modificados fuera de tu módulo.${NC}"
        echo -e "${YELLOW}Deshaz esos cambios antes de abrir tu Pull Request para evitar que el CI/CD te rechace.${NC}"
    else
        echo -e "\n${GREEN}🎉 ¡Felicidades! Todos tus archivos modificados pertenecen a tu módulo.${NC}"
    fi
    
    echo -e "\n${BLUE}🔨 Probando compilación de la solución completa...${NC}"
    if dotnet build IntranetInstitucional.sln --nologo; then
        echo -e "\n${GREEN}✅ COMPILACIÓN PERFECTA (0 Errores). Tu código está listo para PR.${NC}"
    else
        echo -e "\n${RED}❌ Hay errores de compilación. Revisa los mensajes arriba.${NC}"
    fi
}

# 5. Generador Scaffolding CRUD Apple Style
scaffold_crud() {
    echo -e "\n${BLUE}⚡ GENERADOR DE PLANTILLA CRUD APPLE STYLE${NC}"
    read -p "Número de equipo (01 al 09): " EQUIPO_NUM
    EQUIPO_NUM=$(printf "%02d" $((10#$EQUIPO_NUM)))
    
    read -p "Nombre de la Entidad en Singular (ej: Alumno, Curso, Pago): " ENTIDAD
    ENTIDAD="$(tr '[:lower:]' '[:upper:]' <<< ${ENTIDAD:0:1})${ENTIDAD:1}"
    
    MODULE_PATH="src/02_Modulos/Intranet.Modulo${EQUIPO_NUM}"
    
    if [ ! -d "$MODULE_PATH" ]; then
        echo -e "${RED}❌ La carpeta $MODULE_PATH no existe.${NC}"
        return
    fi
    
    mkdir -p "$MODULE_PATH/Controllers"
    mkdir -p "$MODULE_PATH/Models"
    mkdir -p "$MODULE_PATH/Views/${ENTIDAD}"
    
    MODEL_FILE="$MODULE_PATH/Models/${ENTIDAD}.cs"
    CTRL_FILE="$MODULE_PATH/Controllers/${ENTIDAD}Controller.cs"
    VIEW_FILE="$MODULE_PATH/Views/${ENTIDAD}/Index.cshtml"
    
    echo -e "📄 Creando Modelo: ${CYAN}${MODEL_FILE}${NC}"
    cat << MODEL_EOF > "$MODEL_FILE"
namespace Intranet.Modulo${EQUIPO_NUM}.Models;

public class ${ENTIDAD}
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public DateTime FechaRegistro { get; set; } = DateTime.Now;
    public bool Activo { get; set; } = true;
}
MODEL_EOF

    echo -e "📄 Creando Controlador: ${CYAN}${CTRL_FILE}${NC}"
    cat << CTRL_EOF > "$CTRL_FILE"
using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo${EQUIPO_NUM}.Models;

namespace Intranet.Modulo${EQUIPO_NUM}.Controllers;

[Route("Modulo${EQUIPO_NUM}/[controller]")]
public class ${ENTIDAD}Controller : ModuloBaseController
{
    private static readonly List<${ENTIDAD}> _registros = new()
    {
        new ${ENTIDAD} { Id = 1, Codigo = "COD-001", Nombre = "Ejemplo 01", Descripcion = "Registro inicial", Activo = true },
        new ${ENTIDAD} { Id = 2, Codigo = "COD-002", Nombre = "Ejemplo 02", Descripcion = "Segundo registro", Activo = true }
    };

    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Gestión de ${ENTIDAD}s";
        ViewData["TeamName"] = "Equipo ${EQUIPO_NUM}";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        return View(_registros);
    }

    [HttpPost("Crear")]
    public IActionResult Crear(${ENTIDAD} nuevo)
    {
        if (string.IsNullOrWhiteSpace(nuevo.Nombre))
        {
            MostrarAlertaError("El nombre es obligatorio.");
            return RedirectToAction(nameof(Index));
        }

        nuevo.Id = _registros.Count > 0 ? _registros.Max(r => r.Id) + 1 : 1;
        nuevo.FechaRegistro = DateTime.Now;
        _registros.Add(nuevo);

        MostrarAlertaExito("${ENTIDAD} registrado correctamente.");
        return RedirectToAction(nameof(Index));
    }
}
CTRL_EOF

    echo -e "📄 Creando Vista Apple: ${CYAN}${VIEW_FILE}${NC}"
    cat << 'VIEW_EOF' > "$VIEW_FILE"
@model IEnumerable<Intranet.ModuloREPLACE_NUM.Models.REPLACE_ENTITY>
@{
    ViewData["Title"] = "Gestión de REPLACE_ENTITYs";
}

<div class="space-y-6 font-light">
    <!-- Header Apple Style -->
    <div class="bg-white rounded-3xl p-6 border border-[#e5e5e7] shadow-[0_2px_12px_rgba(0,0,0,0.015)] flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div class="flex items-center gap-3.5">
            <div class="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 border border-indigo-100 flex items-center justify-center shrink-0">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
            </div>
            <div>
                <div class="flex items-center gap-2 mb-0.5">
                    <span class="text-[10px] font-mono bg-indigo-50 text-indigo-700 px-2 py-0.5 rounded-full border border-indigo-200/60">MREPLACE_NUM</span>
                    <span class="text-[11px] text-slate-400 font-light">db_moduloREPLACE_NUM • @ViewData["TeamName"]</span>
                </div>
                <h1 class="text-xl sm:text-2xl font-normal text-slate-900 tracking-tight">
                    Gestión de REPLACE_ENTITYs
                </h1>
                <p class="text-xs text-slate-500 font-light">
                    Módulo administrado por el Equipo REPLACE_NUM. Usuario activo: <strong>@ViewData["UsuarioNombre"]</strong> (@ViewData["UsuarioRol"]).
                </p>
            </div>
        </div>
        <button class="px-4 py-2 rounded-xl bg-[#0071e3] hover:bg-[#0077ed] text-white text-xs font-normal transition shadow-sm flex items-center gap-1.5" onclick="modal_nuevo.showModal()">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>
            <span>Nuevo REPLACE_ENTITY</span>
        </button>
    </div>

    <!-- Tabla Apple Style -->
    <div class="bg-white rounded-2xl border border-[#e5e5e7] shadow-[0_2px_8px_rgba(0,0,0,0.015)] overflow-hidden">
        <div class="p-4 border-b border-slate-100 flex justify-between items-center">
            <div>
                <h2 class="text-xs sm:text-sm font-normal text-slate-900">Listado de REPLACE_ENTITYs</h2>
                <p class="text-[11px] text-slate-400 font-light">Registros guardados en db_moduloREPLACE_NUM.</p>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-xs divide-y divide-slate-100">
                <thead>
                    <tr class="bg-[#fbfbfd] text-slate-400 text-[10px] uppercase font-normal tracking-wider">
                        <th class="py-2.5 px-4 font-normal">#</th>
                        <th class="py-2.5 px-4 font-normal">Código</th>
                        <th class="py-2.5 px-4 font-normal">Nombre</th>
                        <th class="py-2.5 px-4 font-normal">Descripción</th>
                        <th class="py-2.5 px-4 font-normal">Fecha</th>
                        <th class="py-2.5 px-4 font-normal">Estado</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 font-light text-slate-700">
                    @foreach (var item in Model)
                    {
                        <tr class="hover:bg-slate-50/50 transition">
                            <td class="py-3 px-4 font-mono text-[11px] text-slate-400">@item.Id</td>
                            <td class="py-3 px-4 font-mono text-[11px] text-indigo-600 font-normal">@item.Codigo</td>
                            <td class="py-3 px-4 font-normal text-slate-900">@item.Nombre</td>
                            <td class="py-3 px-4 text-slate-500">@item.Descripcion</td>
                            <td class="py-3 px-4 text-slate-400 text-[11px]">@item.FechaRegistro.ToString("dd/MM/yyyy HH:mm")</td>
                            <td class="py-3 px-4">
                                <span class="text-[10px] bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full border border-emerald-200/60">Activo</span>
                            </td>
                        </tr>
                    }
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal Formulario Apple Style -->
<dialog id="modal_nuevo" class="modal">
    <div class="modal-box max-w-md bg-white rounded-3xl p-6 shadow-2xl border border-slate-200 font-light">
        <h3 class="text-base font-normal text-slate-900 mb-1">
            Nuevo REPLACE_ENTITY
        </h3>
        <p class="text-xs text-slate-400 font-light mb-4">Completa los campos para registrar en el Módulo REPLACE_NUM.</p>
        
        <form asp-action="Crear" method="post" class="space-y-3 text-xs">
            <div>
                <label class="text-[10px] text-slate-400 uppercase tracking-wider block mb-1">Código</label>
                <input type="text" name="Codigo" required placeholder="Ej: COD-2026" class="w-full px-3 py-2 rounded-xl border border-slate-200 bg-[#fbfbfd] text-xs focus:bg-white focus:outline-none focus:border-[#0071e3]" />
            </div>

            <div>
                <label class="text-[10px] text-slate-400 uppercase tracking-wider block mb-1">Nombre / Título</label>
                <input type="text" name="Nombre" required placeholder="Nombre del registro" class="w-full px-3 py-2 rounded-xl border border-slate-200 bg-[#fbfbfd] text-xs focus:bg-white focus:outline-none focus:border-[#0071e3]" />
            </div>

            <div>
                <label class="text-[10px] text-slate-400 uppercase tracking-wider block mb-1">Descripción</label>
                <textarea name="Descripcion" rows="3" placeholder="Detalle adicional..." class="w-full px-3 py-2 rounded-xl border border-slate-200 bg-[#fbfbfd] text-xs focus:bg-white focus:outline-none focus:border-[#0071e3]"></textarea>
            </div>

            <div class="modal-action mt-6 flex gap-2">
                <button type="button" onclick="modal_nuevo.close()" class="px-3.5 py-1.5 text-xs text-slate-500 hover:bg-slate-100 rounded-xl">Cancelar</button>
                <button type="submit" class="px-4 py-1.5 text-xs rounded-xl bg-[#0071e3] hover:bg-[#0077ed] text-white font-normal">Guardar REPLACE_ENTITY</button>
            </div>
        </form>
    </div>
</dialog>
VIEW_EOF

    sed -i "s/REPLACE_NUM/${EQUIPO_NUM}/g" "$VIEW_FILE"
    sed -i "s/REPLACE_ENTITY/${ENTIDAD}/g" "$VIEW_FILE"

    echo -e "\n${GREEN}🎉 ¡Plantilla CRUD para '${ENTIDAD}' generada con éxito!${NC}"
    echo -e "Ruta web: ${CYAN}http://localhost:5000/Modulo${EQUIPO_NUM}/${ENTIDAD}${NC}"
}

# 6. Subir Cambios y Push
push_changes() {
    echo -e "\n${BLUE}📤 SUBIR CAMBIOS A GITHUB (Push Seguro)${NC}"
    validate_local
    
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" = "main" ]; then
        echo -e "${RED}⛔ No puedes hacer push directo desde 'main'.${NC}"
        return
    fi
    
    echo -e "\n${YELLOW}Escribe un mensaje claro para tu commit:${NC}"
    read -p "Mensaje (ej: feat(m04): formulario de actas): " COMMIT_MSG
    
    git add .
    git commit -m "$COMMIT_MSG"
    
    echo -e "\n${CYAN}Subiendo a GitHub...${NC}"
    git push origin "$CURRENT_BRANCH"
    
    echo -e "\n${GREEN}✅ Push completado con éxito a la rama: ${BOLD}${CURRENT_BRANCH}${NC}"
    echo -e "${CYAN}👉 Ahora abre tu Pull Request en GitHub: https://github.com/felipeostosb/intranet-institucional-modular/pulls${NC}"
}

# Menú Principal
while true; do
    show_header
    echo -e "${BOLD}Selecciona una opción:${NC}\n"
    echo -e "  ${CYAN}1)${NC} 🚀 Iniciar Intranet Local (${BOLD}dotnet watch / Hot Reload${NC})"
    echo -e "  ${CYAN}2)${NC} 🌿 Crear mi Rama de Tarea (${BOLD}moduloXX/mi-tarea${NC})"
    echo -e "  ${CYAN}3)${NC} ⚡ Generar Plantilla CRUD Apple (${BOLD}Controller + Model + Vista${NC})"
    echo -e "  ${CYAN}4)${NC} 🔍 Validar mi Código (${BOLD}Auditoría Zero-Blast-Radius Local${NC})"
    echo -e "  ${CYAN}5)${NC} 📤 Subir Cambios (${BOLD}Git Commit & Push Seguro${NC})"
    echo -e "  ${CYAN}6)${NC} 🔧 Instalar Guardián Local de Git (${BOLD}Pre-Push Hook Poka-Yoke${NC})"
    echo -e "  ${CYAN}0)${NC} 🚪 Salir\n"
    
    read -p "Opción [0-6]: " OPTION
    case $OPTION in
        1) start_local_dev ;;
        2) create_branch ;;
        3) scaffold_crud ;;
        4) validate_local ;;
        5) push_changes ;;
        6) install_git_hooks ;;
        0) echo -e "\n${GREEN}¡Hasta pronto!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción no válida.${NC}" ;;
    esac
    
    echo -e "\n${YELLOW}Presiona ENTER para volver al menú...${NC}"
    read
done
