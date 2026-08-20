# 🔧 Manjaro: Configuración de Entorno Manjaro Linux + GNOME

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Manjaro Linux** con el entorno de escritorio **GNOME** (optimizado para estaciones de trabajo y portátiles de desarrollo basadas en Arch Linux).

---

## 📂 Organización del Repositorio

La configuración está estructurada de forma modular para facilitar su mantenimiento y despliegue:

### 🐚 [Zsh.Setup](./Zsh.Setup/) *(Shell por defecto en Manjaro)*
El núcleo de la configuración modular para **ZSH**:
- **`aliases.zsh`**: Atajos comunes para gestión de paquetes (`pacman`, `pamac`), herramientas modernas en Rust (`eza`, `bat`, `duf`, `dust`, `procs`), monitor de kernel y seguridad.
- **`environment.zsh`**: Variables globales de entorno (`PATH`, `EDITOR`, `PAGER`, Mise, Cargo, Go).
- **`functions.zsh`**: Colección de funciones avanzadas de navegación (`mkcd`, `up`), extracción universal (`extract`), discos (`iso2sd`, `format-drive`), multimedia (`ffmpeg`, `ImageMagick`) y herramientas de Manjaro (`manjaro-mirrors-fast`, `pacman-clean-all`, `aur-search`, `pamac-build-aur`, `check-kernel`).
- **`gnome_settings.zsh`**: Atajos para luz nocturna, temas y reinicio de GNOME Shell.
- **`history.zsh`**: Historial ZSH de alto rendimiento (50.000 líneas, sin duplicados y compartido en tiempo real).
- **`options.zsh`**: Opciones de ZSH (`autocd`, corrección, autocompletado interactivo con flechas).
- **`podman-functions.zsh`**: Funciones para gestión ágil de contenedores y Quadlets.
- **`rclone_aliases.zsh`**: Atajos para sincronización en la nube con Google Drive y OneDrive.
- **`yt-dlp_aliases.zsh`**: Descargas multimedia optimizadas con yt-dlp y ffmpeg.

### 🐚 [Bash.Setup](./Bash.Setup/) *(Compatibilidad secundaria con Bash)*
Configuración espejo adaptada para la shell **Bash** cuando se utilice en terminales o sesiones de mantenimiento.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización de GNOME y rendimiento:
- **`post-install.sh`**: Despachador inteligente con detección automática de procesador (AMD vs Intel) y soporte para banderas CLI (`--amd`, `--intel`).
- **`post-install-amd.sh`**: Post-instalación optimizada para procesadores **AMD Ryzen** y gráficos Radeon (`pacman-mirrors`, microcódigo AMD, firmware GPU, RADV, Mesa, ZRAM, PipeWire, GNOME, Pamac, Flatpak).
- **`post-install-intel.sh`**: Post-instalación optimizada para equipos **Intel Core** (Haswell i7-4790 / HD Graphics 4600) dedicados a centro multimedia (microcódigo Intel, driver VA-API `intel-media-driver`, codecs, Kodi, sin virtualización).
- **`gnome-settings.sh`**: Personalización automatizada de GNOME vía GSettings (Luz nocturna a 3500K, reloj 24h, porcentaje de batería, botones de ventana, VRR).
- **`gnome-extensions.sh`**: Instalación automatizada y limpia de 17 extensiones de GNOME Shell con compilación de esquemas (ver [Guía de Extensiones GNOME](./Docs/gnome_extensions_es.md)).
- **`ptyxis.sh`**: Instalación y perfil moderno de Ptyxis (translúcido al 85%, atajo `Ctrl+Alt+T` e integración en Nautilus).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad (85%), efectos blur, tipografía JetBrainsMono Nerd Font e integración con GNOME.
- **`apariencia.sh`**: Instalación de temas e iconos (Adwaita-Dark, Papirus-Dark e integración visual GTK/Qt).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (Touchpad, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, VRR en Wayland).
- **`fingerprint-setup.sh`**: Desbloqueo y autenticación por huella dactilar (`fprintd`, PAM para `sudo`, `polkit-1` y GDM).
- **`hp-printer-setup.sh`**: Impresora HP LaserJet Pro M15w vía USB (CUPS, HPLIP, plugin propietario y `system-config-printer`).
- **`manjaro-tuning.sh`**: Ajustes de Kernel Sysctl (`inotify`, `max_map_count`), descargas paralelas en `pacman.conf` y soporte de `distrobox`.
- **`build-custom-kernel.sh`**: Compilador de Kernel Linux oficial optimizado para arquitectura `x86_64-v3`, latencia a 1000Hz, Preemption dinámica y actualización de initramfs/GRUB.
- **`cockpit.sh`**: Panel de administración web Cockpit con módulos Podman, Virtualización y Almacenamiento.
- **`fastfetch.sh`**: Información estética del sistema al abrir la terminal (Fastfetch).
- **`firefox.sh`**: Instalación de Mozilla Firefox nativo con paquete de idioma español.
- **`fonts.sh`**: Fuentes tipográficas de desarrollo (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`mount-workspace.sh`**: Automontaje seguro de la partición de trabajo `/home/caballero/Workspace`.
- **`seguridad.sh`**: Endurecimiento (hardening) con Firewall UFW.
- **`seguridad-dot.sh`**: DNS-over-TLS mediante `systemd-resolved`.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`), plugins ZSH y Starship prompt.
- **`screensaver-setup.sh`**: Configuración de salvapantallas 3D/Matrix al bloquear la pantalla en GNOME.
- **`plymouth-setup.sh`**: Instalación y configuración de Splash Screen visual de arranque (Plymouth: BGRT UEFI OEM, Manjaro oficial y spinner).
- **`yt-dlp-setup.sh`**: Dependencias multimedia (yt-dlp, ffmpeg y motor JS Deno vía mise).

### 🐳 [Podman](./Podman/)
Ecosistema completo para contenedores Rootless y Systemd Quadlets:
- **Instalación**: `podman-install.sh`, `quadlets-setup.sh`
- **Servicios Compartidos**: Traefik, PostgreSQL, Redis, Keycloak.
- **Templates**: Python-Postgres, Python-Postgres-Redis, Fullstack.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Instalación y configuración de KVM/QEMU, Libvirt, sockets modulares, VirtIO, Nftables y Nested KVM optimizado para Manjaro.
- **`notas_virtualizacion_manjaro.md`**: Guía detallada de virtualización en Manjaro.

### 💻 [IDEs y Editores](./IDE/)
- **`neovim.sh`**: Neovim moderno con LazyVim.
- **`vscode.sh`**: Visual Studio Code nativo (AUR / Pacman).
- **`antigravity.sh`**: Google Antigravity Desktop 2.0.
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Suite de CLI y motor IDE de Antigravity.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### 🎮 [Juegos](./Juegos/)
- **`steam.sh`**: Steam nativo de Manjaro con soporte para **GameMode**, **MangoHud**, **Vulkan** y **Lutris**.

---

## 🚀 Despliegue Rápido con Just
 
Para ejecutar la instalación según el perfil de tu equipo:

```bash
git clone https://github.com/scaballeroq/Manjaro.git
cd Manjaro
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Git/*.sh Juegos/*.sh

# Portátil de Desarrollo (AMD Ryzen + Huella + Virtualización):
just setup-laptop-amd

# Sobremesa Multimedia (Intel Haswell / Media Center + Kodi - Sin virtualización):
just setup-media-desktop
```

O ejecutar componentes de forma individual:
```bash
just post-install-amd    # Post-instalación para AMD Ryzen
just post-install-intel  # Post-instalación para Intel Media Center
just mirrors             # Clasifica y actualiza los espejos más rápidos
just kodi                # Instala Kodi y complementos de streaming
just gnome               # Aplica configuración de GNOME vía GSettings
just extensions          # Instala y compila las 17 extensiones de GNOME
just ptyxis              # Instala y configura la terminal Ptyxis
just plymouth            # Configura y activa el splash screen visual de arranque
just ides                # Instala Neovim, VSCode, Antigravity y OpenCode
just build-kernel        # Compila un kernel Linux nativo x86_64-v3
```

---

## 📚 Documentación Adicional (`Docs/`)

- [**Guía y Catálogo de Funciones ZSH**](./Docs/zsh_es.md)
- [**Guía de Configuración del Sistema**](./Docs/setup_es.md)
- [**Guía de Extensiones GNOME**](./Docs/gnome_extensions_es.md)
- [**Guía de Virtualización KVM/QEMU**](./Docs/virtualizacion_es.md)
- [**Guía de Podman y Quadlets**](./Docs/podman_es.md)
- [**Guía de Entornos de Desarrollo (IDEs)**](./Docs/ide_es.md)
- [**Guía de Lenguajes de Programación**](./Docs/languages_es.md)
- [**Guía de Seguridad y Firewall**](./Docs/seguridad_es.md)
- [**Guía de Git y LazyGit**](./Docs/git_es.md)
