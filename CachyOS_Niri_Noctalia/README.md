# 🔧 CachyOS Environment Configuration (Niri + Noctalia Shell)

Este repositorio contiene una colección organizada y modular de scripts de configuración para sistemas **CachyOS** (basado en Arch Linux y optimizado para alto rendimiento x86-64-v3/v4) con el compositor Wayland scrollable-tiling **Niri** y el entorno de shell moderno **Noctalia Shell**.

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Zsh** (shell predeterminada en CachyOS) y **Bash**.
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados, recarga dinámica y gestores de paquetes (`pacman` / `paru`).
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, flags Wayland/Qt nativas) y activación automática de Mise en Zsh/Bash.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `hg`) y utilidades multimedia.
- **`niri_noctalia.sh`**: Atajos e IPC para Niri (`niri msg`), Noctalia Shell (`noctalia msg`), capturas interactivas Wayland (`grim` + `slurp`) y grabación (`wl-screenrec`).
- **`history.sh`**: Control de historial optimizado (10k/20k entradas, deduplicación, `~/.zsh_history` y `~/.bash_history`).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos, completado insensible a mayúsculas con `zstyle`/`shopt`).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets compatibles con ambas shells.
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`niri-setup.sh`**: Instalador e integrador de Niri, Noctalia Shell, `xwayland-satellite`, portales GNOME/GTK y plantilla `config.kdl`.
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, Niri stack).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core (VA-API Intel, PipeWire, Niri stack).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (Touchpad tap/scroll en Niri, Bluetooth experimental, brillo, `power-profiles-daemon`).
- **`cachyos-tuning.sh`**: Ajustes de Kernel (`sysctl`), Systemd user limits, Distrobox y optimizaciones de baja latencia Wayland.
- **`cockpit.sh`**: Instalación y configuración de Cockpit (administración web).
- **`fastfetch.sh`**: Información estética del sistema al inicio (Fastfetch).
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (Nerd Fonts).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad/blur y tema Catppuccin.
- **`seguridad.sh`**: Endurecimiento con Firewalld, DNS-over-TLS, MAC Randomization y sysctl.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `btop`, `jq`).
- **`starship.sh`**: Prompt Starship opcional con comandos de activación/desactivación.
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, ffmpeg, deno).

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets (systemd native):
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket, linger, registries.
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets.
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (create, start, stop, logs, status, destroy).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (python-postgres, python-postgres-redis, fullstack).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de Virtualización (KVM/QEMU, libvirtd) optimizada para CachyOS y Wayland.
- **`notas_virtualizacion_cachyos.md`**: Guía detallada de KVM/QEMU en CachyOS.

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup.
- **`antigravity-cli.sh`**: Google Antigravity CLI setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI setup.
- **`opencode.sh`**: OpenCode AI CLI setup.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión de runtimes con **mise**.
- **`mise.sh`**: Mise version manager installer.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`rust.sh`**

---

## 🚀 Cómo empezar

```bash
git clone https://github.com/scaballeroq/CachyOS_Niri_Noctalia.git
cd CachyOS_Niri_Noctalia
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh
just setup-all
```

O para configurar únicamente Niri y Noctalia Shell:
```bash
just niri-setup
```

---
*Mantenido por [caballero](https://github.com/scaballeroq)*
