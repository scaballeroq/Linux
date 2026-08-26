# 🔧 CachyOS Environment Configuration (GNOME Desktop)

Este repositorio contiene una colección organizada y modular de scripts de configuración para sistemas **CachyOS** (basado en Arch Linux y optimizado para alto rendimiento x86-64-v3/v4) con el entorno de escritorio **GNOME** (optimizado para PCs y portátiles de desarrollo).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal Bash.
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados y gestores de paquetes (`pacman` / `paru`).
- **`environment.sh`**: Variables globales que afectan el comportamiento de la shell.
- **`functions.sh`**: Colección de funciones avanzadas y utilidades multimedia.
- **`gnome_settings.sh`**: Configuraciones de entorno para GNOME, touchpad, energía y HiDPI.
- **`history.sh`**: Controla cómo bash recuerda los comandos.
- **`options.sh`**: Configura el comportamiento interno de Bash mediante 'shopt' y 'bind'.
- **`podman-functions.sh`**: Funciones para gestión simplificada de contenedores.
- **`rclone_aliases.sh`**: Atajos para facilitar la sincronización en la nube.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### 🐳 [Podman](./Podman/)
Scripts para instalar y desplegar servicios en contenedores Podman de forma aislada:
- **Core**: `podman.sh` (Instalación principal en CachyOS)
- **Bases de Datos**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Gestión y Monitoreo**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-dozzle.sh`, `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`
- **Infraestructura**: `podman-nginx.sh`, `podman-keycloak.sh`, `podman-rabbitmq.sh`, `podman-minio.sh`, `podman-mailhog.sh`, `podman-browserless.sh`
- **Frameworks/CMS**: `podman-wordpress.sh`, `podman-storybook.sh`

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de Virtualización (KVM/QEMU, libvirtd) optimizada para CachyOS.
- **`notas_virtualizacion_cachyos.md`**: Guía detallada de KVM/QEMU en CachyOS.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`post-install.sh`**: Script maestro de post-instalación para CachyOS (Pacman / repositorios optimizados).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (Touchpad, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, VRR).
- **`fingerprint-setup.sh`**: [NUEVO] Configuración de desbloqueo y autenticación admin por huella dactilar (`fprintd`, PAM `sudo`, `polkit-1`, `system-local-login`).
- **`cachyos-tuning.sh`**: Ajustes de Kernel (`sysctl`), `ananicy-cpp`, `distrobox`, `cachyos-kernel-manager`, `gnome-browser-connector` y descargas automatizadas de tus 17 extensiones personalizadas de GNOME.
- **`apariencia.sh`**: Instalación de temas e iconos (Papirus).
- **`cockpit.sh`**: Instalación y configuración de Cockpit (administración web).
- **`fastfetch.sh`**: Información estética del sistema al inicio (Fastfetch).
- **`firefox.sh`**: Instalación de Firefox CachyOS (`firefox-cachyos` optimizado x86-64-v3/v4).
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (Nerd Fonts).
- **`ptyxis.sh`**: Configuración del emulador de terminal moderno Ptyxis.
- **`seguridad.sh`**: Endurecimiento (hardening) y configuración de UFW.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`) y prompt (`Starship`).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, ffmpeg, deno).

---

## 🚀 Cómo empezar

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/CachyOS
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/*.sh Git/*.sh Apps/*.sh Juegos/*.sh
just setup-all
```

---
*Mantenido por [caballero](https://github.com/scaballeroq)*