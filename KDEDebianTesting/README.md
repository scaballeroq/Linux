# 🌀 Debian Testing Environment Configuration (KDE Plasma 6)

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Debian Testing (Trixie/Sid)** con el entorno de escritorio **KDE Plasma 6** sobre **Wayland** (optimizado para portátiles de desarrollo y estaciones de trabajo en modo oscuro).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Bash** (shell predeterminada del proyecto con soporte modular en `~/.bashrc.d`) y **Zsh** (compatible si existe `~/.zshrc`).
- **`aliases.sh`**: Atajos comunes para navegación, utilidades Rust (`eza`, `bat`, `duf`, `dust`, `procs`, `btop`), Dolphin (`kioclient6`), portapapeles Wayland (`wl-clipboard`) y gestor de paquetes **APT** (`update`, `upgrade`, `install`, `remove`, `clean`, `list`, `installed`, `pkg-info`).
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland/KDE Qt, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `backup`, `extract`, `duh`) y utilidades multimedia (FFmpeg / ImageMagick).
- **`kde_settings.sh`**: Configuraciones de entorno y atajos para KDE Plasma 6 Wayland (Breeze Dark/Light, Night Color, reinicio de Plasma/KWin, accesos KCM).
- **`history.sh`**: Control de historial optimizado (deduplicación, sincronización inmediata, capacidad expandida a 20k comandos).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos con `cdspell`, globbing extendido).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets rootless compatibles con ambas shells (`pps`, `pexec`, `quadlet-*`).
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas con yt-dlp y FFmpeg.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets nativos de systemd:
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket, linger, red pasta/passt y CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (`python-postgres`, `python-postgres-redis`, `fullstack`).
- **`scripts-standalone/`**: Catálogo de 17 contenedores individuales preconfigurados para desarrollo.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de virtualización (KVM/QEMU, Libvirt, virt-manager, virtio-win, Btrfs NoCoW, Polkit) con CLI completa (`--status`, `--with-windows`, `--help`).
- **`notas_virtualizacion_opensuse.md`**: Guía y referencias de arquitectura para KVM/QEMU, VirtIO, redes y almacenamiento.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización de KDE Plasma 6 y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, repositorios oficiales Debian, Flatpak Flathub, suite KDE Plasma 6 y KDE Gear).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core / Media Center (VA-API Intel i965 / media-driver, PipeWire, codecs y Kodi).
- **`kde-settings.sh`**: Configuración y personalización de KDE Plasma 6 (Breeze Dark, KWin botones `IAX`, Dolphin KIO servicemenus para Kitty y Antigravity, Night Color a 4000K, atajo Ctrl+Alt+T).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (power-profiles-daemon, Bluetooth FastConnectable/batería, cierre de tapa inteligente con multimonitor, Touchpad Wayland y perfiles PowerDevil en Plasma 6, `--status`).
- **`fingerprint-setup.sh`**: Autenticación y desbloqueo por huella dactilar (fprintd + PAM en KDE Plasma 6 con `pam-auth-update`, SDDM bypass para contraseña sin retardo y desbloqueo de KWallet, `--status`, `--enroll`, `--verify`, `--disable`, `--sddm-bypass`).
- **`debian-tuning.sh`**: Ajustes de Kernel (`sysctl` ZRAM/BBR/Inotify), límites de descriptores de archivos (1M), exclusiones de Baloo en KDE Plasma 6 y compresión ZRAM (`--status`, `--sysctl`, `--limits`, `--baloo`, `--zram`).
- **`cockpit.sh`**: Consola web Cockpit y cliente de escritorio (Podman, KVM, almacenamiento, `--status`, `--open`, `--client`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: Resumen estético del sistema con temas `debian` (espiral oficial) y `compact` (FastCat) (`--status`, `--theme`, `--diff`, `--force`).
- **`fonts.sh`**: Instalación automatizada y diagnóstico de fuentes de desarrollo (JetBrainsMono, FiraCode, CascadiaCode, Meslo y Hack Nerd Fonts, `--status`, `--list`, `--clean`).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad/blur, tema Catppuccin Mocha, atajo Ctrl+Alt+T y servicemenu en Dolphin (`--status`).
- **`seguridad.sh`**: Endurecimiento con Firewalld / UFW (servicios `kdeconnect`, `mdns`, `ssh`, Cockpit 9090, zona `trusted` para virbr0 y `podman+`) y sysctl unprivileged ports para desarrollo (`--status`).
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Prompt Starship moderno con configuración temática Debian (`--enable`, `--disable`, `--status`).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, FFmpeg, aria2, mutagen, motor JS Deno vía Mise).
- **`multimedia.sh`**: Configuración de codecs multimedia oficiales de Debian, FFmpeg oficial, plugins GStreamer completos y reproductores multimedia desacoplados vía Flatpak (`--status`).
- **`flatpak.sh`**: Suite de aplicaciones de escritorio y utilidades desacopladas vía Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Spotify, Vesktop...) sin tocar el sistema base (`--status`, `--all`, `--essential`, `--multimedia`, `--clean`, `--update`).
- **`chrome.sh`**: Repositorio oficial de Google Chrome e instalación de `google-chrome-stable` con dearmored keyring (`--status`).
- **`steam.sh`**: Instalación de Steam nativo con multiarch `i386`, GameMode, MangoHud, Proton-GE y drivers Vulkan de 32-bit (`--status`).
- **`hp-printer-setup.sh`**: Pila de impresión para impresoras HP (CUPS, HPLIP, plugin propietario para LaserJet M15w, Firewalld USB/Wi-Fi, `--status`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (con sandbox Chromium `4755`, librerías nativas y KIO servicemenu para Dolphin).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (con launcher KDE y servicemenu para Dolphin).
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI setup con configuración global.
- **`opencode.sh`**: OpenCode AI CLI setup integrado en PATH.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de runtimes con **Mise** y **Rustup**:
- **`mise.sh`**: Gestor de versiones Mise vía repositorio APT oficial con integración `environment.d`.
- **`python.sh` & `python-uv-init.sh`**: Protección del Python del sistema (PEP 668), `uv@latest` vía Mise (`UV_LINK_MODE=copy`) y CLI `py-project` para scaffolding de proyectos (FastAPI, CLI, Data Science).
- **`nodejs.sh`**: Node.js LTS activo con Corepack (`pnpm`, `yarn`).
- **`rust.sh`**: Rustup canal Stable con `rust-analyzer`, `clippy`, `rustfmt` y `cargo-binstall`.
- **`dotnet.sh`**: .NET SDK LTS con `DOTNET_ROOT` en `environment.d`.
- **`java.sh`**: OpenJDK LTS (Java 21) con certificados digitales (AutoFirma / DNIe) y Maven.
- **`angular.sh`**: Angular CLI última versión vía npm administrado por Mise.

---

## 🚀 Despliegue Rápido con Just

Para ejecutar el despliegue automático según el perfil de tu equipo:

```bash
git clone https://github.com/scaballeroq/KDEDebianTesting.git
cd KDEDebianTesting
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Juegos/*.sh

# Portátil de Desarrollo (AMD Ryzen + KDE Plasma 6 + Virtualización + Podman):
just setup-laptop-amd

# Sobremesa Centro Multimedia (Intel Haswell / Media Center + Kodi - Sin virtualización):
just setup-media-desktop

# O instalación completa por defecto:
just setup-all
```

O ejecutar componentes de forma individual:
```bash
just post-install        # Post-instalación base con auto-detección de CPU
just kde-setup           # Aplica configuración de KDE Plasma 6, Breeze Dark y atajos
just kde-status          # Verifica estado de configuración de KDE
just laptop              # Optimización para portátiles (Touchpad, Bluetooth)
just fingerprint-status  # Diagnóstico de autenticación biométrica
just tuning              # Aplica sysctl, límites, exclusiones Baloo y ZRAM
just tuning-status       # Diagnóstico de optimizaciones del sistema
just kitty               # Configura terminal Kitty con opacidad, blur y tema Catppuccin
just virtualization      # Configura KVM/QEMU, Libvirt modular y Btrfs NoCoW
just virtualization-status # Diagnóstico del hipervisor KVM
just multimedia          # Configura codecs y Flatpak multimedia
just flatpak             # Instala suite recomendada Flatpak (Flatseal, Podman Desktop, Warehouse, VLC...)
just flatpak-status      # Diagnóstico de repositorios Flathub y aplicaciones instaladas
just chrome              # Instala Google Chrome oficial
just steam               # Instala Steam nativo y librerías 32-bit
just languages           # Instala Node, Python (uv), Rust, .NET, Java y Angular
just python-uv           # Asistente interactivo py-project para crear proyectos Python
just podman-setup        # Configura Podman rootless y Quadlets
just podman-status       # Diagnóstico completo de Podman y Quadlets
just update              # Actualiza los paquetes del sistema (apt update && apt upgrade)
just dist-upgrade        # Actualiza a nivel de distribución (apt dist-upgrade)
```

---

*Mantenido por [caballero](https://github.com/scaballeroq)*
