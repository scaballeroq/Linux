---
name: ubuntu-podman-quadlets
description: >-
  Use this skill when creating, deploying, inspecting, and managing rootless Podman containers, Systemd Quadlets (.container, .network, .volume, .kube), user container services, rootless networking, and container firewall rules on Ubuntu Workstation.
---

# Podman Rootless & Systemd Quadlets Skill (Ubuntu Workstation)

Esta skill proporciona las directrices y comandos para gestionar el ecosistema de contenedores **Podman Rootless** integrado de forma nativa con **Systemd Quadlets** en Ubuntu Workstation (GNOME Shell 51).

---

## 1. Arquitectura Rootless y Requisitos del Sistema

En Ubuntu, Podman se ejecuta completamente en espacio de usuario sin privilegios de `root` ni demonios residentes en segundo plano.

### Verificación de requisitos:
```bash
# Diagnóstico general del entorno Podman
podman info

# Verificar asignación de rangos de UID/GID subordinados
grep "$USER" /etc/subuid /etc/subgid

# Asegurar persistencia de servicios de usuario tras cerrar sesión (Linger)
loginctl show-user "$USER" | grep Linger
# Activar linger si está en no:
loginctl enable-linger "$USER"

# Comprobar socket de Podman en modo usuario (para herramientas compatibles con Docker API)
systemctl --user status podman.socket
```

---

## 2. Systemd Quadlets (`~/.config/containers/systemd/`)

Los **Quadlets** permiten declarar contenedores como archivos declarativos que el generador de systemd (`/usr/lib/systemd/user-generators/podman-user-generator`) convierte automáticamente en servicios `systemd --user`.

Ubicación estándar de las definiciones del usuario:
`~/.config/containers/systemd/`

### 2.1. Ejemplo de definición de contenedor (`mi-servicio.container`):
```ini
[Unit]
Description=Servicio Web Nginx en Contenedor Podman
After=network-online.target

[Container]
Image=docker.io/library/nginx:alpine
ContainerName=nginx-web
PublishPort=8080:80
Volume=%h/Workspace/Contenedores/html:/usr/share/nginx/html:ro,Z
AutoUpdate=registry

[Service]
Restart=always
TimeoutStartSec=300

[Install]
WantedBy=default.target
```

### 2.2. Ciclo de vida con Systemd:
```bash
# Recargar el generador tras editar o crear archivos Quadlet
systemctl --user daemon-reload

# Iniciar, detener o reiniciar el contenedor como servicio systemd
systemctl --user start mi-servicio
systemctl --user restart mi-servicio
systemctl --user stop mi-servicio

# Inspeccionar logs en vivo
journalctl --user -u mi-servicio -f
```

---

## 3. CLI de Utilidad: `podman-utils`

El repositorio incluye la herramienta CLI `podman-utils` en `Podman/lib/podman-utils.sh` (enlazada en `~/.local/bin/podman-utils`):

```bash
# Diagnóstico completo del subsistema de contenedores
podman-utils doctor

# Crear un nuevo proyecto a partir de plantillas
podman-utils create fullstack mi-app
podman-utils create python-postgres mi-api

# Gestión del ciclo de vida del proyecto
podman-utils start mi-app
podman-utils status mi-app
podman-utils logs mi-app
podman-utils stop mi-app

# Desplegar servicios globales compartidos
podman-utils install-global postgres-global
```

---

## 4. Reglas de Cortafuegos (Firewalld)

Toda exposición de puertos hacia la red local debe gestionarse exclusivamente con `firewall-cmd`:
```bash
# Permitir acceso al contenedor en la red local
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=8080/tcp
sudo firewall-cmd --reload
```
