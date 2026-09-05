using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using Intranet.Core.Contracts;
using Intranet.Data;
using Intranet.Data.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Registro de Módulos (9 Equipos en Paralelo)
builder.Services.AddControllersWithViews()
    .AddApplicationPart(typeof(Intranet.Modulo01.Controllers.Modulo01Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo02.Controllers.Modulo02Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo03.Controllers.Modulo03Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo04.Controllers.Modulo04Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo05.Controllers.Modulo05Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo06.Controllers.Modulo06Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo07.Controllers.Modulo07Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo08.Controllers.Modulo08Controller).Assembly)
    .AddApplicationPart(typeof(Intranet.Modulo09.Controllers.Modulo09Controller).Assembly);

// 2. Base de Datos Central (Core)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(connectionString))
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
}

// 3. Inyección de Dependencias de Servicios Core
builder.Services.AddScoped<IUsuarioService, UsuarioService>();

// 4. Autenticación Centralizada (SSO con Cookies)
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromDays(7);
        options.SlidingExpiration = true;
    });

var app = builder.Build();

// 5. Inicialización Automática de Base de Datos al Iniciar
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var db = services.GetService<ApplicationDbContext>();
        if (db != null)
        {
            await DatabaseInitializer.InicializarAsync(db);
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Startup] Error inicializando DB: {ex.Message}");
    }
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseStaticFiles();
app.UseRouting();

// 6. Middleware de Seguridad
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
