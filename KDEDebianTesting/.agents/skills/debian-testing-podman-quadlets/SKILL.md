---
name: debian-testing-podman-quadlets
description: >-
  Use this skill when creating, deploying, inspecting, and managing rootless Podman containers, Systemd Quadlets (.container, .network, .volume, .kube), user container services, rootless networking with pasta/passt, and container firewall rules on Debian Testing.
---

# Podman Rootless & Systemd Quadlets Skill (Debian Testing)

Esta skill proporciona las directrices y comandos para gestionar el ecosistema de contenedores **Podman Rootless** integrado de forma nativa con **Systemd Quadlets** en Debian Testing (KDE Plasma 6).

---

## 1. Arquitectura Rootless y Requisitos del Sistema

En Debian Testing, Podman se ejecuta completamente en espacio de usuario sin privilegios de `root` ni demonios residentes en segundo plano.

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

Los **Quadlets** permiten declarar contenedores como archivos declarativos que el generador de systemd (`/usr/lib/systemd/system-generators/podman-system-generator`) convierte automáticamente en servicios `systemd --user`.

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
Network=pasta

[Service]
Restart=always
TimeoutStartSec=300

[Install]
WantedBy=default.target
```

### 2.2. Ejemplo de volumen persistente (`mi-db-data.volume`):
```ini
[Volume]
VolumeName=postgres_data
```

### 2.3. Ejemplo de red aislada (`dev-network.network`):
```ini
[Network]
NetworkName=dev-net
Subnet=10.89.0.0/24
```

---

## 3. Ciclo de Vida y Gestión de Servicios Quadlets

Cada vez que se añade o modifica un archivo en `~/.config/containers/systemd/`:

```bash
# 1. Recargar el generador de systemd de usuario (convierte .container en .service)
systemctl --user daemon-reload

# 2. Iniciar / detener el servicio
systemctl --user start mi-servicio.service
systemctl --user stop mi-servicio.service
systemctl --user restart mi-servicio.service

# 3. Consultar estado y logs en tiempo real
systemctl --user status mi-servicio.service
journalctl --user -u mi-servicio.service -f --no-pager

# 4. Listar todos los servicios Quadlets activos en el sistema
systemctl --user list-units --type=service "*-project*"
```

---

## 4. Permisos de Archivos y Volúmenes en el Host

En modo rootless, el UID `0` del contenedor se mapea a tu UID real (`1000`) en el host:

```bash
# Si el contenedor necesita permisos específicos sobre una carpeta del host:
# Ejecutar un shell dentro del namespace de UIDs de Podman:
podman unshare chown -R 1000:1000 /ruta/a/datos

# Etiquetado SELinux / DAC:
# Usa :Z para volúmenes privados exclusivos del contenedor
# Usa :z para volúmenes compartidos entre varios contenedores
```

---

## 5. Red Rootless (Pasta / Passt) y Cortafuegos (Firewalld)

Debian Testing utiliza **pasta** (`passt`) como motor predeterminado de red rootless por su alto rendimiento y menor sobrecarga respecto a `slirp4netns`.

### Integración con Firewalld:
```bash
# Permitir tráfico entre contenedores y host (interfaces podman+ en zona de confianza)
sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+
sudo firewall-cmd --reload

# Si expones un servicio del contenedor a la red local (ej. PostgreSQL 5432 o Web 8080):
sudo firewall-cmd --add-port=8080/tcp                        # Temporal
sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload  # Permanente
```

---

## 6. Utilidades del Repositorio (`Podman/`)

El repositorio incorpora herramientas preconfiguradas en `Podman/`:

- **Configuración inicial**: `bash Podman/install/podman-install.sh --status`
- **Configuración de Quadlets**: `bash Podman/install/quadlets-setup.sh --status`
- **Utilidades CLI**: `source Podman/lib/podman-utils.sh`
  - `pps` : Lista contenedores activos con formato enriquecido.
  - `pexec <id>` : Acceso interactivo a un contenedor.
  - `quadlet-status` : Diagnóstico de todos los Quadlets instalados.
  - `quadlet-reload` : Recarga rápida de systemd de usuario.
