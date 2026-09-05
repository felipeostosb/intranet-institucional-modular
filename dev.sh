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

# Instalar guardián local contra push a main de forma silenciosa
if [ -d .git ] && [ ! -f .git/hooks/pre-push ]; then
    mkdir -p .git/hooks
    cat << 'HOOK_EOF' > .git/hooks/pre-push
#!/usr/bin/env bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer push directo a 'main'. Usa una rama de equipo.\033[0m"
    exit 1
fi
exit 0
HOOK_EOF
    chmod +x .git/hooks/pre-push
fi

show_menu() {
    clear
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "desconocida")
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🏛️  INTRANET INSTITUCIONAL IESTP ARGENTINA — ASISTENTE DEV${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "  ${CYAN}Plataforma .NET 10 LTS • MariaDB • 9 Módulos Desacoplados${NC}"
    echo -e "  🌿 Rama actual: ${YELLOW}${CURRENT_BRANCH}${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}\n"
    echo -e "  ${GREEN}1)${NC} 🚀 ${CYAN}Iniciar Intranet${NC} (Ver cambios en vivo en tu navegador)"
    echo -e "  ${GREEN}2)${NC} 🌿 ${CYAN}Crear / Cambiar a mi Rama de Equipo${NC} (Elige tu equipo 01 al 09)"
    echo -e "  ${GREEN}3)${NC} ⚡ ${CYAN}Generar Formulario / Tabla${NC} (Para tu módulo)"
    echo -e "  ${GREEN}4)${NC} 📤 ${CYAN}Subir mi Trabajo a GitHub${NC} (Guarda y sincroniza siempre)"
    echo -e "  ${GREEN}0)${NC} 🚪 ${YELLOW}Salir${NC}\n"
}

start_app() {
    echo -e "\n${BLUE}🚀 Abriendo la Intranet en tu navegador (http://localhost:5000)...${NC}"
    echo -e "${YELLOW}💡 Cada cambio que guardes se actualizará automáticamente.${NC}\n"
    dotnet watch --project src/03_Web/Intranet.Web
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
    
    echo -e "${YELLOW}Recuerda programar en: src/02_Modulos/Intranet.Modulo${num}/${NC}"
}

scaffold_code() {
    echo -e "\n${BLUE}⚡ GENERAR PLANTILLA PARA TU MÓDULO${NC}"
    read -p "👉 ¿Qué número de equipo eres? (1 al 9): " num
    num=$(printf "%02d" $((10#$num)))
    
    read -p "👉 Nombre del registro (ej: Alumno, Producto, Pago): " entidad
    if [ -z "$entidad" ]; then
        echo -e "${RED}❌ El nombre de la entidad es obligatorio.${NC}"
        return
    fi
    entidad="$(tr '[:lower:]' '[:upper:]' <<< ${entidad:0:1})${entidad:1}"
    
    mod_path="src/02_Modulos/Intranet.Modulo${num}"
    mkdir -p "$mod_path/Controllers" "$mod_path/Models" "$mod_path/Views/${entidad}"
    
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
    <div class="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm flex justify-between items-center">
        <div>
            <div class="badge badge-primary font-bold mb-1">Módulo ${num}</div>
            <h1 class="text-2xl font-extrabold text-slate-900">Listado de ${entidad}s</h1>
            <p class="text-xs text-slate-500">Módulo del Equipo ${num}. Usuario: @ViewData["UsuarioNombre"]</p>
        </div>
        <button class="btn btn-primary btn-sm rounded-xl" onclick="modal_nuevo.showModal()">+ Nuevo ${entidad}</button>
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
}

# 4. Subir a GitHub (Maneja Primera Vez y Sincronizaciones Posteriores)
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
    git pull --rebase origin "$branch" >/dev/null 2>&1 || true
    
    # 3. Publicar en GitHub (Cubre Primera Vez con -u y Siguientes veces)
    echo -e "${CYAN}Publicando rama '${branch}' en GitHub...${NC}"
    if git push -u origin "$branch"; then
        echo -e "\n${GREEN}======================================================================${NC}"
        echo -e "${GREEN}🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!${NC}"
        echo -e "${GREEN}======================================================================${NC}"
        echo -e "👉 Abre o revisa tu Pull Request aquí:\n   ${CYAN}https://github.com/felipeostosb/intranet-institucional-modular/pulls${NC}"
    else
        echo -e "\n${RED}❌ Hubo un inconveniente al subir a GitHub. Revisa tu conexión o permisos.${NC}"
    fi
}

while true; do
    show_menu
    read -p "👉 Elige una opción [0-4]: " op
    case $op in
        1) start_app ;;
        2) create_branch ;;
        3) scaffold_code ;;
        4) push_work ;;
        0) echo -e "\n${GREEN}¡Buen trabajo! Hasta luego.${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción no válida.${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona ENTER para volver al menú...${NC}"
    read
done
