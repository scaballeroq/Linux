# 🔧 Fedora Workstation Environment Configuration (GNOME)

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Fedora 44 Workstation** con el entorno de escritorio **GNOME** sobre **Wayland** (optimizado para portátiles y estaciones de trabajo de desarrollo en modo oscuro).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal, optimizado para **Bash** (shell predeterminada del proyecto con soporte modular en `~/.bashrc.d`) y **Zsh** (compatible si existe `~/.zshrc`).
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados, recarga dinámica, Nautilus y gestor de paquetes **DNF5**.
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland/GNOME, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise.
- **`functions.sh`**: Colección de funciones avanzadas (`mkcd`, `up`, `hg`) y utilidades multimedia (FFmpeg / ImageMagick).
- **`gnome_settings.sh`**: Configuraciones de entorno y atajos para GNOME Wayland (tema oscuro, night light, captura Wayland con grim/satty, Nautilus).
- **`history.sh`**: Control de historial optimizado (deduplicación, sincronización inmediata, timestamps).
- **`options.sh`**: Opciones avanzadas de shell (`autocd`, corrección de typos, completado insensible a mayúsculas con `shopt`).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets compatibles con ambas shells.
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets nativos de systemd:
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket, linger, registries y backend de red passt.
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets.
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de Virtualización (KVM/QEMU, Libvirt modular, virt-manager, virtio-win) optimizada para Fedora 44.
- **`notas_virtualizacion_fedora.md`**: Guía detallada de KVM/QEMU, VirtIO, red bridge y almacenamiento en Fedora 44.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, RPM Fusion, codecs multimedia).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core / Media Center (VA-API Intel i965 / media-driver, PipeWire, codecs, Kodi).
- **`gnome-settings.sh`**: Configuración y personalización de GNOME (Modo oscuro `prefer-dark` y `adw-gtk3-dark`, VRR Mutter, atajo Kitty Ctrl+Alt+T, Nautilus).
- **`gnome-extensions.sh`**: Instalador y gestor de extensiones de GNOME Shell desde repositorios oficiales y extensions.gnome.org (Dash to Dock, AppIndicator, Caffeine, Blur my Shell, etc.).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo en GNOME (Touchpad, Bluetooth FastConnectable, no suspender con corriente, persistencia de brillo al 95%).
- **`fedora-tuning.sh`**: Ajustes de Kernel (`sysctl`), límites de sistema (`limits.d`), timeouts de Systemd, exclusiones masivas de Tracker 3 (LocalSearch) y Distrobox.
- **`cockpit.sh`**: Consola web de administración Cockpit con módulos para Podman, MVs KVM, almacenamiento y red.
- **`fastfetch.sh` & `config.jsonc`**: Resumen estético del sistema temático Fedora.
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad/blur, tema Catppuccin Mocha y atajos GNOME / Nautilus.
- **`seguridad.sh`**: Endurecimiento con Firewalld (zona `FedoraWorkstation` con soporte para GSConnect), DNS-over-TLS y sysctl para Podman rootless.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Prompt Starship moderno con configuración temática Fedora.
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, FFmpeg, AtomicParsley, aria2, motor JS Deno).
- **`multimedia.sh`**: Colección completa de codecs multimedia, FFmpeg sin restricciones, plugins GStreamer y soporte DVD descifrado (`libdvdcss`) vía RPM Fusion (Free, Nonfree y Tainted).
- **`chrome.sh`**: Activación del repositorio oficial de Google Chrome e instalación de `google-chrome-stable`.
- **`steam.sh`**: Instalación de Steam nativo desde RPM Fusion Nonfree con GameMode, MangoHud y drivers Vulkan de 32-bit (`mesa-vulkan-drivers.i686`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (con sandbox y script contextual para Nautilus).
- **`antigravity-cli.sh`**: Google Antigravity CLI setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI setup con rama predeterminada `develop`.
- **`opencode.sh`**: OpenCode AI CLI setup.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de runtimes con **Mise**:
- **`mise.sh`**: Gestor de versiones Mise vía RPM oficial DNF5 con integración `environment.d`.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`python-uv-init.sh`**, **`rust.sh`**

---

## 🚀 Despliegue Rápido con Just

Para ejecutar el despliegue automático según el perfil de tu equipo:

```bash
git clone https://github.com/scaballeroq/Fedora-Workstation.git
cd Fedora-Workstation
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Portátil de Desarrollo (AMD Ryzen + GNOME + Virtualización + Podman):
just setup-laptop-amd

# Sobremesa Centro Multimedia (Intel Haswell / Media Center + Kodi - Sin virtualización):
just setup-media-desktop

# O instalación completa por defecto:
just setup-all
```

O ejecutar componentes de forma individual:
```bash
just post-install        # Post-instalación base con auto-detección de CPU
just gnome-setup         # Aplica configuración de GNOME, modo oscuro, reloj y atajos
just gnome-extensions    # Instala y activa extensiones de GNOME Shell
just laptop              # Optimización para portátiles (Touchpad, Bluetooth, brillo 95%)
just tuning              # Aplica sysctl, límites, systemd y exclusiones Tracker 3
just kitty               # Configura terminal Kitty con opacidad y desenfoque
just virtualization      # Configura KVM/QEMU y libvirt
just multimedia         # Instala codecs completos, FFmpeg y drivers privativos
just chrome             # Instala Google Chrome oficial
just steam              # Instala Steam nativo y drivers Vulkan 32-bit
just languages           # Instala Node, Python, Rust, .NET y Java
just podman-setup        # Configura Podman rootless y Quadlets
```

---

*Mantenido por [caballero](https://github.com/scaballeroq)*
