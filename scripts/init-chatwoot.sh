#!/usr/bin/env bash
# ==============================================================================
# Chatwoot Community Edition - Database Preparation & Initialization Script
# ==============================================================================

set -e

echo "========================================================"
echo "  Inicializando Base de Datos de Chatwoot (db:chatwoot_prepare)"
echo "========================================================"

# Verificar que exista el archivo .env
if [ ! -f .env ]; then
  echo "Error: No se encontró el archivo .env. Crea o copia uno antes de continuar."
  exit 1
fi

# Iniciar los servicios de soporte (PostgreSQL y Redis)
echo "[1/3] Iniciando contenedores de base de datos y cache..."
docker compose up -d postgres redis

echo "[2/3] Esperando que PostgreSQL y Redis estén saludables..."
until docker compose exec postgres pg_isready -U postgres -d chatwoot_production > /dev/null 2>&1; do
  echo "  Esperando a PostgreSQL..."
  sleep 3
done

echo "[3/3] Ejecutando rails db:chatwoot_prepare..."
docker compose run --rm rails bundle exec rails db:chatwoot_prepare

echo "========================================================"
echo "  ¡Base de datos preparada correctamente!"
echo "  Puedes iniciar todos los servicios con: docker compose up -d"
echo "========================================================"
