# 🔧 CachyOS Workstation Environment Configuration (GNOME Shell Wayland)

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **CachyOS Linux** (arquitectura optimizada **x86-64-v3** con kernel BORE / sched-ext) con el entorno de escritorio **GNOME Shell (Wayland / Mutter)**, gestor de paquetes **Pacman / Paru**, repositorios oficiales y optimizados de **CachyOS**, y optimización avanzada para estaciones de trabajo y portátiles **HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)** en modo oscuro.

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para garantizar máxima mantenibilidad, idempotencia y paridad funcional:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Zsh como shell principal** (con soporte modular en `~/.zshrc.d`) y compatibilidad dual con **Bash** (en `~/.bashrc.d`):
- **`aliases.sh`**: Atajos comunes para navegación, utilidades Rust (`eza`, `bat`), Nautilus, Git, Firewalld (`fw*`), Libvirt, Podman y gestores de paquetes **Pacman / Paru** (`update`, `upgrade`, `install`, `remove`, `pacup`, `pacin`, `pacrem`, `mirrors`).
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland/GNOME, `QT_QPA_PLATFORMTHEME="gnome"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `hg`) y utilidades multimedia (FFmpeg / ImageMagick).
- **`gnome_settings.sh`**: Configuraciones de entorno y atajos para GNOME Shell Wayland (tema oscuro `adw-gtk3-dark`, Night Light 4000K, captura Wayland con `grim`/`slurp`/`satty`, Nautilus).
- **`history.sh`**: Control de historial optimizado (deduplicación, sincronización inmediata, timestamps).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos con `cdspell`, completado insensible a mayúsculas).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets rootless compatibles con Bash y Zsh.
- **`rclone_aliases.sh`**: Atajos para sincronización, copia y dry-run en la nube con Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas con `yt-dlp` y FFmpeg.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets nativos de systemd:
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket de usuario, linger, registries y backend de red `passt` (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de Virtualización (KVM/QEMU, Libvirt modular, `virt-manager`, `virtio-win`, Btrfs NoCoW, Polkit sin contraseña para grupo `libvirt`, Firewalld) optimizada para CachyOS (`--status`, `--help`).
- **`notas_virtualizacion_cachyos.md`**: Guía detallada de KVM/QEMU, VirtIO, red bridge y almacenamiento en CachyOS.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización de GNOME Shell y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core, `--status`).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen y Radeon Graphics (microcódigo AMD, Vulkan RADV `vulkan-radeon`, VA-API `libva-mesa-driver`, FFmpeg completo, ZRAM zstd, Flathub, repositorios CachyOS x86-64-v3, `--status`).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core / Media Center (VA-API Intel `intel-media-driver`, FFmpeg, PipeWire, `--status`).
- **`zram-setup.sh`**: Configuración de Swap comprimida en RAM mediante `zram-generator` con algoritmo `zstd` al 50% de RAM, prioridad 100 y `vm.page-cluster=0` (`--status`, `--disable`).
- **`cachyos-tuning.sh`**: Ajustes de Kernel (`sysctl` inotify 1M, `max_map_count` 16M, TCP BBR, ZRAM), límites (`limits.d`), timeouts rápidos de Systemd y optimización para kernel BORE/sched-ext (`--status`).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (`power-profiles-daemon`, telemetría de salud de batería en Wh, AMD P-State EPP, topología multimonitor DRM `DP-3`/`DP-4`/`eDP-1`, cierre de tapa inteligente con `systemctl reload systemd-logind`, Touchpad Wayland y Bluetooth `FastConnectable=true`, `--status`).
- **`apariencia.sh`**: Gestor modular e interactivo (`--interactive`) de temas GTK (`adw-gtk3-dark`), iconos (`Papirus-Dark` / `Papirus` / `Adwaita`) y cursores (`Bibata-Modern-Classic`, `--status`).
- **`gnome-settings.sh`**: Configuración integral e interactiva (`--interactive`) de GNOME Shell Wayland (Modo oscuro, selector de terminal `kitty`/`ghostty`/`ptyxis`/`gnome-terminal`, botones de ventana, Mutter VRR, Night Light 4000K, reloj 24h y extensiones Nautilus Python con `python-nautilus`, `--status`).
- **`gnome-extensions.sh`**: Instalador y gestor de extensiones de GNOME Shell (GSConnect, Dash to Dock, AppIndicator, Caffeine, Blur my Shell, Tiling Shell, `--status`).
- **`gsconnect.sh`**: Integración móvil con GSConnect (KDE Connect nativo para GNOME) y reglas automáticas de Firewalld (1714-1764 TCP/UDP y mDNS, `--status`).
- **`fingerprint-setup.sh`**: Configuración de autenticación biométrica por huella dactilar (`fprintd` + PAM en CachyOS/Arch, `--status`, `--enroll`, `--verify`).
- **`hp-printer-setup.sh`**: Instalador y gestor de impresoras HP (CUPS, HPLIP, Avahi, plugin propietario y Firewalld, `--status`).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad 75%, blur 32, tema Catppuccin Mocha, atajo Ctrl+Alt+T y extensión nativa en Nautilus (`python-nautilus`, `--status`).
- **`ghostty.sh`**: Terminal Ghostty con tema Catppuccin Mocha, opacidad 85%, GTK single-instance y extensión nativa en Nautilus (`--status`, `--default-terminal`).
- **`ptyxis.sh`**: Terminal nativa de contenedores Ptyxis con paleta Catppuccin Mocha, transparencia al 85% y extensión nativa en Nautilus (`--status`, `--default-terminal`).
- **`zsh-setup.sh`**: Replicación y configuración integral del entorno Zsh (plugins nativos `zsh-autosuggestions` y `zsh-syntax-highlighting`, FZF, Zoxide, Mise, Starship y módulos `.zsh` en `~/.zshrc.d/`, `--status`, `--default-shell`).
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `btop`, `jq`, `--status`).
- **`starship.sh` & `starship.toml`**: Prompt Starship moderno con configuración temática (`--status`, `--enable`, `--disable`).
- **`fastfetch.sh` & `config-*.jsonc`**: Resumen estético del sistema con selector de temas (`cachyos` Hero categorizado con barras, `modern`, `compact`, `--menu`, `--preview`, `--status`).
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack Nerd Fonts, `--status`).
- **`seguridad.sh`**: Endurecimiento con Firewalld exclusivo (enmascarado de `ufw`, zona de red activa, soporte GSConnect, `podman+` en `trusted`, `virbr0` en `libvirt`, flag `--dev-ports` para puertos 3000/5173/8000/8080, DNS-over-TLS y sysctl con `accept_ra=2`, `--status`).
- **`cockpit.sh`**: Consola web de administración Cockpit con módulos para Podman, MVs KVM, almacenamiento y red (`--status`).
- **`multimedia.sh`**: Aceleración VA-API (`libva-mesa-driver`), códecs completos FFmpeg, GStreamer, miniaturas para Nautilus (`ffmpegthumbnailer`) y reproductores Wayland (Showtime, Loupe, Amberol, Celluloid, MPV Vulkan/VA-API y VLC, `--status`).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (`yt-dlp`, FFmpeg, AtomicParsley, `aria2`, motor JS Deno, `--status`).
- **`flatpak.sh`**: Catálogo desacoplado de aplicaciones Flathub con overrides Wayland/GTK (`--status`, `--all`).
- **`chrome.sh`**: Google Chrome precompilado desde repositorio **Chaotic-AUR** con Pacman/Paru, flags Wayland Ozone y aceleración VA-API (`--status`).
- **`firefox.sh`**: Mozilla Firefox nativo en Wayland con políticas VA-API (`/etc/firefox/policies/policies.json`) y aceleración por hardware (`--status`).
- **`steam.sh`**: Steam nativo con soporte multilib de 32 bits (`lib32-vulkan-radeon`, `lib32-mesa`), GameMode, MangoHud y Proton-GE (`--status`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop 2.0 setup (con sandbox, helper de actualización e integración en Nautilus, `--status`).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup (`--status`).
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (`--status`).
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI (`gh`) setup (`--status`).
- **`opencode.sh`**: OpenCode AI CLI setup (`--status`).

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de runtimes con **Mise** y aislamiento Python con **uv**:
- **`mise.sh`**: Gestor de versiones Mise con integración `environment.d` y shell (`--status`).
- **`python.sh`** & **`python-uv-init.sh`**: Verificación de Python 3 del sistema y gestor `uv` con `UV_LINK_MODE=copy` para aislamiento estricto por proyecto respetando PEP 668.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`rust.sh`**

---

## 🚀 Despliegue Rápido con Justfile

```bash
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Portátil de Desarrollo (AMD Ryzen + GNOME Wayland + Virtualización + Podman):
just setup-laptop-amd

# Instalación completa por defecto:
just setup-all

# Optimización de mirrors de CachyOS:
just rate-mirrors

# Ver el diagnóstico completo de todos los subsistemas:
just status
```

---

## 🔒 Reglas del Monorepo en CachyOS Workstation

* **Pacman + Paru Obligatorio:** Todos los scripts usan `pacman` y `paru` con comprobación idempotente (`pacman -T`), aprovechando los repositorios optimizados en x86-64-v3 y Chaotic-AUR.
* **Firewalld Obligatorio:** Todos los puertos se gestionan mediante `firewall-cmd`. El servicio `ufw` se desactiva y enmascara permanentemente.
* **Wayland Nativo:** Sin herramientas heredadas de X11 (`xclip`, `xrandr`, `xdotool`).
* **Python Protegido:** Uso exclusivo de `uv` por proyecto sin alterar el Python del sistema de CachyOS (PEP 668).
* **Podman Rootless:** Contenedores sin privilegios gestionados mediante Quadlets de systemd.
