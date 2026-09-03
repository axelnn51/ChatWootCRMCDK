#!/usr/bin/env bash
# ==============================================================================
# Chatwoot Community Edition - Restore Backup Script
# Restores PostgreSQL dump, storage files, and environment from a backup bundle
# ==============================================================================

set -e

if [ $# -lt 1 ]; then
  echo "Uso: $0 <RUTA_AL_ARCHIVO_TAR_GZ>"
  echo "Ejemplo: $0 backups/chatwoot_backup_20260901_120000.tar.gz"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "Error: El archivo de respaldo '${BACKUP_FILE}' no existe."
  exit 1
fi

TEMP_RESTORE_DIR="/tmp/chatwoot_restore_$(date +%s)"
mkdir -p "${TEMP_RESTORE_DIR}"

echo "========================================================"
echo "  Iniciando Restauración de Chatwoot desde: ${BACKUP_FILE}"
echo "========================================================"

echo "[1/5] Desempaquetando archivo de respaldo..."
tar -xzf "${BACKUP_FILE}" -C "${TEMP_RESTORE_DIR}"

# Restaurar .env si no existe
if [ ! -f .env ] && [ -f "${TEMP_RESTORE_DIR}/env.backup" ]; then
  echo "[2/5] Restaurando archivo .env..."
  cp "${TEMP_RESTORE_DIR}/env.backup" .env
fi

# Iniciar PostgreSQL
echo "[3/5] Asegurando servicio de PostgreSQL..."
docker compose up -d postgres
until docker compose exec postgres pg_isready -U postgres > /dev/null 2>&1; do
  echo "  Esperando a PostgreSQL..."
  sleep 3
done

# Restaurar Base de Datos
echo "[4/5] Restaurando base de datos PostgreSQL..."
docker compose exec -T postgres dropdb -U postgres --if-exists chatwoot_production || true
docker compose exec -T postgres createdb -U postgres chatwoot_production
docker compose exec -T postgres pg_restore -U postgres -d chatwoot_production --clean --if-exists < "${TEMP_RESTORE_DIR}/chatwoot_db.dump" || true

# Restaurar Almacenamiento
if [ -f "${TEMP_RESTORE_DIR}/storage_data.tar.gz" ]; then
  echo "[5/5] Restaurando archivos de almacenamiento..."
  docker compose run --rm --no-deps rails sh -c "tar -xzf - -C /app/storage" < "${TEMP_RESTORE_DIR}/storage_data.tar.gz"
fi

rm -rf "${TEMP_RESTORE_DIR}"

echo "========================================================"
echo "  ¡Restauración completada exitosamente!"
echo "  Iniciando todos los servicios: docker compose up -d"
echo "========================================================"
docker compose up -d
