# 🔴 Debian GNU/Linux Environment Configuration (GNOME Shell Wayland)

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Debian GNU/Linux 13 (Trixie)** con el entorno de escritorio **GNOME Shell (Wayland / Mutter)**, optimizado para estaciones de trabajo y portátiles HP ProBook 455 G10 en modo oscuro.

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para garantizar máxima mantenibilidad y legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Bash** (con soporte modular en `~/.bashrc.d`) y compatible con **Zsh** (en `~/.zshrc.d`).
- **`aliases.sh`**: Atajos comunes para navegación, utilidades Rust (`eza`, `bat`, `duf`, `dust`), Git, gestor de paquetes **APT** (`update`, `upgrade`, `install`, `clean`), Firewalld (`fw*`), Libvirt y Podman.
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland, `QT_QPA_PLATFORMTHEME="gnome"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise shims.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `extract`, `duh`, `backup_file`, `monitors`) con guardas interactivas.
- **`gnome_settings.sh`**: Configuraciones de entorno y atajos para GNOME Shell Wayland (Adwaita-dark, Luz nocturna 4000K, reinicio de Shell, accesos directos de GNOME Control Center).
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
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM zstd, repositorios `contrib non-free non-free-firmware`, firmware oficial AMD, microcódigo, Mesa RADV, VA-API hardware, PipeWire, Flatpak Flathub, GNOME Software Flatpak plugin).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core / Media Center (VA-API Intel i965/iHD, PipeWire, Kodi).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (power-profiles-daemon, Bluetooth FastConnectable, cierre de tapa inteligente con multimonitor, Touchpad Wayland gestures y Mutter VRR, `--status`).
- **`fingerprint-setup.sh`**: Autenticación y desbloqueo biométrico (fprintd + PAM, sensor Synaptics, `--status`, `--enroll`, `--verify`, `--disable`).
- **`hp-printer-setup.sh`**: Pila de impresión para impresoras HP (CUPS, HPLIP, plugin propietario para LaserJet M15w, Firewalld USB/Wi-Fi, `--status`).
- **`gnome-settings.sh`**: Configuración de GNOME Shell (Modo oscuro Adwaita-dark, botones minimizar/maximizar, scripts de Nautilus para Kitty/Antigravity/VS Code, Night Light a 4000K, reloj 24h, `--status`, `--dark`, `--light`).
- **`gnome-extensions.sh`**: Instalación y configuración de extensiones GNOME (GSConnect, Dash to Dock, AppIndicator, Blur my Shell, Tiling Shell, `--status`).
- **`gsconnect.sh`**: Integración nativa de GSConnect (KDE Connect para GNOME con cero librerías KDE/Qt) y reglas de Firewalld (1714-1764 TCP/UDP, `--status`, `--setup-firewall`, `--daemon`).
- **`debian-tuning.sh`**: Ajustes de Kernel (`sysctl` inotify 1M, max_map_count 16M, TCP BBR, ZRAM), límites del sistema (`limits.d`), exclusiones de GNOME Tracker Miner en directorios pesados (`~/Workspace`, `node_modules`, `.git`, `.venv`, `.cargo`) y compresión ZRAM (`--status`, `--sysctl`, `--limits`, `--tracker`, `--zram`).
- **`zram-setup.sh`**: Configuración de swap comprimida en RAM mediante `zram-tools` con algoritmo zstd al 50%.
- **`cockpit.sh`**: Consola web Cockpit y gestión de servidores (Podman, KVM, almacenamiento, Firewalld exclusivo, `--status`, `--open`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: Resumen estético del sistema con soporte de temas (`debian` oficial Ruby, `compact` FastCat, `--status`, `--theme`, `--diff`, `--force`).
- **`fonts.sh`**: Instalación automatizada y diagnóstico de fuentes de desarrollo (JetBrainsMono, FiraCode, CascadiaCode, Meslo y Hack Nerd Fonts, `--status`, `--list`, `--clean`).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad 75%, blur 32, tema Catppuccin Mocha, atajo Ctrl+Alt+T e integración en menú contextual de Nautilus (`--status`).
- **`ptyxis.sh`**: Terminal moderna Ptyxis con transparencia y modo oscuro.
- **`seguridad.sh`**: Endurecimiento con Firewalld exclusivo (desactivación obligatoria de UFW, servicios `kdeconnect`/GSConnect, `mdns`, `ssh`, zona `libvirt` para virbr0, zona `trusted` para `podman+`, sysctl de puertos no privilegiados).
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`) y sincronización modular.
- **`starship.sh` & `starship.toml`**: Prompt Starship moderno con configuración modular (`--enable`, `--disable`, `--status`).
- **`multimedia.sh`**: Codecs multimedia oficiales (FFmpeg, libavcodec-extra, GStreamer completo con VA-API) y VLC desacoplado vía Flatpak (`--status`).
- **`flatpak.sh`**: Suite de aplicaciones de escritorio desacopladas vía Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Shotcut, Spotify, Vesktop...) sin tocar el sistema base (`--status`, `--all`, `--essential`, `--multimedia`, `--clean`, `--update`).
- **`chrome.sh`**: Activación del repositorio oficial de Google Chrome e instalación de `google-chrome-stable` con optimización Ozone Wayland (`--status`, `--wayland`).
- **`firefox.sh`**: Instalación de Firefox nativo (.deb) desde el repositorio oficial de Mozilla con APT Pin-Priority 900 (`--status`).
- **`steam.sh`**: Instalación de Steam nativo con multiarch i386, repositorios `contrib non-free`, GameMode, MangoHud, Proton-GE y drivers Mesa Vulkan de 32 bits (`--status`).
- **`amd64v3.sh`**: Diagnóstico de compatibilidad CPU para microarquitectura x86-64-v3 y soporte transparente glibc-hwcaps en Debian (`--status`).

### 📦 [ProgrammingLanguages](./ProgrammingLanguages/)
Gestores de versiones y runtimes aislados:
- **`mise.sh`**: Gestor moderno de runtimes polyglot (`mise`).
- **`python.sh`**: Verificación de Python 3 nativo del sistema y gestor `uv` vía Mise con `UV_LINK_MODE=copy` para aislamiento estricto de proyectos sin romper dependencias de APT ni GNOME.
- **`python-uv-init.sh`**: Inicializador interactivo de proyectos Python independientes.
- **`nodejs.sh`**: Node.js LTS, pnpm y herramientas JavaScript.
- **`rust.sh`**: Rustup toolchain stable, cargo y mold linker para aceleración de compilación.
- **`java.sh`**: OpenJDK LTS con resolución canónica de `JAVA_HOME`.
- **`dotnet.sh` & `angular.sh`**: Runtimes de .NET SDK y Angular CLI.

### 💻 [IDE](./IDE/)
Entornos de desarrollo:
- **`git.sh`**: Instalación, optimización y configuración de Git, Delta, Lazygit y GitHub CLI.
- **`antigravity.sh`**: Suite de Google Antigravity Desktop 2.0 (instalador y actualizador).
- **`antigravity-cli.sh`**: Google Antigravity CLI oficial.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine.
- **`opencode.sh`**: OpenCode AI CLI / Editor.

---

## ⚡ Automatización mediante Justfile

La raíz del directorio incluye un **`justfile`** con recetas declarativas:

```bash
# Instalación completa desatendida del entorno
just setup-all

# Perfil específico para Portátil AMD Ryzen
just setup-laptop-amd

# Ver estado de componentes
just tuning-status
just security-status
just podman-status
just virtualization-status
just flatpak-status
just fastfetch
```

---

## 🔒 Reglas del Monorepo

* **Firewalld Obligatorio:** Todos los puertos se abren y gestionan mediante `firewall-cmd`. El servicio `ufw` se desactiva y enmascara permanentemente.
* **Wayland Nativo:** Sin herramientas heredadas de X11 (`xclip`, `xrandr`, `xdotool`).
* **Python Protegido:** Nunca registrar shims globales en Mise para Python. Uso exclusivo de `uv` per-project.
* **Podman Rootless:** Los contenedores se ejecutan sin root en el espacio de usuario gestionados por Quadlets.
