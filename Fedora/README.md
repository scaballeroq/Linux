# 🔧 Fedora: Configuración de Entorno Fedora 44 Workstation + GNOME

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Fedora 44 Workstation** con el entorno de escritorio **GNOME** (optimizado para estaciones de trabajo y portátiles de desarrollo).

---

## 📂 Organización del Repositorio

La configuración está estructurada de forma modular para facilitar su mantenimiento y despliegue:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal Bash:
- **`aliases.sh`**: Atajos comunes para DNF5, comandos frecuentemente utilizados y utilidades modernas en Rust (`eza`, `bat`, `duf`, `dust`, `procs`, `btm`).
- **`environment.sh`**: Variables globales que afectan el comportamiento de la shell (`PATH`, `EDITOR`, `mise`, `GPG_TTY`, DOCKER_HOST).
- **`functions.sh`**: Colección de funciones avanzadas y utilidades multimedia (FFmpeg, ImageMagick, extracción unificada).
- **`gnome_settings.sh`**: Configuraciones de entorno para GNOME, luz nocturna, temas, reinicio de shell y accesos rápidos a Configuración.
- **`history.sh`**: Controla cómo bash recuerda los comandos (sin duplicados, hasta 20k líneas).
- **`options.sh`**: Configura el comportamiento interno de Bash mediante `shopt` y `bind`.
- **`podman-functions.sh`**: Funciones para gestión simplificada de contenedores (`pexec`, `plogs`, `pclean`).
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive y OneDrive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas con yt-dlp, ffmpeg y motor JS (Deno).

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización de GNOME y endurecimiento:
- **`post-install.sh`**: Despachador inteligente con detección automática de procesador (AMD vs Intel) y soporte para banderas CLI (`--amd`, `--intel`).
- **`post-install-amd.sh`**: Post-instalación optimizada para procesadores **AMD Ryzen** y gráficos Radeon (microcódigo AMD, firmware GPU, RADV, Mesa, ZRAM con `zram-generator`, PipeWire, GNOME, RPM Fusion).
- **`post-install-intel.sh`**: Post-instalación optimizada para equipos de sobremesa **Intel Core** (Haswell i7-4790 / HD Graphics 4600) dedicados a centro multimedia y streaming (microcódigo Intel, driver VA-API `i965` / `intel-media-driver`, codecs, Kodi, sin virtualización).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad (85%), efectos blur, tipografía JetBrainsMono Nerd Font e integración con Dolphin y KDE Plasma.
- **`apariencia.sh`**: Instalación de temas e iconos (Adwaita-Dark, Papirus-Dark e integración visual GTK/Qt).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (Touchpad, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, VRR en Wayland, persistencia de brillo al 95%).
- **`fingerprint-setup.sh`**: Desbloqueo y autenticación por huella dactilar (`fprintd`, `fprintd-pam`, `authselect` nativo en Fedora).
- **`hp-printer-setup.sh`**: Impresora HP LaserJet Pro M15w vía USB (CUPS, HPLIP, plugin propietario y `system-config-printer`).
- **`fedora-tuning.sh`**: Ajustes de Kernel Sysctl (`inotify`, `max_map_count`) y soporte de `distrobox`.
- **`build-custom-kernel.sh`**: Compilador de Kernel Linux oficial optimizado para arquitectura `x86_64-v3`, latencia a 1000Hz y Preemption dinámica con Dracut y GRUB.
- **`cockpit.sh`**: Panel de administración web Cockpit con módulos Podman, Virtualización y Almacenamiento.
- **`fastfetch.sh`**: Información estética del sistema al abrir la terminal (Fastfetch).
- **`firefox.sh`**: Instalación y configuración de Mozilla Firefox oficial.
- **`fonts.sh`**: Fuentes tipográficas de desarrollo (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`mount-workspace.sh`**: Automontaje seguro de la partición de trabajo `/home/caballero/Workspace`.
- **`seguridad.sh`**: Endurecimiento (hardening) con Firewall Firewalld (zona `FedoraWorkstation`), MAC Randomization y sysctl hardening.
- **`seguridad-dot.sh`**: DNS-over-TLS mediante `systemd-resolved`.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `duf`, `dust`) y Starship prompt.
- **`screensaver-setup.sh`**: Configuración de salvapantallas 3D/Matrix al bloquear la pantalla en GNOME.
- **`plymouth-setup.sh`**: Instalación, configuración y selector de Splash Screen visual de arranque con `dracut -f`.
- **`yt-dlp-setup.sh`**: Dependencias multimedia (yt-dlp, ffmpeg y motor JS Deno vía mise).

### 🐳 [Podman](./Podman/)
Ecosistema completo para contenedores Rootless y Systemd Quadlets:
- **Instalación**: `podman-install.sh`, `quadlets-setup.sh`
- **Servicios Compartidos**: Traefik, PostgreSQL, Redis, Keycloak.
- **Templates**: Python-Postgres, Python-Postgres-Redis, Fullstack.
- **CLI Utility**: `lib/podman-utils.sh`

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Instalación y configuración de KVM/QEMU, Libvirt, sockets modulares, VirtIO nativo, PipeWire audio, Tuned `virtual-host` y Nested KVM optimizado para Fedora 44.
- **`Notas_Virtualizacion_Fedora.md`**: Guía detallada de virtualización en Fedora 44.

### 💻 [IDEs y Editores](./IDE/)
- **`neovim.sh`**: Neovim moderno con LazyVim.
- **`vscode.sh`**: Visual Studio Code nativo (repo oficial de Microsoft con DNF5).
- **`antigravity.sh`**: Google Antigravity Desktop 2.0.
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Suite de CLI y motor IDE de Antigravity.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### 🎮 [Juegos](./Juegos/)
- **`steam.sh`**: Steam nativo vía RPM Fusion / Flatpak con soporte para **Proton-GE**, MangoHud y GameMode.

---

## 🚀 Despliegue Rápido con Just
 
Para ejecutar la instalación según el perfil de tu equipo:

```bash
git clone https://github.com/scaballeroq/Fedora.git
cd Fedora
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Git/*.sh Juegos/*.sh

# Portátil de Desarrollo (AMD Ryzen + Huella + Virtualización):
just setup-laptop-amd

# Sobremesa Multimedia (Intel Haswell / Media Center + Kodi - Sin virtualización):
just setup-media-desktop
```

O ejecutar componentes de forma individual:
```bash
just post-install-amd    # Post-instalación exclusiva para AMD Ryzen
just post-install-intel  # Post-instalación para Intel Media Center
just kodi                # Instala Kodi y complementos de streaming
just plymouth            # Configura y activa el splash screen visual de arranque
just ides                # Instala Neovim, VSCode, Antigravity y OpenCode
just build-kernel        # Compila un kernel Linux nativo x86_64-v3
```
