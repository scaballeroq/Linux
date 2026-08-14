# 🔧 Kubuntu Environment Configuration (KDE Plasma)

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Kubuntu** (enfocado en KDE Plasma 6 y 5 sobre Kubuntu 24.04 LTS, 24.10 y 26.04 LTS).

El objetivo es automatizar completamente la puesta a punto de un entorno de desarrollo profesional, ultrarrápido, seguro y estéticamente pulido.

---

## 📂 Organización del Repositorio

La configuración está estructurada modularmente para facilitar el mantenimiento y la extensibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
Núcleo modular de la terminal Bash cargado vía `~/.bashrc.d/`:
- **`aliases.sh`**: Atajos para comandos frecuentes, Git, APT, utilidades Rust y virtualización.
- **`desktop_settings.sh`**: Optimizaciones y atajos para KDE Plasma (Luz Nocturna, temas Breeze, energía).
- **`environment.sh`**: Variables globales de entorno (`EDITOR`, `PATH`, personalización de `less` y `man`).
- **`functions.sh`**: Colección de funciones utilitarias (backups, extracción multiformato, ISOs, multimedia).
- **`history.sh`**: Historial persistente optimizado (10k/20k líneas, sin duplicados, con marcas de tiempo).
- **`options.sh`**: Comportamiento avanzado de shell (`autocd`, `globstar`, corrección de typos).
- **`podman-functions.sh`**: Funciones no colisionantes para gestión ágil de contenedores Podman.
- **`rclone_aliases.sh`**: Atajos de sincronización, copia y simulación `--dry-run` para Google Drive y OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia en alta calidad con soporte para motor JS Deno.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, hardware, personalización y endurecimiento:
- **`post-install.sh`**: Configuración base del sistema, repositorios universe/multiverse, Flatpak con Discover y codecs.
- **`kde-settings.sh`**: Personalización completa de KDE Plasma vía CLI (Breeze Dark, Night Color, atajo Meta+T).
- **`apariencia.sh`**: Instalación de temas e iconos Papirus y Breeze.
- **`firefox.sh`**: Instalador oficial de Firefox nativo `.deb` desde Mozilla APT con Pin-Priority 900 (sin Snap).
- **`laptop-setup.sh`**: Optimización para portátiles en Kubuntu (energía, touchpad tap-to-click, bluetooth).
- **`fingerprint-setup.sh`**: Autenticación por huella dactilar (fprintd, PAM, sudo, polkit, SDDM).
- **`hp-printer-setup.sh`**: Instalación y configuración de impresora HP LaserJet Pro M15w (USB/CUPS/HPLIP).
- **`mount-workspace.sh`**: Configuración de automontaje permanente de la partición Workspace en `/etc/fstab`.
- **`cockpit.sh`**: Panel de administración web de alto rendimiento (Storage, KVM, Podman, Redes).
- **`fastfetch.sh`** / **`config.jsonc`**: Resumen estético del sistema al abrir la terminal.
- **`fonts.sh`**: Instalación de fuentes para desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack).
- **`seguridad.sh`**: Endurecimiento (hardening) del sistema mediante reglas seguras de UFW firewall.
- **`shell.sh`** / **`starship.toml`**: Herramientas CLI modernas en Rust (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, etc.) y prompt Starship.
- **`yt-dlp-setup.sh`**: Dependencias para procesamiento y descarga multimedia.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Entorno KVM/QEMU completo con Libvirt, Virt-Manager, bridge `br0`, drivers VirtIO y tuned.
- **`notas_virtualizacion_kubuntu.md`**: Guía paso a paso y mejores prácticas de virtualización en Kubuntu.

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop.
- **`antigravity-cli.sh`**: CLI de Google Antigravity (`agy`).
- **`antigravity-ide.sh`**: Motor IDE de Google Antigravity.
- **`opencode.sh`**: OpenCode AI CLI y Editor.
- **`neovim.sh`**: Neovim modular potenciado con LazyVim y LSPs.
- **`vscode.sh`**: Visual Studio Code desde el repositorio oficial de Microsoft.

### 🛠️ [Git](./Git/)
- **`git.sh`**: Instalación y configuración de Git, Delta (diffs coloreados) y Lazygit (TUI).
- **`github-cli.sh`**: Instalación y autenticación de GitHub CLI (`gh`).

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión moderna de runtimes con **Mise**:
- **`mise.sh`**: Instalador del gestor de versiones Mise.
- **`nodejs.sh`**: Node.js LTS y activación de `pnpm` vía Corepack.
- **`python.sh`**: Python 3.12 y herramientas pip.
- **`rust.sh`**: Rust vía rustup y cargo-binstall.
- **`dotnet.sh`**: .NET SDK.
- **`java.sh`**: OpenJDK.
- **`angular.sh`**: Angular CLI.
- **`gemini.sh`**: Gemini CLI.

### 🐳 [Podman](./Podman/)
19 scripts modulares para desplegar servicios de desarrollo aislados:
- **Core**: `podman.sh`
- **Bases de Datos**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Almacenamiento**: `podman-minio.sh`
- **Monitoreo**: `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`, `podman-dozzle.sh`
- **Administración**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-keycloak.sh`
- **Web & Testing**: `podman-nginx.sh`, `podman-wordpress.sh`, `podman-rabbitmq.sh`, `podman-mailhog.sh`, `podman-browserless.sh`, `podman-storybook.sh`

### 📦 [Apps](./Apps/) y 🎮 [Juegos](./Juegos/)
- **`meld.sh`**: Herramienta visual de diff y merge.
- **`steam.sh`**: Steam y compatibilidad Proton-GE vía Flatpak.

---

## 🚀 Uso con Justfile

El repositorio incluye un archivo [`justfile`](./justfile) para ejecutar cualquier configuración de forma rápida:

```bash
# Configuración completa del sistema
just setup-all

# Tareas individuales
just post-install    # Base del sistema y repositorios
just kde             # Personalización de KDE Plasma 6 / 5
just shell           # Terminal moderna (eza, bat, starship)
just virtualization  # KVM / QEMU / Virt-Manager
just firefox         # Firefox oficial .deb (sin snap)
just ides            # Neovim, VS Code, Antigravity, OpenCode
just languages       # Node, Python, Rust, .NET, Java
just podman-base     # Podman rootless
```

---

## 🐚 Configuración Manual de la Shell

Para cargar los módulos de shell en cualquier sesión:

```bash
mkdir -p ~/.bashrc.d
ln -s $(pwd)/Bash.Setup/*.sh ~/.bashrc.d/
```

Añade esto a tu `~/.bashrc`:
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
