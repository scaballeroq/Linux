# Podman Professional - Quadlets para Desarrollo (Omarchy / Arch Linux)

Gestión moderna de contenedores con **Podman Rootless + Quadlets + systemd** para proyectos FastAPI, Node.js y PostgreSQL con proxy inverso, autenticación y servicios globales compartidos.

---

## Estructura

```
Podman/
├── install/                  # Scripts de instalación y configuración
│   ├── podman-install.sh     # Instala Podman rootless en Omarchy / Arch
│   └── quadlets-setup.sh     # Configura systemd para Quadlets
│
├── lib/
│   └── podman-utils.sh       # CLI para gestionar proyectos
│
├── templates/                # Plantillas de proyectos
│   ├── python-postgres/      # Python (FastAPI) + PostgreSQL
│   ├── python-postgres-redis/# Python + PostgreSQL + Redis
│   └── fullstack/            # Front (Node) + Back (FastAPI) + PostgreSQL + Traefik + Keycloak
│
├── services-shared/          # Servicios globales reutilizables
│   ├── traefik.container     # Proxy inverso global
│   ├── keycloak.container    # OAuth2/OIDC (Google, Microsoft, GitHub)
│   ├── postgres-global.container  # PostgreSQL compartido
│   └── redis-global.container     # Redis compartido
│
└── projects/                 # Tus proyectos locales (gitignored)
```

---

## Instalación

### 1. Instalar Podman

```bash
./install/podman-install.sh
```

Instala Podman rootless con todas las dependencias necesarias (`netavark`, `aardvark-dns`, `slirp4netns`, `passt`, `fuse-overlayfs`) en Omarchy / Arch Linux.

### 2. Configurar Quadlets

```bash
./install/quadlets-setup.sh
```

Crea la estructura de systemd para gestionar contenedores como servicios del usuario.

### 3. Añadir CLI al PATH o usar Aliases

Añade a tu `~/.bashrc` o `~/.zshrc`:

```bash
export PATH="$HOME/Workspace/Repositorios/Linux/Omarchy/Podman/lib:$PATH"
```

O usa los atajos integrados en `Bash.Setup`:

```bash
alias podman-utils="$HOME/Workspace/Repositorios/Linux/Omarchy/Podman/lib/podman-utils.sh"
alias putils="$HOME/Workspace/Repositorios/Linux/Omarchy/Podman/lib/podman-utils.sh"
```

---

## Uso Rápido

### Crear un proyecto

```bash
# Python + PostgreSQL
podman-utils create python-postgres mi-api

# Python + PostgreSQL + Redis (Celery, caché, etc.)
podman-utils create python-postgres-redis mi-api

# Fullstack con proxy y autenticación
podman-utils create fullstack mi-app
```

### Configurar credenciales

```bash
nano projects/mi-api/.env
```

Modifica las contraseñas y variables de entorno deseadas antes de iniciar.

### Iniciar el proyecto

```bash
podman-utils start mi-api
```

### Ver logs

```bash
# Todos los servicios del proyecto
podman-utils logs mi-api

# Un servicio específico
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

### Eliminar proyecto (contenedores, redes, volúmenes y archivos)

```bash
podman-utils destroy mi-api
```

---

## Templates

### `python-postgres`

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| PostgreSQL | 5432 | Base de datos relacional |
| Backend Python | 8000 | API FastAPI con uvicorn + hot-reload |

**Ideal para:** APIs REST con FastAPI, Flask o Django + PostgreSQL.

### `python-postgres-redis`

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| PostgreSQL | 5432 | Base de datos relacional |
| Redis | 6379 | Caché, Celery, colas y sesiones |
| Backend Python | 8000 | API FastAPI con uvicorn + hot-reload |

**Ideal para:** APIs con tareas en segundo plano (Celery), caché y rate limiting.

### `fullstack`

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| Traefik | 80, 443, 8080 | Proxy inverso + dashboard web |
| Keycloak | 8083 | Autenticación OAuth2 / OIDC |
| PostgreSQL | 5432 | Base de datos |
| Backend Python | 8000 | API FastAPI |
| Frontend (Node) | 3000 | Frontend dev server |

**Rutas locales con Traefik:**
- `api.mi-app.localhost` -> Backend
- `app.mi-app.localhost` -> Frontend
- `auth.mi-app.localhost` -> Keycloak
- `:8080` -> Dashboard interactivo de Traefik

**Ideal para:** Aplicaciones completas con autenticación OAuth (Google, Microsoft, GitHub).

---

## Servicios Globales

Servicios compartidos entre múltiples proyectos en segundo plano.

### Instalar

```bash
# Proxy inverso global (un solo Traefik para todos los proyectos)
podman-utils install-global traefik

# PostgreSQL compartido (multi-tenant)
podman-utils install-global postgres-global

# Redis compartido
podman-utils install-global redis-global

# Keycloak global (servidor de autenticación único)
podman-utils install-global keycloak
```

### Iniciar / Detener

```bash
systemctl --user start traefik.service
systemctl --user stop postgres-global.service
```

### Desinstalar

```bash
podman-utils uninstall-global traefik
```

---

## Gestión Directa con systemd

Los Quadlets generan unidades systemd de usuario automáticamente:

```bash
# Ver todos los servicios del proyecto
systemctl --user list-units "mi-api*"

# Iniciar un servicio específico
systemctl --user start mi-api-postgres.service

# Habilitar auto-start al arrancar el sistema
systemctl --user enable mi-api.target

# Ver logs con journalctl
journalctl --user -u mi-api-backend -f
journalctl --user -u mi-api-postgres --since "10 minutes ago"
```

---

## Configurar OAuth (Google, Microsoft, GitHub)

### 1. Crear credenciales en el proveedor

- **Google Cloud Console:**
  - URI de redirección: `http://auth.mi-app.localhost/auth/realms/master/broker/google/endpoint`
- **Microsoft Entra ID (Azure Portal):**
  - URI de redirección: `http://auth.mi-app.localhost/auth/realms/master/broker/microsoft/endpoint`
- **GitHub Developers:**
  - Authorization callback URL: `http://auth.mi-app.localhost/auth/realms/master/broker/github/endpoint`

### 2. Configurar en `.env`

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

1. Abre `http://auth.mi-app.localhost/auth/admin/master/console/`
2. Inicia sesión con `admin`/`admin`
3. Ve a **Identity Providers**
4. Añade Google, Microsoft o GitHub con las credenciales del `.env`

---

## Hot Reload (Desarrollo)

Los contenedores de backend y frontend montan el código fuente local como volumen:

```
projects/mi-api/
├── src/              # Código Python (montado en /app)
│   └── main.py       # Recarga en caliente automática
├── frontend/         # Código Frontend (montado en /app)
│   └── package.json
└── requirements.txt  # Dependencias Python
```

Cualquier cambio en `src/` o `frontend/` se refleja instantáneamente sin reiniciar el contenedor.

---

## Troubleshooting

### Los contenedores no arrancan

```bash
# Ver logs del servicio systemd
journalctl --user -u mi-api-backend -e

# Ver logs de Podman
podman logs mi-api-backend

# Verificar archivos generados
ls -la ~/.config/containers/systemd/
```

### Puerto ya en uso

```bash
# Verificar puerto ocupado
ss -tlnp | grep 5432

# Cambiar el puerto en el archivo .container (ej. PublishPort=5433:5432)
# Recargar configuración:
podman-utils link mi-api
podman-utils restart mi-api
```

### Quadlets no genera servicios

```bash
# Verificar versión de Podman (requiere 4.0+)
podman --version

# Reinstalar quadlets
./install/quadlets-setup.sh

# Recargar daemon systemd de usuario
systemctl --user daemon-reload
```

---

## Comandos de `podman-utils`

| Comando | Descripción |
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
