#!/usr/bin/env bash
# ==============================================================================
# 🏛️ IESTP ARGENTINA - AUTOMATIZACIÓN DE BACKUP POSTGRESQL 16 (CERO COSTO)
# Arquitectura: 3-2-1 Spartan DR (Full DB + Granular por Esquemas + SHA256)
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/home/fob/backups}"
DAILY_DIR="${BACKUP_DIR}/daily"
SCHEMAS_DIR="${BACKUP_DIR}/schemas"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CONTAINER_NAME="postgres-db"
DB_NAME="db_intranet_iestp"
DB_USER="postgres"
RETENTION_DAYS=7

mkdir -p "${DAILY_DIR}" "${SCHEMAS_DIR}"

echo "======================================================================"
echo "🚀 INICIANDO BACKUP POSTGRESQL: ${TIMESTAMP}"
echo "======================================================================"

# 1. Backup Completo de la Base de Datos (Formato Custom Comprimido -Fc -Z 9)
FULL_FILE="${DAILY_DIR}/${DB_NAME}_full_${TIMESTAMP}.dump"
echo "📦 1/3 Generando Dump Completo en: ${FULL_FILE}..."
docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -Fc -Z 9 > "${FULL_FILE}"

# Generar Checksum SHA-256 para validación de integridad
sha256sum "${FULL_FILE}" > "${FULL_FILE}.sha256"
FILE_SIZE=$(du -h "${FULL_FILE}" | awk '{print $1}')
echo "   ✓ Dump Completo generado con éxito (Tamaño: ${FILE_SIZE})"

# 2. Backups Granulares por Esquema (Recuperación Rápida por Equipo en <10s)
SCHEMAS=("core" "mod01" "mod02" "mod03" "mod04" "mod05" "mod06" "mod07" "mod08" "mod09")
echo "🧩 2/3 Generando Snapshots Granulares por Esquema..."

for schema in "${SCHEMAS[@]}"; do
    SCHEMA_FILE="${SCHEMAS_DIR}/${schema}_latest.dump"
    docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -n "${schema}" -Fc -Z 9 > "${SCHEMA_FILE}"
    echo "   ✓ Esquema [${schema}] -> ${SCHEMA_FILE}"
done

# 3. Purga Automática de Backups Antiguos (> 7 días)
echo "🧹 3/3 Aplicando Política de Retención (${RETENTION_DAYS} días)..."
find "${DAILY_DIR}" -type f -name "*.dump" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
find "${DAILY_DIR}" -type f -name "*.sha256" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
echo "   ✓ Política de rotación ejecutada."

echo "======================================================================"
echo "🎉 BACKUP COMPLETADO CON ÉXITO: $(date +"%Y-%m-%d %H:%M:%S")"
echo "======================================================================"
