---
name: cachyos-podman-quadlets
description: Creación, despliegue, inspección y gestión de contenedores Podman Rootless, Systemd Quadlets (~/.config/containers/systemd/), utilidades de podman-utils, redes rootless y reglas de Firewalld en CachyOS Workstation con GNOME.
---

# Podman Rootless & Systemd Quadlets (CachyOS Workstation + GNOME)

Esta skill proporciona las directrices operativas y comandos para gestionar el ecosistema de contenedores **Podman Rootless** integrado con **Systemd Quadlets** y **Firewalld** en **CachyOS Workstation (GNOME Shell Wayland)**.

---

## 1. Arquitectura Rootless y Requisitos del Sistema

En CachyOS, Podman se ejecuta sin privilegios de `root`, utilizando mapeo de IDs de usuario subordinados (`/etc/subuid`, `/etc/subgid`), persistencia con `loginctl enable-linger` y el socket de usuario `podman.socket`.

### 1.1. Diagnóstico del Entorno Podman:
```bash
podman info
grep "$USER" /etc/subuid /etc/subgid
./Podman/install/podman-install.sh --status
just podman-status
```

### 1.2. Activación de Sockets de Usuario:
```bash
systemctl --user status podman.socket
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
```

---

## 2. Systemd Quadlets (`~/.config/containers/systemd/`)

Los Quadlets permiten declarar contenedores como servicios nativos de Systemd con archivos `.container`, `.network` y `.volume`.

### 2.1. Gestión de Servicios Quadlet:
```bash
# Recargar generador de Quadlets
systemctl --user daemon-reload

# Iniciar/detener servicios
systemctl --user start <servicio>.service
systemctl --user status <servicio>.service
```

---

## 3. Redes Rootless y Firewalld

- Driver de red de alto rendimiento: `netavark` y `aardvark-dns`.
- Interfaces virtuales `podman+` asignadas a la zona `trusted` en Firewalld.
- Puertos sin privilegios configurados en `/etc/sysctl.d/99-cachyos-security-podman.conf` (`net.ipv4.ip_unprivileged_port_start = 80`).
