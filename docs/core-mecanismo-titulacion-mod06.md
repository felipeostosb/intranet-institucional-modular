# Propuesta al Core: mecanismo de titulación automática (mod06 → core.estudiantes)

**Fecha:** 2026-10-06 · **Autor:** Ismael (Equipo 01/09, con accesos de DBA admin) · **Revisión para:** Felipe (dueño del core)

## Contexto

El equipo 06 cerró su flujo de titulación con un error de permisos: `42501: permission denied for table estudiantes` — su código hacía `UPDATE core.estudiantes SET condicion='Titulado'`, y el core (correctamente) se lo prohibió. Se evaluaron tres caminos:

1. **GRANT UPDATE al user_equipo06** — descartado: rompe la regla Zero-Blast-Radius (un módulo mutando la tabla central del core).
2. **Que el módulo no toque el core y solo viva en mod06.egresos** — funcional, pero la condición del estudiante jamás cambiaría en todo el resto del sistema.
3. **Mecanismo del core (elegido):** el módulo solo INSERTA en su tabla; el core reacciona con un trigger de SU propiedad.

El mecanismo ya está **aplicado y verificado en producción** (creado por el DBA admin con respaldo previo en `/tmp/backup_core_estudiantes_pre_titulado_20261006_1042.dump`). Este documento persiste el SQL para que quede versionado en el `core_schema.sql` y sobreviva a reinstalaciones.

## SQL exacto para core_schema.sql

Insertar después de la definición de `core.fn_audit_trigger` (tras la línea `$$ LANGUAGE plpgsql SECURITY DEFINER;` de esa función):

```sql
-- ---------------------------------------------------------------------------
-- Mecanismo del Core: Titulación automática al registrar egreso (mod06).
-- El módulo 06 solo INSERTA en mod06.egresos (su tabla); este trigger, de
-- propiedad del core, reacciona y actualiza core.estudiantes.condicion a
-- 'Titulado'. SECURITY DEFINER: corre como dueño del core sin otorgar UPDATE
-- sobre core al módulo (regla Zero-Blast-Radius). Idempotente: si el
-- estudiante ya está titulado no hace nada. No revierte en DELETE: la
-- titulación es un hecho histórico; anulaciones vía flujo administrativo.
-- Verificado en producción 2026-10-06 con SET ROLE user_equipo06.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION core.fn_titular_al_egresar()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = core, pg_temp
AS $$
BEGIN
    UPDATE core.estudiantes
       SET condicion = 'Titulado'
     WHERE id = NEW.estudiante_id
       AND condicion <> 'Titulado';
    RETURN NEW;
END;
$$;

-- El trigger se crea bajo idempotencia; la tabla mod06.egresos puede no
-- existir aún en instalaciones nuevas cuando corre el core (se crea después
-- vía el schema.sql del módulo), por eso se valida existencia.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema = 'mod06' AND table_name = 'egresos') THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_titular_al_egresar ON mod06.egresos;';
        EXECUTE 'CREATE TRIGGER trg_titular_al_egresar AFTER INSERT ON mod06.egresos
                 FOR EACH ROW EXECUTE FUNCTION core.fn_titular_al_egresar();';
    END IF;
END $$;

COMMENT ON FUNCTION core.fn_titular_al_egresar() IS
'Mecanismo del core: al registrar un egreso en mod06.egresos, el estudiante pasa a condicion Titulado en core.estudiantes. SECURITY DEFINER (dueño del core); no otorga UPDATE del core a los módulos.';
```

## Por qué este diseño

- **Zero-Blast-Radius preservado:** `user_equipo06` sigue sin poder hacer UPDATE sobre el core (verificado: `has_table_privilege(...,'UPDATE') = false`). El módulo solo hace `INSERT INTO mod06.egresos` — algo que ya podía.
- **SECURITY DEFINER:** la función corre con los permisos de su dueño (postgres), no del que la invoca. Es el mismo patrón que ya usa `core.fn_audit_trigger`.
- **`SET search_path = core, pg_temp`:** best practice de seguridad para funciones SECURITY DEFINER — evita que un SearchPath manipulable redirija las referencias a tablas falsas.
- **Idempotente:** si el estudiante ya está titulado, no hace nada. Re-insertar egresos no corrompe.
- **Sin reversión en DELETE:** deliberado — la titulación es un hecho histórico. Si un egreso se anula por error, se gestiona administrativamente (decisión pendiente de Felipe si quiere un flujo inverso).
- **El CHECK ya lo permite:** `estudiantes_condicion_check` acepta 'Regular'|'Irregular'|'Egresado'|'Titulado' — el dominio de valores ya estaba diseñado por el dueño.

## Verificación realizada en producción (2026-10-06)

1. Simulación exacta de los permisos del módulo: `SET ROLE user_equipo06` → `INSERT INTO mod06.egresos` pasa → el estudiante queda `Titulado` en core.
2. Auditoría CDC registra el cambio con diff: `{"condicion": {"antes": "Regular", "despues": "Titulado"}}` ejecutado como dueño del core.
3. Datos de prueba revertidos: BD quedó en su estado original (Felipe = Regular, 0 egresos).
4. Reinstalación E2E en BD de pruebas: core → mod06 → core (orden del auto-runner) sin errores; trigger se engancha cuando la tabla existe; re-ejecución idempotente.

## Estado

- **Producción:** ✅ aplicado y verificado (trigger `trg_titular_al_egresar` vivo sobre `mod06.egresos`).
- **PR #75 (merged):** el lado del módulo — `mod06.egresos` ahora está en su schema.sql con la estructura exacta de producción, junto con el enganche idempotente del trigger.
- **Este documento:** el lado del core — pendiente que Felipe copie el bloque SQL a `core_schema.sql` (o lo aplique tal cual la próxima vez que edite el archivo; el DO block lo hace seguro de ejecutar directo también).
