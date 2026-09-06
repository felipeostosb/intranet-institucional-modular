# ==============================================================================
# 🏛️ IESTP ARGENTINA - ASISTENTE DE DESARROLLO WINDOWS (CLI SENCILLO & RESILIENTE)
# ==============================================================================

# Instalar guardián local contra push a main de forma silenciosa
if (Test-Path ".git") {
    $hookDir = ".git/hooks"
    if (-not (Test-Path $hookDir)) { New-Item -ItemType Directory -Path $hookDir | Out-Null }
    $hookFile = "$hookDir/pre-push"
    if (-not (Test-Path $hookFile)) {
        $hookContent = @'
#!/usr/bin/env bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" = "main" ]; then
    echo -e "\033[1;31m⛔ ALERTA: No puedes hacer push directo a 'main'. Usa una rama de equipo.\033[0m"
    exit 1
fi
exit 0
'@
        Set-Content -Path $hookFile -Value $hookContent -NoNewline
    }
}

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

function Scaffold-Code {
    Write-Host "`n⚡ GENERAR PLANTILLA PARA TU MÓDULO" -ForegroundColor Blue
    $num = Read-Host "👉 ¿Qué número de equipo eres? (1 al 9)"
    $numFmt = "{0:D2}" -f [int]$num
    
    $entidad = Read-Host "👉 Nombre del registro (ej: Alumno, Producto, Pago)"
    if ([string]::IsNullOrWhiteSpace($entidad)) {
        Write-Host "❌ El nombre de la entidad es obligatorio." -ForegroundColor Red
        return
    }
    $entidad = (Get-Culture).TextInfo.ToTitleCase($entidad)
    
    $modPath = "src/02_Modulos/Intranet.Modulo$numFmt"
    $ctrlDir = "$modPath/Controllers"
    $modelDir = "$modPath/Models"
    $viewDir = "$modPath/Views/$entidad"
    
    New-Item -ItemType Directory -Force -Path $ctrlDir | Out-Null
    New-Item -ItemType Directory -Force -Path $modelDir | Out-Null
    New-Item -ItemType Directory -Force -Path $viewDir | Out-Null
    
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
    <div class="bg-white rounded-3xl p-6 border border-slate-200 shadow-sm flex justify-between items-center">
        <div>
            <div class="badge badge-primary font-bold mb-1">Módulo $numFmt</div>
            <h1 class="text-2xl font-extrabold text-slate-900">Listado de ${entidad}s</h1>
            <p class="text-xs text-slate-500">Módulo del Equipo $numFmt. Usuario: @ViewData["UsuarioNombre"]</p>
        </div>
        <button class="btn btn-primary btn-sm rounded-xl" onclick="modal_nuevo.showModal()">+ Nuevo $entidad</button>
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
        "3" { Scaffold-Code }
        "4" { Push-Work }
        "0" { Write-Host "`n¡Buen trabajo! Hasta luego.`n" -ForegroundColor Green; exit }
        default { Write-Host "`nOpción no válida." -ForegroundColor Red }
    }
    Write-Host "`nPresiona ENTER para volver al menú..." -ForegroundColor Yellow
    Read-Host
}
