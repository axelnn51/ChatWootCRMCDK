# Chatwoot Community Edition (Self-Hosted con Docker)

Estructura modular y estandarizada de **Chatwoot Community Edition** usando **Docker Compose**, preparada para ser versionada en Git y desplegada en cualquier servidor **Ubuntu / Linux con Docker**.

---

## 🏛️ Arquitectura del Stack

El proyecto opera bajo una red interna aislada (`chatwoot_net`) y con volúmenes nombrados persistentes:

```
                                    +-----------------------------------------+
                                    |       Reverse Proxy / Cloudflare        |
                                    |        (Puerto Host: 3200)             |
                                    +--------------------+--------------------+
                                                         |
                                        +----------------v---------------+
                                        |   chatwoot_rails (Web App)     |
                                        |   chatwoot/chatwoot:latest     |
                                        +-------+---------------+--------+
                                                |               |
             +----------------------------------+               +----------------------------------+
             |                                                                                     |
+------------v------------+                                                           +------------v------------+
|  chatwoot_postgres      |                                                           |     chatwoot_redis      |
|  pgvector/pgvector:pg16 |                                                           |      redis:alpine       |
|  (Base de datos vector) |                                                           |  (Colas y caché redis)  |
+------------^------------+                                                           +------------^------------+
             |                                                                                     |
             +----------------------------------+               +----------------------------------+
                                                |               |
                                        +-------+---------------+--------+
                                        |  chatwoot_sidekiq (Worker)     |
                                        |  chatwoot/chatwoot:latest      |
                                        +--------------------------------+
```

### Componentes y Volúmenes
- **`chatwoot_rails`**: Servidor Puma y aplicación Ruby on Rails expuesta localmente en `127.0.0.1:3200`.
- **`chatwoot_sidekiq`**: Procesador de tareas en segundo plano (colas de mensajes, webhooks, emails).
- **`chatwoot_postgres`**: Base de datos PostgreSQL 16 con extensión `pgvector` para búsqueda semántica.
- **`chatwoot_redis`**: Almacén en memoria para ActionCable, colas de Sidekiq y sesiones.
- **Volúmenes Persistentes**:
  - `chatwoot_storage_data`: Archivos adjuntos y avatares subidos.
  - `chatwoot_postgres_data`: Base de datos transaccional.
  - `chatwoot_redis_data`: Persistencia en disco de Redis.

---

## 🐳 Despliegue con Portainer (Stacks)

1. En tu panel de **Portainer**, ve a **Stacks > Add stack**.
2. Selecciona **Repository**:
   - **Repository URL**: `https://github.com/axelnn51/ChatWootCRMCDK.git`
   - **Repository reference**: `refs/heads/main`
   - **Compose path**: `docker-compose.yaml`
3. En la sección **Environment variables** de Portainer:
   - Copia las variables de `.env.example` (o de tu `.env` privado generado) y pégalas en el editor de variables de Portainer.
   - Asegúrate de asignar valores a: `SECRET_KEY_BASE`, `ACTIVE_RECORD_ENCRYPTION_*`, `POSTGRES_PASSWORD`, `REDIS_PASSWORD` y `FRONTEND_URL`.
4. Haz clic en **Deploy the stack**.
   - El stack levantará PostgreSQL y Redis, ejecutará automáticamente `db:chatwoot_prepare` e iniciará Chatwoot en el puerto `3200`.
5. Accede desde tu navegador a `http://IP_DE_TU_SERVIDOR:3200` y crea tu cuenta de administrador de bienvenida.

---

## 🚀 Despliegue Manual en Servidor Ubuntu (Terminal Git)

Al subir este proyecto a tu repositorio Git (ej. GitHub o GitLab), el despliegue en cualquier servidor Ubuntu se realiza con los siguientes pasos:

1. **Clonar el repositorio en el servidor**:
   ```bash
   git clone <URL_DE_TU_REPOSITORIO_GIT> chatwoot
   cd chatwoot
   ```

2. **Configurar el archivo de entorno**:
   ```bash
   cp .env.example .env
   nano .env
   ```
   *(Asegúrate de definir `SECRET_KEY_BASE`, contraseñas y tu `FRONTEND_URL`)*.

3. **Ejecutar el script de despliegue**:
   ```bash
   bash scripts/deploy-ubuntu.sh
   ```
   Este script descargará las imágenes oficiales, ejecutará `rails db:chatwoot_prepare` e iniciará todos los contenedores.

4. **Crear el usuario Super Administrador**:
   ```bash
   bash scripts/create-admin.sh "Admin CDKeys" "admin@tudominio.com" "TuClaveSegura2026!"
   ```

---

## 📱 ¿Cómo usar tu número actual de WhatsApp Business en este CRM?

Para conectar un número de teléfono existente **sin riesgo de bloqueo, sin perder tu historial y sin usar librerías no oficiales (como Baileys, Evolution o WAHA)**, se utiliza el método oficial de **Meta WhatsApp Cloud API con Coexistencia (WhatsApp Business App Coexistence)**.

### ¿Qué es la Coexistencia de WhatsApp Business?
Meta permite que tu número de teléfono funcione simultáneamente en:
1. **La aplicación WhatsApp Business en tu celular** (sigues recibiendo y enviando mensajes como siempre).
2. **Chatwoot CRM vía WhatsApp Cloud API** (tus agentes atienden, usan bots, etiquetas y respuestas rápidas sincronizadas).

---

### Paso a Paso para la Integración Oficial:

#### Paso 1: Configurar Meta for Developers y Meta Business Suite
1. Ingresa a [developers.facebook.com](https://developers.facebook.com/) con tu cuenta de Meta.
2. Crea una **App de tipo Business** (Negocio).
3. En el panel de la App, agrega el producto **WhatsApp**.
4. Vincula tu **Meta Business Account** (Portafolio Empresarial) verificado o en proceso.

#### Paso 2: Conectar tu Número Existente (Modo Coexistencia)
1. En la sección **WhatsApp > Configuración de la API** en Meta for Developers:
   - Haz clic en **Agregar número de teléfono**.
   - Ingresa el nombre comercial y tu número actual.
   - Selecciona el método de verificación por SMS o llamada.
   - Al tener WhatsApp Business App instalada en tu teléfono, Meta activará el **modo de coexistencia**, manteniendo activa tu app móvil.
2. Anota los siguientes 3 datos que te entregará Meta:
   - **Identificador de número de teléfono (Phone Number ID)**.
   - **Identificador de cuenta de WhatsApp Business (WABA ID)**.
   - **Token de acceso permanente** (generado mediante un Usuario del Sistema en Meta Business Suite con permisos `whatsapp_business_messaging` y `whatsapp_business_management`).

#### Paso 3: Crear la Bandeja de Entrada en Chatwoot
1. Inicia sesión en tu Chatwoot (`http://127.0.0.1:3200` o tu dominio con HTTPS).
2. Ve a **Ajustes > Bandejas de entrada > Añadir bandeja de entrada**.
3. Selecciona el canal **WhatsApp** y elige **WhatsApp Cloud**.
4. Rellena los campos:
   - **Nombre de la bandeja**: Ej. *WhatsApp CDKeys*.
   - **Número de teléfono**: Tu número con código de país (ej. `+51987654321`).
   - **Phone Number ID**: El ID copiado de Meta.
   - **Business Account ID**: El WABA ID de Meta.
   - **API Key / Token de acceso**: El token generado en Meta.
5. Haz clic en **Crear canal**.

#### Paso 4: Configurar el Webhook en Meta
1. Al crear la bandeja, Chatwoot te mostrará una **URL de Callback (Webhook URL)** y un **Token de Verificación (Verify Token)**.
2. Ve a tu App en Meta for Developers > **WhatsApp > Configuración**.
3. En la sección **Webhook**:
   - Haz clic en **Editar**.
   - Pega la **URL de Callback** de Chatwoot (debe ser accesible públicamente con HTTPS, ej. vía Cloudflare Tunnel o Nginx).
   - Pega el **Verify Token**.
   - Haz clic en **Verificar y Guardar**.
4. En los campos de suscripción del Webhook, activa **`messages`**.

¡Listo! A partir de ese momento, cualquier mensaje entrante a tu WhatsApp llegará a Chatwoot en tiempo real y podrás responder desde el CRM manteniendo tu app de WhatsApp Business en tu teléfono.

---

## 🛠️ Comandos de Operación Diaria

| Acción | Comando |
| :--- | :--- |
| **Ver estado de contenedores** | `docker compose ps` |
| **Ver logs en tiempo real** | `docker compose logs -f` |
| **Ver logs solo de Rails** | `docker compose logs -f rails` |
| **Ver logs de Sidekiq** | `docker compose logs -f sidekiq` |
| **Detener servicios** | `docker compose stop` |
| **Iniciar servicios** | `docker compose up -d` |
| **Reiniciar stack completo** | `docker compose restart` |
| **Entrar a la consola Rails** | `docker compose run --rm rails bundle exec rails c` |

---

## 📦 Respaldos y Restauración

### Generar Respaldo Completo
```bash
bash scripts/backup.sh
```
El archivo se guarda en `backups/chatwoot_backup_YYYYMMDD_HHMMSS.tar.gz`.

### Restaurar Respaldo
```bash
bash scripts/restore.sh backups/chatwoot_backup_YYYYMMDD_HHMMSS.tar.gz
```
