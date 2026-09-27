# ❄️ NixOS Environment Configuration (KDE Plasma 6 & Flakes)

Este repositorio contiene una colección organizada, modular, declarativa y automatizada de configuración para sistemas **NixOS** con el entorno de escritorio **KDE Plasma 6** sobre **Wayland** (optimizado para portátiles HP EliteBook y estaciones de trabajo de desarrollo en modo oscuro).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular y reproducible mediante **Nix Flakes** y scripts complementarios de entorno:

### ❄️ [Arquitectura Declarativa de NixOS](./flake.nix)
- **`flake.nix`**: Punto de entrada declarativo que orquesta los inputs (`nixpkgs-unstable`, `nixpkgs-24.11`, `home-manager`), devshells y configuraciones del sistema.
- **`configuration.nix`**: Configuración unificada que importa los módulos esenciales.
- **`hosts/`**: Perfiles de hardware desacoplados:
  - **`laptop-amd/`**: Portátil de desarrollo (AMD Ryzen 7 PRO 4750U / HP EliteBook 855 G7) con KVM, Podman y KDE Plasma 6.
  - **`desktop-intel/`**: Sobremesa Centro Multimedia (Intel Core / Haswell + Kodi).
- **`modules/`**: Módulos del sistema independientes:
  - **`core.nix`**: Bootloader systemd-boot, Kernel Linux optimizado, ZRAM swap con compresión ZSTD, sysctl y localización (`es_ES.UTF-8`).
  - **`desktop-kde.nix`**: KDE Plasma 6 Wayland nativo, SDDM Wayland, PipeWire + WirePlumber, portales XDG y fuentes tipográficas.
  - **`hardware.nix`**: Controladores gráficos Mesa/RADV/VA-API, Bluetooth con soporte de batería y conexión rápida, `power-profiles-daemon`, huella dactilar `fprintd` y CUPS/HPLIP.
  - **`virtualization.nix`**: Hipervisor KVM/QEMU, Libvirtd modular, Virt-Manager, VirtioFS y regla Polkit para el grupo `libvirtd`.
  - **`containers.nix`**: Motor Podman rootless, emulación Docker API (`podman-docker`), registries y almacenamiento overlay.
  - **`development.nix`**: Soporte `nix-ld` para binarios ELF dinámicos (VS Code, Google Antigravity, OpenCode), Git, compiladores, Mise, uv y CLI moderna.
  - **`security.nix`**: Cortafuegos de red (KDE Connect, SSH, Cockpit, interfaces virtuales `virbr0`, `podman+`) y endurecimiento de PAM.
  - **`gaming.nix`**: Steam nativo, GameMode, MangoHud y soporte Vulkan 32-bit.
  - **`flatpak.nix`**: Integración con Flatpak y catálogo Flathub para aplicaciones de escritorio desacopladas.

### 🐚 [Bash.Setup](./Bash.Setup/)
Configuración modular para **Bash** (shell predeterminada en `~/.bashrc.d`) y **Zsh**:
- **`aliases.sh`**: Atajos comunes para navegación, utilidades Rust (`eza`, `bat`, `duf`, `dust`), Dolphin (`kioclient6`), gestión declarativa de NixOS (`switch`, `rebuild`, `test-build`, `nix-update`, `nix-clean`, `generations`, `rollback`) y búsqueda efímera (`nshell`, `nrun`).
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH` priorizando `~/.local/bin`, `~/.nix-profile/bin`, `/run/current-system/sw/bin`, Wayland Qt, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación de Mise.
- **`functions.sh`**: Funciones avanzadas (`mkcd`, `up`, `extract`, `duh`, `nix-where`, `nix-diff-generations`) y utilidades multimedia (FFmpeg / ImageMagick).
- **`kde_settings.sh`**: Atajos para KDE Plasma 6 Wayland (Breeze Dark/Light, Night Color, reinicio de Plasma/KWin, accesos KCM).
- **`history.sh`**: Control de historial optimizado (deduplicación, capacidad para 20.000 comandos).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos con `cdspell`, globbing extendido).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets rootless.
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas con yt-dlp y FFmpeg.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets nativos de systemd:
- **`install/podman-install.sh`**: Configuración de Podman rootless, socket Docker API, linger y CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets.
- **`lib/podman-utils.sh`**: CLI para gestión de proyectos (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directorio para proyectos activos.
- **`templates/`**: Plantillas de proyectos (`python-postgres`, `python-postgres-redis`, `fullstack`).
- **`scripts-standalone/`**: Scripts independientes para desplegar PostgreSQL, Redis, Adminer, MinIO, RabbitMQ, MongoDB, etc.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Diagnóstico y gestión de virtualización (KVM/QEMU, Libvirt modular, virt-manager, virtio-win) con CLI completa (`--status`, `--with-windows`, `--help`).
- **`notas_virtualizacion_nixos.md`**: Guía detallada de KVM/QEMU, VirtIO, redes y almacenamiento en NixOS.

### ⚙️ [Setup](./Setup/)
Scripts de aprovisionamiento, personalización de KDE Plasma 6 y diagnóstico:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación para AMD Ryzen (reconstrucción de flake `laptop-amd`, Flatpak Flathub, Kitty, Starship, Fastfetch).
- **`post-install-intel.sh`**: Post-instalación para Intel Core / Media Center (reconstrucción de flake `desktop-intel`, Kodi, Flatpak).
- **`kde-settings.sh`**: Configuración de KDE Plasma 6 (Breeze Dark, KWin botones, Dolphin servicemenus para Kitty y Antigravity, Night Color a 4000K, atajo Ctrl+Alt+T).
- **`laptop-setup.sh`**: Optimización para portátiles (power-profiles-daemon, Bluetooth FastConnectable, cierre de tapa inteligente, Touchpad Wayland).
- **`fingerprint-setup.sh`**: Autenticación y desbloqueo por huella dactilar (`fprintd` en NixOS, `--status`, `--enroll`, `--verify`, `--delete`).
- **`nixos-tuning.sh`**: Mantenimiento del sistema (recolección de basura en `/nix/store`, optimización con enlaces duros, ZRAM, sysctl, `--status`, `--gc`, `--optimise`, `--generations`, `--verify`).
- **`cockpit.sh`**: Consola web Cockpit (`--status`, `--open`, `--start`, `--stop`).
- **`fastfetch.sh`**: Resumen estético del sistema con Snowflake Hero Theme (`--theme nix`, `--theme compact`, `--status`, `--run`).
- **`fonts.sh`**: Diagnóstico de fuentes de desarrollo (JetBrainsMono, FiraCode, CascadiaCode, Meslo y Hack Nerd Fonts).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad/blur, tema Catppuccin Mocha, atajo Ctrl+Alt+T y servicemenu en Dolphin.
- **`seguridad.sh`**: Diagnóstico de Cortafuegos y puertos permitidos (KDE Connect, SSH, Cockpit, virbr0, podman).
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Prompt Starship moderno con temática NixOS (`--enable`, `--disable`, `--status`).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, FFmpeg, aria2).
- **`multimedia.sh`**: Diagnóstico de códecs multimedia y aceleración por hardware VA-API.
- **`flatpak.sh`**: Suite de aplicaciones de escritorio desacopladas vía Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Spotify, Vesktop...).
- **`chrome.sh`**: Lanzador y gestor de Google Chrome oficial con soporte Wayland nativo.
- **`steam.sh`**: Configuración de Steam nativo con GameMode, MangoHud y drivers Vulkan 32-bit.
- **`hp-printer-setup.sh`**: Pila de impresión para impresoras HP (CUPS, HPLIP, LaserJet M15w).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (compatible con NixOS vía `nix-ld` y sandbox Chromium).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup rootless en `~/.local/bin`.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI setup con configuración global.
- **`opencode.sh`**: OpenCode AI CLI setup integrado en PATH.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de runtimes con **Mise**, **uv** y **Rustup**:
- **`mise.sh`**: Gestor de versiones Mise con integración `environment.d`.
- **`python.sh` & `python-uv-init.sh`**: Entorno Python y gestor `uv` con scaffolding interactivo de proyectos (FastAPI, CLI, Data Science).
- **`nodejs.sh`**: Node.js LTS activo con Corepack (`pnpm`, `yarn`).
- **`rust.sh`**: Rustup canal Stable con `rust-analyzer`, `clippy` y `cargo-binstall`.
- **`dotnet.sh`**: .NET SDK LTS.
- **`java.sh`**: OpenJDK LTS (Java 21).
- **`angular.sh`**: Angular CLI.

---

## 🚀 Despliegue Rápido con Just

Para ejecutar el despliegue automático según el perfil de tu equipo:

```bash
git clone https://github.com/scaballeroq/NixOS.git
cd NixOS
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Juegos/*.sh

# Portátil de Desarrollo (AMD Ryzen + KDE Plasma 6 + Virtualización + Podman):
just setup-laptop-amd

# Sobremesa Centro Multimedia (Intel Core / Media Center - Sin virtualización):
just setup-media-desktop

# O instalación completa por defecto:
just setup-all
```

O ejecutar operaciones declarativas y de mantenimiento de NixOS:
```bash
just switch              # Aplica la configuración del host actual en vivo
just test                # Prueba la configuración sin modificar el bootloader
just boot                # Registra la configuración para el próximo arranque
just update              # Actualiza los inputs del flake (nix flake update)
just clean               # Recolecta basura y optimiza /nix/store
just generations         # Lista las generaciones activas en el perfil del sistema
just rollback            # Revierte a la generación anterior inmediatamente
```

O ejecutar componentes de forma individual:
```bash
just post-install        # Post-instalación base con auto-detección de CPU
just kde-setup           # Aplica configuración de KDE Plasma 6, Breeze Dark y atajos
just kde-status          # Verifica estado de configuración de KDE
just laptop              # Optimización para portátiles (Touchpad, Bluetooth, perfiles)
just tuning              # Mantenimiento y optimización de /nix/store
just tuning-status       # Diagnóstico de optimizaciones del sistema
just kitty               # Configura terminal Kitty con Catppuccin Mocha y desenfoque
just virtualization      # Diagnóstico y verificación de KVM/QEMU y Libvirt
just multimedia          # Diagnóstico de aceleración VA-API y códecs
just flatpak             # Instala suite recomendada Flatpak (Flatseal, Warehouse, VLC...)
just flatpak-status      # Diagnóstico de repositorios Flathub y aplicaciones instaladas
just chrome              # Lanza o instala Google Chrome oficial
just steam               # Diagnóstico de Steam nativo y drivers 32-bit
just languages           # Instala Node, Python (uv), Rust, .NET, Java y Angular
just python-uv           # Asistente interactivo py-project para crear proyectos Python
just podman-setup        # Configura Podman rootless y Quadlets
just podman-status       # Diagnóstico completo de Podman y Quadlets
```

---

*Mantenido por [caballero](https://github.com/scaballeroq)*
