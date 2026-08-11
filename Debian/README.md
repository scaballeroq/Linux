# 🔧 Debian Environment Configuration (GNOME Desktop)

Este repositorio contiene una colección organizada y modular de scripts de configuración para sistemas **Debian** (Debian 12 Bookworm / Debian 13 Trixie) con el entorno de escritorio **GNOME** (optimizado para PCs y portátiles de desarrollo).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal Bash.
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados.
- **`environment.sh`**: Variables globales que afectan el comportamiento de la shell.
- **`functions.sh`**: Colección de funciones avanzadas y utilidades.
- **`gnome_settings.sh`**: Configuraciones de entorno para GNOME, touchpad, energía y HiDPI.
- **`history.sh`**: Controla cómo bash recuerda los comandos.
- **`options.sh`**: Configura el comportamiento interno de Bash mediante 'shopt' y 'bind'.
- **`podman-functions.sh`**: Funciones para gestión simplificada de contenedores.
- **`rclone_aliases.sh`**: Atajos para facilitar la sincronización en la nube.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### 🐳 [Podman](./Podman/)
Scripts para instalar y desplegar servicios en contenedores Podman de forma aislada:
- **Core**: `podman.sh` (Instalación principal en Debian)
- **Bases de Datos**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Gestión y Monitoreo**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-dozzle.sh`, `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`
- **Infraestructura**: `podman-nginx.sh`, `podman-keycloak.sh`, `podman-rabbitmq.sh`, `podman-minio.sh`, `podman-mailhog.sh`, `podman-browserless.sh`
- **Frameworks/CMS**: `podman-wordpress.sh`, `podman-storybook.sh`

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Instalación y configuración de Virtualización de alto rendimiento (KVM/QEMU, libvirtd, sockets modulares, VirtIO, Nested KVM) optimizada para Debian.
- **`notas_virtualizacion_debian.md`**: Guía detallada de KVM/QEMU en Debian.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`post-install.sh`**: Script maestro de post-instalación (Habilita `contrib`, `non-free`, `non-free-firmware` y `backports`).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (Touchpad, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, VRR).
- **`fingerprint-setup.sh`**: Configuración de desbloqueo y autenticación admin por huella dactilar (`fprintd`, PAM `sudo`, `polkit-1`, `pam-auth-update`).
- **`debian-tuning.sh`**: Ajustes de Kernel (`sysctl`) y `distrobox`.
- **`gnome-extensions.sh`**: Instalación automatizada de `gnome-browser-connector`, `extension-manager` y descarga limpia de 17 extensiones personalizadas de GNOME (ver [Guía de Extensiones GNOME](./Docs/gnome_extensions_es.md)).
- **`apariencia.sh`**: Instalación de temas e iconos.
- **`cockpit.sh`**: Instalación y configuración de Cockpit (administración web).
- **`fastfetch.sh`**: Información estética del sistema al inicio (Fastfetch).
- **`firefox.sh`**: Instalación y configuración de Mozilla Firefox.
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (Nerd Fonts).
- **`ptyxis.sh`**: Instalación del emulador de terminal moderno Ptyxis.
- **`seguridad.sh`**: Endurecimiento (hardening) y configuración de UFW.
- **`shell.sh`**: Herramientas modernas de terminal y prompt (Starship).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, ffmpeg).

---

## 🚀 Cómo empezar

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/Debian
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/*.sh Git/*.sh Apps/*.sh Juegos/*.sh
just setup-all
```

---
*Mantenido por [caballero](https://github.com/scaballeroq)*
