# 🔧 Fedora: Configuración de Entorno Fedora 44 Workstation + KDE Plasma 6

Colección organizada, modular y automatizada de scripts de configuración para sistemas **Fedora 44 Workstation** con el entorno de escritorio **KDE Plasma 6** sobre **Wayland** (optimizado para estaciones de trabajo y portátiles de desarrollo).

---

## 📂 Organización del Repositorio

La configuración está estructurada de forma modular para facilitar su mantenimiento y despliegue:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración modular de la terminal Bash (cargada dinámicamente vía `~/.bashrc.d`):
- **`aliases.sh`**: Atajos comunes para DNF5, integración con KDE Plasma/Dolphin, portapapeles Wayland (`wl-copy`/`wl-paste`) y utilidades modernas en Rust (`eza`, `bat`, `duf`, `dust`, `procs`, `btop`, `zoxide`).
- **`kde_settings.sh`**: Gestor CLI interactivo para configuración de KDE Plasma 6, Wayland/KWin, atajos directos a módulos de Preferencias (`kcmshell6`), reinicio de shell y Spectacle.
- **`environment.sh`**: Variables globales de entorno (`PATH`, `EDITOR`, `mise`, `GPG_TTY`, `DOCKER_HOST`, flags Wayland/Qt/Electron).
- **`functions.sh`**: Funciones avanzadas y utilidades multimedia (FFmpeg, ImageMagick, extracción universal multiformato).
- **`history.sh`**: Configuración optimizada del historial de Bash (hasta 20.000 líneas, sin duplicados, sincronización inmediata).
- **`options.sh`**: Opciones internas de Bash mediante `shopt` (`autocd`, `globstar`, `dirspell`, protección de bind).
- **`podman-functions.sh`**: Suite de comandos de gestión rápida de contenedores (`pps`, `pexec`, `plogs`, `pclean-total`, `quadlet-reload`).
- **`rclone_aliases.sh`**: Atajos para sincronización y respaldos en la nube con Google Drive y OneDrive.
- **`yt-dlp_aliases.sh`**: Atajos para descargas multimedia optimizadas (1080p, MP3, listas de reproducción y detección de runtime JS Deno).

### ⚙️ [Setup](./Setup/)
Scripts de aprovisionamiento del sistema operativo, personalización visual y rendimiento:
- **`post-install.sh`**: Despachador inteligente con detección automática de CPU (AMD vs Intel) y soporte para banderas CLI (`--amd`, `--intel`).
- **`post-install-amd.sh`**: Post-instalación optimizada para procesadores **AMD Ryzen** y gráficos Radeon (microcódigo AMD, firmware GPU, RADV, Mesa, PipeWire, ZRAM, RPM Fusion).
- **`post-install-intel.sh`**: Post-instalación optimizada para equipos de sobremesa **Intel Core** (Haswell i7-4790 / HD Graphics 4600) para centro multimedia y streaming (microcódigo Intel, VA-API `i965`/`intel-media-driver`, codecs, Kodi, sin virtualización).
- **`apariencia.sh`**: Gestor de temas y homogeneización visual para KDE Plasma 6 (Breeze Dark, iconos Papirus-Dark, cursores e integración GTK 3/4 y Flatpak).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad personalizable (`--opacity`), desenfoque blur, tipografía JetBrainsMono Nerd Font, atajos al vuelo e integración con Dolphin.
- **`laptop-setup.sh`**: Optimización para portátiles (Touchpad, gestos, Bluetooth, GPU híbrida con `switcheroo-control`, gestión de energía con `tuned-ppd` y servicio de persistencia de brillo al 95%).
- **`hp-printer-setup.sh`**: Impresora HP LaserJet Pro M15w vía USB/Red (CUPS, HPLIP, Print Manager KDE y descarga de plugin privativo).
- **`fedora-tuning.sh`**: Ajustes de Kernel Sysctl (`inotify`, `max_map_count`, `swappiness` ZRAM, BBR), límites de descriptores (`limits.d`), timeouts en Systemd, exclusión de carpetas en indexador KDE Baloo y Distrobox.
- **`seguridad.sh`**: Endurecimiento de seguridad integral (Firewalld en zona `FedoraWorkstation` con soporte para KDE Connect, mDNS y SSH; DNS-over-TLS en `systemd-resolved`; Wi-Fi MAC Randomization; sysctl para Podman rootless).
- **`shell.sh`**: Instalación de herramientas modernas de consola (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `duf`, `du-dust`, `btop`, `jq`), Starship prompt y configuración en `.bashrc`.
- **`plymouth-setup.sh`**: Instalación y selector interactivo de Splash Screen visual de arranque (Breeze, BGRT, Spinner) con regeneración automática de initramfs mediante Dracut.
- **`cockpit.sh`**: Consola web de administración Cockpit con módulos para Podman, MVs KVM, Almacenamiento y Red ([https://localhost:9090](https://localhost:9090)).
- **`fonts.sh`**: Fuentes tipográficas para desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode).
- **`fastfetch.sh`**: Resumen estético del sistema al abrir la terminal.
- **`yt-dlp-setup.sh`**: Instalador completo de yt-dlp + FFmpeg + AtomicParsley + aria2c + motor JS Deno con configuración optimizada.

### 📦 [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de lenguajes de programación y SDKs:
- **`mise.sh`**: Gestor de versiones políglota Mise con integración en sesión Wayland de KDE Plasma (`environment.d`) y shims globales.
- **`nodejs.sh`**: Instalación dinámica de la última versión LTS de Node.js, Corepack (`pnpm`/`yarn`) y CLI status/update.
- **`python.sh`**: Configuración de Python LTS estable, gestor ultrarrápido `uv`, `pipx` y librerías de compilación.
- **`rust.sh`**: Rustup canal Stable, `rust-analyzer`, `clippy`, `cargo-binstall` y variables de entorno.
- **`dotnet.sh`**: .NET SDK LTS para desarrollo en CoreCLR.
- **`java.sh`**: OpenJDK LTS con soporte para certificados y herramientas FNMT / AutoFirma.
- **`angular.sh`**: Angular CLI integrado globalmente vía Mise.
- **`gemini.sh`**: CLI de Google Gemini.

### 💻 [IDEs y Herramientas de Desarrollo](./IDE/)
- **`neovim.sh`**: Neovim modular con la distribución LazyVim preconfigurada.
- **`vscode.sh`**: Visual Studio Code nativo mediante el repositorio oficial RPM de Microsoft con DNF5.
- **`antigravity.sh`**: Google Antigravity Desktop 2.0 (instalador integral con sandbox y lanzador de escritorio).
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Suite CLI y motor IDE independiente de Antigravity.
- **`opencode.sh`**: Cliente y editor de IA OpenCode con control de versión.
- **`git.sh`**: Configuración global de Git, paginador visual Git-Delta (`zdiff3`, `side-by-side`) y Lazygit TUI.
- **`github-cli.sh`**: Cliente oficial de GitHub CLI (`gh`).

### 🐳 [Podman](./Podman/)
Ecosistema profesional para contenedores Rootless y Systemd Quadlets:
- **Instalación**: `install/podman-install.sh` y `install/quadlets-setup.sh`.
- **CLI de Gestión**: `lib/podman-utils.sh` (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **Servicios Compartidos**: Traefik (Proxy inverso), PostgreSQL global, Redis global y Keycloak (OAuth2/OIDC).
- **Plantillas de Proyecto**: `python-postgres`, `python-postgres-redis` y `fullstack` (FastAPI + React/Node + Traefik + Keycloak + Hot Reload).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Aceleración completa KVM/QEMU, Libvirt modular, VirtIO nativo, audio nativo PipeWire, Tuned perfil `virtual-host`, backend nftables y Nested KVM.
- **`Notas_Virtualizacion_Fedora.md`**: Guía técnica y manual de administración.

---

## 🚀 Despliegue Rápido con Just

Para ejecutar el despliegue automático según el perfil de tu equipo:

```bash
git clone https://github.com/scaballeroq/Fedora.git
cd Fedora
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Portátil de Desarrollo (AMD Ryzen + KDE Plasma + Virtualización + Podman):
just setup-laptop-amd

# Sobremesa Centro Multimedia (Intel Haswell / Media Center + Kodi - Sin virtualización):
just setup-media-desktop
```

O ejecutar componentes de forma individual:
```bash
just post-install-amd    # Post-instalación exclusiva para AMD Ryzen
just post-install-intel  # Post-instalación para Intel Media Center
just apariencia          # Aplica tema Breeze Dark + Papirus-Dark en KDE Plasma y GTK
just kitty               # Configura terminal Kitty con opacidad y desenfoque
just tuning              # Aplica sysctl, límites, systemd y Baloo
just plymouth            # Configura y activa el splash screen visual de arranque
just ides                # Instala Neovim, VSCode, Antigravity y OpenCode
just languages           # Instala Node, Python, Rust, .NET y Java
just podman-setup        # Configura Podman rootless y Quadlets
```
