---
sidebar_position: 2
---

# Configuración del Sistema en CachyOS Workstation

Esta guía detalla el proceso de configuración base, optimización de la terminal, instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema **CachyOS Workstation** (con arquitectura **x86-64-v3**, kernel BORE / sched-ext, gestión de paquetes **Pacman / Paru**) y **GNOME** (Modo Oscuro).

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base optimizando espejos de red, instalando software esencial y configurando la aceleración por hardware. El script detecta automáticamente el procesador (AMD Ryzen vs Intel Core) y ejecuta la configuración correspondiente.

1. **Auto-detección de CPU**:
   ```bash
   CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
   ```
   - `AuthenticAMD` → Ejecuta `post-install-amd.sh`
   - `GenuineIntel` → Ejecuta `post-install-intel.sh`

2. **Optimización de Espejos y Pacman**:
   - Clasificación de espejos con `cachyos-rate-mirrors` para máxima velocidad.
   - Activación de descargas paralelas y coloreado en `/etc/pacman.conf`.

3. **Software Esencial**:
   Instala utilidades de compilación, monitorización de sistema y compatibilidad:
   - Compilación: `base-devel`, `cmake`
   - Monitorización: `btop`, `htop`, `inxi`
   - Utilidades: `curl`, `fuse3`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`
   - Paquetes universales: `flatpak` (con repositorio Flathub activado)

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   # AMD (Radeon Graphics / Vega 8)
   sudo pacman -S --needed mesa libva-mesa-driver vulkan-radeon libva-utils vdpauinfo
   # Intel
   sudo pacman -S --needed intel-media-driver vulkan-intel libva-utils
   ```

5. **ZRAM**: Configurado con algoritmo ZSTD mediante `zram-generator` al 50% de RAM.

---

## 2. Entorno de Terminal y Shell (`shell.sh`, `starship.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo y permite gestionar el prompt interactivo Starship y Fastfetch.

### Utilidades Modernas de Terminal (`shell.sh`)
Se instalan alternativas modernas a comandos clásicos y se activa la integración modular en Bash (por defecto) y Zsh (si existe `~/.zshrc`) junto a `zoxide`:
- `eza` (reemplazo de `ls`)
- `bat` (reemplazo de `cat` con sintaxis coloreada)
- `fzf` (buscador difuso)
- `zoxide` (reemplazo inteligente de `cd`)
- `ripgrep` (`rg`, búsqueda rápida de texto)
- `fd` (reemplazo simple de `find`)
- `btop` y `jq`

---

## 3. Terminales Modernas (`kitty.sh`, `ghostty.sh`, `ptyxis.sh`)

Permite desplegar tres alternativas modernas de terminal aceleradas por GPU e integradas con GNOME Shell y Nautilus:
- **Kitty**: Aceleración por GPU, opacidad al 75%, blur 32 y paleta Catppuccin Mocha.
- **Ghostty**: Rendimiento nativo en Wayland con renderizado GTK4 / Libadwaita.
- **Ptyxis**: Terminal nativa de GNOME orientada a contenedores Podman con pestañas de colores.

---

## 4. Ajustes del Sistema y GNOME (`laptop-setup.sh`, `gnome-settings.sh`, `apariencia.sh`)

- **Laptop AMD**: Configura `power-profiles-daemon`, telemetría de batería en Wh, AMD P-State EPP y comportamiento de tapa en modo docked sin suspensión accidental.
- **GNOME Settings**: Tema oscuro por defecto, reloj de 24 horas, aceleración de ventanas Wayland y extensiones para Nautilus con `python-nautilus`.
- **Apariencia**: Tema `adw-gtk3-dark`, iconos `Papirus-Dark` y cursores `Bibata-Modern-Classic`.

---

## 5. Panel de Administración Cockpit (`cockpit.sh`)

Instala Cockpit para administrar el sistema mediante una interfaz web:

```bash
sudo pacman -S --needed --noconfirm cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```

Acceso: [https://localhost:9090](https://localhost:9090)

---

## 6. Soporte Multimedia y yt-dlp (`yt-dlp-setup.sh`)

Configura las herramientas para descargas de video y procesamiento de audio digital:

1. **Instalación de yt-dlp y FFmpeg**:
   ```bash
   sudo pacman -S --needed --noconfirm yt-dlp ffmpeg atomicparsley aria2 python-mutagen
   ```

2. **Motor de descifrado rápido JS**:
   Instala Deno mediante `mise` para permitir que `yt-dlp` procese la lógica JavaScript de plataformas de streaming.

---

## 7. Extensiones de GNOME Shell (`gnome-extensions.sh`)

Instala y gestiona extensiones modernas de GNOME Shell:
- `extension-manager`: Aplicación gráfica nativa para buscar, explorar y administrar extensiones.
- Dash to Dock, AppIndicator, Caffeine, Blur my Shell, Tiling Shell y GSConnect.

---

## 8. Multimedia Completo (`multimedia.sh`)

CachyOS incluye de serie paquetes multimedia completos sin restricciones artificiales de licencias:
- **FFmpeg Full**: Con aceleración VA-API y soporte de todos los códecs comerciales.
- **GStreamer**: Plugins base, good, bad y ugly completos.
- **Miniaturas**: `ffmpegthumbnailer` para generación fluida de miniaturas en Nautilus.
- **Reproductores**: Reproductores nativos en Wayland (Showtime, Celluloid, VLC, MPV con aceleración por hardware).

---

## 9. Navegador Google Chrome (`chrome.sh`)

Despliega Google Chrome nativo y precompilado desde **Chaotic-AUR** con flags de aceleración por hardware en Wayland:
- Instalación directa mediante `pacman` (desde repositorio precompilado `[chaotic-aur]`) o `paru` con fallback a Flatpak.
- Configuración de flags en `~/.config/chrome-flags.conf` (`--ozone-platform-hint=auto`, `--enable-features=VaapiVideoDecodeLinuxGL`).

---

## 10. Steam y Juegos (`steam.sh`)

Prepara el sistema para videojuegos nativos y capas Proton/Wine mediante Steam:
- Soporte multilib de 32 bits activado (`lib32-vulkan-radeon`, `lib32-mesa`, `lib32-pipewire`).
- Paquetes de ejecución: `steam`, `gamemode`, `mangohud`.
- Capa de compatibilidad Proton-GE vía Flathub.

---

## 11. Catálogo Desacoplado Flatpak (`flatpak.sh`)

Permite gestionar aplicaciones de usuario en sandbox sin alterar las dependencias base de CachyOS:
- Repositorio Flathub oficial configurado a nivel de sistema.
- Catálogo modular: Flatseal, Podman Desktop, Warehouse, VLC, OBS Studio, LocalSend, etc.
- Opciones: `--status`, `--update`, `--clean`, `--all`, `--core`, `--multimedia`.

---

## Verificación

Para comprobar que los componentes principales se instalaron y configuraron correctamente:
- **Terminal y Utilidades**: Abre una nueva terminal. Deberías ver el prompt de **Starship** cargado y el resumen de **Fastfetch** en pantalla (`eza`, `bat --version`).
- **Extensiones GNOME**: Ejecuta `./Setup/gnome-extensions.sh --status`.
- **Cockpit**: Abre tu navegador e ingresa a [https://localhost:9090](https://localhost:9090).
- **Firewalld**: Verifica con `sudo firewall-cmd --state`.
- **Aceleración Gráfica**: Ejecuta `vainfo` para verificar que la aceleración VA-API de la Radeon Vega 8 esté activa.
