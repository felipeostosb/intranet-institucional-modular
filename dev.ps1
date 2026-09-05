# ==============================================================================
# 🏛️ IESTP ARGENTINA - ASISTENTE DE DESARROLLO WINDOWS (CLI SENCILLO & RESILIENTE)
# ==============================================================================

function Show-Menu {
    Clear-Host
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "🏛️  INTRANET INSTITUCIONAL IESTP ARGENTINA — ASISTENTE DEV" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  Plataforma .NET 10 LTS • MariaDB • 9 Módulos Desacoplados" -ForegroundColor Cyan
    Write-Host "  🌿 Rama actual: $branch`n" -ForegroundColor Yellow
    Write-Host "  1) 🚀 Iniciar Intranet (Ver cambios en vivo en tu navegador)" -ForegroundColor Green
    Write-Host "  2) 🌿 Crear / Cambiar a mi Rama de Equipo (Elige tu equipo 01 al 09)" -ForegroundColor Green
    Write-Host "  3) ⚡ Generar Formulario / Tabla (Para tu módulo)" -ForegroundColor Green
    Write-Host "  4) 📤 Subir mi Trabajo a GitHub (Guarda y sincroniza siempre)" -ForegroundColor Green
    Write-Host "  0) 🚪 Salir`n" -ForegroundColor Yellow
}

function Start-App {
    Write-Host "`n🚀 Abriendo la Intranet en tu navegador (http://localhost:5000)..." -ForegroundColor Blue
    Write-Host "💡 Cada cambio que guardes se actualizará automáticamente.`n" -ForegroundColor Yellow
    dotnet watch --project src/03_Web/Intranet.Web
}

function Create-Branch {
    Write-Host "`n🌿 CONFIGURAR RAMA DE TRABAJO" -ForegroundColor Blue
    $num = Read-Host "👉 ¿Qué número de equipo eres? (1 al 9)"
    $numFmt = "{0:D2}" -f [int]$num
    
    $tarea = Read-Host "👉 ¿Qué tarea vas a hacer? (ej: formulario-registro)"
    if ([string]::IsNullOrWhiteSpace($tarea)) { $tarea = "avance" }
    $tarea = $tarea.ToLower().Replace(" ", "-")
    
    $branch = "modulo$numFmt/$tarea"
    
    $branchExists = git show-ref --verify --quiet "refs/heads/$branch"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nCambiando a tu rama existente: $branch..." -ForegroundColor Cyan
        git checkout "$branch"
    } else {
        Write-Host "`nSincronizando con 'main' antes de crear la rama..." -ForegroundColor Cyan
        git checkout main 2>$null
        git pull origin main 2>$null
        git checkout -b "$branch"
        Write-Host "`n✅ ¡Rama creada con éxito: $branch!" -ForegroundColor Green
    }
    
    Write-Host "Recuerda programar en: src/02_Modulos/Intranet.Modulo$numFmt/" -ForegroundColor Yellow
}

function Push-Work {
    Write-Host "`n📤 SUBIR Y SINCRONIZAR MI TRABAJO CON GITHUB" -ForegroundColor Blue
    $branch = git rev-parse --abbrev-ref HEAD
    
    if ($branch -eq "main") {
        Write-Host "⛔ Estás en 'main'. Usa la opción 2 para crear o cambiar a tu rama antes de subir." -ForegroundColor Red
        return
    }
    
    Write-Host "🌿 Rama de trabajo: $branch" -ForegroundColor Cyan
    
    $status = git status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        $msg = Read-Host "👉 Describe qué cambiaste (ej: agregue formulario)"
        if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "feat($branch): actualizacion de avance" }
        git add .
        git commit -m "$msg"
        Write-Host "✓ Cambios guardados localmente." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No hay archivos nuevos por guardar, sincronizando con GitHub..." -ForegroundColor Yellow
    }
    
    Write-Host "Sincronizando con GitHub..." -ForegroundColor Cyan
    git pull --rebase origin "$branch" 2>$null
    
    Write-Host "Publicando rama '$branch' en GitHub..." -ForegroundColor Cyan
    git push -u origin "$branch"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n======================================================================" -ForegroundColor Green
        Write-Host "🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!" -ForegroundColor Green
        Write-Host "======================================================================" -ForegroundColor Green
        Write-Host "👉 Abre o revisa tu Pull Request aquí:`n   https://github.com/felipeostosb/intranet-institucional-modular/pulls" -ForegroundColor Cyan
    } else {
        Write-Host "`n❌ Hubo un inconveniente al subir a GitHub. Revisa tu conexión o permisos." -ForegroundColor Red
    }
}

while ($true) {
    Show-Menu
    $op = Read-Host "👉 Elige una opción [0-4]"
    switch ($op) {
        "1" { Start-App }
        "2" { Create-Branch }
        "4" { Push-Work }
        "0" { Write-Host "`n¡Buen trabajo! Hasta luego.`n" -ForegroundColor Green; exit }
        default { Write-Host "`nOpción no válida." -ForegroundColor Red }
    }
    Write-Host "`nPresiona ENTER para volver al menú..." -ForegroundColor Yellow
    Read-Host
}
