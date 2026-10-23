# 🟠 Ubuntu Linux Environment Configuration (GNOME Shell Wayland)

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Ubuntu Linux** con el entorno de escritorio **GNOME Shell (Wayland / Mutter)**, optimizado para estaciones de trabajo y portátiles HP EliteBook en modo oscuro.

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para garantizar máxima mantenibilidad y legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Bash** (con soporte modular en `~/.bashrc.d`) y compatible con **Zsh** (en `~/.zshrc.d`).
- **`aliases.sh`**: Atajos comunes para navegación, utilidades Rust (`eza`, `bat`, `duf`, `dust`), Git, gestor de paquetes **APT** (`update`, `upgrade`, `install`, `clean`), Firewalld (`fw*`), Libvirt y Podman.
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland, `QT_QPA_PLATFORMTHEME="gnome"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise shims.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `extract`, `duh`, `backup_file`, `monitors`) con guardas interactivas.
- **`gnome_settings.sh`**: Configuraciones de entorno y atajos para GNOME Shell Wayland (Yaru-dark, Luz nocturna 4000K, reinicio de Shell, accesos directos de GNOME Control Center).
- **`history.sh`**: Control de historial optimizado (deduplicación, sincronización inmediata, capacidad expandida a 20k comandos).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos con `cdspell`, globbing extendido).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets rootless compatibles con ambas shells.
- **`rclone_aliases.sh`**: Atajos completos para sincronización, copia y dry-run en la nube con Google Drive y OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas con yt-dlp y FFmpeg.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets nativos de systemd:
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket de usuario, linger, registries y CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de virtualización (KVM/QEMU, Libvirt, virt-manager, virtio-win, Btrfs NoCoW, Polkit sin contraseña para grupo `libvirt`, detección segura de Wi-Fi, Firewalld) con CLI completa (`--status`, `--with-windows`, `--help`).

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización de GNOME Shell y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM zstd, Mesa RADV, VA-API hardware, PipeWire, Flatpak Flathub, GNOME Software Flatpak plugin).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core / Media Center (VA-API Intel i965/iHD, PipeWire, Kodi).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (power-profiles-daemon, Bluetooth FastConnectable, cierre de tapa inteligente con multimonitor, Touchpad Wayland gestures y Mutter VRR, `--status`).
- **`fingerprint-setup.sh`**: Autenticación y desbloqueo biométrico (fprintd + PAM, sensor Synaptics, `--status`, `--enroll`, `--verify`, `--disable`).
- **`hp-printer-setup.sh`**: Pila de impresión para impresoras HP (CUPS, HPLIP, plugin propietario para LaserJet M15w, Firewalld USB/Wi-Fi, `--status`).
- **`gnome-settings.sh`**: Configuración de GNOME Shell (Modo oscuro Yaru-dark, botones minimizar/maximizar, scripts de Nautilus para Kitty/Antigravity/VS Code, Night Light a 4000K, reloj 24h, `--status`, `--dark`, `--light`).
- **`gnome-extensions.sh`**: Instalación y configuración de extensiones GNOME (GSConnect, Dash to Dock, AppIndicator, Blur my Shell, Tiling Shell, `--status`).
- **`gsconnect.sh`**: Integración nativa de GSConnect (KDE Connect para GNOME con cero librerías KDE/Qt) y reglas de Firewalld (1714-1764 TCP/UDP, `--status`, `--setup-firewall`, `--daemon`).
- **`ubuntu-tuning.sh`**: Ajustes de Kernel (`sysctl` inotify 1M, max_map_count 16M, TCP BBR, ZRAM), límites del sistema (`limits.d`), exclusiones de GNOME Tracker Miner en directorios pesados (`~/Workspace`, `node_modules`, `.git`, `.venv`, `.cargo`) y compresión ZRAM (`--status`, `--sysctl`, `--limits`, `--tracker`, `--zram`).
- **`zram-setup.sh`**: Configuración de swap comprimida en RAM mediante `zram-tools` con algoritmo zstd.
- **`cockpit.sh`**: Consola web Cockpit y gestión de servidores (Podman, KVM, almacenamiento, Firewalld exclusivo, `--status`, `--open`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: Resumen estético del sistema con soporte de temas (`ubuntu` oficial, `compact` FastCat, `--status`, `--theme`, `--diff`, `--force`).
- **`fonts.sh`**: Instalación automatizada y diagnóstico de fuentes de desarrollo (JetBrainsMono, FiraCode, CascadiaCode, Meslo y Hack Nerd Fonts, `--status`, `--list`, `--clean`).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad 75%, blur 32, tema Catppuccin Mocha, atajo Ctrl+Alt+T e integración en menú contextual de Nautilus (`--status`).
- **`ptyxis.sh`**: Terminal moderna Ptyxis con transparencia y modo oscuro.
- **`seguridad.sh`**: Endurecimiento con Firewalld exclusivo (desactivación obligatoria de UFW, servicios `kdeconnect`/GSConnect, `mdns`, `ssh`, zona `libvirt` para virbr0, zona `trusted` para `podman+`, sysctl de puertos no privilegiados).
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`) y sincronización modular.
- **`starship.sh` & `starship.toml`**: Prompt Starship moderno con configuración modular (`--enable`, `--disable`, `--status`).
- **`multimedia.sh`**: Codecs multimedia oficiales (`ubuntu-restricted-extras`, FFmpeg, GStreamer completo con VA-API) y VLC desacoplado vía Flatpak (`--status`).
- **`flatpak.sh`**: Suite de aplicaciones de escritorio desacopladas vía Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Shotcut, Spotify, Vesktop...) sin tocar el sistema base (`--status`, `--all`, `--essential`, `--multimedia`, `--clean`, `--update`).
- **`chrome.sh`**: Activación del repositorio oficial de Google Chrome e instalación de `google-chrome-stable` con optimización Ozone Wayland (`--status`, `--wayland`).
- **`firefox.sh`**: Instalación de Firefox nativo (.deb) desde el repositorio oficial de Mozilla con APT Pin-Priority 1000 eliminando el wrapper Snap (`--status`).
- **`steam.sh`**: Instalación de Steam nativo con multiarch i386, GameMode, MangoHud, Proton-GE y drivers Mesa Vulkan de 32 bits (`--status`).
- **`yt-dlp-setup.sh`**: Stack multimedia avanzado (yt-dlp, FFmpeg, Mutagen, aria2, motor JS Deno vía Mise, `--status`, `--config`, `--update`, `--clean-cache`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (sandbox Chromium, iconos e integración en Nautilus).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup rootless.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (launcher GNOME y script para Nautilus).
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI setup con configuración global.
- **`opencode.sh`**: OpenCode AI CLI setup integrado en PATH.
- **`vscode.sh`**: Visual Studio Code setup.
- **`neovim.sh`**: Neovim moderno con `wl-clipboard` (sin utilidades X11).

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de runtimes con **Mise** y **uv**:
- **`mise.sh`**: Gestor de versiones Mise con integración `environment.d`.
- **`python.sh` & `python-uv-init.sh`**: Protección del Python del sistema, `uv@latest` vía Mise y CLI `py-project` para scaffolding de proyectos (FastAPI, CLI, Data Science).
- **`nodejs.sh`**: Node.js LTS activo con Corepack (`pnpm`, `yarn`).
- **`rust.sh`**: Rustup canal Stable con `rust-analyzer`, `clippy`, `rustfmt` y `cargo-binstall`.
- **`dotnet.sh`**: .NET SDK LTS con `DOTNET_ROOT` en `environment.d`.
- **`java.sh`**: OpenJDK LTS (Java 21) con certificados digitales (AutoFirma / DNIe) y Maven.
- **`angular.sh`**: Angular CLI última versión vía npm administrado por Mise.

---

## 🚀 Despliegue Rápido con Just

Para ejecutar el despliegue automático según el perfil de tu equipo:

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/Ubuntu
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Portátil de Desarrollo (AMD Ryzen + GNOME Shell Wayland + Virtualización + Podman):
just setup-laptop-amd

# Sobremesa Centro Multimedia (Intel Haswell / Media Center + Kodi - Sin virtualización):
just setup-media-desktop

# O instalación completa por defecto:
just setup-all
```

O ejecutar componentes de forma individual:
```bash
just post-install        # Post-instalación base con auto-detección de CPU
just gnome-setup         # Aplica configuración de GNOME Shell, Yaru-dark y atajos
just gnome-status        # Verifica estado de configuración de GNOME Shell
just gnome-extensions    # Instala y activa extensiones esenciales de GNOME
just gsconnect           # Configura GSConnect y reglas de Firewalld
just laptop              # Optimización para portátiles (Touchpad, Bluetooth, Mutter VRR)
just tuning              # Aplica sysctl, límites, inotify y exclusiones Tracker
just tuning-status       # Diagnóstico de optimizaciones del sistema
just kitty               # Configura terminal Kitty con opacidad, blur y tema Catppuccin
just virtualization      # Configura KVM/QEMU, Libvirt y Btrfs NoCoW
just virtualization-status # Diagnóstico del hipervisor KVM
just multimedia          # Configura codecs multimedia oficiales y Flatpak VLC
just flatpak             # Instala suite recomendada Flatpak (Flatseal, Podman Desktop, Warehouse, VLC...)
just flatpak-status      # Diagnóstico de repositorios Flathub y aplicaciones instaladas
just chrome              # Instala Google Chrome oficial con flags Wayland
just firefox             # Instala Firefox nativo (.deb) de Mozilla (Pin-Priority 1000)
just steam               # Instala Steam nativo y librerías Mesa 32-bit (i386)
just languages           # Instala Node, Python (uv), Rust, .NET, Java y Angular
just python-uv           # Asistente interactivo py-project para crear proyectos Python
just podman-setup        # Configura Podman rootless y Quadlets
just podman-status       # Diagnóstico completo de Podman y Quadlets
just update              # Actualiza el sistema completamente vía APT
```
