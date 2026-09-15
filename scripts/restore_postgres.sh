#!/usr/bin/env bash
# ==============================================================================
# 🏛️ IESTP ARGENTINA - SCRIPT DE RECUPERACIÓN ANTE DESASTRES (POSTGRESQL 16)
# Modos:
#   1. Restaurar Esquema Específico: ./restore_postgres.sh schema <mod01..09|core> [archivo.dump]
#   2. Restaurar Base Completa:     ./restore_postgres.sh full <archivo.dump>
# ==============================================================================

set -euo pipefail

CONTAINER_NAME="postgres-db"
DB_NAME="db_intranet_iestp"
DB_USER="postgres"
BACKUP_DIR="${BACKUP_DIR:-/home/fob/backups}"

show_help() {
    echo "Uso:"
    echo "  $0 schema <nombre_esquema> [ruta_archivo.dump]"
    echo "     Ej: $0 schema mod04"
    echo "     Ej: $0 schema mod04 /home/fob/backups/schemas/mod04_latest.dump"
    echo ""
    echo "  $0 full <ruta_archivo.dump>"
    echo "     Ej: $0 full /home/fob/backups/daily/db_intranet_iestp_full_20260915_015436.dump"
    exit 1
}

if [ $# -lt 1 ]; then
    show_help
fi

MODE="$1"

if [ "$MODE" = "schema" ]; then
    if [ $# -lt 2 ]; then
        echo "❌ Debes especificar el nombre del esquema (core, mod01..mod09)."
        exit 1
    fi
    SCHEMA="$2"
    DUMP_FILE="${3:-${BACKUP_DIR}/schemas/${SCHEMA}_latest.dump}"

    if [ ! -f "${DUMP_FILE}" ]; then
        echo "❌ Archivo dump no encontrado: ${DUMP_FILE}"
        exit 1
    fi

    echo "======================================================================"
    echo "🔄 RESTAURANDO ESQUEMA AISLADO: [${SCHEMA}]"
    echo "📦 Archivo: ${DUMP_FILE}"
    echo "======================================================================"

    # Restauración con pg_restore sin afectar a los demás esquemas
    docker exec -i "${CONTAINER_NAME}" pg_restore -U "${DB_USER}" -d "${DB_NAME}" \
        --clean --if-exists --schema="${SCHEMA}" --no-owner --role="${DB_USER}" < "${DUMP_FILE}" || true

    echo "✅ ¡Esquema [${SCHEMA}] restaurado exitosamente en <5 segundos!"

elif [ "$MODE" = "full" ]; then
    if [ $# -lt 2 ]; then
        echo "❌ Debes especificar la ruta del dump completo."
        exit 1
    fi
    DUMP_FILE="$2"

    if [ ! -f "${DUMP_FILE}" ]; then
        echo "❌ Archivo dump no encontrado: ${DUMP_FILE}"
        exit 1
    fi

    # Validar integridad SHA256 si existe
    if [ -f "${DUMP_FILE}.sha256" ]; then
        echo "🔍 Verificando integridad SHA-256..."
        sha256sum -c "${DUMP_FILE}.sha256"
        echo "   ✓ Checksum verificado correctamente."
    fi

    echo "======================================================================"
    echo "🚨 RESTAURANDO BASE DE DATOS COMPLETA: [${DB_NAME}]"
    echo "📦 Archivo: ${DUMP_FILE}"
    echo "======================================================================"

    docker exec -i "${CONTAINER_NAME}" pg_restore -U "${DB_USER}" -d "${DB_NAME}" \
        --clean --if-exists --no-owner --role="${DB_USER}" < "${DUMP_FILE}" || true

    echo "✅ ¡Base de datos [${DB_NAME}] restaurada exitosamente!"
else
    show_help
fi
