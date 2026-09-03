#!/usr/bin/env bash
# ==============================================================================
# Chatwoot Community Edition - Automated Backup Script
# Creates a compressed bundle with PostgreSQL dump, storage files, and .env
# ==============================================================================

set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups"
TEMP_DIR="/tmp/chatwoot_backup_${TIMESTAMP}"
BACKUP_FILE="${BACKUP_DIR}/chatwoot_backup_${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"
mkdir -p "${TEMP_DIR}"

echo "========================================================"
echo "  Iniciando Respaldo de Chatwoot: ${TIMESTAMP}"
echo "========================================================"

# 1. Respaldo de PostgreSQL
echo "[1/4] Realizando volcado de PostgreSQL..."
docker compose exec -T postgres pg_dump -U postgres -d chatwoot_production -Fc > "${TEMP_DIR}/chatwoot_db.dump"

# 2. Respaldo de Almacenamiento (Archivos y Adjuntos)
echo "[2/4] Copiando archivos de almacenamiento..."
docker compose run --rm --no-deps rails tar -czf - -C /app/storage . > "${TEMP_DIR}/storage_data.tar.gz" 2>/dev/null || true

# 3. Copiar archivo .env
echo "[3/4] Copiando configuración de entorno (.env)..."
if [ -f .env ]; then
  cp .env "${TEMP_DIR}/env.backup"
fi

# 4. Comprimir el paquete final
echo "[4/4] Empaquetando respaldo final..."
tar -czf "${BACKUP_FILE}" -C "${TEMP_DIR}" .

# Limpieza temporal
rm -rf "${TEMP_DIR}"

echo "========================================================"
echo "  ¡Respaldo completado con éxito!"
echo "  Archivo generado: ${BACKUP_FILE} ($(du -h "${BACKUP_FILE}" | cut -f1))"
echo "========================================================"
