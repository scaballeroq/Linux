---
sidebar_position: 8
---

# Gestión de Contenedores con Podman y Quadlets en Fedora 44

Esta guía detalla la arquitectura profesional de contenedores **Podman Rootless** y **Systemd Quadlets** gestionada en la carpeta `Podman`.

A diferencia de Docker tradicional, Podman funciona por defecto de manera segura **sin demonio permanente (daemonless)** y **sin privilegios de root (rootless)**, integrando los contenedores como servicios nativos de Systemd del usuario mediante la especificación **Quadlets**.

---

## 1. Arquitectura del Entorno

```
Podman/
├── install/                  # Scripts de aprovisionamiento
│   ├── podman-install.sh     # Instala y configura Podman rootless
│   └── quadlets-setup.sh     # Estructura de systemd para Quadlets
│
├── lib/
│   └── podman-utils.sh       # CLI principal de gestión de proyectos y servicios
│
├── templates/                # Plantillas listas para producción
│   ├── python-postgres/      # Python (FastAPI/Uvicorn Hot-Reload) + PostgreSQL
│   ├── python-postgres-redis/# Python + PostgreSQL + Redis (Celery / Caché)
│   └── fullstack/            # Traefik + Keycloak + PostgreSQL + Backend + Frontend
│
├── services-shared/          # Servicios globales compartidos
│   ├── traefik.container     # Proxy inverso global
│   ├── keycloak.container    # Autenticación centralizada OAuth2/OIDC
│   ├── postgres-global.container  # PostgreSQL multi-tenant
│   └── redis-global.container     # Redis compartido
│
└── projects/                 # Tus proyectos locales (gitignored)
```

---

## 2. Instalación y Puesta en Marcha (`podman-install.sh`)

Instala Podman, complementos de orquestación y configura el entorno rootless:

```bash
just podman-setup
# o ./Podman/install/podman-install.sh
```

El script automatiza:
1. **Paquetes**: `podman`, `podman-compose`, `podman-docker`, `passt` (pila de red de alto rendimiento para Fedora 44) y `fuse-overlayfs`.
2. **Persistencia (Linger)**: `loginctl enable-linger $USER` (permite que los contenedores sigan ejecutándose tras cerrar sesión).
3. **Socket de Usuario**: Activa `systemctl --user enable --now podman.socket` para emular la API de Docker.
4. **Integración con IDEs**: Registra `DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"` en `~/.config/environment.d/10-podman.conf` para compatibilidad transparente con VS Code, JetBrains y DevContainers en KDE Plasma.
5. **CLI Global**: Crea el enlace simbólico `~/.local/bin/podman-utils`.

---

## 3. Diagnóstico del Sistema (`podman-utils doctor`)

Comprueba la salud del entorno de contenedores:

```bash
podman-utils doctor
# o
just podman-status
```

---

## 4. Gestión de Proyectos con `podman-utils`

### Crear un nuevo proyecto desde plantilla:
```bash
# Python + PostgreSQL:
podman-utils create python-postgres mi-api

# Python + PostgreSQL + Redis:
podman-utils create python-postgres-redis mi-api-celery

# Fullstack con autenticación y proxy:
podman-utils create fullstack mi-app
```

### Ciclo de vida del proyecto:
```bash
# Iniciar todos los contenedores del proyecto:
podman-utils start mi-api

# Ver estado y puertos asignados:
podman-utils status mi-api

# Visualizar logs en tiempo real:
podman-utils logs mi-api
# o de un servicio concreto:
podman-utils logs mi-api backend

# Reiniciar o detener:
podman-utils restart mi-api
podman-utils stop mi-api

# Eliminar proyecto y sus volúmenes asociados:
podman-utils destroy mi-api
```

---

## 5. Servicios Globales Compartidos

Servicios compartidos entre múltiples proyectos para ahorrar memoria y centralizar puertos:

```bash
# Instalar Traefik como proxy inverso global:
podman-utils install-global traefik

# Instalar base de datos PostgreSQL compartida:
podman-utils install-global postgres-global

# Instalar Redis compartido:
podman-utils install-global redis-global

# Instalar servidor de identidad Keycloak:
podman-utils install-global keycloak
```

Control con systemd de usuario:
```bash
systemctl --user start traefik.service
systemctl --user status postgres-global.service
```

---

## 6. Hot-Reload en Desarrollo

Las plantillas montan automáticamente el código fuente en caliente dentro del contenedor:
- `projects/mi-api/src/main.py`: Se recarga automáticamente con Uvicorn al guardar cambios en tu IDE.
- `projects/mi-app/frontend/`: Recarga en vivo para React/Vue/Node.

---

## Verificación

- **Estado Rootless**: Ejecuta `podman info` y verifica que `rootless: true`.
- **Socket**: Ejecuta `podman version` y comprueba la conexión tanto con el cliente como con el servidor.
- **Systemd Units**: Ejecuta `systemctl --user list-units "*container*"` para ver los servicios generados por Quadlets.
