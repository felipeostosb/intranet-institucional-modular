# ==============================================================================
# 🏛️ IESTP ARGENTINA - ASISTENTE DE DESARROLLO WINDOWS (CLI SENCILLO)
# ==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "🏛️  INTRANET INSTITUCIONAL IESTP ARGENTINA — ASISTENTE DEV" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  Plataforma .NET 10 LTS • MariaDB • 9 Módulos Desacoplados`n" -ForegroundColor Cyan
    Write-Host "  1) 🚀 Iniciar Intranet (Ver cambios en vivo en tu navegador)" -ForegroundColor Green
    Write-Host "  2) 🌿 Crear mi Rama de Trabajo (Elige tu equipo 01 al 09)" -ForegroundColor Green
    Write-Host "  3) ⚡ Generar Formulario / Tabla (Para tu módulo)" -ForegroundColor Green
    Write-Host "  4) 📤 Subir mi Trabajo a GitHub (Guardar y enviar)" -ForegroundColor Green
    Write-Host "  0) 🚪 Salir`n" -ForegroundColor Yellow
}

function Start-App {
    Write-Host "`n🚀 Abriendo la Intranet en tu navegador (http://localhost:5000)..." -ForegroundColor Blue
    Write-Host "💡 Cada cambio que guardes se actualizará automáticamente.`n" -ForegroundColor Yellow
    dotnet watch --project src/03_Web/Intranet.Web
}

function Create-Branch {
    Write-Host "`n🌿 CREAR MI RAMA DE EQUIPO" -ForegroundColor Blue
    $num = Read-Host "👉 ¿Qué número de equipo eres? (1 al 9)"
    $numFmt = "{0:D2}" -f [int]$num
    
    $tarea = Read-Host "👉 ¿Qué tarea vas a hacer? (ej: formulario-registro)"
    $tarea = $tarea.ToLower().Replace(" ", "-")
    
    $branch = "modulo$numFmt/$tarea"
    
    Write-Host "`nActualizando código con 'main'..." -ForegroundColor Cyan
    git checkout main
    git pull origin main
    
    git checkout -b "$branch"
    Write-Host "`n✅ ¡Listo! Ya estás en tu rama segura: $branch" -ForegroundColor Green
    Write-Host "Recuerda programar en: src/02_Modulos/Intranet.Modulo$numFmt/" -ForegroundColor Yellow
}

function Push-Work {
    Write-Host "`n📤 SUBIR MI TRABAJO A GITHUB" -ForegroundColor Blue
    $branch = git rev-parse --abbrev-ref HEAD
    
    if ($branch -eq "main") {
        Write-Host "⛔ Estás en 'main'. Usa la opción 2 para crear tu rama antes de subir." -ForegroundColor Red
        return
    }
    
    $msg = Read-Host "`n👉 Describe brevemente qué hiciste (ej: formulario de registro)"
    git add .
    git commit -m "$msg"
    
    Write-Host "`nEnviando a GitHub..." -ForegroundColor Cyan
    git push origin "$branch"
    
    Write-Host "`n✅ ¡Trabajo subido con éxito a la rama: $branch!" -ForegroundColor Green
    Write-Host "👉 Abre tu Pull Request aquí: https://github.com/felipeostosb/intranet-institucional-modular/pulls" -ForegroundColor Cyan
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
