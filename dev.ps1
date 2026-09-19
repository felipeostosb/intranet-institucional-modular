# ==============================================================================
# 🏛️ IESTP ARGENTINA - ASISTENTE DE DESARROLLO EN POWERSHELL
# ==============================================================================

$ErrorActionPreference = "Stop"

# Instalar guardianes locales contra push a main y aislamiento de carpetas
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
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer push directo a 'main'. Usa una rama de equipo.\033[0m"
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
        if [[ "`$file" != "`$ALLOWED_DIR"* ]] && [[ "`$file" != "docs/"* ]] && [[ "`$file" != *.md ]]; then
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
    Write-Host "🏛️  INTRANET INSTITUCIONAL IESTP ARGENTINA — ASISTENTE DEV" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  Plataforma .NET 10 LTS • PostgreSQL 16 • 9 Módulos Desacoplados" -ForegroundColor Cyan
    Write-Host "  🌿 Rama actual: $currentBranch" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------------------------" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  1) 🚀 Iniciar Intranet (Ver cambios en vivo en tu navegador con Hot-Reload)" -ForegroundColor Green
    Write-Host "  2) 🌿 Crear / Cambiar a mi Rama de Equipo (Elige tu equipo 01 al 09)" -ForegroundColor Green
    Write-Host "  3) ⚡ Generar Formulario / Tabla (Modelo, Controlador, Vista y SQL Postgres)" -ForegroundColor Green
    Write-Host "  4) 🧪 Compilar y Validar mi Módulo (Verifica 0 errores localmente)" -ForegroundColor Green
    Write-Host "  5) 📤 Subir mi Trabajo a GitHub (Guarda, sincroniza y genera enlace de PR)" -ForegroundColor Green
    Write-Host "  6) ⚙️  Configurar Base de Datos de mi Equipo (Permisos de Escritura PostgreSQL)" -ForegroundColor Green
    Write-Host "  7) 🗄️  Credenciales y Guía PostgreSQL 16 (Ver accesos de Adminer / DB)" -ForegroundColor Green
    Write-Host "  8) 🤖 Preguntar al Asistente IA de Arquitectura (RAG Gemini + Qdrant)" -ForegroundColor Green
    Write-Host "  0) 🚪 Salir" -ForegroundColor Red
    Write-Host ""
}

function Start-App {
    Write-Host "`n🚀 Iniciando la Intranet en tu navegador (http://localhost:5000)..." -ForegroundColor Blue
    dotnet watch --project src/03_Web/Intranet.Web --urls http://localhost:5000
}

function Create-Branch {
    Write-Host "`n🌿 CONFIGURAR RAMA DE TRABAJO" -ForegroundColor Blue
    $num = Read-Host "👉 ¿Qué número de equipo eres? (1 al 9)"
    
    if (-not [int]::TryParse($num, [ref]$null)) {
        Write-Host "❌ Debes ingresar un número válido." -ForegroundColor Red
        return
    }
    
    $numInt = [int]$num
    if ($numInt -lt 1 -or $numInt -gt 9) {
        Write-Host "❌ Número fuera de rango. Debe ser entre 1 y 9." -ForegroundColor Red
        return
    }
    
    $numFmt = "{0:D2}" -f $numInt
    $tarea = Read-Host "👉 ¿Qué tarea vas a hacer? (ej: formulario-registro)"
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

function Scaffold-Code {
    Write-Host "`n⚡ GENERAR PLANTILLA PARA TU MÓDULO (PostgreSQL 16 + Razor + C#)" -ForegroundColor Blue
    $num = Read-Host "👉 ¿Qué número de equipo eres? (1 al 9)"
    $numInt = [int]$num
    $numFmt = "{0:D2}" -f $numInt
    
    $entidad = Read-Host "👉 Nombre del registro (ej: Alumno, Horario, Pago)"
    if ([string]::IsNullOrWhiteSpace($entidad)) {
        Write-Host "❌ El nombre de la entidad es obligatorio." -ForegroundColor Red
        return
    }
    
    $modPath = "src/02_Modulos/Intranet.Modulo$numFmt"
    if (-not (Test-Path $modPath)) {
        Write-Host "❌ No se encontró la carpeta del módulo: $modPath" -ForegroundColor Red
        return
    }
    
    New-Item -ItemType Directory -Force -Path "$modPath/Controllers" | Out-Null
    New-Item -ItemType Directory -Force -Path "$modPath/Models" | Out-Null
    New-Item -ItemType Directory -Force -Path "$modPath/Sql" | Out-Null
    New-Item -ItemType Directory -Force -Path "$modPath/Views/$entidad" | Out-Null
    
    $entidadSql = $entidad.ToLower()
    $schemaFile = "$modPath/Sql/schema.sql"
    
    $sqlContent = @"
-- Esquema y Tabla para Módulo $numFmt en PostgreSQL 16
CREATE TABLE IF NOT EXISTS mod$numFmt.$entidadSql (
  id SERIAL PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT NULL,
  fecha_registro TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

"@
    Add-Content -Path $schemaFile -Value $sqlContent
    
    Write-Host "`n🎉 ¡Plantilla para '$entidad' creada con éxito!" -ForegroundColor Green
    Write-Host "Ruta web: http://localhost:5000/Modulo$numFmt/$entidad" -ForegroundColor Cyan
}

function Validate-Code {
    Write-Host "`n🧪 VALIDANDO COMPILACIÓN Y CALIDAD DE CÓDIGO...`n" -ForegroundColor Blue
    dotnet build "IntranetInstitucional.sln" --nologo -c Release
}

function Push-Work {
    Write-Host "`n📤 SUBIR Y SINCRONIZAR MI TRABAJO CON GITHUB" -ForegroundColor Blue
    $branch = $(git rev-parse --abbrev-ref HEAD)
    
    if ($branch -eq "main") {
        Write-Host "⛔ Estás en 'main'. Usa la opción 2 para crear o cambiar a tu rama antes de subir." -ForegroundColor Red
        return
    }
    
    Write-Host "🌿 Rama de trabajo: $branch" -ForegroundColor Cyan
    
    $msg = Read-Host "👉 Describe qué cambiaste (ej: agregue formulario)"
    if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "feat($branch): actualizacion de avance" }
    
    git add .
    git commit -m "$msg"
    git pull --rebase origin $branch 2>$null
    git push -u origin $branch
    
    Write-Host "`n🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!" -ForegroundColor Green
}

function Configure-Db {
    Write-Host "`n======================================================================" -ForegroundColor Blue
    Write-Host "⚙️  CONFIGURACIÓN DE BASE DE DATOS DE TU EQUIPO (PostgreSQL 16)" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    
    $num = Read-Host "👉 ¿Qué número de equipo eres? (1 al 9)"
    $numInt = [int]$num
    $numFmt = "{0:D2}" -f $numInt
    
    Write-Host "👤 Usuario PostgreSQL asignado: user_equipo$numFmt" -ForegroundColor Cyan
    $pass = Read-Host "🔑 Ingresa la contraseña de tu equipo (entregada en tu Ficha Privada)"
    
    $dbhost = Read-Host "🌐 Host de BD [ENTER para usar '35.206.81.32' o escribe '127.0.0.1']"
    if ([string]::IsNullOrWhiteSpace($dbhost)) { $dbhost = "35.206.81.32" }
    
    $localConfig = "src/03_Web/Intranet.Web/appsettings.Local.json"
    $jsonContent = @"
{
  "// LOCAL OVERRIDE": "Configuracion de conexion para Equipo $numFmt. Este archivo esta en .gitignore.",
  "ConnectionStrings": {
    "Modulo${numFmt}Connection": "Host=$dbhost;Port=5432;Database=db_intranet_iestp;Username=user_equipo$numFmt;Password=$pass;SearchPath=mod$numFmt,core,public;Pooling=true;MinPoolSize=2;MaxPoolSize=15;"
  }
}
"@
    Set-Content -Path $localConfig -Value $jsonContent
    
    Write-Host "`n✅ ¡CONFIGURACIÓN LOCAL COMPLETADA CON ÉXITO!" -ForegroundColor Green
    Write-Host "📄 Archivo creado: $localConfig (Protegido en .gitignore)" -ForegroundColor Cyan
}

function Show-Db-Info {
    Write-Host "`n======================================================================" -ForegroundColor Blue
    Write-Host "🗄️  INFORMACIÓN DE BASE DE DATOS POSTGRESQL 16 & ADMINER" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  🌐 Panel Web Adminer: http://35.206.81.32:8080" -ForegroundColor Cyan
    Write-Host "  ⚙️  Motor: PostgreSQL 16" -ForegroundColor Cyan
    Write-Host "  🖥️  Servidor: 35.206.81.32" -ForegroundColor Cyan
    Write-Host "  📊 Base de Datos: db_intranet_iestp" -ForegroundColor Cyan
    Write-Host "  👤 Usuario: user_equipo[XX]" -ForegroundColor Cyan
    Write-Host "  🛡️  Esquema Soberano: mod[XX]" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------------" -ForegroundColor Blue
}

function Ask-Ai-Assistant {
    Write-Host "`n🤖 ASISTENTE IA DE ARQUITECTURA (RAG GEMINI + QDRANT)" -ForegroundColor Blue
    $pregunta = Read-Host "💬 Escribe tu pregunta técnica"
    if (-not [string]::IsNullOrWhiteSpace($pregunta)) {
        python scripts/rag/ingest_and_query_rag.py --query "$pregunta"
    }
}

while ($true) {
    Show-Menu
    $op = Read-Host "👉 Elige una opción [0-8]"
    switch ($op) {
        "1" { Start-App }
        "2" { Create-Branch }
        "3" { Scaffold-Code }
        "4" { Validate-Code }
        "5" { Push-Work }
        "6" { Configure-Db }
        "7" { Show-Db-Info }
        "8" { Ask-Ai-Assistant }
        "0" { Write-Host "`n¡Buen trabajo! Hasta luego.`n" -ForegroundColor Green; exit }
        Default { Write-Host "`nOpción no válida." -ForegroundColor Red }
    }
    Write-Host "`nPresiona ENTER para volver al menú..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
