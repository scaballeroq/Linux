# Podman Professional - Quadlets para Desarrollo

Gestión de contenedores con **Podman Rootless + Quadlets + systemd** en **Fedora 44 Workstation + KDE Plasma 6 (Wayland)**.

Al ser Fedora la distribución comunitaria impulsada por **Red Hat**, Podman es el motor de contenedores nativo de primera clase instalado y soportado de serie. Esta configuración aprovecha su integración profunda con `systemd`, `cgroups v2`, `SELinux`, `Netavark`/`pasta` y el generador de Quadlets.

Optimizado específicamente para la estación de trabajo:
- **Distribución Base:** Fedora 44 Workstation (KDE Plasma 6 sobre Wayland)
- **CPU:** AMD Ryzen 7 PRO 4750U (8 núcleos / 16 hilos Zen 2)
- **GPU:** AMD Radeon Vega 7 Graphics (aceleración hardware VA-API y passthrough `/dev/dri/card0` y `/dev/dri/renderD128`)
- **Memoria:** 32 GB RAM DDR4 con ZRAM swap activa
- **Almacenamiento:** SSD NVMe 1 TB (`ext4`/`btrfs`) con driver `overlay` nativo en kernel (sin sobrecarga FUSE)
- **Red:** Rootless de alto rendimiento con `pasta` (`passt`) y Netavark
- **Seguridad:** Firewalld con interfaces `podman+` y `cni-podman+` en zona `trusted`, y compatibilidad nativa con SELinux (`:z` / `:Z`)

---

## Estructura

```
Podman/
├── install/                  # Scripts de instalación y configuración
│   ├── podman-install.sh     # Configura y optimiza Podman rootless para Fedora y hardware AMD
│   └── quadlets-setup.sh     # Prepara directorios y servicios systemd Quadlets
│
├── lib/                      # CLI y autocompletados
│   ├── podman-utils.sh       # CLI unificado para proyectos, contenedores y Quadlets
│   ├── podman-utils-completion.bash # Autocompletado oficial para Bash
│   └── podman-utils-completion.zsh  # Autocompletado oficial para Zsh
│
├── templates/                # Plantillas declarativas de proyectos (Quadlets)
│   ├── python-postgres/      # Python 3.13 (FastAPI/Flask) + PostgreSQL 17
│   ├── python-postgres-redis/# Python + PostgreSQL 17 + Redis 7 (Celery/Cache)
│   └── fullstack/            # Frontend (Node 22) + Backend + Postgres + Traefik + Keycloak 26
│
├── services-shared/          # Servicios globales y redes compartidas
│   ├── proxy-net.network     # Red bridge declarativa para servicios globales
│   ├── traefik.container     # Proxy inverso global con dashboard
│   ├── keycloak.container    # Autenticación OAuth2/OIDC centralizada (Keycloak 26)
│   ├── postgres-global.container  # PostgreSQL multi-base de datos compartido
│   └── redis-global.container     # Redis compartido para cache global
│
├── scripts-standalone/       # 18 Contenedores de desarrollo rápido con volúmenes persistentes
└── projects/                 # Tus proyectos locales generados (gitignored)
```

---

## Instalación y Configuración

### 1. Configuración Integral de Podman Rootless

Dado que Podman ya viene integrado en Fedora, el script comprueba de forma idempotente las dependencias opcionales (`podman-compose`, `podman-docker`, `passt`, `catatonit`), evitando llamadas a `sudo` si los paquetes ya están instalados.

```bash
# Ejecutar el instalador/optimizador:
./install/podman-install.sh

# O mediante just:
just podman-setup
```

**Optimizaciones aplicadas automáticamente:**
- **Overlay Nativo:** Configura `~/.config/containers/storage.conf` con `metacopy=on` para máximo rendimiento I/O sin FUSE.
- **Hardware AMD Ryzen & Vega 7:** `~/.config/containers/containers.conf` configurado con 8 copias paralelas para descargas, runtime `crun`, PIDs limit a 4096 y passthrough `/dev/dri`.
- **Sesión Gráfica KDE Plasma 6 (Wayland):** Inyecta `DOCKER_HOST` y `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` en `~/.config/environment.d/10-podman.conf`. IDEs (VS Code, JetBrains, DevContainers) y utilidades gráficas reconocen el socket inmediatamente al iniciar sesión.
- **Shells Modulares:** Inyección en `~/.bashrc.d/podman.sh` y condicional en `~/.zshrc.d/podman.zsh`.
- **Red y Firewalld:** Interfaz `podman+` añadida a la zona `trusted` en Firewalld.
- **CLI & Autocompletado:** Symlink en `~/.local/bin/podman-utils` y registros de autocompletado en Bash y Zsh.

### 2. Estructura de Quadlets

```bash
# Preparar directorios de usuario para systemd Quadlets:
./install/quadlets-setup.sh

# O instalar también todos los servicios y redes compartidas:
./install/quadlets-setup.sh --install-shared
```

### 3. Diagnóstico del Entorno (Doctor)

Comprueba en cualquier momento el estado de la API, sockets, cgroups, SELinux, firewalld y aceleración GPU:

```bash
podman-utils doctor
# o
just podman-status
```

---

## Flujo de Trabajo con Proyectos (Quadlets)

### Crear un proyecto

```bash
# Python + PostgreSQL
podman-utils create python-postgres mi-api

# Python + PostgreSQL + Redis (Celery, tareas async)
podman-utils create python-postgres-redis mi-api

# Fullstack con proxy y autenticación OAuth2
podman-utils create fullstack mi-app
```

### Configurar credenciales

```bash
nano projects/mi-api/.env
```

Modifica las credenciales y puertos por defecto antes de iniciar los servicios.

### Operaciones del Ciclo de Vida

```bash
# Iniciar servicios del proyecto vía systemd
podman-utils start mi-api

# Ver estado detallado de las unidades systemd y contenedores
podman-utils status mi-api

# Ver logs en tiempo real vía journalctl
podman-utils logs mi-api
podman-utils logs mi-api backend

# Detener o reiniciar
podman-utils stop mi-api
podman-utils restart mi-api

# Destruir proyecto (elimina archivos, enlaces y contenedores tras confirmación)
podman-utils destroy mi-api
```

---

## Plantillas Declarativas

### 1. `python-postgres`
- **PostgreSQL 17 (Alpine):** Puerto `5432`, volumen persistente `__PROJECT__-pg-data`.
- **Backend Python 3.13:** Puerto `8000`, uvicorn con `--reload`, montaje en caliente de `./src` y `./requirements.txt`.
- **Ideal para:** APIs REST con FastAPI, Flask o Django.

### 2. `python-postgres-redis`
- **PostgreSQL 17 (Alpine):** Puerto `5432`.
- **Redis 7 (Alpine):** Puerto `6379`, persistencia AOF en volumen `__PROJECT__-redis-data`.
- **Backend Python 3.13:** Puerto `8000`, uvicorn hot-reload.
- **Ideal para:** APIs con colas Celery/RQ, cacheo y rate-limiting.

### 3. `fullstack`
- **Traefik v3.2:** Puertos `80`, `443`, `8080` (Dashboard).
- **Keycloak 26:** Puerto `8083`, soporte OIDC/OAuth2 (`auth.__PROJECT__.localhost`).
- **PostgreSQL 17:** Base de datos relacional para backend y Keycloak.
- **Backend Python:** API en `api.__PROJECT__.localhost`.
- **Frontend Node 22 (Alpine):** Dev server Vite/Next en `app.__PROJECT__.localhost` (puerto `3000`).

---

## Servicios Compartidos (Globales)

Servicios persistentes que pueden ser consumidos por múltiples proyectos:

```bash
# Instalar todos los servicios y la red proxy-net:
podman-utils install-global all

# O instalar selectivamente:
podman-utils install-global traefik
podman-utils install-global postgres-global
podman-utils install-global redis-global
podman-utils install-global keycloak

# Control directo vía systemd:
systemctl --user start traefik.service
systemctl --user stop postgres-global.service

# Desinstalar servicio compartido:
podman-utils uninstall-global traefik
```

---

## Contenedores Rápidos Standalone (`scripts-standalone/`)

Para pruebas inmediatas, tareas puntuales de debugging o prototipado sin definir Quadlets completos, dispones de scripts preconfigurados con volúmenes persistentes y red común `dev-net`:

| Script | Servicio / Puerto | Características |
|---|---|---|
| `./scripts-standalone/podman-postgres.sh` | PostgreSQL 17 (`5432`) | Volumen `postgres-standalone-data` |
| `./scripts-standalone/podman-redis.sh` | Redis 7 (`6379`) | Volumen `redis-standalone-data`, AOF activo |
| `./scripts-standalone/podman-mysql.sh` | MySQL 8.4 (`3306`) | Volumen `mysql-standalone-data` |
| `./scripts-standalone/podman-mongodb.sh` | MongoDB 7 (`27017`) | Volumen `mongo-standalone-data` |
| `./scripts-standalone/podman-nginx.sh` | Nginx (`8082`) | Servidor web estático |
| `./scripts-standalone/podman-adminer.sh` | Adminer (`8080`) | GUI web para Postgres, MySQL, SQLite |
| `./scripts-standalone/podman-minio.sh` | MinIO S3 (`9000`/`9001`) | Almacenamiento compatible S3 |
| `./scripts-standalone/podman-rabbitmq.sh` | RabbitMQ (`5672`/`15672`)| Broker AMQP + Management Web UI |
| `./scripts-standalone/podman-keycloak.sh` | Keycloak 26 (`8083`) | Servidor de identidades en dev-mode |
| `./scripts-standalone/podman-mailhog.sh` | MailHog (`1025`/`8025`) | Captura SMTP local + Web UI |
| `./scripts-standalone/podman-grafana.sh` | Grafana (`3000`) | Dashboards y visualización métricas |
| `./scripts-standalone/podman-prometheus.sh` | Prometheus (`9090`) | Recolección de métricas y series temporales |
| `./scripts-standalone/podman-jaeger.sh` | Jaeger Tracing (`16686`) | Trazabilidad distribuida OpenTelemetry |
| `./scripts-standalone/podman-portainer.sh` | Portainer CE (`9443`) | GUI de gestión vía socket de usuario |
| `./scripts-standalone/podman-dozzle.sh` | Dozzle (`8888`) | Visor ligero de logs en tiempo real |
| `./scripts-standalone/podman-browserless.sh` | Chrome Headless (`3000`)| Scraping y automatización Playwright/Puppeteer |
| `./scripts-standalone/podman-storybook.sh` | Storybook (`6006`) | Entorno visual de componentes frontend |
| `./scripts-standalone/podman-wordpress.sh` | WordPress (`8085`) | Pila rápida de blogs / CMS |

---

## Consideraciones de Red Hat, Fedora y SELinux

1. **SELinux en modo Enforcing:**
   Fedora ejecuta SELinux de forma activa. Todos los montajes de volúmenes de host en las plantillas utilizan el sufijo `:z` (etiquetado compartido) o `:ro,z` (solo lectura compartido) para permitir que los procesos del contenedor lean y escriban sin violaciones de política SELinux.
2. **Firewalld:**
   La interfaz de red virtual `podman+` se asocia a la zona `trusted` para garantizar que las solicitudes DNS (`Netavark`/`Aardvark-dns`) y el reenvío entre contenedores no se vean bloqueados por el cortafuegos del host.
3. **Cgroups v2:**
   Fedora utiliza cgroups v2 de forma nativa. Podman se coordina directamente con `systemd` como `cgroup_manager`, asegurando contabilidad de memoria, CPU y límites de PIDs transparentes a nivel de usuario.
4. **Desarrollo Hot-Reload:**
   Los volúmenes montados desde `./src` en el backend y `./frontend` en el cliente web permiten reflejar cambios de código instantáneamente sin necesidad de reconstruir las imágenes.

---

## Tabla de Comandos `podman-utils`

| Comando | Descripción |
|---|---|
| `create <template> <nombre>` | Crea un nuevo proyecto a partir de una plantilla declarativa |
| `start <nombre>` | Inicia el proyecto vía unidades `systemd` de usuario |
| `stop <nombre>` | Detiene los servicios del proyecto |
| `restart <nombre>` | Reinicia el proyecto |
| `logs <nombre> [servicio]` | Muestra logs combinados o de un servicio vía `journalctl` |
| `status <nombre>` | Muestra estado de units systemd y contenedores Podman |
| `destroy <nombre>` | Detiene, desenlaza de systemd y borra archivos del proyecto |
| `link <nombre>` | Enlaza los archivos Quadlet del proyecto a `~/.config/containers/systemd/` |
| `unlink <nombre>` | Desenlaza los archivos Quadlet del proyecto |
| `install-global <servicio\|all>` | Instala servicio/red global compartido (`postgres-global`, `traefik`, etc.) |
| `uninstall-global <servicio>` | Desinstala un servicio global compartido |
| `pps` | Muestra contenedores activos con formato enriquecido (redes, puertos) |
| `pexec <id> [cmd]` | Abre una shell interactiva `/bin/bash` dentro de un contenedor en ejecución |
| `quadlet-status` | Inspecciona todos los archivos Quadlet y unidades activas |
| `quadlet-reload` | Recarga inmediata del generador Quadlet (`systemctl --user daemon-reload`) |
| `list` | Lista todos los proyectos locales y si tienen contenedores corriendo |
| `list-templates` | Muestra las plantillas disponibles |
| `doctor` | Diagnóstico completo de motor, socket, GPU, storage, SELinux, Firewalld y red |
