# ==============================================================================
# 🦅 AQUILA A-ERP — ASISTENTE DEV EN POWERSHELL (WINDOWS)
# Intranet Institucional IESTP Argentina • .NET 10 LTS • PostgreSQL 16
# ==============================================================================

$ErrorActionPreference = "Stop"

# Instalar guardianes locales contra push directo a 'main' y aislamiento modular
if (Test-Path .git) {
    $hookDir = ".git/hooks"
    if (-not (Test-Path $hookDir)) { New-Item -ItemType Directory -Path $hookDir | Out-Null }
    
    # 1. Pre-push hook
    $hookPush = "$hookDir/pre-push"
    if (-not (Test-Path $hookPush)) {
        $hookScriptPush = @"
#!/usr/bin/env bash
BRANCH=`$(git rev-parse --abbrev-ref HEAD)
if [ "`$BRANCH" = "main" ]; then
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer push directo a 'main'. Usa una rama de equipo (moduloXX/tarea).\033[0m"
    exit 1
fi
exit 0
"@
        Set-Content -Path $hookPush -Value $hookScriptPush -NoNewline
    }

    # 2. Pre-commit hook
    $hookCommit = "$hookDir/pre-commit"
    if (-not (Test-Path $hookCommit)) {
        $hookScriptCommit = @"
#!/usr/bin/env bash
BRANCH=`$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [ "`$BRANCH" = "main" ]; then
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer commit directo en 'main'. Usa una rama de equipo.\033[0m"
    exit 1
fi

MOD_NUM=`$(echo "`$BRANCH" | grep -o -E 'modulo-?[0-9]{2}' | tr -d '-' | tr '[:upper:]' '[:lower:]' | grep -o -E '[0-9]{2}' || true)
if [ -n "`$MOD_NUM" ]; then
    ALLOWED_DIR="src/02_Modulos/Intranet.Modulo`$MOD_NUM/"
    STAGED_FILES=`$(git diff --cached --name-only)
    VIOLATIONS=0
    for file in `$STAGED_FILES; do
        if [[ "`$file" != "`$ALLOWED_DIR"* ]] && [[ "`$file" != "docs/"* ]] && [[ "`$file" != *.md ]] && [[ "`$file" != "dev.sh" ]] && [[ "`$file" != "dev.ps1" ]]; then
            echo -e "\033[1;31m❌ VIOLACIÓN DE LÍMITES MODULARES (Zero-Blast-Radius):\033[0m"
            echo -e "   El archivo '`$file' está fuera de tu módulo '`$ALLOWED_DIR'."
            VIOLATIONS=`$((VIOLATIONS + 1))
        fi
    done
    if [ `$VIOLATIONS -gt 0 ]; then
        echo -e "\033[1;31m⛔ COMMIT BLOQUEADO: Solo puedes modificar archivos en `$ALLOWED_DIR\033[0m"
        exit 1
    fi
fi
exit 0
"@
        Set-Content -Path $hookCommit -Value $hookScriptCommit -NoNewline
    }
}

function Show-Menu {
    Clear-Host
    $currentBranch = $(git rev-parse --abbrev-ref HEAD 2>$null)
    if (-not $currentBranch) { $currentBranch = "desconocida" }
    
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "🦅 AQUILA A-ERP — INTRANET INSTITUCIONAL IESTP ARGENTINA" -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  Plataforma .NET 10 LTS • PostgreSQL 16 • 10 Módulos (00 - 09)" -ForegroundColor Cyan
    Write-Host "  🌿 Rama actual: $currentBranch" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------------" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  1) 🚀 Iniciar Intranet (Ver cambios en vivo con Hot-Reload en http://localhost:5000)" -ForegroundColor Green
    Write-Host "  2) 🌿 Mi Rama de Equipo (Crear o cambiar a tu rama modulo00..modulo09)" -ForegroundColor Green
    Write-Host "  3) 🧪 Compilar y Validar (Verifica 0 errores en toda la solución .NET 10)" -ForegroundColor Green
    Write-Host "  4) 📤 Subir a GitHub (Guarda cambios, sincroniza y genera enlace de PR)" -ForegroundColor Green
    Write-Host "  5) 🗄️  Base de Datos PostgreSQL (Credenciales Adminer y Configuración Local)" -ForegroundColor Green
    Write-Host "  0) 🚪 Salir" -ForegroundColor Red
    Write-Host ""
}

function Start-App {
    Write-Host "`n🚀 Iniciando Aquila A-ERP en tu navegador (http://localhost:5000)..." -ForegroundColor Blue
    dotnet watch --project src/03_Web/Intranet.Web --urls http://localhost:5000
}

function Create-Branch {
    Write-Host "`n🌿 CONFIGURAR RAMA DE TRABAJO (EQUIPOS 00 AL 09)" -ForegroundColor Blue
    $num = Read-Host "👉 ¿Qué número de equipo eres? (0 al 9)"
    
    if (-not [int]::TryParse($num, [ref]$null)) {
        Write-Host "❌ Debes ingresar un número válido." -ForegroundColor Red
        return
    }
    
    $numInt = [int]$num
    if ($numInt -lt 0 -or $numInt -gt 9) {
        Write-Host "❌ Número fuera de rango. Debe ser entre 0 y 9." -ForegroundColor Red
        return
    }
    
    $numFmt = "{0:D2}" -f $numInt
    $tarea = Read-Host "👉 ¿Qué tarea vas a realizar? (ej: login-seguridad, asistencia-alumnos)"
    if ([string]::IsNullOrWhiteSpace($tarea)) { $tarea = "avance" }
    
    $tarea = $tarea.ToLower() -replace '[^a-z0-9-]', '-'
    $branch = "modulo$numFmt/$tarea"
    
    $branchExists = git branch --list $branch
    if ($branchExists) {
        Write-Host "`nCambiando a tu rama existente: $branch..." -ForegroundColor Cyan
        git checkout $branch
    } else {
        Write-Host "`nSincronizando con 'main' antes de crear la rama..." -ForegroundColor Cyan
        git checkout main 2>$null | Out-Null
        git pull origin main 2>$null | Out-Null
        git checkout -b $branch
        Write-Host "`n✅ ¡Rama creada con éxito: $branch!" -ForegroundColor Green
    }
    
    Write-Host "🔒 Guardián Activado: Solo puedes modificar archivos en: src/02_Modulos/Intranet.Modulo$numFmt/" -ForegroundColor Yellow
}

function Validate-Code {
    Write-Host "`n🧪 VALIDANDO COMPILACIÓN Y CALIDAD DE CÓDIGO (.NET 10)...`n" -ForegroundColor Blue
    dotnet build "IntranetInstitucional.sln" --nologo -c Release
}

function Push-Work {
    Write-Host "`n📤 SUBIR Y SINCRONIZAR MI TRABAJO CON GITHUB" -ForegroundColor Blue
    $branch = $(git rev-parse --abbrev-ref HEAD)
    
    if ($branch -eq "main") {
        Write-Host "⛔ Estás en 'main'. Usa la opción 2 para crear o cambiar a tu rama antes de subir." -ForegroundColor Red
        return
    }
    
    Write-Host "🌿 Rama de trabajo actual: $branch" -ForegroundColor Cyan
    
    $msg = Read-Host "👉 Describe qué cambiaste (ej: avance del formulario)"
    if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "feat($branch): actualizacion de avance" }
    
    git add .
    git commit -m "$msg"
    git pull --rebase origin $branch 2>$null
    
    Write-Host "`n🔨 Verificando compilación..." -ForegroundColor Cyan
    dotnet build "IntranetInstitucional.sln" -v q --nologo
    
    Write-Host "Publicando en GitHub..." -ForegroundColor Cyan
    git push -u origin $branch
    
    Write-Host "`n🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!" -ForegroundColor Green
    Write-Host "👉 Abre tu Pull Request en: https://github.com/felipeostosb/intranet-institucional-modular/compare/main...$branch" -ForegroundColor Cyan
}

function Manage-Db {
    Write-Host "`n======================================================================" -ForegroundColor Blue
    Write-Host "🗄️  INFORMACIÓN Y CONFIGURACIÓN DE BASE DE DATOS (PostgreSQL 16)" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  🌐 Panel Web Adminer:  http://35.206.81.32:8080" -ForegroundColor Cyan
    Write-Host "  ⚙️  Motor:              PostgreSQL 16" -ForegroundColor Cyan
    Write-Host "  🖥️  Host / Servidor:    35.206.81.32  (Puerto: 5432)" -ForegroundColor Cyan
    Write-Host "  📊 Base de Datos:      db_intranet_iestp" -ForegroundColor Cyan
    Write-Host "  👤 Usuario Equipo:     user_equipo[00..09]" -ForegroundColor Cyan
    Write-Host "  🛡️  Esquema Soberano:   mod[00..09] (Control total INSERT/UPDATE/DELETE)" -ForegroundColor Cyan
    Write-Host "  📖 Esquema Común:      core (Solo lectura SELECT para roles y usuarios)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------------" -ForegroundColor Blue
    
    $confOpt = Read-Host "👉 ¿Deseas configurar/actualizar tu contraseña local (appsettings.Local.json)? [s/N]"
    if ($confOpt -match "^[sSyY]$") {
        $num = Read-Host "👉 ¿Qué número de equipo eres? (0 al 9)"
        $numInt = [int]$num
        if ($numInt -lt 0 -or $numInt -gt 9) {
            Write-Host "❌ Número no válido. Debe ser entre 0 y 9." -ForegroundColor Red
            return
        }
        $numFmt = "{0:D2}" -f $numInt
        
        Write-Host "👤 Usuario PostgreSQL asignado: user_equipo$numFmt" -ForegroundColor Cyan
        $pass = Read-Host "🔑 Ingresa la contraseña de tu equipo (de tu Ficha Privada)"
        
        if ([string]::IsNullOrWhiteSpace($pass)) {
            Write-Host "❌ La contraseña no puede estar vacía." -ForegroundColor Red
            return
        }
        
        $dbhost = Read-Host "🌐 Host de BD [ENTER para usar '35.206.81.32' o escribe '127.0.0.1']"
        if ([string]::IsNullOrWhiteSpace($dbhost)) { $dbhost = "35.206.81.32" }
        
        $localConfig = "src/03_Web/Intranet.Web/appsettings.Local.json"
        $jsonContent = @"
{
  "// LOCAL OVERRIDE": "Configuracion de conexion para Equipo $numFmt. Protegido en .gitignore.",
  "ConnectionStrings": {
    "Modulo${numFmt}Connection": "Host=$dbhost;Port=5432;Database=db_intranet_iestp;Username=user_equipo$numFmt;Password=$pass;SearchPath=mod$numFmt,core,public;Pooling=true;MinPoolSize=2;MaxPoolSize=15;"
  }
}
"@
        Set-Content -Path $localConfig -Value $jsonContent
        
        Write-Host "`n✅ ¡CONFIGURACIÓN LOCAL COMPLETADA CON ÉXITO!" -ForegroundColor Green
        Write-Host "📄 Archivo creado: $localConfig (Protegido en .gitignore)" -ForegroundColor Cyan
    }
}

while ($true) {
    Show-Menu
    $op = Read-Host "👉 Elige una opción [0-5]"
    switch ($op) {
        "1" { Start-App }
        "2" { Create-Branch }
        "3" { Validate-Code }
        "4" { Push-Work }
        "5" { Manage-Db }
        "0" { Write-Host "`n¡Buen trabajo! Hasta la próxima sesión.`n" -ForegroundColor Green; exit }
        Default { Write-Host "`nOpción no válida. Ingresa un número del 0 al 5." -ForegroundColor Red }
    }
    Write-Host "`nPresiona ENTER para volver al menú..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
