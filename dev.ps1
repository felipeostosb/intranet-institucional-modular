# ==============================================================================
# 🦅 AQUILA A-ERP — ASISTENTE DEV EN POWERSHELL (WINDOWS)
# Intranet Institucional IESTP Argentina • .NET 10 LTS • PostgreSQL 16
# ==============================================================================

$ErrorActionPreference = "Stop"

# Añadir dotnet SDK al PATH (instalado en ~/.dotnet, no en PATH del sistema)
$dotnetPath = "$env:USERPROFILE\.dotnet"
if (Test-Path $dotnetPath) {
    $env:PATH = "$dotnetPath;$env:PATH"
}

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
        if [[ "`$file" != "`$ALLOWED_DIR"* ]] && [[ "`$file" != "docs/"* ]] && [[ "`$file" != *.md ]] && [[ "`$file" != "dev.sh" ]] && [[ "`$file" != "dev.ps1" ]] && [[ "`$file" != ".dockerignore" ]] && [[ "`$file" != "Dockerfile" ]]; then
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
    $localCfg = "src/03_Web/Intranet.Web/appsettings.Local.json"
    $team = "—"
    if (Test-Path $localCfg) {
        $json = Get-Content $localCfg -Raw | ConvertFrom-Json
        $connProp = $json.ConnectionStrings.PSObject.Properties | Where-Object { $_.Name -match "Modulo\d+Connection" } | Select-Object -First 1
        if ($connProp) { $team = "Equipo $([regex]::Match($connProp.Name, '\d+').Value)" }
    }

    Write-Host ""
    Write-Host "                 ▄████▄" -ForegroundColor Blue
    Write-Host "              ▄▀▀▀▀▀▀▀▀▀▀▄" -ForegroundColor Blue
    Write-Host "           ▄▀▀  ▄▄▄   ▄▄▄  ▀▀▄" -ForegroundColor Blue
    Write-Host "         ▄▀  ▄▀▀  ▀▀▀▀▀  ▀▄  ▀▄" -ForegroundColor Blue
    Write-Host "        █  ▄▀  ▄▄█     █▄▄  ▀▄  █" -ForegroundColor Blue
    Write-Host "        █ █  ▄▀ █▀ ▀▄▄▀ █▄▀  █  █" -ForegroundColor Blue
    Write-Host "        █ █ ▀▄▄▀ ▄█▀▀▀█▄ ▀▄▄ █  █" -ForegroundColor Blue
    Write-Host "        █  ▀▄  ▀▀▀▀   ▀▀▀▀  ▄▀  █" -ForegroundColor Blue
    Write-Host "         ▀▄  ▀▀▀▀▀▀▀▀▀▀▀▀▀▀  ▄▀" -ForegroundColor Blue
    Write-Host "           ▀▀▄▄          ▄▄▀▀" -ForegroundColor Blue
    Write-Host "              ▀▀▀▀▀▀▀▀▀▀▀▀" -ForegroundColor Blue
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║  AQUILA A-ERP — Intranet Institucional IESTP Argentina     ║" -ForegroundColor Blue
    Write-Host "║  .NET 10 LTS • PostgreSQL 16 • 10 Módulos (00 - 09)        ║" -ForegroundColor Blue
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
    Write-Host "║  🌿 Rama: $currentBranch" -ForegroundColor Yellow -NoNewline
    Write-Host (" " * [Math]::Max(1, 53 - $currentBranch.Length) + "║") -ForegroundColor Blue
    if ($team -ne "—") {
        Write-Host "║  👤 $team" -ForegroundColor Green -NoNewline
        Write-Host (" " * [Math]::Max(1, 52 - $team.Length) + "║") -ForegroundColor Blue
    } else {
        Write-Host "║  👤 Sin configurar" -ForegroundColor Red -NoNewline
        Write-Host (" " * [Math]::Max(1, 40) + "║") -ForegroundColor Blue
    }
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
    Write-Host "║                                                              ║" -ForegroundColor Blue
    Write-Host "║  ▸ DESARROLLO                                               ║" -ForegroundColor Blue
    Write-Host "║    1) 🚀 Iniciar Intranet                                ║" -ForegroundColor Blue
    Write-Host "║    4) 🧪 Compilar y Validar                              ║" -ForegroundColor Blue
    Write-Host "║    5) 📤 Subir a GitHub                                  ║" -ForegroundColor Blue
    Write-Host "║                                                              ║" -ForegroundColor Blue
    Write-Host "║  ▸ RAMAS Y SYNC                                             ║" -ForegroundColor Blue
    Write-Host "║    2) 🌿 Mi Rama de Equipo                               ║" -ForegroundColor Blue
    Write-Host "║    3) 🔄 Sincronizar con main                            ║" -ForegroundColor Blue
    Write-Host "║    9) 📋 Ver Mis Cambios                                 ║" -ForegroundColor Blue
    Write-Host "║                                                              ║" -ForegroundColor Blue
    Write-Host "║  ▸ BASE DE DATOS                                            ║" -ForegroundColor Blue
    Write-Host "║    6) 🗄️  Info y Configuración                             ║" -ForegroundColor Blue
    Write-Host "║    7) 💾 Backup / Restore                                 ║" -ForegroundColor Blue
    Write-Host "║                                                              ║" -ForegroundColor Blue
    Write-Host "║  ▸ MONITOREO                                                 ║" -ForegroundColor Blue
    Write-Host "║    8) 📊 Estado del Proyecto                              ║" -ForegroundColor Blue
    Write-Host "║   10) 🔧 Extras                                           ║" -ForegroundColor Blue
    Write-Host "║                                                              ║" -ForegroundColor Blue
    Write-Host "║    0) 🚪 Salir                                            ║" -ForegroundColor Red
    Write-Host "║                                                              ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
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

function Sync-Main {
    Write-Host "`n🔄 SINCRONIZAR Y ACTUALIZAR CON 'main' (PRODUCCIÓN)" -ForegroundColor Blue
    $branch = $(git rev-parse --abbrev-ref HEAD 2>$null)
    
    if ($branch -eq "main") {
        Write-Host "ℹ️ Estás en 'main'. Descargando últimos cambios directamente de GitHub..." -ForegroundColor Yellow
        git pull origin main
        Write-Host "`n✅ ¡Rama 'main' actualizada con éxito!" -ForegroundColor Green
        return
    }
    
    Write-Host "🌿 Tu rama actual: $branch" -ForegroundColor Cyan
    Write-Host "Iniciando sincronización segura (Zero-Data-Loss)...`n" -ForegroundColor Cyan
    
    $stashed = $false
    $status = $(git status --porcelain)
    if ($status) {
        Write-Host "📦 Guardando temporalmente tus cambios locales no guardados (stash)..." -ForegroundColor Yellow
        git stash push -m "WIP-dev-sync" | Out-Null
        $stashed = $true
        Write-Host "✓ Trabajo local respaldado con seguridad." -ForegroundColor Green
    }
    
    Write-Host "📥 Descargando actualizaciones de 'main' desde GitHub (git fetch)..." -ForegroundColor Cyan
    git fetch origin main
    
    Write-Host "🔀 Integrando los cambios de producción en tu rama ($branch)..." -ForegroundColor Cyan
    git rebase origin/main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n⚠️  HUBO UN CONFLICTO al integrar los cambios de main." -ForegroundColor Red
        Write-Host "Cancelando rebase para proteger tu código..." -ForegroundColor Yellow
        git rebase --abort 2>$null | Out-Null
        if ($stashed) {
            git stash pop | Out-Null
        }
        Write-Host "`n💡 Pide apoyo a tu Scrum Master o revisa con 'git status'." -ForegroundColor Cyan
        return
    }
    
    if ($stashed) {
        Write-Host "📦 Restaurando tus cambios locales de vuelta a tus archivos..." -ForegroundColor Cyan
        git stash pop | Out-Null
        Write-Host "✓ Tus cambios locales están de vuelta intactos." -ForegroundColor Green
    }
    
    Write-Host "`n🧪 Verificando compilación de la solución..." -ForegroundColor Cyan
    dotnet build "IntranetInstitucional.sln" -v q --nologo
    
    Write-Host "`n======================================================================" -ForegroundColor Green
    Write-Host "🎉 ¡RAMA '$branch' 100% ACTUALIZADA CON PRODUCCIÓN ('main')!" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "💡 Todos los cambios nuevos de otros equipos ya están en tu computadora." -ForegroundColor White
    Write-Host "💡 Todo tu avance local fue preservado sin ninguna pérdida.`n" -ForegroundColor White
    
    $pushNow = Read-Host "👉 ¿Deseas subir también tu rama actualizada a GitHub ahora? [S/n]"
    if ($pushNow -notmatch "^[nN]$") {
        Write-Host "Subiendo '$branch' a GitHub..." -ForegroundColor Cyan
        git push --force-with-lease origin $branch 2>$null
        if ($LASTEXITCODE -ne 0) {
            git push -u origin $branch
        }
        Write-Host "✅ ¡Rama remota en GitHub actualizada!" -ForegroundColor Green
        Write-Host "👉 Revisa tu Pull Request: https://github.com/felipeostosb/intranet-institucional-modular/compare/main...$branch" -ForegroundColor Cyan
    }
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
    git fetch origin main 2>$null | Out-Null
    git rebase origin/main 2>$null | Out-Null
    
    Write-Host "`n🔨 Verificando compilación..." -ForegroundColor Cyan
    dotnet build "IntranetInstitucional.sln" -v q --nologo
    
    Write-Host "Publicando en GitHub..." -ForegroundColor Cyan
    git push --force-with-lease origin $branch 2>$null
    if ($LASTEXITCODE -ne 0) {
        git push -u origin $branch
    }
    
    Write-Host "`n🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!" -ForegroundColor Green
    Write-Host "👉 Abre tu Pull Request en: https://github.com/felipeostosb/intranet-institucional-modular/compare/main...$branch" -ForegroundColor Cyan
}


function Backup-Db {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
    Write-Host "`n======================================================================" -ForegroundColor Blue
    Write-Host "🗄️  BACKUP DE BASE DE DATOS (PostgreSQL 16)" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue

    $localCfg = "src/03_Web/Intranet.Web/appsettings.Local.json"
    if (-not (Test-Path $localCfg)) {
        Write-Host "❌ No se encontró appsettings.Local.json" -ForegroundColor Red
        Write-Host "💡 Primero ejecuta la opción 6 (Base de Datos) para configurar tus credenciales." -ForegroundColor Cyan
        return
    }

    $json = Get-Content $localCfg -Raw | ConvertFrom-Json
    $connStr = $json.ConnectionStrings.PSObject.Properties | Where-Object { $_.Name -match "Modulo[0-9]+Connection" } | Select-Object -First 1
    if (-not $connStr) {
        Write-Host "❌ No se pudo detectar la conexión en appsettings.Local.json" -ForegroundColor Red
        return
    }
    $numFmt = [regex]::Match($connStr.Name, '[0-9]+').Value
    $parts = @{}
    $connStr.Value -split ';' | ForEach-Object {
        $kv = $_ -split '=', 2
        if ($kv.Length -eq 2) { $parts[$kv[0].Trim()] = $kv[1].Trim() }
    }

    Write-Host "  👤 Equipo:         $numFmt" -ForegroundColor Cyan
    Write-Host "  🌐 Host:           $($parts.Host)" -ForegroundColor Cyan
    Write-Host "  📊 Base de datos:  $($parts.Database)" -ForegroundColor Cyan
    Write-Host "  🔑 Usuario:        $($parts.Username)" -ForegroundColor Cyan
    Write-Host "  🛡️  Esquema:        mod$numFmt`n" -ForegroundColor Cyan

    $backupDir = "backups"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "$backupDir/mod$numFmt`_$timestamp.sql"

    $action = Read-Host "👉 ¿Qué deseas hacer? [B]ackup / [R]estore / [V]olver"
    switch -Regex ($action) {
        "^[bB]$" {
            Write-Host "`n📦 Iniciando backup del esquema mod$numFmt..." -ForegroundColor Cyan
            if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

            $env:PGPASSWORD = $parts.Password
            pg_dump -h $parts.Host -p 5432 -U $parts.Username -d $parts.Database `
                --schema="mod$numFmt" --no-owner --no-privileges --file=$backupFile 2>$null
            Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue

            if (Test-Path $backupFile) {
                $size = (Get-Item $backupFile).Length
                Write-Host "`n✅ BACKUP COMPLETADO CON ÉXITO" -ForegroundColor Green
                Write-Host "📄 Archivo: $backupFile" -ForegroundColor Cyan
                Write-Host "📏 Tamaño:  $size bytes" -ForegroundColor Cyan
            } else {
                Write-Host "`n⛔ Error al crear el backup." -ForegroundColor Red
            }
        }
        "^[rR]$" {
            if (-not (Test-Path $backupDir)) {
                Write-Host "📁 No hay backups previos en '$backupDir/'." -ForegroundColor Yellow
                return
            }
            $files = Get-ChildItem "$backupDir/*.sql" | Sort-Object LastWriteTime -Descending
            if ($files.Count -eq 0) {
                Write-Host "📁 No hay backups previos en '$backupDir/'." -ForegroundColor Yellow
                return
            }
            Write-Host "`n📋 Backups disponibles:" -ForegroundColor Cyan
            foreach ($f in $files) { Write-Host "  → $($f.Name) ($($f.LastWriteTime))" -ForegroundColor Cyan }
            $restoreFile = Read-Host "`n👉 Nombre del archivo a restaurar"
            $restorePath = "$backupDir/$restoreFile"
            if (-not (Test-Path $restorePath)) {
                Write-Host "❌ Archivo no encontrado: $restorePath" -ForegroundColor Red
                return
            }
            $confirm = Read-Host "⚠️  SOBRESCRIBIRÁ el esquema mod$numFmt. Escribe 'SI' para confirmar"
            if ($confirm -ne "SI") { Write-Host "Cancelado." -ForegroundColor Yellow; return }
            $env:PGPASSWORD = $parts.Password
            psql -h $parts.Host -p 5432 -U $parts.Username -d $parts.Database -f $restorePath 2>$null
            Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
            Write-Host "`n✅ Restauración completada." -ForegroundColor Green
        }
        default { Write-Host "Volviendo al menú..." -ForegroundColor Yellow }
    }
    } finally { $ErrorActionPreference = $prevEAP }
}

function Show-Status {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
    Write-Host "`n======================================================================" -ForegroundColor Blue
    Write-Host "📊 ESTADO DEL PROYECTO — AQUILA A-ERP" -ForegroundColor Blue
    Write-Host "======================================================================`n" -ForegroundColor Blue

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) { $branch = "desconocida" }
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>$null
    $ahead = 0; $behind = 0
    if ($upstream) {
        $ahead = [int](git rev-list --count @{u}..HEAD 2>$null)
        $behind = [int](git rev-list --count HEAD..@{u} 2>$null)
    }
    Write-Host "  🌿 Rama:        $branch" -ForegroundColor Yellow
    if ($branch -eq "main") {
        Write-Host "  📍 Ubicación:   Estás en main" -ForegroundColor Cyan
    } elseif ($upstream) {
        Write-Host "  📍 Tracking:    $upstream" -ForegroundColor Cyan
        if ($ahead -gt 0) { Write-Host "  ⬆️  $ahead commit(s) por subir" -ForegroundColor Green }
        if ($behind -gt 0) { Write-Host "  ⬇️  $behind commit(s) sin sincronizar (ejecuta opción 3)" -ForegroundColor Red }
    } else {
        Write-Host "  📍 Tracking:    Sin rama remota (usa opción 5)" -ForegroundColor Red
    }

    $staged = [int](git diff --cached --numstat 2>$null | Measure-Object | Select-Object -ExpandProperty Count)
    $unstaged = [int](git diff --numstat 2>$null | Measure-Object | Select-Object -ExpandProperty Count)
    $untracked = [int](git ls-files --others --exclude-standard 2>$null | Measure-Object | Select-Object -ExpandProperty Count)
    $totalPend = $staged + $unstaged + $untracked
    Write-Host ""
    if ($totalPend -eq 0) {
        Write-Host "  📝 Working tree limpio — nada pendiente" -ForegroundColor Green
    } else {
        Write-Host "  📝 Cambios pendientes:  $totalPend archivo(s)" -ForegroundColor Yellow
        if ($staged -gt 0) { Write-Host "     🟢 $staged staged (listo para commit)" }
        if ($unstaged -gt 0) { Write-Host "     🔴 $unstaged sin staging" }
        if ($untracked -gt 0) { Write-Host "     ⚪ $untracked sin seguimiento (nuevos)" }
    }

    $inRebase = (Test-Path .git/rebase-merge) -or (Test-Path .git/rebase-apply)
    $inMerge = Test-Path .git/MERGE_HEAD
    if ($inRebase -or $inMerge) { Write-Host "`n  ⚠️  REBASE/MERGE EN CURSO — conflictos pendientes" -ForegroundColor Red }

    Write-Host ""
    try {
        $code = curl.exe -s -o NUL -w "%{http_code}" http://localhost:5000/ --max-time 2 2>$null
        if ($code -eq "200") { Write-Host "  🚀 Servidor ACTIVO en http://localhost:5000 ✓" -ForegroundColor Green }
        else { Write-Host "  🚀 Servidor inactivo (ejecuta opción 1)" -ForegroundColor Yellow }
    } catch {
        Write-Host "  🚀 Servidor inactivo (ejecuta opción 1)" -ForegroundColor Yellow
    }

    Write-Host ""
    $localCfg = "src/03_Web/Intranet.Web/appsettings.Local.json"
    if (Test-Path $localCfg) {
        $json = Get-Content $localCfg -Raw | ConvertFrom-Json
        $connProp = $json.ConnectionStrings.PSObject.Properties | Where-Object { $_.Name -match "Modulo[0-9]+Connection" } | Select-Object -First 1
        if ($connProp) {
            $teamNum = [regex]::Match($connProp.Name, '[0-9]+').Value
            Write-Host "  🗄️  appsettings.Local.json existe — Equipo: $teamNum" -ForegroundColor Green
        }
    } else {
        Write-Host "  🗄️  appsettings.Local.json no existe (ejecuta opción 6)" -ForegroundColor Yellow
    }

    Write-Host ""
    if ($totalPend -gt 10) { Write-Host "  ⚠️  Muchos archivos sin commitear ($totalPend). Considera subir." -ForegroundColor Yellow }
    if ($behind -gt 5) { Write-Host "  ⚠️  Tu rama está $behind commits detrás de main. Ejecuta opción 3." -ForegroundColor Yellow }
    if ($totalPend -le 10 -and $behind -le 5) { Write-Host "  ✅ Estado saludable — no hay alertas." -ForegroundColor Green }
    } finally { $ErrorActionPreference = $prevEAP }
}

function Show-Changes {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
    Write-Host "`n======================================================================" -ForegroundColor Blue
    Write-Host "📋 MIS CAMBIOS — ARCHIVOS MODIFICADOS" -ForegroundColor Blue
    Write-Host "======================================================================`n" -ForegroundColor Blue

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    Write-Host "  🌿 Rama: $branch`n" -ForegroundColor Cyan

    $allChanges = @()
    $allChanges += git diff --cached --name-only 2>$null
    $allChanges += git diff --name-only 2>$null
    $allChanges += git ls-files --others --exclude-standard 2>$null
    $allChanges = $allChanges | Where-Object { $_ } | Sort-Object -Unique

    if ($allChanges.Count -eq 0) {
        Write-Host "  ✅ No hay cambios — working tree limpio." -ForegroundColor Green
        return
    }

    $cViews=0; $cCtrl=0; $cSql=0; $cModel=0; $cConfig=0; $cCore=0; $cOther=0
    foreach ($f in $allChanges) {
        switch -Regex ($f) {
            "Views|\.cshtml$"            { $cViews++ }
            "Controller"                 { $cCtrl++ }
            "Schema|schema|\.sql$"       { $cSql++ }
            "Model|Dto|Entity"           { $cModel++ }
            "\.json$|\.yml$|\.yaml$|\.props$" { $cConfig++ }
            "^src/01_Core/"              { $cCore++ }
            default                      { $cOther++ }
        }
    }

    $total = $allChanges.Count
    Write-Host "  📊 Total: $total archivo(s)" -ForegroundColor Cyan
    if ($cViews -gt 0) { Write-Host "     👁️  $cViews vista(s)" }
    if ($cCtrl -gt 0) { Write-Host "     🎮 $cCtrl controlador(es)" }
    if ($cSql -gt 0) { Write-Host "     🗄️  $cSql SQL/schema" }
    if ($cModel -gt 0) { Write-Host "     📦 $cModel modelo(s)/entidad(es)" }
    if ($cConfig -gt 0) { Write-Host "     ⚙️  $cConfig configuración(es)" }
    if ($cCore -gt 0) { Write-Host "     🔧 $cCore core/compartido" }
    if ($cOther -gt 0) { Write-Host "     📄 $cOther otro(s)" }
    Write-Host ""

    Write-Host "  📂 Detalle por carpeta:`n" -ForegroundColor Cyan
    $groups = $allChanges | Group-Object { ($_.Split('/')[0..3] -join '/') }
    foreach ($g in $groups) {
        Write-Host "  📁 $($g.Name)/" -ForegroundColor Cyan
        foreach ($item in $g.Group) { Write-Host "     $(Split-Path $item -Leaf)" }
        Write-Host ""
    }

    Write-Host "  📏 Líneas modificadas:" -ForegroundColor Cyan
    $totalAdd=0; $totalDel=0
    foreach ($f in $allChanges) {
        $stat = git diff --cached --numstat -- $f 2>$null
        if (-not $stat) { $stat = git diff --numstat -- $f 2>$null }
        if ($stat) {
            $parts = $stat -split "`t"
            $add = [int]$parts[0]; $del = [int]$parts[1]
            if ($add -gt 0 -or $del -gt 0) {
                $totalAdd += $add; $totalDel += $del
                Write-Host "     " -NoNewline
                Write-Host "+$add" -ForegroundColor Green -NoNewline
                Write-Host "  -$del" -ForegroundColor Red -NoNewline
                Write-Host "  $(Split-Path $f -Leaf)"
            }
        }
    }
    if ($totalAdd -gt 0 -or $totalDel -gt 0) {
        Write-Host "     ─────────────────────────────────"
        Write-Host "     " -NoNewline
        Write-Host "+$totalAdd" -ForegroundColor Green -NoNewline
        Write-Host "  -$totalDel" -ForegroundColor Red -NoNewline
        Write-Host "  TOTAL"
    }
    } finally { $ErrorActionPreference = $prevEAP }
}


function Show-Extras {
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
    while ($true) {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
        Write-Host "║  🔧 EXTRAS — Herramientas Avanzadas                        ║" -ForegroundColor Blue
        Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
        Write-Host "║                                                              ║" -ForegroundColor Blue
        Write-Host "║  ▸ CÓDIGO                                                   ║" -ForegroundColor Cyan
        Write-Host "║    1) 📜 Historial de Mi Módulo                           ║" -ForegroundColor Green
        Write-Host "║    2) 🔗 Generar Descripción de PR                        ║" -ForegroundColor Green
        Write-Host "║    3) 🗄️  Verificar Mi Esquema SQL                          ║" -ForegroundColor Green
        Write-Host "║                                                              ║" -ForegroundColor Blue
        Write-Host "║  ▸ BASE DE DATOS                                            ║" -ForegroundColor Cyan
        Write-Host "║    4) 🔌 Diagnosticar Conexión                             ║" -ForegroundColor Green
        Write-Host "║    5) 📊 Ver Datos de Prueba                               ║" -ForegroundColor Green
        Write-Host "║                                                              ║" -ForegroundColor Blue
        Write-Host "║    0) 🔙 Volver al Menú Principal                          ║" -ForegroundColor Yellow
        Write-Host "║                                                              ║" -ForegroundColor Blue
        Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
        Write-Host ""
        $extraOp = Read-Host "  👉 Selecciona una opción [0-5]"
        switch -Regex ($extraOp) {
            "^1$"  { Show-ExtraHistory }
            "^2$"  { Show-ExtraPRDescription }
            "^3$"  { Show-ExtraVerifySchema }
            "^4$"  { Show-ExtraDiagConnection }
            "^5$"  { Show-ExtraTestData }
            "^0$"  { break }
            default { Write-Host "  Opción no válida." -ForegroundColor Red }
        }
        Write-Host "`n  Presiona ENTER para volver al submenú..." -ForegroundColor Yellow
        [void][System.Console]::ReadLine()
    }
    } finally { $ErrorActionPreference = $prevEAP }
}

function Show-ExtraHistory {
    Write-Host "`n📜 HISTORIAL DE MI MÓDULO" -ForegroundColor Blue
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $modNum = [regex]::Match($branch, 'modulo-?(\d{2})').Groups[1].Value
    if (-not $modNum) {
        $modNum = Read-Host "👉 Módulo (0 al 9)"
        $modNum = "{0:D2}" -f [int]$modNum
    }
    Write-Host "`nÚltimos 15 commits en Intranet.Modulo${modNum}:" -ForegroundColor Cyan
    git log --oneline -15 -- "src/02_Modulos/Intranet.Modulo${modNum}/" 2>$null | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }
    $count = [int](git log --oneline -- "src/02_Modulos/Intranet.Modulo${modNum}/" 2>$null | Measure-Object | Select-Object -ExpandProperty Count)
    Write-Host "`n  Total commits: $count" -ForegroundColor Cyan
}

function Show-ExtraPRDescription {
    Write-Host "`n🔗 GENERAR DESCRIPCIÓN DE PR" -ForegroundColor Blue
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if ($branch -eq "main") { Write-Host "Estás en main." -ForegroundColor Red; return }
    $modNum = [regex]::Match($branch, 'modulo-?(\d{2})').Groups[1].Value
    $files = git diff main...HEAD --name-only 2>$null
    $stat = git diff main...HEAD --numstat 2>$null
    $add=0; $del=0
    if ($stat) { $stat | ForEach-Object { $parts = $_ -split "`t"; $add += [int]$parts[0]; $del += [int]$parts[1] } }
    $count = if ($files) { ($files | Measure-Object).Count } else { 0 }
    Write-Host "`n---BEGIN PR---"
    Write-Host "## 📌 Qué se hizo"
    if ($modNum) { Write-Host "Avance en el **Módulo $modNum** (Intranet.Modulo$modNum).`n" }
    else { Write-Host "Cambios en la rama ``$branch``.`n" }
    Write-Host "## 📊 Resumen`n- **$count** archivo(s) modificado(s)`n- **+$add** / **-$del** líneas`n"
    Write-Host "## 📁 Archivos modificados`n"
    if ($files) { foreach ($f in $files) { Write-Host "- ``$f``" } }
    Write-Host "`n---END PR---"
    Write-Host "`nCopia el texto entre ---BEGIN PR--- y ---END PR--- en tu Pull Request." -ForegroundColor Cyan
}

function Show-ExtraVerifySchema {
    Write-Host "`n🗄️  VERIFICAR MI ESQUEMA SQL" -ForegroundColor Blue
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $modNum = [regex]::Match($branch, 'modulo-?(\d{2})').Groups[1].Value
    if (-not $modNum) {
        $modNum = Read-Host "👉 Módulo (0 al 9)"
        $modNum = "{0:D2}" -f [int]$modNum
    }
    $schema = "src/02_Modulos/Intranet.Modulo${modNum}/Sql/schema.sql"
    if (-not (Test-Path $schema)) { Write-Host "❌ No se encontró: $schema" -ForegroundColor Red; return }
    Write-Host "Analizando: $schema`n" -ForegroundColor Cyan
    $errors = 0
    $content = Get-Content $schema -Raw
    if ($content -match "CREATE SCHEMA IF NOT EXISTS") { Write-Host "  ✓ CREATE SCHEMA IF NOT EXISTS" -ForegroundColor Green }
    else { Write-Host "  ✗ Falta CREATE SCHEMA IF NOT EXISTS" -ForegroundColor Red; $errors++ }
    if ($content -notmatch "CREATE TABLE(?!\s+IF\s+NOT\s+EXISTS)") { Write-Host "  ✓ Todas las tablas usan IF NOT EXISTS" -ForegroundColor Green }
    else { Write-Host "  ✗ CREATE TABLE sin IF NOT EXISTS" -ForegroundColor Red; $errors++ }
    $noPrefix = Select-String -InputObject $content -Pattern "CREATE TABLE IF NOT EXISTS\s+(?!mod$modNum\.)" -AllMatches
    if ($noPrefix.Matches.Count -eq 0) { Write-Host "  ✓ Tablas con prefijo mod$modNum" -ForegroundColor Green }
    else { Write-Host "  ✗ Tablas sin prefijo mod$modNum" -ForegroundColor Red; $errors++ }
    $tables = ([regex]::Matches($content, "CREATE TABLE")).Count
    Write-Host "`n  Tablas: $tables" -ForegroundColor Cyan
    if ($errors -eq 0) { Write-Host "`n  ✅ ESQUEMA VÁLIDO" -ForegroundColor Green }
    else { Write-Host "`n  ⛔ $errors error(es) detectado(s)" -ForegroundColor Red }
}

function Show-ExtraDiagConnection {
    Write-Host "`n🔌 DIAGNOSTICAR CONEXIÓN A POSTGRESQL" -ForegroundColor Blue
    $localCfg = "src/03_Web/Intranet.Web/appsettings.Local.json"
    if (-not (Test-Path $localCfg)) { Write-Host "❌ appsettings.Local.json no existe." -ForegroundColor Red; return }
    $json = Get-Content $localCfg -Raw | ConvertFrom-Json
    $connProp = $json.ConnectionStrings.PSObject.Properties | Where-Object { $_.Name -match "Modulo\d+Connection" } | Select-Object -First 1
    if (-not $connProp) { Write-Host "❌ No se detectó conexión." -ForegroundColor Red; return }
    $numFmt = [regex]::Match($connProp.Name, '\d+').Value
    $parts = @{}; $connProp.Value -split ';' | ForEach-Object { $kv = $_ -split '=', 2; if ($kv.Length -eq 2) { $parts[$kv[0].Trim()] = $kv[1].Trim() } }
    Write-Host "  Equipo: $numFmt | Host: $($parts.Host) | BD: $($parts.Database)`n" -ForegroundColor Cyan
    $env:PGPASSWORD = $parts.Password
    $ok = psql -h $parts.Host -p 5432 -U $parts.Username -d $parts.Database -c "SELECT 1" 2>$null
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
    if ($ok) { Write-Host "  ✓ Conexión exitosa" -ForegroundColor Green } else { Write-Host "  ✗ No se pudo conectar" -ForegroundColor Red }
}

function Show-ExtraTestData {
    Write-Host "`n📊 DATOS DE PRUEBA (Usuarios para Login)`n" -ForegroundColor Blue
    $localCfg = "src/03_Web/Intranet.Web/appsettings.Local.json"
    if (-not (Test-Path $localCfg)) { Write-Host "❌ Configura tu conexión primero (opción 6)." -ForegroundColor Red; return }
    $json = Get-Content $localCfg -Raw | ConvertFrom-Json
    $connProp = $json.ConnectionStrings.PSObject.Properties | Where-Object { $_.Name -match "Modulo\d+Connection" } | Select-Object -First 1
    $parts = @{}; $connProp.Value -split ';' | ForEach-Object { $kv = $_ -split '=', 2; if ($kv.Length -eq 2) { $parts[$kv[0].Trim()] = $kv[1].Trim() } }
    $env:PGPASSWORD = $parts.Password
    psql -h $parts.Host -p 5432 -U $parts.Username -d $parts.Database -c "SELECT u.codigo_institucional AS Codigo, p.dni AS DNI, p.nombres || ' ' || p.apellidos AS Nombre, r.nombre AS Rol FROM core.usuarios u JOIN core.personas p ON u.persona_id = p.id JOIN core.usuario_roles ur ON ur.usuario_id = u.id JOIN core.roles r ON ur.rol_id = r.id WHERE u.estado = TRUE AND ur.es_activo = TRUE ORDER BY r.nombre;" 2>$null
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
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
    $op = Read-Host "👉 Elige una opción [0-10]"
    switch ($op) {
        "1" { Start-App }
        "2" { Create-Branch }
        "3" { Sync-Main }
        "4" { Validate-Code }
        "5" { Push-Work }
        "6" { Manage-Db }
        "7" { Backup-Db }
        "8" { Show-Status }
        "9" { Show-Changes }
        "10" { Show-Extras }
        "0" { Write-Host "`n¡Buen trabajo! Hasta la próxima sesión.`n" -ForegroundColor Green; exit }
        Default { Write-Host "`nOpción no válida. Ingresa un número del 0 al 10." -ForegroundColor Red }
    }
    Write-Host "`nPresiona ENTER para volver al menú..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
