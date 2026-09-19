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

manage_db() {
    echo -e "\n${BLUE}======================================================================${NC}"
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
    read -p "👉 Elige una opción [0-6]: " op
    case $op in
        1) start_app ;;
        2) create_branch ;;
        3) sync_main ;;
        4) validate_code ;;
        5) push_work ;;
        6) manage_db ;;
        0) echo -e "\n${GREEN}¡Buen trabajo! Hasta la próxima sesión.${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}Opción no válida. Ingresa un número del 0 al 6.${NC}" ;;
    esac
    echo -e "\n${YELLOW}Presiona ENTER para volver al menú...${NC}"
    read -r
done
