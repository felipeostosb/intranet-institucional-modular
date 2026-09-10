using Microsoft.EntityFrameworkCore;
using Intranet.Core.Entities;

namespace Intranet.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    public DbSet<Persona> Personas => Set<Persona>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Rol> Roles => Set<Rol>();
    public DbSet<UsuarioRol> UsuarioRoles => Set<UsuarioRol>();
    public DbSet<Carrera> Carreras => Set<Carrera>();
    public DbSet<PeriodoAcademico> PeriodosAcademicos => Set<PeriodoAcademico>();
    public DbSet<Aula> Aulas => Set<Aula>();
    public DbSet<UnidadDidactica> UnidadesDidacticas => Set<UnidadDidactica>();
    public DbSet<Estudiante> Estudiantes => Set<Estudiante>();
    public DbSet<Docente> Docentes => Set<Docente>();
    public DbSet<Administrativo> Administrativos => Set<Administrativo>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Persona>(entity =>
        {
            entity.ToTable("core_personas");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Dni).IsUnique();
        });

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.ToTable("core_usuarios");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CodigoInstitucional).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasOne(e => e.Persona)
                  .WithOne()
                  .HasForeignKey<Usuario>(e => e.PersonaId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Rol>(entity =>
        {
            entity.ToTable("core_roles");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Nombre).IsUnique();
        });

        modelBuilder.Entity<UsuarioRol>(entity =>
        {
            entity.ToTable("core_usuario_roles");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UsuarioId, e.RolId }).IsUnique();

            entity.HasOne(e => e.Usuario)
                  .WithMany(u => u.UsuarioRoles)
                  .HasForeignKey(e => e.UsuarioId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Rol)
                  .WithMany(r => r.UsuarioRoles)
                  .HasForeignKey(e => e.RolId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Carrera>(entity =>
        {
            entity.ToTable("core_carreras");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Codigo).IsUnique();
        });

        modelBuilder.Entity<PeriodoAcademico>(entity =>
        {
            entity.ToTable("core_periodos_academicos");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Codigo).IsUnique();
        });

        modelBuilder.Entity<Aula>(entity =>
        {
            entity.ToTable("core_aulas");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Codigo).IsUnique();
        });

        modelBuilder.Entity<UnidadDidactica>(entity =>
        {
            entity.ToTable("core_unidades_didacticas");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Codigo).IsUnique();
            entity.HasOne(e => e.Carrera)
                  .WithMany()
                  .HasForeignKey(e => e.CarreraId);
        });

        modelBuilder.Entity<Estudiante>(entity =>
        {
            entity.ToTable("core_estudiantes");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CodigoEstudiante).IsUnique();
            entity.HasOne(e => e.Persona).WithMany().HasForeignKey(e => e.PersonaId);
            entity.HasOne(e => e.Carrera).WithMany().HasForeignKey(e => e.CarreraId);
            entity.HasOne(e => e.PeriodoIngreso).WithMany().HasForeignKey(e => e.PeriodoIngresoId);
        });

        modelBuilder.Entity<Docente>(entity =>
        {
            entity.ToTable("core_docentes");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CodigoDocente).IsUnique();
            entity.HasOne(e => e.Persona).WithMany().HasForeignKey(e => e.PersonaId);
            entity.HasOne(e => e.CarreraPrincipal).WithMany().HasForeignKey(e => e.CarreraPrincipalId);
        });

        modelBuilder.Entity<Administrativo>(entity =>
        {
            entity.ToTable("core_administrativos");
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.CodigoStaff).IsUnique();
            entity.HasOne(e => e.Persona).WithMany().HasForeignKey(e => e.PersonaId);
        });
    }
}
