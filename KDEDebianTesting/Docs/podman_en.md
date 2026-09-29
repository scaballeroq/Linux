---
sidebar_position: 10
---

# Podman Rootless and Systemd Quadlets on Debian Testing (KDE Plasma 6)

This guide describes the deployment of the **Rootless Podman** container ecosystem and native integration with **Systemd Quadlets** on **Debian Testing (Trixie/Sid)**.

---

## 1. Architecture

- **Security**: 100% rootless execution without root privileges or daemon processes (`daemonless`).
- **Modern Networking**: High-performance rootless networking with `passt` / `pasta` and `slirp4netns` native to Debian Testing with Netavark and local container DNS.
- **Orchestration**: Quadlets managed as native Systemd user units in `~/.config/containers/systemd/`.
- **Docker Compatibility**: Podman user socket active at `$XDG_RUNTIME_DIR/podman/podman.sock` and `docker -> podman` symlink.
- **Persistence**: User linger mode enabled (`loginctl enable-linger`) so user containers survive logout.

---

## 2. Installation and Configuration

```bash
just podman-base      # Installs Podman, passt, uidmap, and user socket
just podman-quadlets  # Sets up Quadlet directories and shared services
just podman-status    # Diagnoses container runtime and tools
```

---

## 3. Project and Container Manager (`podman-utils.sh`)

Includes the CLI utility `podman-utils.sh` (available in `PATH` and via the `podman-utils` alias):

```bash
podman-utils doctor             # Environment health check
podman-utils templates          # List available templates
podman-utils create <tpl> <nom> # Create isolated project from template
podman-utils shared-start       # Start global services (Traefik, Postgres...)
podman-utils shared-status      # Check shared services status
```

---

## 4. Available Templates (`Podman/templates/`)

- `python-postgres`: Python backend + PostgreSQL.
- `python-postgres-redis`: Python backend + PostgreSQL + Redis Cache.
- `fullstack`: Frontend + Backend + PostgreSQL + Keycloak Auth + Traefik Reverse Proxy.

---

## 5. Shared Services (`Podman/services-shared/`)

- `traefik.container`: Local reverse proxy with routing.
- `postgres-global.container`: Shared developer PostgreSQL database.
- `redis-global.container`: Centralized Redis cache.
- `keycloak.container`: IAM authentication server (OIDC/OAuth2).

---

## 6. Standalone Container Scripts (`Podman/scripts-standalone/`)

Collection of 17 individual containers ready for rapid development with safe replacement (`--replace`):
- Databases: MariaDB, MySQL, PostgreSQL, MongoDB, Redis.
- Messaging & Queues: RabbitMQ, Apache Kafka.
- Search & Observability: Elasticsearch, OpenSearch, Graylog, Grafana.
- Web Servers & Tools: Apache HTTPD, Nginx, Adminer.
- Security & Utilities: Vaultwarden, Cloudflare Tunnel.
