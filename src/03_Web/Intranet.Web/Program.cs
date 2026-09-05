using System.Reflection;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using Intranet.Core.Contracts;
using Intranet.Core.Events;
using Intranet.Data;
using Intranet.Data.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Registro de Módulos (9 Equipos en Paralelo)
var mvcBuilder = builder.Services.AddControllersWithViews();

var moduleAssemblies = new List<Assembly>
{
    typeof(Intranet.Modulo01.Controllers.Modulo01Controller).Assembly,
    typeof(Intranet.Modulo02.Controllers.Modulo02Controller).Assembly,
    typeof(Intranet.Modulo03.Controllers.Modulo03Controller).Assembly,
    typeof(Intranet.Modulo04.Controllers.Modulo04Controller).Assembly,
    typeof(Intranet.Modulo05.Controllers.Modulo05Controller).Assembly,
    typeof(Intranet.Modulo06.Controllers.Modulo06Controller).Assembly,
    typeof(Intranet.Modulo07.Controllers.Modulo07Controller).Assembly,
    typeof(Intranet.Modulo08.Controllers.Modulo08Controller).Assembly,
    typeof(Intranet.Modulo09.Controllers.Modulo09Controller).Assembly
};

foreach (var assembly in moduleAssemblies)
{
    mvcBuilder.AddApplicationPart(assembly);
}

// 2. Base de Datos Central (Core)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(connectionString))
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
}

// 3. Inyección de Dependencias Core, Fábrica de Conexiones y EventBus Desacoplado
builder.Services.AddScoped<IUsuarioService, UsuarioService>();
builder.Services.AddSingleton<IModuleDbConnectionFactory, ModuleDbConnectionFactory>();
builder.Services.AddSingleton<IEventPublisher, InMemoryEventBus>();

// 4. Auto-Discovery de Servicios Modulares (IModuloStartup) y Manejadores de Eventos (IEventHandler)
foreach (var assembly in moduleAssemblies)
{
    // A. Startups de Módulo
    var startupTypes = assembly.GetTypes()
        .Where(t => typeof(IModuloStartup).IsAssignableFrom(t) && !t.IsInterface && !t.IsAbstract);

    foreach (var type in startupTypes)
    {
        if (Activator.CreateInstance(type) is IModuloStartup startupInstance)
        {
            startupInstance.ConfigureServices(builder.Services, builder.Configuration);
            Console.WriteLine($"[Auto-Discovery] ✓ Registrado IModuloStartup de: {assembly.GetName().Name}");
        }
    }

    // B. Event Handlers Inter-Modulares Desacoplados
    var handlerTypes = assembly.GetTypes()
        .Where(t => !t.IsAbstract && !t.IsInterface)
        .SelectMany(t => t.GetInterfaces()
            .Where(i => i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IEventHandler<>))
            .Select(i => new { Interface = i, Implementation = t }));

    foreach (var h in handlerTypes)
    {
        builder.Services.AddScoped(h.Interface, h.Implementation);
        Console.WriteLine($"[EventBus] ✓ Registrado {h.Implementation.Name} para evento: {h.Interface.GenericTypeArguments[0].Name}");
    }
}

// 5. Autenticación Centralizada (SSO con Cookies)
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

// 6. Inicialización Automática de Base de Datos y Esquemas al Iniciar
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var db = services.GetService<ApplicationDbContext>();
        if (db != null)
        {
            await DatabaseInitializer.InicializarAsync(db, app.Configuration);
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

app.UseStatusCodePagesWithReExecute("/Home/Error", "?statusCode={0}");

app.UseStaticFiles();
app.UseRouting();

// 7. Middleware de Seguridad
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
