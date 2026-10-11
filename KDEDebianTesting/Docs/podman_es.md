---
sidebar_position: 10
---

# Podman Rootless y Systemd Quadlets en Debian Testing (KDE Plasma 6)

Esta guía describe el despliegue del ecosistema de contenedores **Podman Rootless** y la integración nativa con **Systemd Quadlets** en **Debian Testing (Trixie/Sid)**.

---

## 1. Arquitectura

- **Seguridad**: Ejecución 100% rootless sin privilegios de administrador ni demonio persistente en root (`daemonless`).
- **Redes Modernas**: Pila de red rootless de alto rendimiento con `passt` / `pasta` y `slirp4netns` nativas de Debian Testing con Netavark y DNS local.
- **Orquestación**: Quadlets gestionados como unidades nativas de Systemd de usuario en `~/.config/containers/systemd/`.
- **Compatibilidad Docker**: Socket de Podman activo en `$XDG_RUNTIME_DIR/podman/podman.sock` y symlink `docker -> podman`.
- **Persistencia**: Modo Linger activado (`loginctl enable-linger`) para que los servicios persistan tras cerrar la terminal.

---

## 2. Instalación y Configuración

```bash
just podman-base      # Instala Podman, passt, uidmap y socket de usuario
just podman-quadlets  # Despliega estructura de Quadlets y servicios compartidos
just podman-status    # Diagnóstico del entorno y herramientas
```

---

## 3. Gestor de Proyectos y Contenedores (`podman-utils.sh`)

Se incluye la utilidad CLI `podman-utils.sh` (integrada en `PATH` y alias `podman-utils`):

```bash
podman-utils doctor             # Comprobación de salud del entorno
podman-utils templates          # Listar plantillas disponibles
podman-utils create <tpl> <nom> # Crear nuevo proyecto desacoplado
podman-utils shared-start       # Iniciar servicios globales (Traefik, Postgres...)
podman-utils shared-status      # Estado de servicios compartidos
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

---

## 6. Scripts Standalone (`Podman/scripts-standalone/`)

Colección de 17 contenedores individuales listos para desarrollo rápido con sustitución segura (`--replace`):
- Bases de datos: MariaDB, MySQL, PostgreSQL, MongoDB, Redis.
- Mensajería y colas: RabbitMQ, Apache Kafka.
- Búsqueda y observabilidad: Elasticsearch, OpenSearch, Graylog, Grafana.
- Runtimes y servidores: Apache HTTPD, Nginx, Adminer.
- Seguridad y túneles: Vaultwarden, Cloudflare Tunnel.
