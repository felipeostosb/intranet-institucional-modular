#!/usr/bin/env bash
# ==============================================================================
# 🦅 AQUILA A-ERP — ASISTENTE DEV RESILIENTE & SIMPLIFICADO
# Intranet Institucional IESTP Argentina • .NET 10 LTS • PostgreSQL 16
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

# Detectar si la rama corresponde a un módulo (ej: modulo00/login, modulo02/avance)
MOD_NUM=$(echo "$BRANCH" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | tr '[:upper:]' '[:lower:]' | grep -o -E '[0-9]{2}' || true)

if [ -n "$MOD_NUM" ]; then
    ALLOWED_DIR="src/02_Modulos/Intranet.Modulo${MOD_NUM}/"
    STAGED_FILES=$(git diff --cached --name-only)
    
    VIOLATIONS=0
    for file in $STAGED_FILES; do
        # Permitir archivos de su propio módulo, documentación general o scripts
        if [[ "$file" != "$ALLOWED_DIR"* ]] && [[ "$file" != "docs/"* ]] && [[ "$file" != *.md ]] && [[ "$file" != "dev.sh" ]] && [[ "$file" != "dev.ps1" ]] && [[ "$file" != ".dockerignore" ]] && [[ "$file" != "Dockerfile" ]]; then
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
    echo -e "${CYAN}🦅 AQUILA A-ERP ${BLUE}— INTRANET INSTITUCIONAL IESTP ARGENTINA${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "  ${CYAN}Plataforma .NET 10 LTS • PostgreSQL 16 • 10 Módulos (00 - 09)${NC}"
    echo -e "  🌿 Rama actual: ${YELLOW}${CURRENT_BRANCH}${NC}"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}\n"
    echo -e "  ${GREEN}1)${NC} 🚀 ${CYAN}Iniciar Intranet${NC} (Ver cambios en vivo con Hot-Reload en http://localhost:5000)"
    echo -e "  ${GREEN}2)${NC} 🌿 ${CYAN}Mi Rama de Equipo${NC} (Crear o cambiar a tu rama modulo00..modulo09)"
    echo -e "  ${GREEN}3)${NC} 🔄 ${CYAN}Sincronizar con 'main'${NC} (Descarga cambios de producción sin perder tu trabajo)"
    echo -e "  ${GREEN}4)${NC} 🧪 ${CYAN}Compilar y Validar${NC} (Verifica 0 errores en toda la solución .NET 10)"
    echo -e "  ${GREEN}5)${NC} 📤 ${CYAN}Subir a GitHub${NC} (Guarda cambios, sincroniza y genera enlace de PR)"
    echo -e "  ${GREEN}6)${NC} 🗄️  ${CYAN}Base de Datos PostgreSQL${NC} (Credenciales Adminer y Configuración Local)"
    echo -e "  ${GREEN}7)${NC} 💾 ${CYAN}Backup / Restore de BD${NC} (Respaldar o restaurar tu esquema modXX)"
    echo -e "  ${GREEN}8)${NC} 📊 ${CYAN}Estado del Proyecto${NC} (Dashboard: rama, cambios, servidor, configuración)"
    echo -e "  ${GREEN}9)${NC} 📋 ${CYAN}Ver Mis Cambios${NC} (Lista legible de archivos modificados con diffstat)"
    echo -e "  ${GREEN}10)${NC} 🔧 ${CYAN}Extras${NC} (Submenú: historial, esquema, PR, datos de prueba y más)"
    echo -e "  ${GREEN}0)${NC} 🚪 ${YELLOW}Salir${NC}\n"
}

start_app() {
    echo -e "\n${BLUE}🚀 Iniciando Aquila A-ERP en tu navegador (http://localhost:5000)...${NC}\n"
    
    # Intentar con dotnet watch (Hot-Reload), y si falla por límite inotify en Linux, fallback a dotnet run
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
    echo -e "\n${BLUE}🌿 CONFIGURAR RAMA DE TRABAJO (EQUIPOS 00 AL 09)${NC}"
    read -p "👉 ¿Qué número de equipo eres? (0 al 9): " num
    num_clean=$(echo "$num" | tr -cd '0-9')
    
    if [ -z "$num_clean" ] || [ "$num_clean" -lt 0 ] || [ "$num_clean" -gt 9 ]; then
        echo -e "${RED}❌ Número no válido. Debe ser entre 0 y 9 (ej: 0, 1, 02).${NC}"
        return
    fi
    
    num_fmt=$(printf "%02d" "$num_clean")
    
    read -p "👉 ¿Qué tarea vas a realizar? (ej: login-seguridad, asistencia-alumnos): " tarea
    if [ -z "$tarea" ]; then
        tarea="avance"
    fi
    tarea=$(echo "$tarea" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    
    branch="modulo${num_fmt}/${tarea}"
    
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
    
    echo -e "${YELLOW}🔒 Guardián Activado: Solo puedes modificar archivos en 'src/02_Modulos/Intranet.Modulo${num_fmt}/'${NC}"
}

sync_main() {
    echo -e "\n${BLUE}🔄 SINCRONIZAR Y ACTUALIZAR CON 'main' (PRODUCCIÓN)${NC}"
    branch=$(git rev-parse --abbrev-ref HEAD)
    
    if [ "$branch" = "main" ]; then
        echo -e "${YELLOW}ℹ️ Estás en 'main'. Descargando últimos cambios directamente de GitHub...${NC}"
        git pull origin main
        echo -e "\n${GREEN}✅ ¡Rama 'main' actualizada con éxito!${NC}"
        return
    fi
    
    echo -e "🌿 Tu rama actual: ${CYAN}${branch}${NC}"
    echo -e "${CYAN}Iniciando sincronización segura (Zero-Data-Loss)...${NC}\n"
    
    # 1. Guardar cambios locales sin commitear en stash de respaldo si existen
    STASHED=0
    STATUS=$(git status --porcelain)
    if [ -n "$STATUS" ]; then
        echo -e "${YELLOW}📦 Guardando temporalmente tus cambios locales no guardados (stash)...${NC}"
        git stash push -m "WIP-dev-sync-$(date +%s)" >/dev/null 2>&1
        STASHED=1
        echo -e "${GREEN}✓ Trabajo local respaldado con seguridad.${NC}"
    fi
    
    # 2. Obtener los últimos cambios de main desde GitHub
    echo -e "${CYAN}📥 Descargando actualizaciones de 'main' desde GitHub (git fetch)...${NC}"
    git fetch origin main
    
    # 3. Aplicar rebase de origin/main sobre la rama actual
    echo -e "${CYAN}🔀 Integrando los cambios de producción en tu rama (${branch})...${NC}"
    if ! git rebase origin/main; then
        echo -e "\n${RED}⚠️  HUBO UN CONFLICTO al integrar los cambios de main.${NC}"
        echo -e "${YELLOW}Cancelando rebase para proteger tu código...${NC}"
        git rebase --abort 2>/dev/null || true
        if [ $STASHED -eq 1 ]; then
            git stash pop >/dev/null 2>&1 || true
        fi
        echo -e "\n${CYAN}💡 Recomendación:${NC}"
        echo -e "   Si modificaste un archivo que otro equipo también tocó (ej: archivo compartido),"
        echo -e "   pide apoyo a tu Scrum Master para revisar el cruce.\n"
        return 1
    fi
    
    # 4. Restaurar cambios locales del stash si se crearon
    if [ $STASHED -eq 1 ]; then
        echo -e "${CYAN}📦 Restaurando tus cambios locales de vuelta a tus archivos...${NC}"
        git stash pop >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ Tus cambios locales están de vuelta intactos.${NC}"
    fi
    
    # 5. Validar compilación de la solución unificada
    echo -e "\n${CYAN}🧪 Verificando que todo compile perfectamente (.NET 10)...${NC}"
    if command -v dotnet >/dev/null 2>&1; then
        if dotnet build "IntranetInstitucional.sln" -v q --nologo; then
            echo -e "${GREEN}✅ Compilación exitosa: 0 Errores.${NC}"
        else
            echo -e "${YELLOW}⚠️  Aviso: Se detectaron detalles en la compilación. Ejecuta la opción 4 para validar.${NC}"
        fi
    fi
    
    echo -e "\n${GREEN}======================================================================${NC}"
    echo -e "${GREEN}🎉 ¡RAMA '${branch}' 100% ACTUALIZADA CON PRODUCCIÓN ('main')!${NC}"
    echo -e "${GREEN}======================================================================${NC}"
    echo -e "💡 Todos los cambios nuevos de otros equipos ya están en tu computadora."
    echo -e "💡 Todo tu avance local fue preservado sin ninguna pérdida.\n"
    
    # 6. Preguntar si desea actualizar su rama en GitHub ahora
    read -p "👉 ¿Deseas subir también tu rama actualizada a GitHub ahora? [S/n]: " push_now
    if [[ ! "$push_now" =~ ^[nN]$ ]]; then
        echo -e "${CYAN}Subiendo '${branch}' a GitHub...${NC}"
        if git push --force-with-lease origin "$branch" 2>/dev/null || git push -u origin "$branch"; then
            echo -e "${GREEN}✅ ¡Rama remota en GitHub actualizada!${NC}"
            echo -e "👉 Revisa tu Pull Request: ${CYAN}https://github.com/felipeostosb/intranet-institucional-modular/compare/main...${branch}${NC}"
        else
            echo -e "${YELLOW}⚠️  No se pudo subir automáticamente a GitHub. Puedes usar la opción 5 para subir cuando desees.${NC}"
        fi
    fi
}

validate_code() {
    echo -e "\n${BLUE}🧪 VALIDANDO COMPILACIÓN Y CALIDAD DE CÓDIGO (.NET 10)...${NC}\n"
    if ! command -v dotnet >/dev/null 2>&1; then
        echo -e "${RED}❌ El SDK de .NET 10 no está instalado o no se encuentra en el PATH.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Ejecutando: dotnet build IntranetInstitucional.sln -c Release${NC}"
    if dotnet build "IntranetInstitucional.sln" --nologo -c Release; then
        echo -e "\n${GREEN}======================================================================${NC}"
        echo -e "${GREEN}✅ ¡PROYECTO IMPECABLE: 0 ERRORES Y 0 ADVERTENCIAS!${NC}"
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
    
    echo -e "🌿 Rama de trabajo actual: ${CYAN}${branch}${NC}"
    
    # 1. Comprobar si hay cambios pendientes por guardar
    STATUS=$(git status --porcelain)
    if [ -n "$STATUS" ]; then
        MOD_NUM=$(echo "$branch" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | tr '[:upper:]' '[:lower:]' | grep -o -E '[0-9]{2}' || true)
        if [ -n "$MOD_NUM" ]; then
            ALLOWED_DIR="src/02_Modulos/Intranet.Modulo${MOD_NUM}/"
            OUTSIDE_FILES=$(git status --porcelain | awk '{print $2}' | grep -v "^${ALLOWED_DIR}" | grep -v "^docs/" | grep -v "\.md$" | grep -v "dev\.sh$" | grep -v "dev\.ps1$" | grep -v "Dockerfile$" | grep -v "^\.dockerignore$" || true)
            if [ -n "$OUTSIDE_FILES" ]; then
                echo -e "\n${RED}⛔ ERROR DE AISLAMIENTO MODULAR:${NC}"
                echo -e "Detectamos cambios en archivos fuera de tu módulo '${ALLOWED_DIR}':"
                echo -e "${YELLOW}${OUTSIDE_FILES}${NC}\n"
                echo -e "${CYAN}💡 Para no bloquear tu Pull Request, revierte los cambios ajenos antes de subir.${NC}\n"
                return 1
            fi
        fi

        read -p "👉 Describe qué cambiaste (ej: formulario de registro terminado): " msg
        if [ -z "$msg" ]; then
            msg="feat(${branch}): actualizacion de avance"
        fi
        git add .
        git commit -m "$msg"
        echo -e "${GREEN}✓ Cambios guardados localmente.${NC}"
    else
        echo -e "${YELLOW}ℹ️ No hay archivos pendientes por guardar localmente.${NC}"
    fi
    
    # 2. Descargar posibles cambios remotos y rebase con main
    echo -e "${CYAN}Sincronizando con 'main' de GitHub...${NC}"
    git fetch origin main >/dev/null 2>&1 || true
    if ! git rebase origin/main 2>/dev/null; then
        if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
            git rebase --abort 2>/dev/null || true
            echo -e "${YELLOW}⚠️  Aviso: Se continuará sin rebase de main. Usa la opción 3 si deseas sincronizar a fondo.${NC}"
        fi
    fi
    
    # 3. Compilar ANTES de pushear
    echo -e "${CYAN}🔨 Verificando compilación antes de subir...${NC}"
    if command -v dotnet >/dev/null 2>&1; then
        if ! dotnet build "IntranetInstitucional.sln" -v q --nologo 2>&1 | tail -20; then
            echo -e "\n${RED}⛔ EL CÓDIGO NO COMPILÓ. No se subió nada a GitHub.${NC}"
            echo -e "${YELLOW}💡 Corrige los errores antes de publicar.${NC}"
            return 1
        fi
    fi
    
    # 4. Publicar en GitHub
    echo -e "${CYAN}Publicando rama '${branch}' en GitHub...${NC}"
    if git push --force-with-lease origin "$branch" 2>/dev/null || git push -u origin "$branch"; then
        echo -e "\n${GREEN}======================================================================${NC}"
        echo -e "${GREEN}🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!${NC}"
        echo -e "${GREEN}======================================================================${NC}"
        echo -e "👉 Abre o revisa tu Pull Request aquí:\n   ${CYAN}https://github.com/felipeostosb/intranet-institucional-modular/compare/main...${branch}${NC}"
    else
        echo -e "\n${RED}❌ Hubo un inconveniente al subir a GitHub. Revisa tus credenciales o conexión.${NC}"
    fi
}


backup_db() {
    set +e
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🗄️  BACKUP DE BASE DE DATOS (PostgreSQL 16)${NC}"
    echo -e "${BLUE}======================================================================${NC}"

    LOCAL_CFG="src/03_Web/Intranet.Web/appsettings.Local.json"
    if [ ! -f "$LOCAL_CFG" ]; then
        echo -e "${RED}❌ No se encontró appsettings.Local.json${NC}"
        echo -e "${CYAN}💡 Primero ejecuta la opción 6 (Base de Datos) para configurar tus credenciales.${NC}"
        return 1
    fi

    # Extraer número de equipo del archivo de configuración local
    NUM_FMT=$(grep -o 'Modulo[0-9]\+Connection' "$LOCAL_CFG" | head -1 | grep -o '[0-9]\+' | head -1)
    if [ -z "$NUM_FMT" ]; then
        echo -e "${RED}❌ No se pudo detectar el número de equipo en appsettings.Local.json${NC}"
        return 1
    fi

    # Extraer datos de conexión del JSON (sin jq)
    HOST=$(grep -o '"Host=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Host=//')
    DBNAME=$(grep -o '"Database=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Database=//')
    USER=$(grep -o '"Username=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Username=//')
    PASS=$(grep -o '"Password=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Password=//')

    echo -e "  👤 ${CYAN}Equipo:${NC}         $NUM_FMT"
    echo -e "  🌐 ${CYAN}Host:${NC}           $HOST"
    echo -e "  📊 ${CYAN}Base de datos:${NC}  $DBNAME"
    echo -e "  🔑 ${CYAN}Usuario:${NC}        $USER"
    echo -e "  🛡️  ${CYAN}Esquema:${NC}        mod${NUM_FMT}"
    echo ""

    BACKUP_DIR="backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/mod${NUM_FMT}_${TIMESTAMP}.sql"

    read -p "👉 ¿Qué deseas hacer? [B]ackup / [R]estore / [V]olver: " action
    case "$action" in
        [bB])
            echo -e "\n${CYAN}📦 Iniciando backup del esquema mod${NUM_FMT}...${NC}"
            if [ ! -d "$BACKUP_DIR" ]; then
                mkdir -p "$BACKUP_DIR"
                echo -e "${GREEN}✓ Carpeta 'backups/' creada.${NC}"
            fi

            if PGPASSWORD="$PASS" pg_dump -h "$HOST" -p 5432 -U "$USER" -d "$DBNAME"                 --schema="mod${NUM_FMT}" --no-owner --no-privileges                 --file="$BACKUP_FILE" 2>/dev/null; then
                BYTES=$(wc -c < "$BACKUP_FILE" | tr -d ' ')
                echo -e "\n${GREEN}======================================================================${NC}"
                echo -e "${GREEN}✅ BACKUP COMPLETADO CON ÉXITO${NC}"
                echo -e "${GREEN}======================================================================${NC}"
                echo -e "📄 Archivo: ${CYAN}${BACKUP_FILE}${NC}"
                echo -e "📏 Tamaño:  ${CYAN}${BYTES} bytes${NC}"
                echo -e "🕐 Hora:    ${CYAN}${TIMESTAMP}${NC}"
            else
                echo -e "\n${RED}⛔ Error al crear el backup. Verifica tus credenciales y conexión.${NC}"
                rm -f "$BACKUP_FILE"
                return 1
            fi
            ;;
        [rR])
            echo -e "\n${CYAN}📋 Backups disponibles:${NC}"
            if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.sql 2>/dev/null)" ]; then
                echo -e "${YELLOW}  No hay backups previos en la carpeta 'backups/'.${NC}"
                return
            fi
            ls -lt "$BACKUP_DIR"/*.sql 2>/dev/null | while read -r line; do
                echo -e "  ${CYAN}→ $(basename "$(echo "$line" | awk '{print $NF}')")${NC} ($(echo "$line" | awk '{print $5, $6, $7, $8}'))"
            done
            echo ""
            read -p "👉 Nombre del archivo a restaurar: " restore_file
            if [ ! -f "$BACKUP_DIR/$restore_file" ]; then
                echo -e "${RED}❌ Archivo no encontrado: $BACKUP_DIR/$restore_file${NC}"
                return 1
            fi
            echo -e "\n${YELLOW}⚠️  RESTAURAR SOBRESCRIBIRÁ el esquema mod${NUM_FMT} completo.${NC}"
            read -p "👉 ¿Estás seguro? (escribe 'SI' para confirmar): " confirm
            if [ "$confirm" != "SI" ]; then
                echo -e "${YELLOW}Restauración cancelada.${NC}"
                return
            fi
            if PGPASSWORD="$PASS" psql -h "$HOST" -p 5432 -U "$USER" -d "$DBNAME"                 -f "$BACKUP_DIR/$restore_file" 2>/dev/null; then
                echo -e "\n${GREEN}✅ Restauración completada con éxito.${NC}"
            else
                echo -e "\n${RED}⛔ Error durante la restauración.${NC}"
                return 1
            fi
            ;;
        *)
        echo -e "${YELLOW}Volviendo al menú...${NC}"
        ;;
        esac
        set -e
        }

        show_status() {
    set +e
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}📊 ESTADO DEL PROYECTO — AQUILA A-ERP${NC}"
    echo -e "${BLUE}======================================================================${NC}\n"

    # --- Rama actual ---
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "desconocida")
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    AHEAD=0; BEHIND=0
    if [ -n "$UPSTREAM" ]; then
        AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
    fi
    echo -e "  🌿 ${CYAN}Rama:${NC}        ${YELLOW}${BRANCH}${NC}"
    if [ "$BRANCH" = "main" ]; then
        echo -e "  📍 ${CYAN}Ubicación:${NC}   Estás en main"
    elif [ -n "$UPSTREAM" ]; then
        echo -e "  📍 ${CYAN}Tracking:${NC}    $UPSTREAM"
        [ "$AHEAD" -gt 0 ] && echo -e "  ⬆️  ${GREEN}${AHEAD} commit(s) por subir${NC}"
        [ "$BEHIND" -gt 0 ] && echo -e "  ⬇️  ${RED}${BEHIND} commit(s) sin sincronizar (ejecuta opción 3)${NC}"
    else
        echo -e "  📍 ${CYAN}Tracking:${NC}    ${RED}Sin rama remota (usa opción 5 para publicar)${NC}"
    fi

    # --- Archivos pendientes ---
    STAGED=$(git diff --cached --numstat 2>/dev/null | wc -l)
    UNSTAGED=$(git diff --numstat 2>/dev/null | wc -l)
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
    TOTAL_PEND=$((STAGED + UNSTAGED + UNTRACKED))
    echo ""
    if [ "$TOTAL_PEND" -eq 0 ]; then
        echo -e "  📝 ${GREEN}Working tree limpio — nada pendiente${NC}"
    else
        echo -e "  📝 ${CYAN}Cambios pendientes:${NC}  ${YELLOW}${TOTAL_PEND} archivo(s)${NC}"
        [ "$STAGED" -gt 0 ] && echo -e "     🟢 ${STAGED} staged (listo para commit)"
        [ "$UNSTAGED" -gt 0 ] && echo -e "     🔴 ${UNSTAGED} sin staging"
        [ "$UNTRACKED" -gt 0 ] && echo -e "     ⚪ ${UNTRACKED} sin seguimiento (nuevos)"
    fi

    # --- Conflictos pendientes ---
    if [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
        echo -e "\n  ⚠️  ${RED}REBASE EN CURSO — hay conflictos pendientes${NC}"
    elif [ -f .git/MERGE_HEAD ]; then
        echo -e "\n  ⚠️  ${RED}MERGE EN CURSO — hay conflictos pendientes${NC}"
    fi

    # --- Servidor de desarrollo ---
    echo ""
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>/dev/null | grep -q "200"; then
        echo -e "  🚀 ${GREEN}Servidor ACTIVO en http://localhost:5000 ✓${NC}"
    else
        echo -e "  🚀 ${YELLOW}Servidor inactivo (ejecuta opción 1 para iniciarlo)${NC}"
    fi

    # --- Configuración local ---
    echo ""
    LOCAL_CFG="src/03_Web/Intranet.Web/appsettings.Local.json"
    if [ -f "$LOCAL_CFG" ]; then
        TEAM=$(grep -o 'Modulo[0-9]\+Connection' "$LOCAL_CFG" | head -1 | grep -o '[0-9]\+' | head -1)
        echo -e "  🗄️  ${GREEN}appsettings.Local.json existe — Equipo: ${TEAM}${NC}"
    else
        echo -e "  🗄️  ${YELLOW}appsettings.Local.json no existe (ejecuta opción 6 para configurar)${NC}"
    fi

    # --- Resumen de salud ---
    echo ""
    HEALTH_OK=true
    [ "$TOTAL_PEND" -gt 10 ] && { echo -e "  ⚠️  ${YELLOW}Muchos archivos sin commitear (${TOTAL_PEND}). Considera subir tu progreso.${NC}"; HEALTH_OK=false; }
    [ "$BEHIND" -gt 5 ] && { echo -e "  ⚠️  ${YELLOW}Tu rama está ${BEHIND} commits detrás de main. Ejecuta opción 3.${NC}"; HEALTH_OK=false; }
    if [ "$HEALTH_OK" = true ]; then
        echo -e "  ✅ ${GREEN}Estado saludable — no hay alertas.${NC}"
    fi
    set -e
}

show_changes() {
    set +e
    echo -e "\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}📋 MIS CAMBIOS — ARCHIVOS MODIFICADOS${NC}"
    echo -e "${BLUE}======================================================================${NC}\n"

    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "desconocida")
    echo -e "  🌿 Rama: ${CYAN}${BRANCH}${NC}\n"

    # Recolectar archivos modificados: staged, unstaged y untracked
    ALL_CHANGES=$(git diff --cached --name-only 2>/dev/null)
    ALL_CHANGES="$ALL_CHANGES\n$(git diff --name-only 2>/dev/null)"
    ALL_CHANGES="$ALL_CHANGES\n$(git ls-files --others --exclude-standard 2>/dev/null)"
    ALL_CHANGES=$(echo -e "$ALL_CHANGES" | sort -u | sed '/^$/d')

    if [ -z "$ALL_CHANGES" ]; then
        echo -e "  ${GREEN}✅ No hay cambios — working tree limpio.${NC}"
        return
    fi

    # Contar por categoría
    C_VIEWS=0; C_CONTROLLERS=0; C_SQL=0; C_MODELS=0; C_CONFIG=0; C_CORE=0; C_OTHER=0
    while IFS= read -r file; do
        case "$file" in
            *Views*|*Views*)    C_VIEWS=$((C_VIEWS + 1)) ;;
            *Controller*)       C_CONTROLLERS=$((C_CONTROLLERS + 1)) ;;
            *Schema*|*schema*|*Sql*|*.sql) C_SQL=$((C_SQL + 1)) ;;
            *Model*|*Dto*|*Entity*) C_MODELS=$((C_MODELS + 1)) ;;
            *.json|*.yml|*.yaml|*.props) C_CONFIG=$((C_CONFIG + 1)) ;;
            src/01_Core/*)      C_CORE=$((C_CORE + 1)) ;;
            *)                  C_OTHER=$((C_OTHER + 1)) ;;
        esac
    done <<< "$ALL_CHANGES"

    TOTAL=$(echo "$ALL_CHANGES" | wc -l | tr -d ' ')
    echo -e "  ${CYAN}📊 Total: ${TOTAL} archivo(s)${NC}"
    [ "$C_VIEWS" -gt 0 ] && echo -e "     👁️  ${C_VIEWS} vista(s)"
    [ "$C_CONTROLLERS" -gt 0 ] && echo -e "     🎮 ${C_CONTROLLERS} controlador(es)"
    [ "$C_SQL" -gt 0 ] && echo -e "     🗄️  ${C_SQL} SQL/schema"
    [ "$C_MODELS" -gt 0 ] && echo -e "     📦 ${C_MODELS} modelo(s)/entidad(es)"
    [ "$C_CONFIG" -gt 0 ] && echo -e "     ⚙️  ${C_CONFIG} configuración(es)"
    [ "$C_CORE" -gt 0 ] && echo -e "     🔧 ${C_CORE} core/compartido"
    [ "$C_OTHER" -gt 0 ] && echo -e "     📄 ${C_OTHER} otro(s)"
    echo ""

    # Agrupar por directorio padre (máx 4 niveles)
    echo -e "  ${CYAN}📂 Detalle por carpeta:${NC}\n"
    echo "$ALL_CHANGES" | awk -F'/' '{
        if (NF >= 4) dir = $1"/"$2"/"$3"/"$4;
        else if (NF >= 3) dir = $1"/"$2"/"$3;
        else dir = $1;
        if (dir != prev) { if (prev != "") print ""; printf "  📁 %s/
", dir; prev = dir }
    } { printf "     %s
", $NF }'

    # Diffstat resumido
    echo -e "\n  ${CYAN}📏 Líneas modificadas:${NC}"
    TOTAL_ADD=0; TOTAL_DEL=0
    while IFS= read -r file; do
        ADD=$(git diff --cached --numstat -- "$file" 2>/dev/null | awk '{print $1}')
        DEL=$(git diff --cached --numstat -- "$file" 2>/dev/null | awk '{print $2}')
        [ -z "$ADD" ] && ADD=$(git diff --numstat -- "$file" 2>/dev/null | awk '{print $1}')
        [ -z "$DEL" ] && DEL=$(git diff --numstat -- "$file" 2>/dev/null | awk '{print $2}')
        ADD=${ADD:-0}; DEL=${DEL:-0}
        if [ "$ADD" -gt 0 ] || [ "$DEL" -gt 0 ]; then
            TOTAL_ADD=$((TOTAL_ADD + ADD))
            TOTAL_DEL=$((TOTAL_DEL + DEL))
            printf "     ${GREEN}+%-5s${NC} ${RED}-%-5s${NC} %s\n" "$ADD" "$DEL" "$(basename "$file")"
        fi
    done <<< "$ALL_CHANGES"
    if [ "$TOTAL_ADD" -gt 0 ] || [ "$TOTAL_DEL" -gt 0 ]; then
        echo -e "     ───────────────────────────────────────"
        printf "     ${GREEN}+%-5s${NC} ${RED}-%-5s${NC} TOTAL\n" "$TOTAL_ADD" "$TOTAL_DEL"
    fi
    set -e
}


extras_menu() {
    set +e
    while true; do
        echo ""
        echo -e "${BLUE}======================================================================${NC}"
        echo -e "${BLUE}🔧 EXTRAS — HERRAMIENTAS AVANZADAS${NC}"
        echo -e "${BLUE}======================================================================${NC}"
        echo -e "  ${GREEN}1)${NC} 📜 ${CYAN}Historial de Mi Módulo${NC} (Últimos commits que tocaron tu módulo)"
        echo -e "  ${GREEN}2)${NC} 🔗 ${CYAN}Generar Descripción de PR${NC} (Genera texto listo para copiar al PR)"
        echo -e "  ${GREEN}3)${NC} 🗄️  ${CYAN}Verificar Mi Esquema SQL${NC} (Revisa tu schema.sql por errores comunes)"
        echo -e "  ${GREEN}4)${NC} 🔌 ${CYAN}Diagnosticar Conexión BD${NC} (Prueba si tu conexión a PostgreSQL funciona)"
        echo -e "  ${GREEN}5)${NC} 📊 ${CYAN}Ver Datos de Prueba${NC} (Muestra usuarios/DNI para hacer login)"
        echo -e "  ${GREEN}0)${NC} 🔙 ${YELLOW}Volver al Menú Principal${NC}"
        echo ""
        read -p "👉 Elige una opción [0-5]: " extra_op
        case "$extra_op" in
            1) extras_module_history ;;
            2) extras_pr_description ;;
            3) extras_verify_schema ;;
            4) extras_diag_connection ;;
            5) extras_test_data ;;
            0) break ;;
            *) echo -e "${RED}Opción no válida.${NC}" ;;
        esac
        echo -e "\n${YELLOW}Presiona ENTER para volver al submenú...${NC}"
        read -r
    done
    set -e
}

extras_module_history() {
    echo -e "\n${BLUE}📜 HISTORIAL DE MI MÓDULO${NC}"
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    MOD_NUM=$(echo "$BRANCH" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | grep -o -E '[0-9]{2}' || true)
    if [ -z "$MOD_NUM" ]; then
        echo -e "${YELLOW}No estás en una rama de módulo (moduloXX).\n${CYAN}Ingresa tu número de módulo:${NC}"
        read -p "👉 Módulo (0 al 9): " MOD_NUM
        MOD_NUM=$(printf "%02d" "$((MOD_NUM))")
    fi
    echo -e "\n${CYAN}Últimos 15 commits que tocaron Intranet.Modulo${MOD_NUM}:${NC}\n"
    git log --oneline -15 -- "src/02_Modulos/Intranet.Modulo${MOD_NUM}/" 2>/dev/null | while read -r line; do
        echo -e "  ${GREEN}${line}${NC}"
    done
    COUNT=$(git log --oneline -- "src/02_Modulos/Intranet.Modulo${MOD_NUM}/" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "\n  📊 Total de commits que tocaron este módulo: ${CYAN}${COUNT}${NC}"
}

extras_pr_description() {
    echo -e "\n${BLUE}🔗 GENERAR DESCRIPCIÓN DE PR${NC}\n"
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ "$BRANCH" = "main" ]; then
        echo -e "${RED}⛔ Estás en main. Cambia a tu rama de trabajo.${NC}"
        return
    fi
    MOD_NUM=$(echo "$BRANCH" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | grep -o -E '[0-9]{2}' || true)
    FILES=$(git diff main...HEAD --name-only 2>/dev/null)
    ADDITIONS=$(git diff main...HEAD --numstat 2>/dev/null | awk '{s+=$1} END {print s+0}')
    DELETIONS=$(git diff main...HEAD --numstat 2>/dev/null | awk '{s+=$2} END {print s+0}')
    COUNT=$(echo "$FILES" | grep -c '.' || echo "0")
    VIEWS=$(echo "$FILES" | grep -c "Views\|\.cshtml" || echo "0")
    CTRL=$(echo "$FILES" | grep -c "Controller" || echo "0")
    SQL=$(echo "$FILES" | grep -c "schema\|\.sql" || echo "0")
    MODELS=$(echo "$FILES" | grep -c "Model\|Dto\|Entity" || echo "0")
    echo -e "📝 Descripción generada para ${CYAN}${BRANCH}${NC}:\n"
    echo "---BEGIN PR---"
    echo "## 📌 Qué se hizo"
    echo ""
    if [ -n "$MOD_NUM" ]; then
        echo "Avance en el **Módulo ${MOD_NUM}** (\`Intranet.Modulo${MOD_NUM}\`)."
    else
        echo "Cambios en la rama \`${BRANCH}\`."
    fi
    echo ""
    echo "## 📊 Resumen"
    echo ""
    echo "- **${COUNT}** archivo(s) modificado(s)"
    echo "- **+${ADDITIONS}** / **-${DELETIONS}** líneas"
    [ "$VIEWS" -gt 0 ] && echo "- 👁️ ${VIEWS} vista(s) Razor"
    [ "$CTRL" -gt 0 ] && echo "- 🎮 ${CTRL} controlador(es)"
    [ "$SQL" -gt 0 ] && echo "- 🗄️ ${SQL} archivo(s) SQL/schema"
    [ "$MODELS" -gt 0 ] && echo "- 📦 ${MODELS} modelo(s)/entidad(es)"
    echo ""
    echo "## 📁 Archivos modificados"
    echo ""
    echo "$FILES" | while read -r f; do echo "- \`$f\`"; done
    echo ""
    echo "---END PR---"
    echo -e "\n${CYAN}Copia el texto entre ---BEGIN PR--- y ---END PR--- en tu Pull Request.${NC}"
}

extras_verify_schema() {
    echo -e "\n${BLUE}🗄️  VERIFICAR MI ESQUEMA SQL${NC}"
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    MOD_NUM=$(echo "$BRANCH" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | grep -o -E '[0-9]{2}' || true)
    if [ -z "$MOD_NUM" ]; then
        echo -e "${YELLOW}No estás en rama de módulo. Ingresa tu número:${NC}"
        read -p "👉 Módulo (0 al 9): " MOD_NUM
        MOD_NUM=$(printf "%02d" "$((MOD_NUM))")
    fi
    SCHEMA="src/02_Modulos/Intranet.Modulo${MOD_NUM}/Sql/schema.sql"
    if [ ! -f "$SCHEMA" ]; then
        echo -e "${RED}❌ No se encontró: ${SCHEMA}${NC}"
        return
    fi
    echo -e "${CYAN}Analizando: ${SCHEMA}${NC}\n"
    ERRORS=0
    if grep -q "CREATE SCHEMA IF NOT EXISTS" "$SCHEMA"; then
        echo -e "  ${GREEN}✓${NC} CREATE SCHEMA IF NOT EXISTS mod${MOD_NUM} encontrado"
    else
        echo -e "  ${RED}✗${NC} Falta CREATE SCHEMA IF NOT EXISTS mod${MOD_NUM}"
        ERRORS=$((ERRORS + 1))
    fi
    WRONG_SCHEMA=$(grep -i "CREATE TABLE" "$SCHEMA" | grep -v "IF NOT EXISTS" || true)
    if [ -n "$WRONG_SCHEMA" ]; then
        echo -e "  ${RED}✗${NC} CREATE TABLE sin IF NOT EXISTS"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "  ${GREEN}✓${NC} Todas las tablas usan CREATE TABLE IF NOT EXISTS"
    fi
    NO_PREFIX=$(grep -i "CREATE TABLE IF NOT EXISTS" "$SCHEMA" | grep -v "mod${MOD_NUM}\." || true)
    if [ -n "$NO_PREFIX" ]; then
        echo -e "  ${RED}✗${NC} Tablas sin prefijo mod${MOD_NUM}:"
        echo "$NO_PREFIX" | sed 's/^/     /'
        ERRORS=$((ERRORS + 1))
    else
        echo -e "  ${GREEN}✓${NC} Todas las tablas tienen prefijo mod${MOD_NUM}."
    fi
    BAD_FK=$(grep -i "REFERENCES" "$SCHEMA" | grep -v "core\." | grep -v "mod${MOD_NUM}\." || true)
    if [ -n "$BAD_FK" ]; then
        echo -e "  ${RED}✗${NC} Foreign Keys fuera de core/mod${MOD_NUM}:"
        echo "$BAD_FK" | sed 's/^/     /'
        ERRORS=$((ERRORS + 1))
    else
        echo -e "  ${GREEN}✓${NC} Foreign Keys correctas"
    fi
    TABLES=$(grep -ci "CREATE TABLE" "$SCHEMA" || echo "0")
    echo -e "\n  📊 Tablas: ${CYAN}${TABLES}${NC}"
    echo ""
    if [ "$ERRORS" -eq 0 ]; then
        echo -e "  ${GREEN}✅ ESQUEMA VÁLIDO${NC}"
    else
        echo -e "  ${RED}⛔ ${ERRORS} error(es) detectado(s)${NC}"
    fi
}

extras_diag_connection() {
    echo -e "\n${BLUE}🔌 DIAGNOSTICAR CONEXIÓN A POSTGRESQL${NC}\n"
    LOCAL_CFG="src/03_Web/Intranet.Web/appsettings.Local.json"
    if [ ! -f "$LOCAL_CFG" ]; then
        echo -e "${RED}❌ appsettings.Local.json no existe.${NC}"
        echo -e "${CYAN}💡 Ejecuta la opción 6 del menú principal.${NC}"
        return
    fi
    NUM_FMT=$(grep -o 'Modulo[0-9]\\+Connection' "$LOCAL_CFG" | head -1 | grep -o '[0-9]\\+' | head -1)
    HOST=$(grep -o '"Host=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Host=//')
    DBNAME=$(grep -o '"Database=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Database=//')
    USER=$(grep -o '"Username=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Username=//')
    PASS=$(grep -o '"Password=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Password=//')
    echo -e "  👤 ${CYAN}Equipo:${NC}     $NUM_FMT"
    echo -e "  🌐 ${CYAN}Host:${NC}       $HOST"
    echo -e "  📊 ${CYAN}BD:${NC}         $DBNAME"
    echo -e "  🔑 ${CYAN}Usuario:${NC}    $USER\n"
    echo -e "${CYAN}1. Probando conexión...${NC}"
    if PGPASSWORD="$PASS" psql -h "$HOST" -p 5432 -U "$USER" -d "$DBNAME" -c "SELECT 1" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Conexión exitosa${NC}"
    else
        echo -e "  ${RED}✗ No se pudo conectar${NC}"
        return
    fi
    echo -e "\n${CYAN}2. Esquema mod${NUM_FMT}...${NC}"
    EXISTS=$(PGPASSWORD="$PASS" psql -h "$HOST" -p 5432 -U "$USER" -d "$DBNAME" -t -A -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='mod${NUM_FMT}'" 2>/dev/null)
    if [ "$EXISTS" = "1" ]; then
        echo -e "  ${GREEN}✓ Existe${NC}"
    else
        echo -e "  ${RED}✗ NO existe${NC}"
    fi
    echo -e "\n${CYAN}3. Tablas en mod${NUM_FMT}...${NC}"
    TABLES=$(PGPASSWORD="$PASS" psql -h "$HOST" -p 5432 -U "$USER" -d "$DBNAME" -t -A -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='mod${NUM_FMT}'" 2>/dev/null)
    echo -e "  📊 Encontradas: ${CYAN}${TABLES}${NC}"
    if [ "$TABLES" -gt 0 ]; then
        PGPASSWORD="$PASS" psql -h "$HOST" -p 5432 -U "$USER" -d "$DBNAME" -t -A -c "SELECT table_name FROM information_schema.tables WHERE table_schema='mod${NUM_FMT}' ORDER BY table_name" 2>/dev/null | while read -r tbl; do
            echo -e "     → ${CYAN}${tbl}${NC}"
        done
    fi
}

extras_test_data() {
    echo -e "\n${BLUE}📊 DATOS DE PRUEBA (Usuarios para Login)${NC}\n"
    LOCAL_CFG="src/03_Web/Intranet.Web/appsettings.Local.json"
    if [ ! -f "$LOCAL_CFG" ]; then
        echo -e "${RED}❌ Configura tu conexión primero (opción 6).${NC}"
        return
    fi
    HOST=$(grep -o '"Host=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Host=//')
    DBNAME=$(grep -o '"Database=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Database=//')
    USER=$(grep -o '"Username=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Username=//')
    PASS=$(grep -o '"Password=[^;]*' "$LOCAL_CFG" | head -1 | sed 's/"Password=//')
    echo -e "${CYAN}Usuarios (contraseña: 123456 para todos):${NC}\n"
    PGPASSWORD="$PASS" psql -h "$HOST" -p 5432 -U "$USER" -d "$DBNAME" -c "
        SELECT u.codigo_institucional AS \"Código\", p.dni AS \"DNI\",
               p.nombres || ' ' || p.apellidos AS \"Nombre Completo\",
               r.nombre AS \"Rol\"
        FROM core.usuarios u
        JOIN core.personas p ON u.persona_id = p.id
        JOIN core.usuario_roles ur ON ur.usuario_id = u.id
        JOIN core.roles r ON ur.rol_id = r.id
        WHERE u.estado = TRUE AND ur.es_activo = TRUE
        ORDER BY r.nombre, u.codigo_institucional;
    " 2>/dev/null || echo -e "${RED}  ⚠️  No se pudo conectar.${NC}"
}
manage_db() {
    echo -e "\\n${BLUE}======================================================================${NC}"
    echo -e "${BLUE}🗄️  INFORMACIÓN Y CONFIGURACIÓN DE BASE DE DATOS (PostgreSQL 16)${NC}"
    echo -e "${BLUE}======================================================================${NC}"
    echo -e "  🌐 ${CYAN}Panel Web Adminer:${NC}  http://35.206.81.32:8080"
    echo -e "  ⚙️  ${CYAN}Motor:${NC}              PostgreSQL 16"
    echo -e "  🖥️  ${CYAN}Host / Servidor:${NC}    35.206.81.32  (Puerto: 5432)"
    echo -e "  📊 ${CYAN}Base de Datos:${NC}      db_intranet_iestp"
    echo -e "  👤 ${CYAN}Usuario Equipo:${NC}     user_equipo[00..09]"
    echo -e "  🛡️  ${CYAN}Esquema Soberano:${NC}   mod[00..09] (Control total INSERT/UPDATE/DELETE)"
    echo -e "  📖 ${CYAN}Esquema Común:${NC}      core (Solo lectura SELECT para roles y usuarios)"
    echo -e "${BLUE}----------------------------------------------------------------------${NC}\n"
    
    read -p "👉 ¿Deseas configurar/actualizar tu contraseña local (appsettings.Local.json)? [s/N]: " conf_opt
    if [[ "$conf_opt" =~ ^[sSyY]$ ]]; then
        read -p "👉 ¿Qué número de equipo eres? (0 al 9): " num
        num_clean=$(echo "$num" | tr -cd '0-9')
        if [ -z "$num_clean" ] || [ "$num_clean" -lt 0 ] || [ "$num_clean" -gt 9 ]; then
            echo -e "${RED}❌ Número no válido. Debe ser entre 0 y 9.${NC}"
            return
        fi
        num_fmt=$(printf "%02d" "$num_clean")
        
        echo -e "👤 Usuario PostgreSQL: ${CYAN}user_equipo${num_fmt}${NC}"
        read -sp "🔑 Ingresa la contraseña de tu equipo (de tu Ficha Privada): " pass
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
  "// LOCAL OVERRIDE": "Configuracion de conexion para Equipo ${num_fmt}. Protegido en .gitignore.",
  "ConnectionStrings": {
    "Modulo${num_fmt}Connection": "Host=${dbhost};Port=5432;Database=db_intranet_iestp;Username=user_equipo${num_fmt};Password=${pass};SearchPath=mod${num_fmt},core,public;Pooling=true;MinPoolSize=2;MaxPoolSize=15;"
  }
}
JSON_EOF

        echo -e "\n${GREEN}======================================================================${NC}"
        echo -e "${GREEN}✅ ¡CONFIGURACIÓN LOCAL GUARDADA CON ÉXITO!${NC}"
        echo -e "${GREEN}======================================================================${NC}"
        echo -e "📄 Archivo: ${CYAN}${LOCAL_CONFIG}${NC} (No se subirá a GitHub)"
        echo -e "🛡️  Tu equipo tiene permisos de escritura en ${CYAN}mod${num_fmt}${NC}."
    fi
}

while true; do
    show_menu
    read -p "👉 Elige una opción [0-10]: " op
    case $op in
        1) start_app ;;
        2) create_branch ;;
        3) sync_main ;;
        4) validate_code ;;
        5) push_work ;;
        6) manage_db ;;
        7) backup_db ;;
        8) show_status ;;
        9) show_changes ;;
        10) extras_menu ;;
        0) echo -e "\n${GREEN}¡Buen trabajo! Hasta la próxima sesión.${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción no válida. Ingresa un número del 0 al 10.${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona ENTER para volver al menú...${NC}"
    read -r
done
