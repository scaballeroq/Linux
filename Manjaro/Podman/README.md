# Podman Professional - Quadlets para Desarrollo

Gestion de contenedores con **Podman + Quadlets + systemd** para proyectos Python/PostgreSQL con proxy, autenticacion y servicios compartidos.

---

## Estructura

```
Podman/
├── install/                  # Scripts de instalacion
│   ├── podman-install.sh     # Instala Podman rootless
│   └── quadlets-setup.sh     # Configura systemd para Quadlets
│
├── lib/
│   └── podman-utils.sh       # CLI para gestionar proyectos
│
├── templates/                # Plantillas de proyectos
│   ├── python-postgres/      # Python + PostgreSQL
│   ├── python-postgres-redis/# Python + PostgreSQL + Redis
│   └── fullstack/            # Front + Back + PostgreSQL + Traefik + Keycloak
│
├── services-shared/          # Servicios globales reutilizables
│   ├── traefik.container     # Proxy inverso
│   ├── keycloak.container    # OAuth2/OIDC (Google, Microsoft, GitHub)
│   ├── postgres-global.container  # PostgreSQL compartido
│   └── redis-global.container     # Redis compartido
│
└── projects/                 # Tus proyectos (gitignored)
```

---

## Instalacion

### 1. Instalar Podman

```bash
./install/podman-install.sh
```

Instala Podman rootless con todas las dependencias necesarias.

### 2. Configurar Quadlets

```bash
./install/quadlets-setup.sh
```

Crea la estructura de systemd para gestionar contenedores como servicios.

### 3. Anadir CLI al PATH

```bash
# En ~/.bashrc o ~/.zshrc
export PATH="$HOME/Workspace/Repositorios/Linux/Manjaro/Podman/lib:$PATH"
```

O crea un alias:

```bash
alias podman-utils="$HOME/Workspace/Repositorios/Linux/Manjaro/Podman/lib/podman-utils.sh"
```

---

## Uso Rapido

### Crear un proyecto

```bash
# Python + PostgreSQL
podman-utils create python-postgres mi-api

# Python + PostgreSQL + Redis (Celery, cache, etc.)
podman-utils create python-postgres-redis mi-api

# Fullstack con proxy y autenticacion
podman-utils create fullstack mi-app
```

### Configurar credenciales

```bash
nano projects/mi-api/.env
```

Cambia las contraseñas por defecto antes de iniciar.

### Iniciar el proyecto

```bash
podman-utils start mi-api
```

### Ver logs

```bash
# Todos los servicios
podman-utils logs mi-api

# Un servicio especifico
podman-utils logs mi-api backend
podman-utils logs mi-api postgres
```

### Ver estado

```bash
podman-utils status mi-api
```

### Detener

```bash
podman-utils stop mi-api
```

### Reiniciar

```bash
podman-utils restart mi-api
```

### Eliminar proyecto (datos incluidos)

```bash
podman-utils destroy mi-api
```

---

## Templates

### python-postgres

| Servicio | Puerto | Descripcion |
|----------|--------|-------------|
| PostgreSQL | 5432 | Base de datos |
| Backend Python | 8000 | API con uvicorn + hot-reload |

**Ideal para:** APIs REST con FastAPI, Flask o Django + PostgreSQL.

### python-postgres-redis

| Servicio | Puerto | Descripcion |
|----------|--------|-------------|
| PostgreSQL | 5432 | Base de datos |
| Redis | 6379 | Cache, Celery, sesiones |
| Backend Python | 8000 | API con uvicorn + hot-reload |

**Ideal para:** APIs con tareas en segundo plano (Celery), cache, rate limiting.

### fullstack

| Servicio | Puerto | Descripcion |
|----------|--------|-------------|
| Traefik | 80, 443, 8080 | Proxy inverso + dashboard |
| Keycloak | 8083 | Auth OAuth2/OIDC |
| PostgreSQL | 5432 | Base de datos |
| Backend Python | 8000 | API |
| Frontend (Node) | 3000 | Frontend dev server |

**Rutas con Traefik:**
- `api.mi-app.localhost` -> Backend
- `app.mi-app.localhost` -> Frontend
- `auth.mi-app.localhost` -> Keycloak
- `:8080` -> Dashboard de Traefik

**Ideal para:** Aplicaciones completas con autenticacion OAuth (Google, Microsoft, GitHub).

---

## Servicios Globales

Servicios compartidos entre multiples proyectos.

### Instalar

```bash
# Proxy inverso global (un solo Traefik para todos los proyectos)
podman-utils install-global traefik

# PostgreSQL compartido (multi-tenant)
podman-utils install-global postgres-global

# Redis compartido
podman-utils install-global redis-global

# Keycloak global (un solo servidor de auth)
podman-utils install-global keycloak
```

### Iniciar/Detener

```bash
systemctl --user start traefik.service
systemctl --user stop postgres-global.service
```

### Desinstalar

```bash
podman-utils uninstall-global traefik
```

---

## Gestion Directa con systemd

Los Quadlets generan servicios systemd automaticamente:

```bash
# Ver todos los servicios del proyecto
systemctl --user list-units "mi-api*"

# Iniciar un servicio especifico
systemctl --user start mi-api-postgres.service

# Habilitar auto-start al boot
systemctl --user enable mi-api.target

# Ver logs con journalctl
journalctl --user -u mi-api-backend -f
journalctl --user -u mi-api-postgres --since "10 minutes ago"
```

---

## Configurar OAuth (Google, Microsoft, GitHub)

### 1. Crear credenciales en el proveedor

**Google:**
1. Ve a https://console.cloud.google.com/apis/credentials
2. Crea un proyecto y configura OAuth 2.0
3. URI de redireccion: `http://auth.mi-app.localhost/auth/realms/master/broker/google/endpoint`

**Microsoft:**
1. Ve a https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade
2. Registra una app
3. URI de redireccion: `http://auth.mi-app.localhost/auth/realms/master/broker/microsoft/endpoint`

**GitHub:**
1. Ve a https://github.com/settings/developers
2. Crea un OAuth App
3. Callback URL: `http://auth.mi-app.localhost/auth/realms/master/broker/github/endpoint`

### 2. Configurar en .env

```bash
# En projects/mi-app/.env
GOOGLE_CLIENT_ID=tu-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=tu-client-secret
MICROSOFT_CLIENT_ID=tu-client-id
MICROSOFT_CLIENT_SECRET=tu-client-secret
GITHUB_CLIENT_ID=tu-client-id
GITHUB_CLIENT_SECRET=tu-client-secret
```

### 3. Configurar Identity Providers en Keycloak

1. Abre http://auth.mi-app.localhost/auth/admin/master/console/
2. Login con admin/admin
3. Ve a Identity Providers
4. Anade Google, Microsoft o GitHub con las credenciales del .env

---

## Hot Reload (Desarrollo)

Los contenedores de backend y frontend montan el codigo fuente como volumen:

```
projects/mi-api/
├── src/              # Tu codigo Python (montado en /app)
│   └── main.py       # Se recarga automaticamente con uvicorn --reload
├── frontend/         # Tu codigo frontend (montado en /app)
│   └── package.json
└── requirements.txt  # Dependencias Python
```

Cualquier cambio en `src/` o `frontend/` se refleja automaticamente sin reiniciar el contenedor.

---

## Troubleshooting

### Los contenedores no arrancan

```bash
# Ver logs del servicio
journalctl --user -u mi-api-backend -e

# Ver logs de Podman
podman logs mi-api-backend

# Verificar que systemd tiene los archivos
ls -la ~/.config/containers/systemd/
```

### Puerto ya en uso

```bash
# Ver que usa el puerto
ss -tlnp | grep 5432

# Cambiar el puerto en el archivo .container
# PublishPort=5433:5432

# Recargar
podman-utils link mi-api
podman-utils restart mi-api
```

### Quadlets no genera servicios

```bash
# Verificar version de Podman (requiere 4.0+)
podman --version

# Reinstalar quadlets
./install/quadlets-setup.sh

# Verificar directorio
ls ~/.config/containers/systemd/
```

### Reset completo de un proyecto

```bash
podman-utils destroy mi-api
rm -rf projects/mi-api
rm -f ~/.config/containers/systemd/mi-api*
systemctl --user daemon-reload
```

---

## Comandos de podman-utils

| Comando | Descripcion |
|---------|-------------|
| `create <template> <nombre>` | Crear proyecto desde plantilla |
| `start <nombre>` | Iniciar proyecto |
| `stop <nombre>` | Detener proyecto |
| `restart <nombre>` | Reiniciar proyecto |
| `logs <nombre> [servicio]` | Ver logs en tiempo real |
| `status <nombre>` | Ver estado del proyecto |
| `destroy <nombre>` | Eliminar proyecto (datos incluidos) |
| `link <nombre>` | Enlazar proyecto a systemd |
| `unlink <nombre>` | Desenlazar proyecto de systemd |
| `install-global <servicio>` | Instalar servicio compartido |
| `uninstall-global <servicio>` | Desinstalar servicio compartido |
| `list` | Listar proyectos |
| `list-templates` | Listar plantillas disponibles |
