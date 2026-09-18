# 🔧 CachyOS Environment Configuration (GNOME Workstation)

Este repositorio contiene una colección organizada y modular de scripts de configuración para sistemas **CachyOS** (basado en Arch Linux y optimizado para alto rendimiento x86-64-v3/v4) con el entorno de escritorio **GNOME** (optimizado para portátiles y PCs de desarrollo en modo oscuro).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Zsh** (shell predeterminada en CachyOS) y **Bash**.
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados, recarga dinámica, Nautilus y gestores de paquetes (`pacman` / `paru`).
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland/GNOME, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise en Zsh/Bash.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `hg`) y utilidades multimedia.
- **`gnome_settings.sh`**: Configuraciones de entorno y atajos para GNOME Wayland (tema oscuro, night light, captura Wayland con grim/satty, Nautilus).
- **`history.sh`**: Control de historial optimizado (10k/20k entradas, deduplicación, `~/.zsh_history` y `~/.bash_history`).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos, completado insensible a mayúsculas con `zstyle`/`shopt`).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets compatibles con ambas shells.
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets (systemd native):
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket, linger, registries.
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets.
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (create, start, stop, logs, status, destroy).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (python-postgres, python-postgres-redis, fullstack).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de Virtualización (KVM/QEMU, libvirt, virt-manager) optimizada para CachyOS.
- **`notas_virtualizacion_cachyos.md`**: Guía detallada de KVM/QEMU y VirtioFS en CachyOS.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, GNOME, Early KMS amdgpu).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core (VA-API Intel, PipeWire, GNOME).
- **`gnome-settings.sh`**: Configuración y personalización de GNOME (Modo oscuro `prefer-dark` y `adw-gtk3-dark`, VRR Mutter, atajo Kitty Ctrl+Alt+T, Nautilus).
- **`gnome-extensions.sh`**: Instalador y gestor de extensiones oficiales de GNOME Shell desde repositorios (Dash to Dock, AppIndicator, Caffeine, Weather O'Clock, Bing Wallpaper, Blur my Shell, Logo Menu).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo en GNOME (Touchpad, Bluetooth, no suspender con corriente, persistencia de brillo).
- **`cachyos-tuning.sh`**: Ajustes de Kernel (`sysctl`), límites de sistema, Ananicy-CPP, UKSMD, exclusiones de Tracker y Distrobox.
- **`cockpit.sh`**: Instalación y configuración de Cockpit (administración web en zona `home`).
- **`fastfetch.sh`**: Información estética del sistema al inicio (Fastfetch).
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (Nerd Fonts).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad/blur, tema Catppuccin Mocha y atajos GNOME.
- **`seguridad.sh`**: Endurecimiento con Firewalld exclusivo (zona `home` por defecto), DNS-over-TLS y sysctl para Podman/KVM.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `btop`, `jq`).
- **`starship.sh`**: Prompt Starship opcional con comandos de activación/desactivación.
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, ffmpeg, deno).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (con script contextual para Nautilus).
- **`antigravity-cli.sh`**: Google Antigravity CLI setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI setup.
- **`opencode.sh`**: OpenCode AI CLI setup.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión de runtimes con **mise**.
- **`mise.sh`**: Mise version manager installer.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`rust.sh`**

### 🎮 [Juegos](./Juegos/)
- **`steam.sh`**: Steam con Proton CachyOS.

---

## 🚀 Cómo empezar

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/CachyOS
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Apps/*.sh Podman/install/*.sh Podman/lib/*.sh
just setup-all
```

---
*Mantenido por [caballero](https://github.com/scaballeroq)*
