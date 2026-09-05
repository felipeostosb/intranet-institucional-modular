# ==============================================================================
# 🏛️ IESTP ARGENTINA - CLI DE DESARROLLO WINDOWS POWERSHELL (DX & POKA-YOKE)
# ==============================================================================

function Show-Header {
    Clear-Host
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "🏛️  INTRANET INSTITUCIONAL IESTP ARGENTINA - DEVELOPER SUITE (DX)  " -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Cyan
    Write-Host "  Plataforma Modular .NET 10 LTS • MariaDB 10.11 • Zero-Blast-Radius" -ForegroundColor White
    Write-Host "----------------------------------------------------------------------" -ForegroundColor Cyan
}

function Start-LocalDev {
    Write-Host "`n🚀 Iniciando Intranet en modo desarrollo con Hot-Reload (dotnet watch)..." -ForegroundColor Blue
    Write-Host "💡 Tip: Al modificar archivos C# o HTML, el navegador se actualizará automáticamente." -ForegroundColor Yellow
    Write-Host "🌐 Abriendo en: http://localhost:5000`n" -ForegroundColor Cyan
    dotnet watch --project src/03_Web/Intranet.Web
}

function Create-Branch {
    Write-Host "`n🌿 CREAR NUEVA RAMA DE TRABAJO (Estandarizada)" -ForegroundColor Blue
    $equipo = Read-Host "Equipo (01 al 09, ej: 04)"
    $equipoNum = "{0:D2}" -f [int]$equipo
    
    $tarea = Read-Host "Nombre breve de la tarea (ej: formulario-actas)"
    $tarea = $tarea.ToLower().Replace(" ", "-")
    
    $branchName = "modulo$equipoNum/$tarea"
    
    Write-Host "`nSincronizando con 'main'..." -ForegroundColor Cyan
    git checkout main
    git pull origin main
    
    Write-Host "Creando y cambiando a la rama '$branchName'..." -ForegroundColor Green
    git checkout -b "$branchName"
    Write-Host "`n✅ ¡Listo! Ahora estás trabajando de forma segura en: $branchName" -ForegroundColor Green
    Write-Host "Recuerda programar ÚNICAMENTE dentro de: src/02_Modulos/Intranet.Modulo$equipoNum/" -ForegroundColor Yellow
}

function Validate-Local {
    Write-Host "`n🔍 AUDITORÍA LOCAL ZERO-BLAST-RADIUS" -ForegroundColor Blue
    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "🌿 Rama actual: $currentBranch"
    
    if ($currentBranch -eq "main") {
        Write-Host "⚠️ Estás en la rama 'main'. Crea una rama con la opción 2 antes de programar." -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n🔨 Probando compilación de la solución completa..." -ForegroundColor Blue
    dotnet build IntranetInstitucional.sln --nologo
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ COMPILACIÓN PERFECTA (0 Errores). Tu código está listo para PR." -ForegroundColor Green
    } else {
        Write-Host "`n❌ Hay errores de compilación. Corrige antes de subir." -ForegroundColor Red
    }
}

function Push-Changes {
    Write-Host "`n📤 SUBIR CAMBIOS A GITHUB (Push Seguro)" -ForegroundColor Blue
    Validate-Local
    
    $currentBranch = git rev-parse --abbrev-ref HEAD
    if ($currentBranch -eq "main") {
        Write-Host "⛔ No puedes hacer push directo desde 'main'." -ForegroundColor Red
        return
    }
    
    $msg = Read-Host "`nEscribe un mensaje claro para tu commit (ej: feat(m04): formulario de actas)"
    git add .
    git commit -m "$msg"
    
    Write-Host "`nSubiendo a GitHub..." -ForegroundColor Cyan
    git push origin "$currentBranch"
    
    Write-Host "`n✅ Push completado con éxito a la rama: $currentBranch" -ForegroundColor Green
    Write-Host "👉 Ahora abre tu Pull Request en GitHub: https://github.com/felipeostosb/intranet-institucional-modular/pulls" -ForegroundColor Cyan
}

while ($true) {
    Show-Header
    Write-Host "Selecciona una opción:`n" -ForegroundColor White
    Write-Host "  1) 🚀 Iniciar Intranet Local (dotnet watch / Hot Reload)" -ForegroundColor Cyan
    Write-Host "  2) 🌿 Crear mi Rama de Tarea (moduloXX/mi-tarea)" -ForegroundColor Cyan
    Write-Host "  3) 🔍 Validar mi Código (Auditoría Local y Compilación)" -ForegroundColor Cyan
    Write-Host "  4) 📤 Subir Cambios (Git Commit & Push Seguro)" -ForegroundColor Cyan
    Write-Host "  0) 🚪 Salir`n" -ForegroundColor Cyan
    
    $op = Read-Host "Opción [0-4]"
    switch ($op) {
        "1" { Start-LocalDev }
        "2" { Create-Branch }
        "3" { Validate-Local }
        "4" { Push-Changes }
        "0" { Write-Host "`n¡Hasta pronto!`n" -ForegroundColor Green; exit }
        default { Write-Host "`nOpción no válida." -ForegroundColor Red }
    }
    
    Write-Host "`nPresiona ENTER para volver al menú..." -ForegroundColor Yellow
    Read-Host
}
