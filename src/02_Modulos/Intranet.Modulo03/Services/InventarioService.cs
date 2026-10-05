using System.Data;
using Intranet.Core.Contracts;
using Intranet.Modulo03.Models;

namespace Intranet.Modulo03.Services;

public class InventarioService
{
    private readonly IModuleDbConnectionFactory _connectionFactory;

    public InventarioService(IModuleDbConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    private IDbConnection OpenConnection()
    {
        var connection = _connectionFactory.CreateConnection("03");
        connection.Open();
        return connection;
    }

    private static IDbDataParameter AddParameter(IDbCommand command, string name, object? value)
    {
        var parameter = command.CreateParameter();
        parameter.ParameterName = name;
        parameter.Value = value ?? DBNull.Value;
        command.Parameters.Add(parameter);
        return parameter;
    }

    private static string? StringValue(IDataRecord record, string name)
    {
        var value = record[name];
        return value == DBNull.Value ? null : Convert.ToString(value);
    }

    public List<BienInventario> ObtenerInventario(InventarioFiltroModel? filtro = null)
    {
        var lista = new List<BienInventario>();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();

        var sql = """
            SELECT
                b.id_bien,
                b.id_almacen,
                b.id_clasificacion,
                b.cbi,
                b.codigo_inventario,
                b.descripcion,
                cb.nombre AS clasificacion,
                b.marca,
                b.modelo,
                b.serie,
                b.procedencia,
                b.fecha_ingreso,
                b.estado,
                a.nombre AS almacen_actual,
                a.ubicacion AS ubicacion_almacen,
                amb.nombre AS ambiente_actual,
                asg.responsable,
                b.observacion
            FROM mod03.bien b
            JOIN mod03.almacen a ON a.id_almacen = b.id_almacen
            JOIN mod03.clasificaciones_bien cb ON cb.id_clasificacion = b.id_clasificacion
            LEFT JOIN LATERAL (
                SELECT ax.*
                FROM mod03.asignacion ax
                WHERE ax.id_bien = b.id_bien
                  AND ax.estado = 'Activa'
                ORDER BY ax.fecha_asignacion DESC, ax.id_asignacion DESC
                LIMIT 1
            ) AS asg ON TRUE
            LEFT JOIN mod03.ambiente amb ON amb.id_ambiente = asg.id_ambiente
            WHERE 1 = 1
            """;

        if (!string.IsNullOrWhiteSpace(filtro?.Q))
        {
            sql += " AND (LOWER(b.cbi) LIKE LOWER(@q) OR LOWER(COALESCE(b.codigo_inventario,'')) LIKE LOWER(@q) OR LOWER(b.descripcion) LIKE LOWER(@q) OR LOWER(COALESCE(b.marca,'')) LIKE LOWER(@q) OR LOWER(COALESCE(b.modelo,'')) LIKE LOWER(@q) OR LOWER(COALESCE(b.serie,'')) LIKE LOWER(@q) OR LOWER(b.estado) LIKE LOWER(@q) OR LOWER(cb.nombre) LIKE LOWER(@q))";
            AddParameter(command, "@q", $"%{filtro.Q.Trim()}%");
        }

        if (!string.IsNullOrWhiteSpace(filtro?.Estado))
        {
            sql += " AND b.estado = @estado";
            AddParameter(command, "@estado", filtro.Estado);
        }

        if (filtro?.IdClasificacion is not null)
        {
            sql += " AND b.id_clasificacion = @clasificacion";
            AddParameter(command, "@clasificacion", filtro.IdClasificacion.Value);
        }

        if (filtro?.IdAlmacen is not null)
        {
            sql += " AND b.id_almacen = @almacen";
            AddParameter(command, "@almacen", filtro.IdAlmacen.Value);
        }

        sql += " ORDER BY b.id_bien DESC";
        command.CommandText = sql;

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            lista.Add(new BienInventario
            {
                IdBien = reader.GetInt32(reader.GetOrdinal("id_bien")),
                IdAlmacen = reader.GetInt32(reader.GetOrdinal("id_almacen")),
                IdClasificacion = reader.GetInt32(reader.GetOrdinal("id_clasificacion")),
                Cbi = reader.GetString(reader.GetOrdinal("cbi")),
                CodigoInventario = StringValue(reader, "codigo_inventario"),
                Descripcion = reader.GetString(reader.GetOrdinal("descripcion")),
                Clasificacion = reader.GetString(reader.GetOrdinal("clasificacion")),
                Marca = StringValue(reader, "marca"),
                Modelo = StringValue(reader, "modelo"),
                Serie = StringValue(reader, "serie"),
                Procedencia = reader.GetString(reader.GetOrdinal("procedencia")),
                FechaIngreso = reader.GetDateTime(reader.GetOrdinal("fecha_ingreso")),
                Estado = reader.GetString(reader.GetOrdinal("estado")),
                AlmacenActual = reader.GetString(reader.GetOrdinal("almacen_actual")),
                UbicacionAlmacen = StringValue(reader, "ubicacion_almacen"),
                AmbienteActual = StringValue(reader, "ambiente_actual"),
                Responsable = StringValue(reader, "responsable"),
                Observacion = StringValue(reader, "observacion")
            });
        }

        return lista;
    }

    public BienInventario? ObtenerBien(int id)
    {
        return ObtenerInventario(new InventarioFiltroModel()).FirstOrDefault(x => x.IdBien == id);
    }

    public List<AlmacenModel> ObtenerAlmacenes(bool soloActivos = false)
    {
        var lista = new List<AlmacenModel>();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT a.id_almacen, a.id_especialidad, e.nombre AS especialidad,
                   a.nombre, a.ubicacion, a.responsable, a.estado
            FROM mod03.almacen a
            LEFT JOIN mod03.especialidad e ON e.id_especialidad = a.id_especialidad
            WHERE 1 = 1
            """ + (soloActivos ? " AND a.estado = 'Activo'" : "") + " ORDER BY a.nombre;";

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            lista.Add(new AlmacenModel
            {
                IdAlmacen = reader.GetInt32(reader.GetOrdinal("id_almacen")),
                IdEspecialidad = reader["id_especialidad"] == DBNull.Value ? null : reader.GetInt32(reader.GetOrdinal("id_especialidad")),
                Especialidad = StringValue(reader, "especialidad"),
                Nombre = reader.GetString(reader.GetOrdinal("nombre")),
                Ubicacion = StringValue(reader, "ubicacion"),
                Responsable = StringValue(reader, "responsable"),
                Estado = reader.GetString(reader.GetOrdinal("estado"))
            });
        }
        return lista;
    }

    public List<ClasificacionModel> ObtenerClasificaciones(bool soloActivas = true)
    {
        var lista = new List<ClasificacionModel>();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id_clasificacion, nombre, estado FROM mod03.clasificaciones_bien" + (soloActivas ? " WHERE estado = 'Activo'" : "") + " ORDER BY nombre;";
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            lista.Add(new ClasificacionModel
            {
                IdClasificacion = reader.GetInt32(reader.GetOrdinal("id_clasificacion")),
                Nombre = reader.GetString(reader.GetOrdinal("nombre")),
                Estado = reader.GetString(reader.GetOrdinal("estado"))
            });
        }
        return lista;
    }

    public List<AmbienteModel> ObtenerAmbientes(bool soloActivos = true)
    {
        var lista = new List<AmbienteModel>();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT a.id_ambiente, a.id_especialidad, e.nombre AS especialidad,
                   a.nombre, a.estado
            FROM mod03.ambiente a
            LEFT JOIN mod03.especialidad e ON e.id_especialidad = a.id_especialidad
            WHERE 1 = 1
            """ + (soloActivos ? " AND a.estado = 'Activo'" : "") + " ORDER BY e.nombre, a.nombre;";
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            lista.Add(new AmbienteModel
            {
                IdAmbiente = reader.GetInt32(reader.GetOrdinal("id_ambiente")),
                IdEspecialidad = reader["id_especialidad"] == DBNull.Value ? null : reader.GetInt32(reader.GetOrdinal("id_especialidad")),
                Especialidad = StringValue(reader, "especialidad"),
                Nombre = reader.GetString(reader.GetOrdinal("nombre")),
                Estado = reader.GetString(reader.GetOrdinal("estado"))
            });
        }
        return lista;
    }

    public List<BienInventario> ObtenerBienesDisponiblesAsignacion()
    {
        var todos = ObtenerInventario();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT id_bien FROM mod03.asignacion WHERE estado = 'Activa';";
        var ocupados = new HashSet<int>();
        using var reader = command.ExecuteReader();
        while (reader.Read()) ocupados.Add(reader.GetInt32(0));
        return todos.Where(x => !ocupados.Contains(x.IdBien) && x.Estado != "De baja").ToList();
    }

    public void RegistrarBien(BienFormModel model)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT INTO mod03.bien
            (id_almacen, id_clasificacion, cbi, codigo_inventario, descripcion,
             marca, modelo, serie, procedencia, fecha_ingreso, estado, observacion)
            VALUES
            (@almacen, @clasificacion, @cbi, @codigo, @descripcion,
             @marca, @modelo, @serie, @procedencia, @fecha, @estado, @observacion);
            """;
        AddParameter(command, "@almacen", model.IdAlmacen);
        AddParameter(command, "@clasificacion", model.IdClasificacion);
        AddParameter(command, "@cbi", model.Cbi.Trim());
        AddParameter(command, "@codigo", NullIfEmpty(model.CodigoInventario));
        AddParameter(command, "@descripcion", model.Descripcion.Trim());
        AddParameter(command, "@marca", NullIfEmpty(model.Marca));
        AddParameter(command, "@modelo", NullIfEmpty(model.Modelo));
        AddParameter(command, "@serie", NullIfEmpty(model.Serie));
        AddParameter(command, "@procedencia", model.Procedencia);
        AddParameter(command, "@fecha", model.FechaIngreso.Date);
        AddParameter(command, "@estado", model.Estado);
        AddParameter(command, "@observacion", NullIfEmpty(model.Observacion));
        command.ExecuteNonQuery();
    }

    public void ActualizarBien(BienFormModel model)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            UPDATE mod03.bien
            SET id_almacen = @almacen,
                id_clasificacion = @clasificacion,
                cbi = @cbi,
                codigo_inventario = @codigo,
                descripcion = @descripcion,
                marca = @marca,
                modelo = @modelo,
                serie = @serie,
                procedencia = @procedencia,
                fecha_ingreso = @fecha,
                estado = @estado,
                observacion = @observacion
            WHERE id_bien = @id;
            """;
        AddParameter(command, "@id", model.IdBien);
        AddParameter(command, "@almacen", model.IdAlmacen);
        AddParameter(command, "@clasificacion", model.IdClasificacion);
        AddParameter(command, "@cbi", model.Cbi.Trim());
        AddParameter(command, "@codigo", NullIfEmpty(model.CodigoInventario));
        AddParameter(command, "@descripcion", model.Descripcion.Trim());
        AddParameter(command, "@marca", NullIfEmpty(model.Marca));
        AddParameter(command, "@modelo", NullIfEmpty(model.Modelo));
        AddParameter(command, "@serie", NullIfEmpty(model.Serie));
        AddParameter(command, "@procedencia", model.Procedencia);
        AddParameter(command, "@fecha", model.FechaIngreso.Date);
        AddParameter(command, "@estado", model.Estado);
        AddParameter(command, "@observacion", NullIfEmpty(model.Observacion));
        command.ExecuteNonQuery();
    }

    public void DarDeBaja(int id)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = "UPDATE mod03.bien SET estado = 'De baja' WHERE id_bien = @id;";
        AddParameter(command, "@id", id);
        command.ExecuteNonQuery();
    }

    public void EliminarBien(int id)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = "DELETE FROM mod03.bien WHERE id_bien = @id;";
        AddParameter(command, "@id", id);
        command.ExecuteNonQuery();
    }

    public List<AsignacionModel> ObtenerAsignaciones()
    {
        var lista = new List<AsignacionModel>();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT a.id_asignacion, a.id_bien, b.cbi, b.descripcion,
                   a.id_ambiente, amb.nombre AS ambiente, e.nombre AS especialidad,
                   a.responsable, a.fecha_asignacion, a.fecha_fin, a.estado, a.observacion
            FROM mod03.asignacion a
            JOIN mod03.bien b ON b.id_bien = a.id_bien
            JOIN mod03.ambiente amb ON amb.id_ambiente = a.id_ambiente
            LEFT JOIN mod03.especialidad e ON e.id_especialidad = amb.id_especialidad
            ORDER BY a.id_asignacion DESC;
            """;
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            lista.Add(new AsignacionModel
            {
                IdAsignacion = reader.GetInt32(reader.GetOrdinal("id_asignacion")),
                IdBien = reader.GetInt32(reader.GetOrdinal("id_bien")),
                Cbi = reader.GetString(reader.GetOrdinal("cbi")),
                Descripcion = reader.GetString(reader.GetOrdinal("descripcion")),
                IdAmbiente = reader.GetInt32(reader.GetOrdinal("id_ambiente")),
                Ambiente = reader.GetString(reader.GetOrdinal("ambiente")),
                Especialidad = StringValue(reader, "especialidad"),
                Responsable = StringValue(reader, "responsable"),
                FechaAsignacion = reader.GetDateTime(reader.GetOrdinal("fecha_asignacion")),
                FechaFin = reader["fecha_fin"] == DBNull.Value ? null : reader.GetDateTime(reader.GetOrdinal("fecha_fin")),
                Estado = reader.GetString(reader.GetOrdinal("estado")),
                Observacion = StringValue(reader, "observacion")
            });
        }
        return lista;
    }

    public void CrearAsignacion(AsignacionFormModel model)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT INTO mod03.asignacion
                (id_bien, id_ambiente, responsable, fecha_asignacion, estado, observacion)
            SELECT @bien, @ambiente, @responsable, @fecha, 'Activa', @observacion
            WHERE NOT EXISTS (
                SELECT 1 FROM mod03.asignacion WHERE id_bien = @bien AND estado = 'Activa'
            );
            """;
        AddParameter(command, "@bien", model.IdBien);
        AddParameter(command, "@ambiente", model.IdAmbiente);
        AddParameter(command, "@responsable", NullIfEmpty(model.Responsable));
        AddParameter(command, "@fecha", model.FechaAsignacion.Date);
        AddParameter(command, "@observacion", NullIfEmpty(model.Observacion));
        if (command.ExecuteNonQuery() == 0)
            throw new InvalidOperationException("El bien ya tiene una asignación activa.");
    }

    public void FinalizarAsignacion(int id)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = "UPDATE mod03.asignacion SET estado = 'Finalizada', fecha_fin = CURRENT_DATE WHERE id_asignacion = @id AND estado = 'Activa';";
        AddParameter(command, "@id", id);
        command.ExecuteNonQuery();
    }

    public List<TransferenciaModel> ObtenerTransferencias()
    {
        var lista = new List<TransferenciaModel>();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT t.id_transferencia, t.id_bien, b.cbi, b.descripcion,
                   t.id_almacen_origen, ao.nombre AS almacen_origen,
                   t.id_almacen_destino, ad.nombre AS almacen_destino,
                   t.fecha_solicitud, t.fecha_salida, t.fecha_recepcion,
                   t.estado_movimiento, t.motivo, t.responsable_origen,
                   t.responsable_destino, t.documento, t.observacion
            FROM mod03.transferencia t
            JOIN mod03.bien b ON b.id_bien = t.id_bien
            JOIN mod03.almacen ao ON ao.id_almacen = t.id_almacen_origen
            JOIN mod03.almacen ad ON ad.id_almacen = t.id_almacen_destino
            ORDER BY t.id_transferencia DESC;
            """;
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            lista.Add(new TransferenciaModel
            {
                IdTransferencia = reader.GetInt32(reader.GetOrdinal("id_transferencia")),
                IdBien = reader.GetInt32(reader.GetOrdinal("id_bien")),
                Cbi = reader.GetString(reader.GetOrdinal("cbi")),
                Descripcion = reader.GetString(reader.GetOrdinal("descripcion")),
                IdAlmacenOrigen = reader.GetInt32(reader.GetOrdinal("id_almacen_origen")),
                AlmacenOrigen = reader.GetString(reader.GetOrdinal("almacen_origen")),
                IdAlmacenDestino = reader.GetInt32(reader.GetOrdinal("id_almacen_destino")),
                AlmacenDestino = reader.GetString(reader.GetOrdinal("almacen_destino")),
                FechaSolicitud = reader.GetDateTime(reader.GetOrdinal("fecha_solicitud")),
                FechaSalida = reader["fecha_salida"] == DBNull.Value ? null : reader.GetDateTime(reader.GetOrdinal("fecha_salida")),
                FechaRecepcion = reader["fecha_recepcion"] == DBNull.Value ? null : reader.GetDateTime(reader.GetOrdinal("fecha_recepcion")),
                EstadoMovimiento = reader.GetString(reader.GetOrdinal("estado_movimiento")),
                Motivo = reader.GetString(reader.GetOrdinal("motivo")),
                ResponsableOrigen = StringValue(reader, "responsable_origen"),
                ResponsableDestino = StringValue(reader, "responsable_destino"),
                Documento = StringValue(reader, "documento"),
                Observacion = StringValue(reader, "observacion")
            });
        }
        return lista;
    }

    public void CrearTransferencia(TransferenciaFormModel model)
    {
        if (model.IdAlmacenOrigen == model.IdAlmacenDestino)
            throw new InvalidOperationException("El almacén de origen y destino deben ser diferentes.");

        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT INTO mod03.transferencia
                (id_bien, id_almacen_origen, id_almacen_destino, motivo,
                 responsable_origen, responsable_destino, estado_movimiento,
                 documento, observacion)
            VALUES
                (@bien, @origen, @destino, @motivo,
                 @responsableOrigen, @responsableDestino, 'Pendiente de recepción',
                 @documento, @observacion);
            """;
        AddParameter(command, "@bien", model.IdBien);
        AddParameter(command, "@origen", model.IdAlmacenOrigen);
        AddParameter(command, "@destino", model.IdAlmacenDestino);
        AddParameter(command, "@motivo", model.Motivo.Trim());
        AddParameter(command, "@responsableOrigen", NullIfEmpty(model.ResponsableOrigen));
        AddParameter(command, "@responsableDestino", NullIfEmpty(model.ResponsableDestino));
        AddParameter(command, "@documento", NullIfEmpty(model.Documento));
        AddParameter(command, "@observacion", NullIfEmpty(model.Observacion));
        command.ExecuteNonQuery();
    }

    public void RecepcionarTransferencia(int id)
    {
        using var connection = OpenConnection();
        using var transaction = connection.BeginTransaction();
        try
        {
            int bienId;
            int destinoId;

            using (var select = connection.CreateCommand())
            {
                select.Transaction = transaction;
                select.CommandText = "SELECT id_bien, id_almacen_destino FROM mod03.transferencia WHERE id_transferencia = @id AND estado_movimiento <> 'Recepcionado' AND estado_movimiento <> 'Cancelado';";
                AddParameter(select, "@id", id);
                using var reader = select.ExecuteReader();
                if (!reader.Read()) throw new InvalidOperationException("La transferencia no está disponible para recepción.");
                bienId = reader.GetInt32(0);
                destinoId = reader.GetInt32(1);
            }

            using (var updateTransfer = connection.CreateCommand())
            {
                updateTransfer.Transaction = transaction;
                updateTransfer.CommandText = "UPDATE mod03.transferencia SET estado_movimiento='Recepcionado', fecha_salida=COALESCE(fecha_salida,CURRENT_TIMESTAMP), fecha_recepcion=CURRENT_TIMESTAMP WHERE id_transferencia=@id;";
                AddParameter(updateTransfer, "@id", id);
                updateTransfer.ExecuteNonQuery();
            }

            using (var updateBien = connection.CreateCommand())
            {
                updateBien.Transaction = transaction;
                updateBien.CommandText = "UPDATE mod03.bien SET id_almacen=@destino, procedencia='Transferencia' WHERE id_bien=@bien;";
                AddParameter(updateBien, "@destino", destinoId);
                AddParameter(updateBien, "@bien", bienId);
                updateBien.ExecuteNonQuery();
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public void CancelarTransferencia(int id)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = "UPDATE mod03.transferencia SET estado_movimiento='Cancelado' WHERE id_transferencia=@id AND estado_movimiento NOT IN ('Recepcionado','Cancelado');";
        AddParameter(command, "@id", id);
        command.ExecuteNonQuery();
    }

    public List<InventarioAnualModel> ObtenerInventarioAnual()
    {
        var lista = new List<InventarioAnualModel>();
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT ia.id_inventario, ia.id_bien, b.cbi, b.descripcion, b.serie,
                   a.nombre AS almacen, ia.anio, ia.fecha_verificacion,
                   ia.resultado, ia.observacion
            FROM mod03.inventario_anual ia
            JOIN mod03.bien b ON b.id_bien = ia.id_bien
            JOIN mod03.almacen a ON a.id_almacen = b.id_almacen
            ORDER BY ia.anio DESC, ia.fecha_verificacion DESC, ia.id_inventario DESC;
            """;
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            lista.Add(new InventarioAnualModel
            {
                IdInventario = reader.GetInt32(reader.GetOrdinal("id_inventario")),
                IdBien = reader.GetInt32(reader.GetOrdinal("id_bien")),
                Cbi = reader.GetString(reader.GetOrdinal("cbi")),
                Descripcion = reader.GetString(reader.GetOrdinal("descripcion")),
                Serie = StringValue(reader, "serie"),
                Almacen = reader.GetString(reader.GetOrdinal("almacen")),
                Anio = reader.GetInt32(reader.GetOrdinal("anio")),
                FechaVerificacion = reader.GetDateTime(reader.GetOrdinal("fecha_verificacion")),
                Resultado = reader.GetString(reader.GetOrdinal("resultado")),
                Observacion = StringValue(reader, "observacion")
            });
        }
        return lista;
    }

    public void RegistrarInventarioAnual(InventarioAnualFormModel model)
    {
        using var connection = OpenConnection();
        using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT INTO mod03.inventario_anual
                (id_bien, anio, fecha_verificacion, resultado, observacion)
            VALUES (@bien, @anio, @fecha, @resultado, @observacion);
            """;
        AddParameter(command, "@bien", model.IdBien);
        AddParameter(command, "@anio", model.Anio);
        AddParameter(command, "@fecha", model.FechaVerificacion.Date);
        AddParameter(command, "@resultado", model.Resultado);
        AddParameter(command, "@observacion", NullIfEmpty(model.Observacion));
        command.ExecuteNonQuery();
    }

    public int ContarBienes() => ObtenerInventario().Count;

    private static object? NullIfEmpty(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
