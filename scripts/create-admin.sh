#!/usr/bin/env bash
# ==============================================================================
# Chatwoot Community Edition - Create / Reset Super Admin User
# ==============================================================================

set -e

if [ $# -lt 3 ]; then
  echo "Uso: $0 <NOMBRE> <EMAIL> <PASSWORD>"
  echo "Ejemplo: $0 \"Admin CDKeys\" \"admin@cdkeysperu.com\" \"ClaveSegura2026!\""
  exit 1
fi

ADMIN_NAME="$1"
ADMIN_EMAIL="$2"
ADMIN_PASSWORD="$3"

echo "Creando Super Admin: $ADMIN_EMAIL ..."

docker compose run --rm rails bundle exec rails runner "
user = User.find_or_initialize_by(email: '$ADMIN_EMAIL')
user.name = '$ADMIN_NAME'
user.password = '$ADMIN_PASSWORD'
user.password_confirmation = '$ADMIN_PASSWORD'
user.role = :administrator
user.type = 'SuperAdmin'
user.confirmed_at = Time.now.utc
user.save!
puts 'Super Admin creado o actualizado exitosamente: ' + user.email
"

echo "¡Listo! Ya puedes iniciar sesión con $ADMIN_EMAIL"
