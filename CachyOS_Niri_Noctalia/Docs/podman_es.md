---
sidebar_position: 8
---

# Gestión de Contenedores con Podman en CachyOS

Esta guía detalla la instalación de la plataforma de contenedores **Podman** con **Quadlets** (systemd native) y el listado de servicios preconfigurados en la carpeta `Podman`.

A diferencia de Docker, Podman funciona por defecto de manera segura **sin demonio (daemonless)** y **sin privilegios de root (rootless)**, aislando los contenedores del usuario de manera nativa.

---

## 1. Configuración de Podman Core (`install/podman-install.sh`)

Instala Podman, su herramienta de orquestación `compose` y las dependencias de red avanzadas:

```bash
./Podman/install/podman-install.sh
```

Esto configura:
- **Podman rootless** con `passt` (red de alto rendimiento)
- **Persistencia Linger**: Los contenedores siguen corriendo al cerrar sesión
- **Socket de usuario**: API compatible con Docker en `/run/user/$UID/podman/podman.sock`
- **DOCKER_HOST**: Exportado en `environment.d` y `.bashrc.d` para integración con IDEs
- **Storage**: Driver overlay nativo en `~/.config/containers/storage.conf`
- **Registries**: docker.io, quay.io, ghcr.io, registry.archlinux.org

### Verificar estado
```bash
./Podman/install/podman-install.sh --status
```

---

## 2. Quadlets (`install/quadlets-setup.sh`)

Configura la estructura de directorios para servicios systemd nativos de Podman:

```bash
./Podman/install/quadlets-setup.sh
```

Directorios gestionados:
- `~/.config/containers/systemd/` → Proyectos activos
- `~/.config/containers/systemd/global/` → Servicios compartidos globales

---

## 3. CLI podman-utils (`lib/podman-utils.sh`)

Herramienta completa para gestión de proyectos con Quadlets:

```bash
# Crear proyecto desde plantilla
podman-utils create python-postgres mi-api

# Iniciar/detener/reiniciar
podman-utils start mi-api
podman-utils stop mi-api
podman-utils restart mi-api

# Ver logs y estado
podman-utils logs mi-api
podman-utils status mi-api

# Eliminar proyecto completamente
podman-utils destroy mi-api

# Listar proyectos y templates
podman-utils list
podman-utils list-templates

# Diagnóstico
podman-utils doctor
```

---

## 4. Plantillas de Proyectos (`templates/`)

### python-postgres
Python (FastAPI/Flask) + PostgreSQL
```bash
podman-utils create python-postgres mi-api
```

### python-postgres-redis
Python + PostgreSQL + Redis (Celery/Cache)
```bash
podman-utils create python-postgres-redis mi-api
```

### fullstack
Frontend + Backend + PostgreSQL + Traefik + Keycloak
```bash
podman-utils create fullstack mi-app
```

---

## 5. Servicios Globales Compartidos (`services-shared/`)

Servicios que pueden compartirse entre múltiples proyectos:

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| `postgres-global` | 5432 | PostgreSQL compartido |
| `redis-global` | 6379 | Redis compartido |
| `traefik` | 80, 443, 8080 | Reverse proxy |
| `keycloak` | 8080 | Identity management |

### Instalar servicio global
```bash
podman-utils install-global postgres
podman-utils install-global redis
podman-utils install-global traefik
podman-utils install-global keycloak
```

### Desinstalar servicio global
```bash
podman-utils uninstall-global postgres
```

---

## 6. Catálogo de Servicios Auxiliares (Legacy)

Los scripts individuales en `Podman/` siguen disponibles para despliegue rápido:

### Bases de Datos
- **PostgreSQL** (`podman-postgres.sh`): Puerto `5432`
- **MySQL** (`podman-mysql.sh`): Puerto `3306`
- **MongoDB** (`podman-mongodb.sh`): Puerto `27017`
- **Redis** (`podman-redis.sh`): Puerto `6379`

### Administración y Monitoreo
- **Portainer CE** (`podman-portainer.sh`): `https://localhost:9443`
- **Adminer** (`podman-adminer.sh`): `http://localhost:8080`
- **Dozzle** (`podman-dozzle.sh`): `http://localhost:8888`
- **Grafana** (`podman-grafana.sh`): `http://localhost:3000`
- **Prometheus** (`podman-prometheus.sh`): `http://localhost:9090`
- **Jaeger** (`podman-jaeger.sh`): `http://localhost:16686`

### Infraestructura
- **Nginx** (`podman-nginx.sh`): Puertos `80` y `443`
- **Keycloak** (`podman-keycloak.sh`): `http://localhost:8081`
- **RabbitMQ** (`podman-rabbitmq.sh`): `5672` / `15672`
- **MinIO** (`podman-minio.sh`): `9000` / `9001`
- **MailHog** (`podman-mailhog.sh`): `1025` / `8025`
- **Browserless** (`podman-browserless.sh`): Puerto `3001`

### CMS/Frameworks
- **WordPress** (`podman-wordpress.sh`): Puerto `8082`
- **Storybook** (`podman-storybook.sh`): Puerto `6006`

---

## Verificación

- **Estado de Podman**: `podman info` (debe indicar modo rootless)
- **Socket**: `curl --unix-socket $XDG_RUNTIME_DIR/podman/podman.sock http://d/info`
- **Diagnóstico completo**: `podman-utils doctor`
- **Servicios activos**: `podman ps`
