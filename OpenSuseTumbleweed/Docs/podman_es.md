---
sidebar_position: 10
---

# Podman Rootless y Systemd Quadlets en openSUSE Tumbleweed (KDE Plasma 6)

Esta guía describe el despliegue del ecosistema de contenedores **Podman Rootless** y la integración nativa con **Systemd Quadlets** en **openSUSE Tumbleweed**.

---

## 1. Arquitectura

- **Seguridad**: Ejecución 100% rootless sin privilegios de administrador ni demonio persistente en root (`daemonless`).
- **Redes Modernas**: Pila de red rootless de alto rendimiento con `pasta` (`passt`) y Netavark con DNS local.
- **Orquestación**: Quadlets gestionados como unidades nativas de Systemd de usuario en `~/.config/containers/systemd/`.
- **Compatibilidad Docker**: Socket de Podman activo en `$XDG_RUNTIME_DIR/podman/podman.sock` y symlink `docker -> podman`.
- **Persistencia**: Modo Linger activado (`loginctl enable-linger`) para que los servicios persistan tras cerrar la terminal.

---

## 2. Instalación y Configuración

```bash
just podman-base      # Instala Podman, passt y socket de usuario
just podman-quadlets  # Despliega estructura de Quadlets y servicios compartidos
just podman-status    # Diagnóstico del entorno y herramientas
```

---

## 3. Gestor de Proyectos y Contenedores (`podman-utils.sh`)

Se incluye la utilidad CLI `podman-utils.sh` (integrada en `PATH` y alias `podman-utils`):

```bash
podman-utils doctor             # Comprobación de salud del entorno (Overlay, Pasta, Firewalld, GPU)
podman-utils list-templates     # Listar plantillas disponibles
podman-utils create <tpl> <nom> # Crear nuevo proyecto desacoplado
podman-utils install-global all # Iniciar servicios globales (Traefik, Postgres, proxy-net...)
podman-utils quadlet-status     # Estado de archivos Quadlet y servicios systemd
podman-utils pps                # Listado enriquecido de contenedores activos
```

---

## 4. Plantillas Disponibles (`Podman/templates/`)

- `python-postgres`: Backend Python + PostgreSQL.
- `python-postgres-redis`: Backend Python + PostgreSQL + Redis Cache.
- `fullstack`: Frontend + Backend + PostgreSQL + Keycloak Auth + Traefik Reverse Proxy.

---

## 5. Servicios Compartidos (`Podman/services-shared/`)

- `traefik.container`: Reverse proxy local con enrutamiento inteligente.
- `postgres-global.container`: Base de datos PostgreSQL compartida para desarrollo.
- `redis-global.container`: Caché Redis centralizado.
- `keycloak.container`: Servidor de autenticación IAM (OIDC/OAuth2).
- `proxy-net.network`: Red compartida puente para interconexión de servicios globales.

---

## 6. Scripts Standalone (`Podman/scripts-standalone/`)

Colección de contenedores individuales listos para desarrollo rápido con sustitución segura (`--replace`):
- Bases de datos: MySQL, PostgreSQL, MongoDB, Redis.
- Observabilidad y logs: Prometheus, Grafana, Jaeger, Dozzle.
- Mensajería y correo: RabbitMQ, Mailhog.
- Runtimes y desarrollo: Portainer, Nginx, Adminer, MinIO, Browserless, Storybook, WordPress.
