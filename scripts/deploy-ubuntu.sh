#!/usr/bin/env bash
# ==============================================================================
# Chatwoot Community Edition - Ubuntu Server Deployment & Update Script
# Location: ./scripts/deploy-ubuntu.sh
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${PROJECT_DIR}"

echo "========================================================"
echo "  Desplegando Chatwoot Community Edition en Ubuntu Server"
echo "  Directorio: ${PROJECT_DIR}"
echo "========================================================"

# 1. Comprobar que Docker y Docker Compose estén presentes
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker no está instalado o no se encuentra en PATH."
  exit 1
fi

# 2. Comprobar existencia de .env
if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    echo "Advertencia: .env no encontrado. Copiando desde .env.example..."
    cp .env.example .env
    echo "Por favor edita .env con tus credenciales y vuelve a ejecutar."
    exit 1
  else
    echo "Error: No se encontró .env ni .env.example."
    exit 1
  fi
fi

# 3. Descargar imágenes actualizadas
echo "[1/4] Descargando imágenes oficiales de Docker..."
docker compose pull

# 4. Inicializar base de datos si es la primera vez
echo "[2/4] Verificando e inicializando base de datos..."
docker compose up -d postgres redis

echo "  Esperando a PostgreSQL y Redis..."
sleep 5
until docker compose exec postgres pg_isready -U postgres -d chatwoot_production > /dev/null 2>&1; do
  echo "  Esperando disponibilidad de PostgreSQL..."
  sleep 3
done

echo "  Ejecutando migraciones / preparación de base de datos..."
docker compose run --rm rails bundle exec rails db:chatwoot_prepare || true

# 5. Iniciar la totalidad de servicios en segundo plano
echo "[3/4] Levantando el stack de Chatwoot (rails, sidekiq, postgres, redis)..."
docker compose up -d

# 6. Verificación de salud y estado
echo "[4/4] Verificando estado de los contenedores..."
sleep 5
docker compose ps

echo "========================================================"
echo "  ¡Chatwoot desplegado correctamente!"
echo "  Acceso local: http://127.0.0.1:3200"
echo "  Para ver logs en tiempo real: docker compose logs -f"
echo "========================================================"
