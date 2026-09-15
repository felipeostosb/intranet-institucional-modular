# ==============================================================================
# 🏛️ IESTP ARGENTINA - ASISTENTE DE DESARROLLO EN POWERSHELL
# ==============================================================================

$ErrorActionPreference = "Stop"

# Instalar guardián local contra push a main
if (Test-Path .git) {
    $hookPath = ".git/hooks/pre-push"
    if (-not (Test-Path $hookPath)) {
        $hookDir = ".git/hooks"
        if (-not (Test-Path $hookDir)) { New-Item -ItemType Directory -Path $hookDir | Out-Null }
        $hookScript = @"
#!/usr/bin/env bash
BRANCH=`$(git rev-parse --abbrev-ref HEAD)
if [ "`$BRANCH" = "main" ]; then
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer push directo a 'main'. Usa una rama de equipo.\033[0m"
    exit 1
fi
exit 0
"@
        Set-Content -Path $hookPath -Value $hookScript -NoNewline
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
    Write-Host "  6) 🗄️ Credenciales y Guía PostgreSQL 16 (Ver accesos de Adminer / DB)" -ForegroundColor Green
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
    
    Write-Host "Recuerda programar en: src/02_Modulos/Intranet.Modulo$numFmt/" -ForegroundColor Yellow
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
    
    $entidadRaw = $entidad
    $entidad = ($entidad -replace '\s+', '-') -replace '[^a-zA-Z0-9-]', ''
    if ($entidad -notmatch '^[a-zA-Z][a-zA-Z0-9-]*$') {
        Write-Host "❌ '$entidadRaw' no es un nombre válido. Debe empezar por una letra (ej: Matricula, PagoMensual)." -ForegroundColor Red
        return
    }
    
    # PascalCase
    $segments = $entidad -split '-'
    $pascalSegments = foreach ($seg in $segments) {
        if ([string]::IsNullOrEmpty($seg)) { continue }
        if ($seg.Length -eq 1) { $seg.ToUpper() }
        else {
            $first = $seg.Substring(0, 1).ToUpper()
            $rest = if ($seg -ceq $seg.ToUpper()) { $seg.Substring(1).ToLower() } else { $seg.Substring(1) }
            "$first$rest"
        }
    }
    $entidad = -join $pascalSegments
    
    $modPath = "src/02_Modulos/Intranet.Modulo$numFmt"
    if (-not (Test-Path $modPath)) {
        Write-Host "❌ No se encontró la carpeta del módulo: $modPath" -ForegroundColor Red
        return
    }
    
    $ctrlDir = "$modPath/Controllers"
    $modelDir = "$modPath/Models"
    $viewDir = "$modPath/Views/$entidad"
    $sqlDir = "$modPath/Sql"
    
    New-Item -ItemType Directory -Force -Path $ctrlDir | Out-Null
    New-Item -ItemType Directory -Force -Path $modelDir | Out-Null
    New-Item -ItemType Directory -Force -Path $sqlDir | Out-Null
    New-Item -ItemType Directory -Force -Path $viewDir | Out-Null
    
    $entidadSql = $entidad.ToLower()
    $sqlContent = @"
-- Esquema y Tabla para Módulo $numFmt en PostgreSQL 16
CREATE TABLE IF NOT EXISTS mod${numFmt}.${entidadSql} (
  id SERIAL PRIMARY KEY,
  codigo VARCHAR(30) NOT NULL,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT NULL,
  fecha_registro TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

"@
    Add-Content -Path "$sqlDir/schema.sql" -Value $sqlContent -Encoding utf8
    
    $modelCode = @"
namespace Intranet.Modulo$numFmt.Models;

public class $entidad
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public DateTime FechaRegistro { get; set; } = DateTime.Now;
}
"@
    Set-Content -Path "$modelDir/$entidad.cs" -Value $modelCode
    
    $ctrlCode = @"
using Microsoft.AspNetCore.Mvc;
using Intranet.Core.Controllers;
using Intranet.Modulo$numFmt.Models;

namespace Intranet.Modulo$numFmt.Controllers;

[Route("Modulo$numFmt/[controller]")]
public class ${entidad}Controller : ModuloBaseController
{
    private static readonly List<$entidad> _lista = new()
    {
        new $entidad { Id = 1, Codigo = "REG-001", Nombre = "Registro de Prueba 1", Descripcion = "Demostración inicial" },
        new $entidad { Id = 2, Codigo = "REG-002", Nombre = "Registro de Prueba 2", Descripcion = "Segundo elemento" }
    };

    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {
        ViewData["Title"] = "Gestión de $entidad";
        ViewData["TeamName"] = "Equipo $numFmt";
        ViewData["UsuarioNombre"] = UsuarioActualNombre;
        ViewData["UsuarioRol"] = UsuarioActualRol;

        return View(_lista);
    }

    [HttpPost("Crear")]
    public IActionResult Crear($entidad item)
    {
        if (string.IsNullOrWhiteSpace(item.Nombre))
        {
            MostrarAlertaError("El nombre no puede estar vacío.");
            return RedirectToAction(nameof(Index));
        }

        item.Id = _lista.Count + 1;
        item.FechaRegistro = DateTime.Now;
        _lista.Add(item);

        MostrarAlertaExito("$entidad guardado con éxito.");
        return RedirectToAction(nameof(Index));
    }
}
"@
    Set-Content -Path "$ctrlDir/${entidad}Controller.cs" -Value $ctrlCode
    
    $viewCode = @"
@model IEnumerable<Intranet.Modulo$numFmt.Models.$entidad>
@{
    ViewData["Title"] = "Gestión de $entidad";
}

<div class="space-y-6">
    <div class="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <a href="/Modulo$numFmt" class="text-xs text-blue-600 font-semibold hover:underline">← Módulo $numFmt</a>
                <span class="text-slate-300">•</span>
                <span class="badge badge-primary font-bold text-[10px]">Equipo $numFmt</span>
            </div>
            <h1 class="text-2xl font-extrabold text-slate-900">Listado de ${entidad}s</h1>
            <p class="text-xs text-slate-500">Módulo del Equipo $numFmt. Usuario actual: @ViewData["UsuarioNombre"]</p>
        </div>
        <div class="flex gap-2">
            <a href="/Modulo$numFmt" class="btn btn-ghost btn-sm rounded-xl text-xs">Volver</a>
            <button class="btn btn-primary btn-sm rounded-xl text-xs font-bold" onclick="modal_nuevo.showModal()">+ Nuevo $entidad</button>
        </div>
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
        <h3 class="font-bold text-base mb-3">Nuevo $entidad</h3>
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
"@
    Set-Content -Path "$viewDir/Index.cshtml" -Value $viewCode
    
    Write-Host "`n🎉 ¡Plantilla para '$entidad' creada con éxito!" -ForegroundColor Green
    Write-Host "Ruta web: http://localhost:5000/Modulo$numFmt/$entidad" -ForegroundColor Cyan
    Write-Host "Script SQL añadido en: $sqlDir/schema.sql" -ForegroundColor Cyan
}

function Validate-Code {
    Write-Host "`n🧪 VALIDANDO COMPILACIÓN Y CALIDAD DE CÓDIGO..." -ForegroundColor Blue
    Write-Host "Ejecutando: dotnet build IntranetInstitucional.sln" -ForegroundColor Cyan
    
    try {
        dotnet build "IntranetInstitucional.sln" --nologo -c Release
        Write-Host "`n======================================================================" -ForegroundColor Green
        Write-Host "✅ ¡TODO EL PROYECTO COMPILA CON 0 ERRORES Y 0 WARNINGS!" -ForegroundColor Green
        Write-Host "======================================================================" -ForegroundColor Green
    } catch {
        Write-Host "`n⛔ Se encontraron errores de compilación. Revisa los mensajes de arriba." -ForegroundColor Red
    }
}

function Push-Work {
    Write-Host "`n📤 SUBIR Y SINCRONIZAR MI TRABAJO CON GITHUB" -ForegroundColor Blue
    $branch = $(git rev-parse --abbrev-ref HEAD)
    
    if ($branch -eq "main") {
        Write-Host "⛔ Estás en 'main'. Usa la opción 2 para crear o cambiar a tu rama antes de subir." -ForegroundColor Red
        return
    }
    
    Write-Host "🌿 Rama de trabajo: $branch" -ForegroundColor Cyan
    
    $status = $(git status --porcelain)
    if ($status) {
        $msg = Read-Host "👉 Describe qué cambiaste (ej: agregue formulario)"
        if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "feat($branch): actualizacion de avance" }
        git add .
        git commit -m "$msg"
        Write-Host "✓ Cambios guardados localmente." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No hay archivos nuevos por guardar, sincronizando con GitHub..." -ForegroundColor Yellow
    }
    
    Write-Host "Sincronizando con GitHub..." -ForegroundColor Cyan
    try {
        git pull --rebase origin $branch 2>$null | Out-Null
    } catch {
        git rebase --abort 2>$null | Out-Null
        Write-Host "`n⚠️  CONFLICTO DETECTADO: Un compañero subió cambios que chocan con los tuyos." -ForegroundColor Red
        return
    }
    
    Write-Host "🔨 Compilando tu módulo antes de subir (verificación local)..." -ForegroundColor Cyan
    try {
        dotnet build "IntranetInstitucional.sln" -v q --nologo
    } catch {
        Write-Host "`n⛔ EL CÓDIGO NO COMPILÓ. No se subió nada a GitHub." -ForegroundColor Red
        Write-Host "💡 Corrige los errores de arriba y vuelve a intentar." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Publicando rama '$branch' en GitHub..." -ForegroundColor Cyan
    git push -u origin $branch
    
    Write-Host "`n======================================================================" -ForegroundColor Green
    Write-Host "🎉 ¡TU TRABAJO ESTÁ PUBLICADO Y SINCRONIZADO EN GITHUB!" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "👉 Crea o revisa tu Pull Request aquí:" -ForegroundColor White
    Write-Host "   https://github.com/felipeostosb/intranet-institucional-modular/compare/main...$branch" -ForegroundColor Cyan
}

function Show-DbInfo {
    Write-Host "`n======================================================================" -ForegroundColor Blue
    Write-Host "🗄️  INFORMACIÓN DE BASE DE DATOS POSTGRESQL 16 & ADMINER" -ForegroundColor Blue
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host "  🌐 Panel Web Adminer: http://35.206.81.32:8080" -ForegroundColor Cyan
    Write-Host "  ⚙️  Motor: PostgreSQL 16" -ForegroundColor Cyan
    Write-Host "  🖥️  Servidor: postgres (o 35.206.81.32 desde DBeaver/VS Code)" -ForegroundColor Cyan
    Write-Host "  📊 Base de Datos: db_intranet_iestp" -ForegroundColor Cyan
    Write-Host "  👤 Usuario: user_equipo[XX] (Tu usuario asignado)" -ForegroundColor Cyan
    Write-Host "  🔑 Contraseña: (Consulta tu Ficha Privada entregada por el Administrador)" -ForegroundColor Cyan
    Write-Host "  🛡️  Esquema Soberano: mod[XX] (Tu espacio aislado de tablas)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------------------------------" -ForegroundColor Blue
    Write-Host "  💡 Permisos RBAC: Control total en 'modXX' y lectura (SELECT) en 'core'." -ForegroundColor Yellow
    Write-Host "  💡 Conexión Automática: La app ya lee tu cadena desde appsettings.json." -ForegroundColor Cyan
    Write-Host "======================================================================" -ForegroundColor Blue
    Write-Host ""
}

while ($true) {
    Show-Menu
    $op = Read-Host "👉 Elige una opción [0-6]"
    switch ($op) {
        "1" { Start-App }
        "2" { Create-Branch }
        "3" { Scaffold-Code }
        "4" { Validate-Code }
        "5" { Push-Work }
        "6" { Show-DbInfo }
        "0" { Write-Host "`n¡Buen trabajo! Hasta luego.`n" -ForegroundColor Green; break }
        default { Write-Host "`nOpción no válida." -ForegroundColor Red }
    }
    Write-Host "`nPresiona ENTER para volver al menú..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}
