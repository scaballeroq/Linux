---
sidebar_position: 8
---

# Container Management with Podman on CachyOS

This guide details the installation of the **Podman** container platform with **Quadlets** (systemd native) and the list of pre-configured services inside the `Podman` folder.

Unlike Docker, Podman runs by default in a secure, **daemonless**, and **rootless** mode, keeping user containers securely isolated in user-space.

---

## 1. Configuring Podman Core (`install/podman-install.sh`)

Installs Podman, its `compose` orchestration helper, and modern network stacks:

```bash
./Podman/install/podman-install.sh
```

This configures:
- **Rootless Podman** with `passt` (high-performance networking)
- **User Linger**: Containers keep running after closing terminal session
- **User Socket**: Docker-compatible API at `/run/user/$UID/podman/podman.sock`
- **DOCKER_HOST**: Exported in `environment.d` and `.bashrc.d` for IDE integration
- **Storage**: Native overlay driver in `~/.config/containers/storage.conf`
- **Registries**: docker.io, quay.io, ghcr.io, registry.archlinux.org

### Check status
```bash
./Podman/install/podman-install.sh --status
```

---

## 2. Quadlets (`install/quadlets-setup.sh`)

Configures systemd native directories for Podman services:

```bash
./Podman/install/quadlets-setup.sh
```

Managed directories:
- `~/.config/containers/systemd/` → Active projects
- `~/.config/containers/systemd/global/` → Global shared services

---

## 3. CLI podman-utils (`lib/podman-utils.sh`)

Complete tool for project management with Quadlets:

```bash
# Create project from template
podman-utils create python-postgres my-api

# Start/stop/restart
podman-utils start my-api
podman-utils stop my-api
podman-utils restart my-api

# View logs and status
podman-utils logs my-api
podman-utils status my-api

# Destroy project completely
podman-utils destroy my-api

# List projects and templates
podman-utils list
podman-utils list-templates

# Diagnostics
podman-utils doctor
```

---

## 4. Project Templates (`templates/`)

### python-postgres
Python (FastAPI/Flask) + PostgreSQL
```bash
podman-utils create python-postgres my-api
```

### python-postgres-redis
Python + PostgreSQL + Redis (Celery/Cache)
```bash
podman-utils create python-postgres-redis my-api
```

### fullstack
Frontend + Backend + PostgreSQL + Traefik + Keycloak
```bash
podman-utils create fullstack my-app
```

---

## 5. Global Shared Services (`services-shared/`)

Services that can be shared across multiple projects:

| Service | Port | Description |
|---------|------|-------------|
| `postgres-global` | 5432 | Shared PostgreSQL |
| `redis-global` | 6379 | Shared Redis |
| `traefik` | 80, 443, 8080 | Reverse proxy |
| `keycloak` | 8080 | Identity management |

### Install global service
```bash
podman-utils install-global postgres
podman-utils install-global redis
podman-utils install-global traefik
podman-utils install-global keycloak
```

### Uninstall global service
```bash
podman-utils uninstall-global postgres
```

---

## 6. Legacy Auxiliary Services

Individual scripts in `Podman/` are still available for quick deployment:

### Databases
- **PostgreSQL** (`podman-postgres.sh`): Port `5432`
- **MySQL** (`podman-mysql.sh`): Port `3306`
- **MongoDB** (`podman-mongodb.sh`): Port `27017`
- **Redis** (`podman-redis.sh`): Port `6379`

### Administration and Monitoring
- **Portainer CE** (`podman-portainer.sh`): `https://localhost:9443`
- **Adminer** (`podman-adminer.sh`): `http://localhost:8080`
- **Dozzle** (`podman-dozzle.sh`): `http://localhost:8888`
- **Grafana** (`podman-grafana.sh`): `http://localhost:3000`
- **Prometheus** (`podman-prometheus.sh`): `http://localhost:9090`
- **Jaeger** (`podman-jaeger.sh`): `http://localhost:16686`

### Infrastructure
- **Nginx** (`podman-nginx.sh`): Ports `80` and `443`
- **Keycloak** (`podman-keycloak.sh`): `http://localhost:8081`
- **RabbitMQ** (`podman-rabbitmq.sh`): `5672` / `15672`
- **MinIO** (`podman-minio.sh`): `9000` / `9001`
- **MailHog** (`podman-mailhog.sh`): `1025` / `8025`
- **Browserless** (`podman-browserless.sh`): Port `3001`

### CMS/Frameworks
- **WordPress** (`podman-wordpress.sh`): Port `8082`
- **Storybook** (`podman-storybook.sh`): Port `6006`

---

## Verification

- **Podman Status**: `podman info` (should show rootless mode)
- **Socket**: `curl --unix-socket $XDG_RUNTIME_DIR/podman/podman.sock http://d/info`
- **Full diagnostics**: `podman-utils doctor`
- **Active services**: `podman ps`
