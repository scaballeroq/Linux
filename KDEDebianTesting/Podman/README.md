# Podman Professional - Quadlets para Desarrollo

Gestión de contenedores con **Podman Rootless + Quadlets + systemd** en **Debian Testing (forky/sid) + KDE Plasma 6 (Wayland)**.

Optimizado específicamente para:
- **CPU:** AMD Ryzen 7 PRO 4750U (8 núcleos / 16 hilos Zen 2)
- **GPU:** AMD Radeon Vega 7 Graphics (passthrough acelerado `/dev/dri/card0` y `/dev/dri/renderD128`)
- **Memoria:** 32 GB RAM DDR4 con ZRAM swap activa
- **Almacenamiento:** SSD NVMe 1 TB en formato `ext4` con driver `overlay` nativo en kernel (sin FUSE)
- **Red:** Rootless de alto rendimiento con `pasta` (`passt`) y Netavark
- **Seguridad:** Firewalld con interfaces `podman+` en zona `trusted`

---

## Estructura

```
Podman/
├── install/                  # Scripts de instalación y configuración
│   ├── podman-install.sh     # Instala y optimiza Podman rootless para el hardware
│   └── quadlets-setup.sh     # Configura directorios y servicios systemd Quadlets
│
├── lib/                      # CLI y autocompletados
│   ├── podman-utils.sh       # CLI para proyectos, contenedores y Quadlets
│   ├── podman-utils-completion.bash # Autocompletado Bash
│   └── podman-utils-completion.zsh  # Autocompletado Zsh
│
├── templates/                # Plantillas de proyectos declarativos
│   ├── python-postgres/      # Python 3.13 + PostgreSQL 17
│   ├── python-postgres-redis/# Python + PostgreSQL + Redis 7
│   └── fullstack/            # Frontend (Node 22) + Backend + Postgres + Traefik + Keycloak
│
├── services-shared/          # Servicios globales y redes compartidas
│   ├── proxy-net.network     # Red bridge común para servicios globales
│   ├── traefik.container     # Proxy inverso global
│   ├── keycloak.container    # OAuth2/OIDC compartido
│   ├── postgres-global.container  # PostgreSQL compartido
│   └── redis-global.container     # Redis compartido
│
├── scripts-standalone/       # Contenedores de desarrollo rápido con volúmenes persistentes
└── projects/                 # Tus proyectos locales (gitignored)
```

---

## Instalación

### 1. Instalar y Optimizar Podman

```bash
./install/podman-install.sh
```

Configura Podman rootless con almacenamiento overlay nativo en kernel, `containers.conf` con 8 descargas paralelas y soporte GPU Vega 7, linger persistente, socket Docker API y variables de entorno para KDE Plasma 6 y shells.

### 2. Configurar Quadlets y Servicios Globales

```bash
# Inicializar estructura de directorios:
./install/quadlets-setup.sh

# O instalar también todos los servicios y redes compartidos:
./install/quadlets-setup.sh --install-shared
```

### 3. CLI podman-utils disponible en PATH

El script `podman-install.sh` crea automáticamente un enlace simbólico en `~/.local/bin/podman-utils` y registra los autocompletados para Bash y Zsh.

Si deseas verificar el entorno o diagnosticar el sistema:

```bash
podman-utils doctor
podman-utils help
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

| Comando | Descripción |
|---------|-------------|
| `create <template> <nombre>` | Crear proyecto desde plantilla |
| `start <nombre>` | Iniciar proyecto vía systemd |
| `stop <nombre>` | Detener proyecto |
| `restart <nombre>` | Reiniciar proyecto |
| `logs <nombre> [servicio]` | Ver logs en tiempo real vía journalctl |
| `status <nombre>` | Ver estado detallado del proyecto y contenedores |
| `destroy <nombre>` | Eliminar proyecto (archivos, contenedores, volúmenes) |
| `link <nombre>` | Enlazar proyecto a systemd Quadlets |
| `unlink <nombre>` | Desenlazar proyecto de systemd |
| `install-global <servicio>` | Instalar servicio/red compartido (`postgres-global`, `traefik`, `all`) |
| `uninstall-global <servicio>` | Desinstalar servicio compartido |
| `pps` | Listar contenedores activos con formato enriquecido (redes, puertos) |
| `pexec <id> [cmd]` | Abrir shell interactivo en un contenedor |
| `quadlet-status` | Diagnóstico de todos los Quadlets y servicios de usuario |
| `quadlet-reload` | Recargar generadores y unidades systemd de usuario |
| `list` | Listar proyectos y contenedores asociados |
| `list-templates` | Listar plantillas disponibles |
| `doctor` | Diagnóstico completo de motor, socket, GPU, storage y red |

