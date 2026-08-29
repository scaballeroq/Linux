# 🔧 CachyOS Environment Configuration (KDE Plasma 6)

Este repositorio contiene una colección organizada y modular de scripts de configuración para sistemas **CachyOS** (basado en Arch Linux y optimizado para alto rendimiento x86-64-v3/v4) con el entorno de escritorio **KDE Plasma 6** (optimizado para PCs y portátiles de desarrollo).

---

## 📂 Organización del Repositorio

La configuración se ha estructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal Bash.
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados y gestores de paquetes (`pacman` / `paru`).
- **`environment.sh`**: Variables globales que afectan el comportamiento de la shell.
- **`functions.sh`**: Colección de funciones avanzadas y utilidades multimedia.
- **`kde_settings.sh`**: Configuraciones de entorno para KDE Plasma 6, touchpad, energía y Wayland.
- **`history.sh`**: Controla cómo bash recuerda los comandos.
- **`options.sh`**: Configura el comportamiento interno de Bash mediante 'shopt' y 'bind'.
- **`podman-functions.sh`**: Funciones para gestión simplificada de contenedores con Quadlets.
- **`rclone_aliases.sh`**: Atajos para facilitar la sincronización en la nube.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### 🐳 [Podman](./Podman/)
Ecosistema de contenedores rootless con Quadlets (systemd native):
- **`install/podman-install.sh`**: Instalación y configuración de Podman rootless, socket, linger, registries.
- **`install/quadlets-setup.sh`**: Configuración de directorios y servicios systemd Quadlets.
- **`lib/podman-utils.sh`**: CLI completo para gestión de proyectos (create, start, stop, logs, status, destroy).
- **`projects/`**: Directorio para proyectos activos.
- **`services-shared/`**: Servicios globales compartidos (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Plantillas de proyectos (python-postgres, python-postgres-redis, fullstack).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Configuración de Virtualización (KVM/QEMU, libvirtd) optimizada para CachyOS.
- **`notas_virtualizacion_cachyos.md`**: Guía detallada de KVM/QEMU en CachyOS.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con auto-detección de CPU (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-instalación optimizada para AMD Ryzen (ZRAM, RADV, Mesa, PipeWire).
- **`post-install-intel.sh`**: Post-instalación optimizada para Intel Core (VA-API Intel, PipeWire).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo en KDE Plasma 6 (Touchpad, Bluetooth, PowerDevil, HiDPI, VRR).
- **`fingerprint-setup.sh`**: Configuración de desbloqueo por huella dactilar (`fprintd`, PAM, `polkit`, SDDM, KDE).
- **`cachyos-tuning.sh`**: Ajustes de Kernel (`sysctl`), Baloo, Systemd, Distrobox y límites de sistema.
- **`apariencia.sh`**: Gestor de temas con Kvantum, Papirus, Breeze e integración GTK/Qt en KDE Plasma 6.
- **`cockpit.sh`**: Instalación y configuración de Cockpit (administración web).
- **`fastfetch.sh`**: Información estética del sistema al inicio (Fastfetch).
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (Nerd Fonts).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad/blur y tema Catppuccin.
- **`seguridad.sh`**: Endurecimiento con Firewalld, DNS-over-TLS, MAC Randomization y sysctl.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`) y prompt (`Starship`).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, ffmpeg, deno).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup.
- **`antigravity-cli.sh`**: Google Antigravity CLI setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta y Lazygit setup.
- **`github-cli.sh`**: GitHub CLI installer.
- **`neovim.sh`**: Neovim & LazyVim setup.
- **`opencode.sh`**: OpenCode AI CLI setup.
- **`vscode.sh`**: Visual Studio Code installer.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión de runtimes con **mise**.
- **`mise.sh`**: Mise version manager installer.
- **`angular.sh`**, **`dotnet.sh`**, **`gemini.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`rust.sh`**

### 🎮 [Juegos](./Juegos/)
- **`steam.sh`**: Steam con Proton CachyOS.

---

## 🚀 Cómo empezar

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/CachyOS
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Juegos/*.sh
just setup-all
```

---
*Mantenido por [caballero](https://github.com/scaballeroq)*
