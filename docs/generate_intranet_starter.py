import os
import uuid

BASE_DIR = "/home/prozac/dev/intranet-institucional-modular"
os.makedirs(BASE_DIR, exist_ok=True)

guids = {
    "solution": str(uuid.uuid4()).upper(),
    "core": str(uuid.uuid4()).upper(),
    "data": str(uuid.uuid4()).upper(),
    "web": str(uuid.uuid4()).upper(),
}
for i in range(1, 10):
    guids[f"mod{i:02d}"] = str(uuid.uuid4()).upper()

folder_core_guid = str(uuid.uuid4()).upper()
folder_mod_guid = str(uuid.uuid4()).upper()
folder_web_guid = str(uuid.uuid4()).upper()

dirs = [
    ".github/workflows",
    ".vscode",
    "src/01_Core/Intranet.Core/Entities",
    "src/01_Core/Intranet.Core/DTOs",
    "src/01_Core/Intranet.Core/Contracts",
    "src/01_Core/Intranet.Data",
    "src/03_Web/Intranet.Web/Controllers",
    "src/03_Web/Intranet.Web/Views/Shared",
    "src/03_Web/Intranet.Web/Views/Home",
    "src/03_Web/Intranet.Web/wwwroot/css",
    "src/03_Web/Intranet.Web/wwwroot/js",
]

for i in range(1, 10):
    mod_name = f"Intranet.Modulo{i:02d}"
    dirs.extend([
        f"src/02_Modulos/{mod_name}/Controllers",
        f"src/02_Modulos/{mod_name}/Models",
        f"src/02_Modulos/{mod_name}/Views/Modulo{i:02d}",
    ])

for d in dirs:
    os.makedirs(os.path.join(BASE_DIR, d), exist_ok=True)

# 2. .gitignore
with open(os.path.join(BASE_DIR, ".gitignore"), "w", encoding="utf-8") as f:
    f.write("""bin/
obj/
.vs/
.vscode/*
!.vscode/launch.json
!.vscode/tasks.json
*.user
*.suo
*.userosscache
*.sln.docstates
*.log
.DS_Store
Thumbs.db
""")

# 3. .vscode
with open(os.path.join(BASE_DIR, ".vscode", "launch.json"), "w", encoding="utf-8") as f:
    f.write("""{
    "version": "0.2.0",
    "configurations": [
        {
            "name": ".NET Core Launch (web)",
            "type": "coreclr",
            "request": "launch",
            "preLaunchTask": "build",
            "program": "${workspaceFolder}/src/03_Web/Intranet.Web/bin/Debug/net8.0/Intranet.Web.dll",
            "args": [],
            "cwd": "${workspaceFolder}/src/03_Web/Intranet.Web",
            "stopAtEntry": false,
            "serverReadyAction": {
                "action": "openExternally",
                "pattern": "\\\\bNow listening on:\\\\s+(https?://\\\\S+)"
            },
            "env": {
                "ASPNETCORE_ENVIRONMENT": "Development"
            }
        }
    ]
}
""")

with open(os.path.join(BASE_DIR, ".vscode", "tasks.json"), "w", encoding="utf-8") as f:
    f.write("""{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "build",
            "command": "dotnet",
            "type": "process",
            "args": [
                "build",
                "${workspaceFolder}/src/03_Web/Intranet.Web/Intranet.Web.csproj",
                "/property:GenerateFullPaths=true",
                "/consoleloggerparameters:NoSummary"
            ],
            "problemMatcher": "$msCompile"
        }
    ]
}
""")

# 4. Intranet.Core.csproj
with open(os.path.join(BASE_DIR, "src/01_Core/Intranet.Core/Intranet.Core.csproj"), "w", encoding="utf-8") as f:
    f.write("""<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
""")

with open(os.path.join(BASE_DIR, "src/01_Core/Intranet.Core/Entities/Usuario.cs"), "w", encoding="utf-8") as f:
    f.write("""namespace Intranet.Core.Entities;

public class Usuario
{
    public int Id { get; set; }
    public string Dni { get; set; } = string.Empty;
    public string CodigoInstitucional { get; set; } = string.Empty;
    public string Nombres { get; set; } = string.Empty;
    public string Apellidos { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Rol { get; set; } = "Alumno";
    public bool Estado { get; set; } = true;
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
}
""")

with open(os.path.join(BASE_DIR, "src/01_Core/Intranet.Core/DTOs/UsuarioDto.cs"), "w", encoding="utf-8") as f:
    f.write("""namespace Intranet.Core.DTOs;

public record UsuarioDto(
    int Id,
    string Dni,
    string CodigoInstitucional,
    string NombreCompleto,
    string Email,
    string Rol
);
""")

# 5. Intranet.Data.csproj
with open(os.path.join(BASE_DIR, "src/01_Core/Intranet.Data/Intranet.Data.csproj"), "w", encoding="utf-8") as f:
    f.write("""<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\\Intranet.Core\\Intranet.Core.csproj" />
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.8" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Relational" Version="8.0.8" />
    <PackageReference Include="Pomelo.EntityFrameworkCore.MySql" Version="8.0.2" />
  </ItemGroup>
</Project>
""")

with open(os.path.join(BASE_DIR, "src/01_Core/Intranet.Data/ApplicationDbContext.cs"), "w", encoding="utf-8") as f:
    f.write("""using Microsoft.EntityFrameworkCore;
using Intranet.Core.Entities;

namespace Intranet.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    public DbSet<Usuario> Usuarios => Set<Usuario>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.ToTable("core_usuarios");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Dni).IsUnique();
            entity.HasIndex(e => e.CodigoInstitucional).IsUnique();
        });
    }
}
""")

# 6. Generate 9 Modules
for i in range(1, 10):
    mod_name = f"Intranet.Modulo{i:02d}"
    mod_dir = os.path.join(BASE_DIR, f"src/02_Modulos/{mod_name}")
    
    with open(os.path.join(mod_dir, f"{mod_name}.csproj"), "w", encoding="utf-8") as f:
        f.write(f"""<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <AddRazorSupportForMvc>true</AddRazorSupportForMvc>
  </PropertyGroup>

  <ItemGroup>
    <FrameworkReference Include="Microsoft.AspNetCore.App" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\\..\\01_Core\\Intranet.Core\\Intranet.Core.csproj" />
  </ItemGroup>
</Project>
""")

    controller_code = f"""using Microsoft.AspNetCore.Mvc;

namespace {mod_name}.Controllers;

[Route("Modulo{i:02d}")]
public class Modulo{i:02d}Controller : Controller
{{
    [HttpGet("")]
    [HttpGet("Index")]
    public IActionResult Index()
    {{
        ViewData["Title"] = "Módulo {i:02d}";
        ViewData["TeamName"] = "Equipo {i:02d}";
        return View();
    }}
}}
"""
    with open(os.path.join(mod_dir, "Controllers", f"Modulo{i:02d}Controller.cs"), "w", encoding="utf-8") as f:
        f.write(controller_code)

    view_code = """@{
    ViewData["Title"] = "Módulo """ + f"{i:02d}" + """";
}

<div class="space-y-6">
    <div class="card bg-base-100 shadow-xl border border-base-200">
        <div class="card-body">
            <div class="flex items-center justify-between flex-wrap gap-4">
                <div>
                    <div class="badge badge-primary badge-outline font-semibold mb-2">Equipo """ + f"{i:02d}" + """</div>
                    <h1 class="text-3xl font-bold text-base-content">Módulo """ + f"{i:02d}" + """ - Panel de Control</h1>
                    <p class="text-base-content/70 mt-1">Este espacio pertenece al <strong>Equipo """ + f"{i:02d}" + """</strong>. Desarrollen aquí sus vistas y formularios.</p>
                </div>
                <button class="btn btn-primary gap-2" onclick="my_modal_""" + str(i) + """.showModal()">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>
                    Nuevo Registro
                </button>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="stat bg-base-100 shadow-md rounded-2xl border border-base-200">
            <div class="stat-figure text-primary">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            </div>
            <div class="stat-title">Registros Activos</div>
            <div class="stat-value text-primary">24</div>
            <div class="stat-desc">Base de datos: db_modulo""" + f"{i:02d}" + """</div>
        </div>
        
        <div class="stat bg-base-100 shadow-md rounded-2xl border border-base-200">
            <div class="stat-figure text-secondary">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path></svg>
            </div>
            <div class="stat-title">Operaciones Hoy</div>
            <div class="stat-value text-secondary">100%</div>
            <div class="stat-desc">Aislamiento Total OK</div>
        </div>
        
        <div class="stat bg-base-100 shadow-md rounded-2xl border border-base-200">
            <div class="stat-figure text-accent">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-8 h-8 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            </div>
            <div class="stat-title">Estado del Módulo</div>
            <div class="stat-value text-accent">En Línea</div>
            <div class="stat-desc">ASP.NET Core .NET 8</div>
        </div>
    </div>

    <div class="card bg-base-100 shadow-xl border border-base-200 overflow-hidden">
        <div class="p-6 border-b border-base-200">
            <h2 class="text-xl font-bold">Listado de Datos (Equipo """ + f"{i:02d}" + """)</h2>
            <p class="text-sm text-base-content/70">Diseño responsivo con Tailwind CSS + DaisyUI listo para conectar a MariaDB.</p>
        </div>
        <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Código</th>
                        <th>Descripción</th>
                        <th>Fecha</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <th>1</th>
                        <td><span class="font-mono font-semibold text-primary">REG-001</span></td>
                        <td>Registro de prueba del Módulo """ + f"{i:02d}" + """</td>
                        <td>@DateTime.Now.ToString("dd/MM/yyyy")</td>
                        <td><span class="badge badge-success gap-1">Completado</span></td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</div>

<dialog id="my_modal_""" + str(i) + """" class="modal">
    <div class="modal-box">
        <h3 class="font-bold text-lg">Nuevo Registro - Módulo """ + f"{i:02d}" + """</h3>
        <p class="py-2 text-sm text-base-content/70">Formulario listo para vincular al controlador.</p>
        <div class="space-y-4 my-4">
            <div class="form-control">
                <label class="label"><span class="label-text">Código / Título</span></label>
                <input type="text" placeholder="Ej: REG-2026" class="input input-bordered w-full" />
            </div>
            <div class="form-control">
                <label class="label"><span class="label-text">Descripción</span></label>
                <textarea class="textarea textarea-bordered h-24" placeholder="Detalle del registro..."></textarea>
            </div>
        </div>
        <div class="modal-action">
            <form method="dialog">
                <button class="btn btn-ghost mr-2">Cancelar</button>
                <button class="btn btn-primary">Guardar</button>
            </form>
        </div>
    </div>
</dialog>
"""
    with open(os.path.join(mod_dir, f"Views/Modulo{i:02d}/Index.cshtml"), "w", encoding="utf-8") as f:
        f.write(view_code)

    with open(os.path.join(mod_dir, "README.md"), "w", encoding="utf-8") as f:
        f.write(f"""# 📁 Intranet.Modulo{i:02d} (Espacio Soberano del Equipo {i:02d})

¡Bienvenidos Equipo {i:02d}! Este es su proyecto independiente dentro de la Intranet Institucional.

## 🚀 Reglas de Trabajo para su Equipo:
1. **Su Carpeta Exclusiva:** Todo el código de su equipo (Controladores, Vistas Razor, Modelos) debe estar dentro de `src/02_Modulos/Intranet.Modulo{i:02d}/`.
2. **Su Ruta Web:** Su módulo se accede en el navegador en la ruta: `/Modulo{i:02d}`.
3. **Su Base de Datos:** Tienen asignada la base de datos `db_modulo{i:02d}` en MariaDB (`mili2`).
4. **Git Branch:** Creen sus ramas de trabajo a partir de `feature/modulo-{i:02d}`.
""")

# 7. Intranet.Web.csproj
with open(os.path.join(BASE_DIR, "src/03_Web/Intranet.Web/Intranet.Web.csproj"), "w", encoding="utf-8") as f:
    mod_refs = "\n".join([f'    <ProjectReference Include="..\\..\\02_Modulos\\Intranet.Modulo{i:02d}\\Intranet.Modulo{i:02d}.csproj" />' for i in range(1, 10)])
    f.write(f"""<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\\..\\01_Core\\Intranet.Core\\Intranet.Core.csproj" />
    <ProjectReference Include="..\\..\\01_Core\\Intranet.Data\\Intranet.Data.csproj" />
{mod_refs}
  </ItemGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.8">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
  </ItemGroup>
</Project>
""")

# Program.cs
with open(os.path.join(BASE_DIR, "src/03_Web/Intranet.Web/Program.cs"), "w", encoding="utf-8") as f:
    app_parts = "\n".join([f"    .AddApplicationPart(typeof(Intranet.Modulo{i:02d}.Controllers.Modulo{i:02d}Controller).Assembly)" for i in range(1, 10)])
    f.write(f"""using Microsoft.EntityFrameworkCore;
using Intranet.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews()
{app_parts};

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(connectionString))
{{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
}}

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{{controller=Home}}/{{action=Index}}/{{id?}}");

app.Run();
""")

# appsettings.json
with open(os.path.join(BASE_DIR, "src/03_Web/Intranet.Web/appsettings.json"), "w", encoding="utf-8") as f:
    f.write("""{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=35.208.213.59;Port=3306;Database=db_core;User=root;Password=@921291524;"
  }
}
""")

# HomeController.cs
with open(os.path.join(BASE_DIR, "src/03_Web/Intranet.Web/Controllers/HomeController.cs"), "w", encoding="utf-8") as f:
    f.write("""using Microsoft.AspNetCore.Mvc;

namespace Intranet.Web.Controllers;

public class HomeController : Controller
{
    public IActionResult Index()
    {
        ViewData["Title"] = "Panel Principal";
        return View();
    }

    public IActionResult Error()
    {
        return View();
    }
}
""")

# Layout with Tailwind CSS + DaisyUI
with open(os.path.join(BASE_DIR, "src/03_Web/Intranet.Web/Views/Shared/_Layout.cshtml"), "w", encoding="utf-8") as f:
    menu_items = "\n".join([f"""                <li>
                    <a href="/Modulo{i:02d}" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-base-200 transition font-medium">
                        <span class="badge badge-sm badge-primary">M{i:02d}</span>
                        <span>Módulo {i:02d}</span>
                    </a>
                </li>""" for i in range(1, 10)])

    f.write(f"""<!DOCTYPE html>
<html lang="es" data-theme="light">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>@ViewData["Title"] - Intranet Institucional</title>
    
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.10/dist/full.min.css" rel="stylesheet" type="text/css" />
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        body {{
            font-family: 'Plus Jakarta Sans', sans-serif;
        }}
    </style>
</head>
<body class="bg-base-200/50 min-h-screen flex flex-col">
    <div class="drawer lg:drawer-open flex-1">
        <input id="main-drawer" type="checkbox" class="drawer-toggle" />
        
        <div class="drawer-content flex flex-col">
            <div class="navbar bg-base-100 shadow-sm sticky top-0 z-30 px-4 lg:px-8 border-b border-base-200">
                <div class="flex-none lg:hidden">
                    <label for="main-drawer" aria-label="open sidebar" class="btn btn-square btn-ghost">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="inline-block w-6 h-6 stroke-current"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
                    </label>
                </div>
                <div class="flex-1">
                    <a href="/" class="text-xl font-extrabold tracking-tight bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
                        🏛️ INTRANET INSTITUCIONAL
                    </a>
                </div>
                <div class="flex-none gap-3">
                    <div class="badge badge-accent badge-outline hidden sm:flex">36 Desarrolladores</div>
                    <div class="dropdown dropdown-end">
                        <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar placeholder">
                            <div class="bg-primary text-primary-content rounded-full w-10">
                                <span>FO</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <main class="flex-1 p-4 lg:p-8 max-w-7xl w-full mx-auto">
                @RenderBody()
            </main>

            <footer class="footer footer-center p-4 bg-base-100 text-base-content border-t border-base-200 text-sm">
                <div>
                    <p>© @DateTime.Now.Year - Intranet Institucional Modular (.NET 8 + MariaDB + Tailwind CSS)</p>
                </div>
            </footer>
        </div> 

        <div class="drawer-side z-40">
            <label for="main-drawer" aria-label="close sidebar" class="drawer-overlay"></label> 
            <aside class="bg-base-100 w-72 min-h-screen border-r border-base-200 flex flex-col p-4">
                <div class="p-4 mb-2 flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-primary flex items-center justify-center text-primary-content font-bold shadow-md">
                        IT
                    </div>
                    <div>
                        <h2 class="font-bold text-base leading-tight">Instituto Argentina</h2>
                        <span class="text-xs text-base-content/60">Arquitectura Modular</span>
                    </div>
                </div>

                <ul class="menu menu-md w-full space-y-1 flex-1">
                    <li>
                        <a href="/" class="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-base-200 transition font-semibold">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" /></svg>
                            <span>Dashboard General</span>
                        </a>
                    </li>
                    <li class="menu-title pt-4 text-xs font-bold uppercase tracking-wider text-base-content/50">Módulos por Equipo (9)</li>
{menu_items}
                </ul>
            </aside>
        </div>
    </div>

    @await RenderSectionAsync("Scripts", required: false)
</body>
</html>
""")

# Home/Index.cshtml
with open(os.path.join(BASE_DIR, "src/03_Web/Intranet.Web/Views/Home/Index.cshtml"), "w", encoding="utf-8") as f:
    cards = "\n".join([f"""        <div class="card bg-base-100 shadow-md hover:shadow-xl transition border border-base-200">
            <div class="card-body">
                <div class="flex items-center justify-between">
                    <span class="badge badge-primary font-bold">Módulo {i:02d}</span>
                    <span class="text-xs text-base-content/50 font-mono">db_modulo{i:02d}</span>
                </div>
                <h2 class="card-title text-lg mt-2">Módulo {i:02d}</h2>
                <p class="text-sm text-base-content/70">Asignado al <strong>Equipo {i:02d}</strong> (4 Desarrolladores).</p>
                <div class="card-action justify-end mt-4">
                    <a href="/Modulo{i:02d}" class="btn btn-sm btn-primary btn-outline w-full">Ingresar al Módulo</a>
                </div>
            </div>
        </div>""" for i in range(1, 10)])

    f.write(f"""<div class="space-y-8">
    <div class="hero bg-gradient-to-r from-primary to-secondary rounded-3xl text-primary-content p-8 lg:p-12 shadow-2xl">
        <div class="hero-content flex-col lg:flex-row gap-8">
            <div class="max-w-2xl">
                <div class="badge badge-accent font-bold mb-4">Arquitectura Modular .NET 8</div>
                <h1 class="text-4xl lg:text-5xl font-extrabold tracking-tight">Intranet Institucional</h1>
                <p class="py-4 text-lg text-primary-content/90">
                    Plataforma académica y administrativa desarrollada por <strong>36 ingenieros</strong> en <strong>9 equipos autónomos</strong> con despliegue continuo en la nube y arquitectura desacoplada.
                </p>
            </div>
        </div>
    </div>

    <div>
        <div class="flex items-center justify-between mb-6">
            <div>
                <h2 class="text-2xl font-bold text-base-content">Módulos del Sistema (9 Equipos)</h2>
                <p class="text-sm text-base-content/60">Cada equipo trabaja en su propio espacio independiente sin colisiones.</p>
            </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
{cards}
        </div>
    </div>
</div>
""")

# 8. Solution File
sln_header = """Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
"""

sln_projects = f"""Project("{{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}}") = "Intranet.Core", "src\\01_Core\\Intranet.Core\\Intranet.Core.csproj", "{{{guids['core']}}}"
EndProject
Project("{{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}}") = "Intranet.Data", "src\\01_Core\\Intranet.Data\\Intranet.Data.csproj", "{{{guids['data']}}}"
EndProject
Project("{{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}}") = "Intranet.Web", "src\\03_Web\\Intranet.Web\\Intranet.Web.csproj", "{{{guids['web']}}}"
EndProject
"""

for i in range(1, 10):
    mod_name = f"Intranet.Modulo{i:02d}"
    sln_projects += f"""Project("{{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}}") = "{mod_name}", "src\\02_Modulos\\{mod_name}\\{mod_name}.csproj", "{{{guids[f'mod{i:02d}']}}}"
EndProject
"""

sln_projects += f"""Project("{{2150E333-8FDC-42A3-9474-1A3956D46DE8}}") = "01_Core", "01_Core", "{{{folder_core_guid}}}"
EndProject
Project("{{2150E333-8FDC-42A3-9474-1A3956D46DE8}}") = "02_Modulos", "02_Modulos", "{{{folder_mod_guid}}}"
EndProject
Project("{{2150E333-8FDC-42A3-9474-1A3956D46DE8}}") = "03_Web", "03_Web", "{{{folder_web_guid}}}"
EndProject
"""

sln_nesting = f"""	GlobalSection(NestedProjects) = preSolution
		{{{guids['core']}}} = {{{folder_core_guid}}}
		{{{guids['data']}}} = {{{folder_core_guid}}}
		{{{guids['web']}}} = {{{folder_web_guid}}}
"""
for i in range(1, 10):
    sln_nesting += f"\t\t{{{guids[f'mod{i:02d}']}}} = {{{folder_mod_guid}}}\n"
sln_nesting += "\tEndGlobalSection\n"

sln_config = """	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
"""

with open(os.path.join(BASE_DIR, "IntranetInstitucional.sln"), "w", encoding="utf-8") as f:
    f.write(sln_header + sln_projects + "Global\n" + sln_config + sln_nesting + "EndGlobal\n")

# 9. Dockerfile
with open(os.path.join(BASE_DIR, "Dockerfile"), "w", encoding="utf-8") as f:
    mod_copies = "\n".join([f'COPY ["src/02_Modulos/Intranet.Modulo{i:02d}/Intranet.Modulo{i:02d}.csproj", "src/02_Modulos/Intranet.Modulo{i:02d}/"]' for i in range(1, 10)])
    f.write(f"""FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /src

COPY ["src/01_Core/Intranet.Core/Intranet.Core.csproj", "src/01_Core/Intranet.Core/"]
COPY ["src/01_Core/Intranet.Data/Intranet.Data.csproj", "src/01_Core/Intranet.Data/"]
{mod_copies}
COPY ["src/03_Web/Intranet.Web/Intranet.Web.csproj", "src/03_Web/Intranet.Web/"]

RUN dotnet restore "src/03_Web/Intranet.Web/Intranet.Web.csproj"

COPY . .
WORKDIR "/src/src/03_Web/Intranet.Web"
RUN dotnet publish -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS final
WORKDIR /app
COPY --from=build /app/publish .

EXPOSE 5000
ENTRYPOINT ["dotnet", "Intranet.Web.dll"]
""")

# 10. .github/workflows/deploy.yml
with open(os.path.join(BASE_DIR, ".github/workflows/deploy.yml"), "w", encoding="utf-8") as f:
    f.write("""name: CI/CD Pipeline - Despliegue en mili3

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: 1. Checkout del Repositorio
        uses: actions/checkout@v4

      - name: 2. Login en GitHub Container Registry (ghcr.io)
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: 3. Construir y Publicar Imagen Docker en la Nube
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:latest

      - name: 4. Despliegue Automático en mili3 vía SSH
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.MILI3_HOST }}
          username: fob
          key: ${{ secrets.MILI3_SSH_KEY }}
          script: |
            cd /home/fob/services/app-net
            docker compose pull app
            docker compose up -d app
            echo ">>> DESPLIEGUE EXITOSO EN MILI3 <<<"
""")

# 11. .github/CODEOWNERS
with open(os.path.join(BASE_DIR, ".github/CODEOWNERS"), "w", encoding="utf-8") as f:
    owners = "\n".join([f"/src/02_Modulos/Intranet.Modulo{i:02d}/ @team-modulo{i:02d}" for i in range(1, 10)])
    f.write(f"""/src/01_Core/ @felipeostosb
/src/03_Web/  @felipeostosb
{owners}
""")

# 12. README.md
with open(os.path.join(BASE_DIR, "README.md"), "w", encoding="utf-8") as f:
    f.write("""# 🏛️ Intranet Institucional Modular (.NET 8 + Tailwind CSS + MariaDB)

Bienvenido al proyecto integrador de la Intranet Institucional. Este sistema está construido con una **Arquitectura Modular Desacoplada** diseñada para que **36 desarrolladores (9 equipos de 4 personas)** trabajen en paralelo con total autonomía y cero colisiones.

---

## 🚀 Guía de Inicio Rápido para Desarrolladores

### 💜 Si usas Visual Studio (el morado en Windows):
1. Clona el repositorio: `git clone https://github.com/felipeostosb/intranet-institucional-modular.git`
2. Haz doble clic en el archivo **`IntranetInstitucional.sln`**.
3. Presiona **`F5`** (o clic en el botón verde de reproducir).
4. ¡Listo! Tu navegador abrirá automáticamente la Intranet en `http://localhost:5000`.

### 💙 Si usas Visual Studio Code (en Windows, Mac o Linux):
1. Clona el repositorio y abre la carpeta del proyecto en VS Code.
2. Abre la terminal integrada (`Ctrl + \``) y ejecuta:
   ```bash
   dotnet watch run --project src/03_Web/Intranet.Web
   ```
3. Cada vez que modifiques código y guardes (`Ctrl + S`), la web se actualizará sola en **100 milisegundos (Hot Reload)**.

---

## 👥 Asignación de Carpetas por Equipo (9 Módulos):
Cada equipo tiene su propia carpeta soberana dentro de `src/02_Modulos/`:
* **Equipo 1:** `src/02_Modulos/Intranet.Modulo01/` (Ruta Web: `/Modulo01`)
* **Equipo 2:** `src/02_Modulos/Intranet.Modulo02/` (Ruta Web: `/Modulo02`)
* **Equipo 3:** `src/02_Modulos/Intranet.Modulo03/` (Ruta Web: `/Modulo03`)
* **Equipo 4:** `src/02_Modulos/Intranet.Modulo04/` (Ruta Web: `/Modulo04`)
* **Equipo 5:** `src/02_Modulos/Intranet.Modulo05/` (Ruta Web: `/Modulo05`)
* **Equipo 6:** `src/02_Modulos/Intranet.Modulo06/` (Ruta Web: `/Modulo06`)
* **Equipo 7:** `src/02_Modulos/Intranet.Modulo07/` (Ruta Web: `/Modulo07`)
* **Equipo 8:** `src/02_Modulos/Intranet.Modulo08/` (Ruta Web: `/Modulo08`)
* **Equipo 9:** `src/02_Modulos/Intranet.Modulo09/` (Ruta Web: `/Modulo09`)

---

## 🎨 Estilos y Diseño (Tailwind CSS + DaisyUI)
La Intranet ya viene con **Tailwind CSS y DaisyUI** preconfigurados en el Layout maestro:
* Botones modernos: `<button class="btn btn-primary">Guardar</button>`
* Tarjetas: `<div class="card bg-base-100 shadow-xl p-6">...</div>`
* Tablas: `<table class="table table-zebra w-full">...</table>`
* Modales: `<dialog class="modal">...</dialog>`
""")

print("=== STARTER KIT GENERADO EXITOSAMENTE ===")
