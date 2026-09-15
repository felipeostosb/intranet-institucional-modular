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

        // Configuración de Esquema Core para PostgreSQL
        modelBuilder.HasDefaultSchema("core");

        modelBuilder.Entity<Persona>(entity =>
        {
            entity.ToTable("personas", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Dni).HasColumnName("dni").HasMaxLength(15);
            entity.Property(e => e.Nombres).HasColumnName("nombres").HasMaxLength(100);
            entity.Property(e => e.Apellidos).HasColumnName("apellidos").HasMaxLength(100);
            entity.Property(e => e.FechaNacimiento).HasColumnName("fecha_nacimiento");
            entity.Property(e => e.Sexo).HasColumnName("sexo").HasMaxLength(10);
            entity.Property(e => e.EmailPersonal).HasColumnName("email_personal").HasMaxLength(150);
            entity.Property(e => e.Telefono).HasColumnName("telefono").HasMaxLength(20);
            entity.Property(e => e.Direccion).HasColumnName("direccion").HasMaxLength(255);
            entity.Property(e => e.FotoUrl).HasColumnName("foto_url").HasMaxLength(255);
            entity.Property(e => e.CreadoEn).HasColumnName("creado_en");
            entity.HasIndex(e => e.Dni).IsUnique();
        });

        modelBuilder.Entity<Usuario>(entity =>
        {
            entity.ToTable("usuarios", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.PersonaId).HasColumnName("persona_id");
            entity.Property(e => e.CodigoInstitucional).HasColumnName("codigo_institucional").HasMaxLength(50);
            entity.Property(e => e.Email).HasColumnName("email").HasMaxLength(150);
            entity.Property(e => e.PasswordHash).HasColumnName("password_hash").HasMaxLength(255);
            entity.Property(e => e.UltimoAcceso).HasColumnName("ultimo_acceso");
            entity.Property(e => e.Estado).HasColumnName("estado");
            entity.Property(e => e.CreadoEn).HasColumnName("creado_en");

            entity.HasIndex(e => e.CodigoInstitucional).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasOne(e => e.Persona)
                  .WithOne()
                  .HasForeignKey<Usuario>(e => e.PersonaId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Rol>(entity =>
        {
            entity.ToTable("roles", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Nombre).HasColumnName("nombre").HasMaxLength(50);
            entity.Property(e => e.Descripcion).HasColumnName("descripcion").HasMaxLength(200);
            entity.HasIndex(e => e.Nombre).IsUnique();
        });

        modelBuilder.Entity<UsuarioRol>(entity =>
        {
            entity.ToTable("usuario_roles", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.UsuarioId).HasColumnName("usuario_id");
            entity.Property(e => e.RolId).HasColumnName("rol_id");
            entity.Property(e => e.AsignadoEn).HasColumnName("asignado_en");
            entity.Property(e => e.EsActivo).HasColumnName("es_activo");

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
            entity.ToTable("carreras", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Codigo).HasColumnName("codigo").HasMaxLength(15);
            entity.Property(e => e.Nombre).HasColumnName("nombre").HasMaxLength(150);
            entity.Property(e => e.TotalSemestres).HasColumnName("total_semestres");
            entity.Property(e => e.Modalidad).HasColumnName("modalidad").HasMaxLength(20);
            entity.Property(e => e.Estado).HasColumnName("estado");
            entity.HasIndex(e => e.Codigo).IsUnique();
        });

        modelBuilder.Entity<PeriodoAcademico>(entity =>
        {
            entity.ToTable("periodos_academicos", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Codigo).HasColumnName("codigo").HasMaxLength(20);
            entity.Property(e => e.FechaInicio).HasColumnName("fecha_inicio");
            entity.Property(e => e.FechaFin).HasColumnName("fecha_fin");
            entity.Property(e => e.EsActivo).HasColumnName("es_activo");
            entity.Property(e => e.PermiteMatricula).HasColumnName("permite_matricula");
            entity.HasIndex(e => e.Codigo).IsUnique();
        });

        modelBuilder.Entity<Aula>(entity =>
        {
            entity.ToTable("aulas", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Codigo).HasColumnName("codigo").HasMaxLength(20);
            entity.Property(e => e.Pabellon).HasColumnName("pabellon").HasMaxLength(10);
            entity.Property(e => e.Aforo).HasColumnName("aforo");
            entity.Property(e => e.Tipo).HasColumnName("tipo").HasMaxLength(30);
            entity.HasIndex(e => e.Codigo).IsUnique();
        });

        modelBuilder.Entity<UnidadDidactica>(entity =>
        {
            entity.ToTable("unidades_didacticas", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CarreraId).HasColumnName("carrera_id");
            entity.Property(e => e.Ciclo).HasColumnName("ciclo").HasMaxLength(5);
            entity.Property(e => e.Codigo).HasColumnName("codigo").HasMaxLength(20);
            entity.Property(e => e.Nombre).HasColumnName("nombre").HasMaxLength(150);
            entity.Property(e => e.Creditos).HasColumnName("creditos");
            entity.Property(e => e.HorasSemanales).HasColumnName("horas_semanales");
            entity.Property(e => e.Tipo).HasColumnName("tipo").HasMaxLength(30);
            entity.HasIndex(e => e.Codigo).IsUnique();
            entity.HasOne(e => e.Carrera)
                  .WithMany()
                  .HasForeignKey(e => e.CarreraId);
        });

        modelBuilder.Entity<Estudiante>(entity =>
        {
            entity.ToTable("estudiantes", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.PersonaId).HasColumnName("persona_id");
            entity.Property(e => e.CodigoEstudiante).HasColumnName("codigo_estudiante").HasMaxLength(30);
            entity.Property(e => e.CarreraId).HasColumnName("carrera_id");
            entity.Property(e => e.PeriodoIngresoId).HasColumnName("periodo_ingreso_id");
            entity.Property(e => e.CicloActual).HasColumnName("ciclo_actual").HasMaxLength(5);
            entity.Property(e => e.Turno).HasColumnName("turno").HasMaxLength(10);
            entity.Property(e => e.Condicion).HasColumnName("condicion").HasMaxLength(15);

            entity.HasIndex(e => e.CodigoEstudiante).IsUnique();
            entity.HasOne(e => e.Persona).WithMany().HasForeignKey(e => e.PersonaId);
            entity.HasOne(e => e.Carrera).WithMany().HasForeignKey(e => e.CarreraId);
            entity.HasOne(e => e.PeriodoIngreso).WithMany().HasForeignKey(e => e.PeriodoIngresoId);
        });

        modelBuilder.Entity<Docente>(entity =>
        {
            entity.ToTable("docentes", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.PersonaId).HasColumnName("persona_id");
            entity.Property(e => e.CodigoDocente).HasColumnName("codigo_docente").HasMaxLength(30);
            entity.Property(e => e.CarreraPrincipalId).HasColumnName("carrera_principal_id");
            entity.Property(e => e.Profesion).HasColumnName("profesion").HasMaxLength(150);
            entity.Property(e => e.GradoAcademico).HasColumnName("grado_academico").HasMaxLength(100);
            entity.Property(e => e.Condicion).HasColumnName("condicion").HasMaxLength(15);

            entity.HasIndex(e => e.CodigoDocente).IsUnique();
            entity.HasOne(e => e.Persona).WithMany().HasForeignKey(e => e.PersonaId);
            entity.HasOne(e => e.CarreraPrincipal).WithMany().HasForeignKey(e => e.CarreraPrincipalId);
        });

        modelBuilder.Entity<Administrativo>(entity =>
        {
            entity.ToTable("administrativos", "core");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.PersonaId).HasColumnName("persona_id");
            entity.Property(e => e.CodigoStaff).HasColumnName("codigo_staff").HasMaxLength(30);
            entity.Property(e => e.Cargo).HasColumnName("cargo").HasMaxLength(100);
            entity.Property(e => e.Area).HasColumnName("area").HasMaxLength(100);

            entity.HasIndex(e => e.CodigoStaff).IsUnique();
            entity.HasOne(e => e.Persona).WithMany().HasForeignKey(e => e.PersonaId);
        });
    }
}
