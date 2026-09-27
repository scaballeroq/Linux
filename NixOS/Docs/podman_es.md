---
sidebar_position: 10
---

# Podman Rootless y Systemd Quadlets en OpenSUSE Tumbleweed

Esta guía describe el despliegue del ecosistema de contenedores **Podman Rootless** y la integración nativa con **Systemd Quadlets** en **OpenSUSE Tumbleweed**.

---

## 1. Arquitectura

- **Seguridad**: Ejecución 100% rootless sin privilegios de administrador.
- **Redes**: Netavark y Aardvark-DNS con soporte para DNS local entre contenedores.
- **Orquestación**: Quadlets gestionados como unidades nativas de Systemd en `~/.config/containers/systemd/`.
- **Compatibilidad Docker**: Socket de Podman activo en `$XDG_RUNTIME_DIR/podman/podman.sock`.

---

## 2. Instalación y Configuración

```bash
just podman-base
just podman-quadlets
```

---

## 3. Plantillas Disponibles (`Podman/templates/`)

- `python-postgres`: Backend Python + PostgreSQL.
- `python-postgres-redis`: Backend Python + PostgreSQL + Redis Cache.
- `fullstack`: Frontend + Backend + PostgreSQL + Keycloak Auth + Traefik Reverse Proxy.

---

## 4. Servicios Compartidos (`Podman/services-shared/`)

- `traefik.container`: Reverse proxy local con certificados SSL automáticos.
- `postgres-global.container`: Base de datos compartida para desarrollo.
- `redis-global.container`: Cache Redis centralizado.
- `keycloak.container`: Servidor de autenticación IAM (OIDC/OAuth2).
