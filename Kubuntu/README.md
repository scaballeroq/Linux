# Kubuntu Environment Configuration (KDE Plasma 6)

Colección modular y automatizada de scripts de configuración para sistemas **Kubuntu** (KDE Plasma 6 y 5 sobre Kubuntu 24.04 LTS, 24.10 y 26.04 LTS).

Automatiza completamente la puesta a punto de un entorno de desarrollo profesional, rápido, seguro y estéticamente pulido.

---

## Estructura del Repositorio

### Bash.Setup
Núcleo modular de la terminal Bash cargado vía `~/.bashrc.d/`:
- **`aliases.sh`**: Atajos para comandos frecuentes, Git, APT, kernel-check, VM, Podman.
- **`desktop_settings.sh`**: Optimizaciones y atajos para KDE Plasma.
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland/Qt flags).
- **`functions.sh`**: Funciones utilitarias (backups, extracción, multimedia).
- **`history.sh`**: Historial optimizado (10k/20k líneas, sin duplicados).
- **`options.sh`**: Comportamiento avanzado de shell (`autocd`, `globstar`).
- **`podman-functions.sh`**: Funciones para contenedores Podman + Quadlets.
- **`rclone_aliases.sh`**: Sincronización Google Drive y OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia con motor Deno.

### Setup
Scripts de configuración del sistema, hardware y personalización:
- **`post-install.sh`**: Dispatcher con auto-detección de CPU (AMD/Intel).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen.
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core.
- **`zram-setup.sh`**: ZRAM con compresión ZSTD al 50% de RAM.
- **`kubuntu-tuning.sh`**: Optimizaciones de rendimiento (sysctl, limits, Baloo, systemd).
- **`kde-settings.sh`**: Personalización de KDE Plasma (Breeze Dark, Night Color).
- **`kde-widgets.sh`**: Widgets, Klipper, KWin tiling, atajos globales.
- **`kde-plasma-customization.sh`**: Material You Colors, plasmoids oficiales.
- **`konsole.sh`**: Terminal Konsole translúcido (85% opacidad + blur).
- **`kitty.sh`**: Terminal Kitty con GPU, tema Catppuccin, opacidad configurable.
- **`laptop-setup.sh`**: Optimización para portátiles (VRR, HiDPI, touchpad, energía).
- **`seguridad.sh`**: UFW + Fail2ban + sysctl hardening.
- **`seguridad-dot.sh`**: DNS-over-TLS (Quad9 + Cloudflare).
- **`screensaver-setup.sh`**: KScreenLocker (bloqueo automático).
- **`shell.sh`** / **`starship.toml`**: Herramientas CLI modernas + prompt Starship.
- **`apariencia.sh`**: Temas e iconos Papirus y Breeze.
- **`fonts.sh`**: Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack).
- **`fastfetch.sh`** / **`config.jsonc`**: Resumen estético del sistema.
- **`firefox.sh`**: Firefox nativo .deb desde Mozilla APT (sin Snap).
- **`cockpit.sh`**: Panel de administración web.
- **`yt-dlp-setup.sh`**: yt-dlp, ffmpeg, Deno.
- **`fingerprint-setup.sh`**: Autenticación por huella dactilar.
- **`hp-printer-setup.sh`**: Impresora HP LaserJet Pro M15w.
- **`mount-workspace.sh`**: Automontaje de partición Workspace.

### Virtualizacion
- **`virtualization.sh`**: KVM/QEMU con Libvirt, Virt-Manager, bridge `br0`, VirtIO.
- **`notas_virtualizacion_kubuntu.md`**: Guía de virtualización.

### IDE
- **`git.sh`**: Git, Delta, Lazygit.
- **`github-cli.sh`**: GitHub CLI (`gh`).
- **`neovim.sh`**: Neovim + LazyVim.
- **`vscode.sh`**: Visual Studio Code.
- **`antigravity.sh`**: Google Antigravity Desktop.
- **`antigravity-cli.sh`**: Google Antigravity CLI.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### ProgrammingLanguages
Gestión de runtimes con **Mise**:
- **`mise.sh`**: Gestor de versiones Mise.
- **`nodejs.sh`**: Node.js LTS + pnpm.
- **`python.sh`**: Python 3.12 + pip.
- **`rust.sh`**: Rust + cargo-binstall.
- **`dotnet.sh`**: .NET SDK.
- **`java.sh`**: OpenJDK.
- **`angular.sh`**: Angular CLI.
- **`gemini.sh`**: Gemini CLI.

### Podman
Ecosistema de contenedores rootless con Quadlets:
- **`install/`**: `podman-install.sh`, `quadlets-setup.sh`
- **`lib/`**: `podman-utils.sh` (CLI para gestión de proyectos)
- **`services-shared/`**: Servicios globales (PostgreSQL, Redis, Traefik, Keycloak)
- **`templates/`**: Plantillas de proyectos (python-postgres, python-postgres-redis, fullstack)
- **`projects/`**: Proyectos activos (gitignored)

### Apps y Juegos
- **`Apps/meld.sh`**: Herramienta visual de diff y merge.
- **`Juegos/steam.sh`**: Steam + Proton-GE vía Flatpak.

---

## Uso con Justfile

### Perfiles completos
```bash
just setup-all            # Auto-detección de CPU
just setup-laptop-amd     # Portátil AMD Ryzen
just setup-laptop-intel   # Portátil Intel Core
just setup-desktop-amd    # Sobremesa AMD
just setup-desktop-intel  # Sobremesa Intel
```

### Tareas individuales
```bash
just post-install         # Base del sistema (auto-detect CPU)
just post-install-amd     # Post-instalación AMD
just post-install-intel   # Post-instalación Intel
just zram                 # ZRAM con ZSTD
just kde                  # KDE Plasma settings
just widgets              # Widgets, Klipper, atajos
just kde-custom           # Material You, plasmoids
just konsole              # Konsole translúcido
just kitty                # Kitty GPU terminal
just shell                # Terminal moderna + Starship
just security             # UFW + Fail2ban
just security-dot         # DNS-over-TLS
just tuning               # Optimizaciones de rendimiento
just tuning-status        # Estado de optimizaciones
just virtualization       # KVM/QEMU
just firefox              # Firefox .deb
just ides                 # Todos los IDEs
just languages            # Node, Python, Rust, .NET, Java
just podman-setup         # Podman rootless + Quadlets
just podman-status        # Estado de Podman
```

---

## Configuración Manual de la Shell

```bash
mkdir -p ~/.bashrc.d
ln -s $(pwd)/Bash.Setup/*.sh ~/.bashrc.d/
```

Añade a tu `~/.bashrc`:
```bash
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

*Mantenido por [caballero](https://github.com/scaballeroq)*
