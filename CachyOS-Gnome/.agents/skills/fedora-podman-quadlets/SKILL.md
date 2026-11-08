---
name: fedora-podman-quadlets
description: Creación, despliegue, inspección y gestión de contenedores Podman Rootless, Systemd Quadlets (~/.config/containers/systemd/), utilidades de podman-utils, redes rootless y reglas de Firewalld en Fedora 45 Workstation con GNOME 51.
---

# Podman Rootless & Systemd Quadlets Skill (Fedora 45 Workstation + GNOME 51)

Esta skill proporciona las directrices operativas y comandos para gestionar el ecosistema de contenedores **Podman Rootless** integrado con **Systemd Quadlets** y **Firewalld** en **Fedora 45 Workstation (GNOME Shell 51 Wayland)**.

---

## 1. Arquitectura Rootless y Requisitos del Sistema

En Fedora 45, Podman se ejecuta de forma nativa sin privilegios de `root`, utilizando mapeo de IDs de usuario subordinados y el bus de usuario de Systemd.

### 1.1. Diagnóstico del Entorno Podman:
```bash
# Diagnóstico general del subsistema Podman
podman info

# Verificar mapeo de subuid y subgid asignados al usuario
grep "$USER" /etc/subuid /etc/subgid

# Comprobar estado del script de instalación del repositorio
./Podman/install/podman-install.sh --status
./Podman/install/quadlets-setup.sh --status

# Asegurar persistencia de servicios tras cerrar sesión (Linger activo)
loginctl show-user "$USER" | grep Linger
# Habilitar linger si no está activo:
loginctl enable-linger "$USER"

# Comprobar socket de Podman en modo usuario (API compatible con Docker)
systemctl --user status podman.socket
```

---

## 2. Systemd Quadlets (`~/.config/containers/systemd/`)

Los **Quadlets** permiten declarar contenedores, redes y volúmenes mediante archivos declarativos (`.container`, `.network`, `.volume`, `.kube`) que el generador `/usr/lib/systemd/user-generators/podman-user-generator` traduce automáticamente a servicios nativos de `systemd --user`.

Ubicación estándar de las definiciones del usuario:
`~/.config/containers/systemd/`

### 2.1. Estructura de un Archivo Quadlet (`.container`):
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

### 2.2. Ciclo de Vida y Control con Systemd:
```bash
# Recargar el generador tras editar o crear archivos Quadlet
systemctl --user daemon-reload

# Iniciar, detener o reiniciar el servicio del contenedor
systemctl --user start nginx-web
systemctl --user status nginx-web
systemctl --user restart nginx-web
systemctl --user stop nginx-web

# Inspeccionar logs en vivo vía Journald
journalctl --user -u nginx-web -f
```

---

## 3. Utilidad CLI de Gestión: `podman-utils`

El repositorio incluye la herramienta integral `podman-utils` en `Podman/lib/podman-utils.sh` (con autocompletado en Bash y Zsh):

```bash
# Diagnóstico general del entorno Podman y Quadlets
podman-utils doctor

# Desplegar servicios globales compartidos (PostgreSQL global, Redis global, Traefik)
podman-utils install-global postgres-global
podman-utils install-global redis-global

# Crear un nuevo proyecto a partir de plantillas modulares
podman-utils create fullstack mi-proyecto
podman-utils create python-postgres mi-api
podman-utils create python-postgres-redis mi-servicio

# Control del ciclo de vida del proyecto
podman-utils start mi-proyecto
podman-utils status mi-proyecto
podman-utils logs mi-proyecto
podman-utils stop mi-proyecto
```

---

## 4. Redes de Contenedores y Cortafuegos (Firewalld)

Fedora 45 requiere autorización explícita del tráfico de interfaces virtuales generadas por Podman:

```bash
# Asegurar comunicación fluida en la zona trusted para la interfaz de Podman
sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+
sudo firewall-cmd --reload

# Exponer el puerto del contenedor hacia la red local (ej. 8080 en la zona FedoraWorkstation)
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=8080/tcp
sudo firewall-cmd --reload
```

---

## 5. Recetas Justfile para Podman

```bash
# Desplegar Podman Rootless, socket y servicios compartidos
just podman

# Diagnóstico de estado de Podman y Quadlets
just podman-status
```
