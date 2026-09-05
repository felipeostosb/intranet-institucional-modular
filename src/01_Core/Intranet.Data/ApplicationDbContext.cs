using Microsoft.EntityFrameworkCore;
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
