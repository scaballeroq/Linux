# 🔧 Arch Linux Environment Configuration (Niri + Dank Material Shell)

Colección organizada, modular y automatizada de scripts de configuración y aprovisionamiento para **Arch Linux** con el compositor scrollable-tiling **Niri** (Wayland) y el entorno de escritorio moderno **Dank Material Shell (DMS)** con diseño Material 3 (Material You).

---

## 🌟 Características Principales

- **Distribución**: Arch Linux pura (rolling release, kernel oficial, microcódigo y pacman optimizado).
- **Compositor**: [Niri](https://github.com/YaLTeR/niri) (compositor Wayland con disposición scrollable-tiling infinita).
- **Entorno de Escritorio**: [Dank Material Shell](https://danklinux.com/) (DMS) basado en Quickshell y Material Design 3:
  - Barra superior / dock integrada y reactiva.
  - Lanzador de aplicaciones, centro de control y ajustes rápidos de hardware (Wi-Fi, Bluetooth, brillo, audio).
  - Portapapeles con vista previa y bloqueo de pantalla.
  - Satélites: `dankcalendar` (`dcal`), `danksearch` y greeter para Greetd.
  - Paletas de colores dinámicas mediante **Matugen** aplicadas a Kitty, GTK y Niri.
- **Terminal y Shell**: Emulador **Kitty** acelerado por GPU con transparencia/blur y carga modular para **Zsh** y **Bash** (`~/.zshrc.d` y `~/.bashrc.d`), enriquecido con el prompt **Starship**.
- **Contenedores**: Ecosistema **Podman Rootless** integrado con **Systemd Quadlets**, plantillas de proyectos y socket de Docker para IDEs.
- **Virtualización**: **KVM / QEMU** optimizado con sockets modulares de Libvirt 12+, VirGL 3D, VirtioFS y reglas de ventana Niri.
- **Entornos de Desarrollo e IA**: Google Antigravity Desktop, Antigravity CLI (`agy`), Antigravity IDE, OpenCode, VS Code, Neovim (LazyVim), Meld y Gemini CLI.
- **Gestión de Lenguajes**: Runtimes aislados y configurados vía **Mise** (Node.js, Python, Rust, .NET SDK, OpenJDK, Angular).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación para AMD Ryzen (microcódigo AMD, RADV, Mesa, PipeWire, Niri + DMS stack).
- **`post-install-intel.sh`**: Post-instalación para Intel Core (microcódigo Intel, VA-API Intel, PipeWire, Niri + DMS stack).
- **`dms-setup.sh`**: Verificador y gestor del entorno Dank Material Shell (`dms doctor`, servicio systemd, reinicio, temas).
- **`backup-niri-dms.sh`**: Gestor de copias de seguridad de configuraciones de Niri y DMS (creación, listado, restauración).
- **`kitty.sh`**: Configuración de Kitty acelerada por GPU con opacidad, blur y tema dinámico Material You.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `btop`, `jq`, `zsh`, `starship`).
- **`seguridad.sh`**: Configuración de Firewalld (LAN doméstica), integración con QEMU/KVM, Podman y Sysctl.
- **`cockpit.sh`**: Instalación y configuración de Cockpit (administración web on-demand).
- **`fastfetch.sh`**: Diagnóstico e información estética del sistema con configuración personalizada.
- **`fonts.sh`**: Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode e Inter Variable).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, FFmpeg, Deno/Node).

### 🐚 [ZSH.Setup](./ZSH.Setup/)
Configuración modular de terminal para **Zsh** y **Bash**:
- **`aliases.sh`**: Atajos de navegación (`arch`, `project`, `repo`), seguridad (`rm -i`), paquetes (`pacman` / `yay`), espejos (`rate-mirrors`) y pipes globales en Zsh (`G`, `L`, `H`, `J`).
- **`niri_dms.sh`**: Control e IPC de Niri y Dank Material Shell (`dms ipc`), capturas Wayland (`grim` + `slurp` + `satty`) y grabación (`wl-screenrec`).
- **`environment.sh`**: Variables globales (`EDITOR`, `PATH`, Wayland/Qt, Docker host) y activación de Mise.
- **`functions.sh`**: Utilidades multimedia, gestión de discos, extracción universal y navegación rápida (`mkcd`, `up`).
- **`history.sh`**: Control de historial optimizado (50k entradas, deduplicación y guardado inmediato).
- **`options.sh`**: Comportamiento interno de la shell (`autocd`, corrección de typos, menús interactivos).
- **`podman-functions.sh`**: Funciones y atajos para contenedores Podman y Quadlets.
- **`rclone_aliases.sh`**: Sincronización en la nube con Google Drive (`gdrive-arch`) y OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets (systemd native):
- **`install/podman-install.sh`**: Configuración de Podman rootless, socket, linger, registries.
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets.
- **`lib/podman-utils.sh`**: CLI para gestión de proyectos y servicios compartidos.
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (python-postgres, python-postgres-redis, fullstack).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de KVM/QEMU, Libvirt modular sockets, VirGL 3D, VirtioFS y reglas de ventana Niri.
- **`notas_virtualizacion_arch.md`**: Manual técnico exhaustivo de virtualización en Arch Linux.

### 💻 [IDE](./IDE/), [Apps](./Apps/) & [AI](./AI/)
- **`git.sh`**: Git, Delta, Lazygit y GitHub CLI.
- **`antigravity.sh`**: Google Antigravity Desktop setup y auto-updater.
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`opencode.sh`**: OpenCode AI CLI setup.
- **`vscode.sh`**: Visual Studio Code (AUR).
- **`neovim.sh`**: Neovim + LazyVim.
- **`Apps/meld.sh`**: Herramienta gráfica de diferencias Meld.
- **`AI/gemini.sh`**: Google Gemini CLI vía Mise/NPM.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión de runtimes mediante **Mise**:
- **`mise.sh`**: Instalación de Mise con generación de variables para Wayland y shells.
- **`nodejs.sh`**, **`python.sh`**, **`rust.sh`**, **`dotnet.sh`**, **`java.sh`**, **`angular.sh`**.

### 📚 [Docs](./Docs/)
Documentación técnica bilingüe (Español e Inglés) detallada para cada subsistema:
- `setup_es.md` / `setup_en.md`
- `dms_niri_es.md` / `dms_niri_en.md`
- `zsh_es.md` / `zsh_en.md`
- `seguridad_es.md` / `seguridad_en.md`
- `virtualizacion_es.md` / `virtualization_en.md`
- `podman_es.md` / `podman_en.md`
- `ide_es.md` / `ide_en.md`
- `git_es.md` / `git_en.md`
- `languages_es.md` / `languages_en.md`

---

## 🚀 Despliegue Rápido con `just`

El repositorio incluye un `justfile` que automatiza la configuración completa o por módulos:

```bash
# 1. Clonar el repositorio
git clone https://github.com/scaballeroq/ArchLinux-Niri-DMS.git
cd ArchLinux-Niri-DMS

# 2. Instalar el orquestador just si no está presente
sudo pacman -S --needed just

# 3. Desplegar el entorno completo (Auto-detección de CPU AMD/Intel)
just setup-all
```

### Recetas Específicas:
```bash
just post-install        # Configuración base del sistema
just shell               # Utilidades de terminal y cargador modular
just dms-setup           # Verificación y estado de Dank Material Shell
just dms-doctor          # Diagnóstico de salud de DMS
just security            # Firewalld, puertos y sysctl
just kitty               # Terminal Kitty con tema Material You y blur
just git-setup           # Git, Git-Delta, Lazygit y GitHub CLI
just ides                # Antigravity Desktop, CLI, IDE y OpenCode
just languages           # Todos los lenguajes de programación
just podman-setup        # Podman rootless y Quadlets
just virtualization      # KVM/QEMU y Libvirt
just backup              # Crear copia de seguridad de Niri y DMS
```
