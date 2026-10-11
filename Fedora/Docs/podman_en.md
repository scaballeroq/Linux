---
sidebar_position: 8
---

# Container Management with Podman & Quadlets on Fedora 44

This guide details the professional **Rootless Podman** and **Systemd Quadlets** container ecosystem managed in the `Podman` folder.

Unlike traditional Docker, Podman runs by default **daemonless** and **rootless**, integrating containers natively as user-level systemd units via the **Quadlets** specification.

---

## 1. Directory Structure

```
Podman/
├── install/                  # Provisioning scripts
│   ├── podman-install.sh     # Installs and configures rootless Podman
│   └── quadlets-setup.sh     # Systemd Quadlet file structure
│
├── lib/
│   └── podman-utils.sh       # Main CLI for project and service lifecycle
│
├── templates/                # Production-ready project templates
│   ├── python-postgres/      # Python (FastAPI/Uvicorn Hot-Reload) + PostgreSQL
│   ├── python-postgres-redis/# Python + PostgreSQL + Redis (Celery / Cache)
│   └── fullstack/            # Traefik + Keycloak + PostgreSQL + Backend + Frontend
│
├── services-shared/          # Reusable global services
│   ├── traefik.container     # Global reverse proxy
│   ├── keycloak.container    # Centralized OAuth2/OIDC IAM
│   ├── postgres-global.container  # Shared multi-tenant PostgreSQL
│   └── redis-global.container     # Shared Redis store
│
└── projects/                 # Local projects (gitignored)
```

---

## 2. Setup & Activation (`podman-install.sh`)

Installs Podman, orchestration plugins, and configures the rootless environment:

```bash
just podman-setup
# or ./Podman/install/podman-install.sh
```

The script automates:
1. **Packages**: `podman`, `podman-compose`, `podman-docker`, `passt` (high-performance networking stack for Fedora 44), and `fuse-overlayfs`.
2. **User Persistence (Linger)**: `loginctl enable-linger $USER` (keeps background containers running after logout).
3. **User Socket**: Enables `systemctl --user enable --now podman.socket` for Docker API emulation.
4. **IDE Integration**: Injects `DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"` into `~/.config/environment.d/10-podman.conf` for seamless VS Code, JetBrains, and DevContainer integration in KDE Plasma.
5. **Global CLI**: Creates symlink `~/.local/bin/podman-utils`.

---

## 3. Environment Diagnosis (`podman-utils doctor`)

Checks the health of the container environment:

```bash
podman-utils doctor
# or
just podman-status
```

---

## 4. Project Management with `podman-utils`

### Create a new project from template:
```bash
# Python + PostgreSQL:
podman-utils create python-postgres my-api

# Python + PostgreSQL + Redis:
podman-utils create python-postgres-redis my-api-celery

# Fullstack with authentication & reverse proxy:
podman-utils create fullstack my-app
```

### Project Lifecycle:
```bash
# Start all containers in the project:
podman-utils start my-api

# Check status and exposed ports:
podman-utils status my-api

# Stream real-time logs:
podman-utils logs my-api
# or for a specific container:
podman-utils logs my-api backend

# Restart or stop:
podman-utils restart my-api
podman-utils stop my-api

# Destroy project and purge associated volumes:
podman-utils destroy my-api
```

---

## 5. Shared Global Services

Shared services across multiple projects to save memory and avoid port conflicts:

```bash
# Install Traefik as global reverse proxy:
podman-utils install-global traefik

# Install shared multi-tenant PostgreSQL:
podman-utils install-global postgres-global

# Install shared Redis:
podman-utils install-global redis-global

# Install Keycloak IAM server:
podman-utils install-global keycloak
```

Manage with user-level systemd:
```bash
systemctl --user start traefik.service
systemctl --user status postgres-global.service
```

---

## 6. Live Hot-Reload in Development

Templates mount source code volumes live into containers:
- `projects/my-api/src/main.py`: Automatically reloads via Uvicorn whenever changes are saved in your IDE.
- `projects/my-app/frontend/`: Live hot-reload for React/Vue/Node frontends.

---

## Verification

- **Rootless Status**: Run `podman info` and verify `rootless: true`.
- **Socket**: Run `podman version` to verify client/server connectivity.
- **Systemd Units**: Run `systemctl --user list-units "*container*"` to view active Quadlet-generated services.
