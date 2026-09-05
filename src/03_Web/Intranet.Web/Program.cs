using Microsoft.EntityFrameworkCore;
using Intranet.Data;

var builder = WebApplication.CreateBuilder(args);

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

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (!string.IsNullOrEmpty(connectionString))
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));
}

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
