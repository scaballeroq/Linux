# 🦎 openSUSE Tumbleweed Environment Configuration (KDE Plasma 6)

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **openSUSE Tumbleweed (Rolling Release)** con el entorno de escritorio **KDE Plasma 6** sobre **Wayland** (optimizado para portátiles HP EliteBook y estaciones de trabajo de desarrollo en modo oscuro).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Bash** (shell predeterminada del proyecto con soporte modular en `~/.bashrc.d`) y **Zsh** (compatible si existe `~/.zshrc`).
- **`aliases.sh`**: Atajos comunes para navegación, utilidades Rust (`eza`, `bat`, `duf`, `dust`), Dolphin (`kioclient6`), `snapper` y gestor de paquetes **Zypper** (`dup`, `update`, `install`, `clean`).
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland/KDE Qt, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `extract`, `duh`) y utilidades multimedia (FFmpeg / ImageMagick).
- **`kde_settings.sh`**: Configuraciones de entorno y atajos para KDE Plasma 6 Wayland (Breeze Dark/Light, Night Color, reinicio de Plasma/KWin, accesos KCM).
- **`history.sh`**: Control de historial optimizado (deduplicación, sincronización inmediata, capacidad expandida a 20k comandos).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos con `cdspell`, globbing extendido).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets rootless compatibles con ambas shells.
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas con yt-dlp y FFmpeg.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets nativos de systemd:
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket, linger, registries y CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de virtualización (KVM/QEMU, Libvirt modular, virt-manager, virtio-win, Btrfs NoCoW, Polkit) con CLI completa (`--status`, `--with-windows`, `--help`).
- **`notas_virtualizacion_opensuse.md`**: Guía detallada de KVM/QEMU, VirtIO, redes y almacenamiento Btrfs NoCoW en openSUSE.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización de KDE Plasma 6 y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, repositorio oficial OpenH264 Cisco, Flatpak Flathub, patrones KDE Plasma 6, suite KDE Gear).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core / Media Center (VA-API Intel i965 / media-driver, PipeWire, codecs OpenH264, Kodi).
- **`kde-settings.sh`**: Configuración y personalización de KDE Plasma 6 (Breeze Dark, KWin botones, Dolphin KIO servicemenus para Kitty y Antigravity, Night Color a 4000K, atajo Ctrl+Alt+T).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (KDE Touchpad `kcminputrc`, PowerDevil `powermanagementprofilesrc`, Bluetooth FastConnectable, logind lid switch, persistencia de brillo al 95%).
- **`tumbleweed-tuning.sh`**: Ajustes de Kernel (`sysctl` ZRAM/BBR/Inotify), límites de sistema (`limits.d`), políticas de retención Snapper en Btrfs y exclusiones para Baloo en directorios de desarrollo (`--status`, `--sysctl`, `--limits`, `--snapper`, `--baloo`).
- **`cockpit.sh`**: Consola web de administración Cockpit con módulos para Podman, MVs KVM, almacenamiento y Snapper snapshots (`--status`, `--open`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: Resumen estético del sistema con soporte para openSUSE y KDE Plasma.
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad/blur, tema Catppuccin Mocha, atajo Ctrl+Alt+T y servicemenu en Dolphin.
- **`seguridad.sh`**: Endurecimiento con Firewalld (servicios `kdeconnect`, `mdns`, `ssh`, zona `libvirt` para virbr0, zona `trusted` para `podman+`) y sysctl unprivileged ports para desarrollo.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Prompt Starship moderno con configuración temática openSUSE (`--enable`, `--disable`, `--status`).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, FFmpeg, AtomicParsley, aria2, motor JS Deno vía Mise).
- **`multimedia.sh`**: Configuración de codecs multimedia oficiales (OpenH264 Cisco), FFmpeg oficial, plugins GStreamer y reproductores multimedia desacoplados vía Flatpak sin Packman (`--status`).
- **`chrome.sh`**: Activación del repositorio oficial de Google Chrome e instalación de `google-chrome-stable` (`--status`).
- **`steam.sh`**: Instalación de Steam nativo con GameMode, MangoHud, Proton-GE y drivers Vulkan de 32-bit (`--status`).
- **`apariencia.sh`**: Iconos Papirus-Dark, Breeze-Dark e integración GTK 3/4 y Qt.
- **`mount-workspace.sh`**: Automontaje seguro y permanente de `/home/caballero/Workspace` en `/etc/fstab`.

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (con sandbox Chromium, iconos pixmap y KIO servicemenu para Dolphin).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (con launcher KDE y servicemenu para Dolphin).
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI setup con configuración global.
- **`opencode.sh`**: OpenCode AI CLI setup integrado en PATH.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de runtimes con **Mise** y **Rustup**:
- **`mise.sh`**: Gestor de versiones Mise vía RPM oficial Zypper con integración `environment.d`.
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
git clone https://github.com/scaballeroq/OpenSuseTumbleweed.git
cd OpenSuseTumbleweed
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Git/*.sh Juegos/*.sh

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
just laptop              # Optimización para portátiles (Touchpad, Bluetooth, brillo 95%)
just tuning              # Aplica sysctl, límites, Btrfs Snapper y exclusiones Baloo
just tuning-status       # Diagnóstico de optimizaciones del sistema
just kitty               # Configura terminal Kitty con opacidad, blur y tema Catppuccin
just virtualization      # Configura KVM/QEMU, Libvirt modular y Btrfs NoCoW
just virtualization-status # Diagnóstico del hipervisor KVM
just multimedia          # Configura codecs OpenH264 oficiales y Flatpak multimedia
just chrome              # Instala Google Chrome oficial
just steam               # Instala Steam nativo y librerías 32-bit
just languages           # Instala Node, Python (uv), Rust, .NET, Java y Angular
just python-uv           # Asistente interactivo py-project para crear proyectos Python
just podman-setup        # Configura Podman rootless y Quadlets
just podman-status       # Diagnóstico completo de Podman y Quadlets
just dup                 # Actualiza el sistema rolling release (zypper dup)
just snapshots           # Lista instantáneas de Snapper en Btrfs
```

---

*Mantenido por [caballero](https://github.com/scaballeroq)*
