---
sidebar_position: 2
---

# Configuración del Sistema en Fedora 44 Workstation

Esta guía detalla el proceso de configuración base, optimización de la terminal, instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema **Fedora 44 Workstation** (con gestión de paquetes DNF5) y **GNOME** (Modo Oscuro).

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base optimizando repositorios, instalando software esencial y configurando la aceleración por hardware. El script detecta automáticamente el procesador (AMD Ryzen vs Intel Core) y ejecuta la configuración correspondiente.

1. **Auto-detección de CPU**:
   ```bash
   CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
   ```
   - `AuthenticAMD` → Ejecuta `post-install-amd.sh`
   - `GenuineIntel` → Ejecuta `post-install-intel.sh`

2. **Optimización de DNF5**:
   - `max_parallel_downloads=10`
   - `fastestmirror=True`
   - `clean_requirements_on_remove=True`

3. **Software Esencial**:
   Instala utilidades de compilación, monitorización de sistema y compatibilidad:
   - Compilación: `@development-tools`, `cmake`, `gcc-c++`
   - Monitorización: `btop`, `htop`, `inxi`
   - Utilidades: `curl`, `fuse`, `fuse3`, `exfatprogs`, `p7zip`, `p7zip-plugins`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`
   - Paquetes universales: `flatpak` (con repositorio Flathub activado)

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   # AMD
   sudo dnf5 install -y mesa-va-drivers mesa-vdpau-drivers vulkan-loader mesa-vulkan-drivers
   # Intel
   sudo dnf5 install -y libva-intel-driver intel-media-driver libvdpau-va-gl vulkan-loader mesa-vulkan-drivers
   ```

5. **ZRAM**: Configurado con algoritmo ZSTD integrado nativamente en Fedora.

---

## 2. Entorno de Terminal y Shell (`shell.sh`, `starship.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo y permite gestionar de forma opcional el prompt interactivo Starship.

### Utilidades Modernas de Terminal (`shell.sh`)
Se instalan alternativas modernas a comandos clásicos y se activa la integración modular en Bash (por defecto) y Zsh (si existe `~/.zshrc`) junto a `zoxide`:
- `eza` (reemplazo de `ls`)
- `bat` (reemplazo de `cat` con sintaxis coloreada)
- `fzf` (buscador difuso)
- `zoxide` (reemplazo inteligente de `cd`)
- `ripgrep` (`rg`, búsqueda rápida de texto)
- `fd` (reemplazo simple de `find`)
- `duf` (reemplazo visual de `df`)
- `dust` (visualizador de espacio en disco)
- `procs` (reemplazo moderno de `ps`)
- `btop` (monitor de recursos)

### Prompt Starship Opcional (`starship.sh`)
Permite activar o desactivar fácilmente el prompt **Starship** en Bash (y en Zsh si existe `~/.zshrc`):
```bash
# Instalar y activar Starship
./Setup/starship.sh

# Desactivar y restaurar el prompt nativo
./Setup/starship.sh --disable

# Ver estado actual
./Setup/starship.sh --status
```
La configuración de Starship se gestiona mediante `Setup/starship.toml` en `~/.config/starship.toml`.

### Fuentes de Desarrollo (Nerd Fonts)
Descarga e instala fuentes optimizadas para programación y símbolos de terminal (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo` y `Hack`):
```bash
# Descarga y extracción automatizada en ~/.local/share/fonts
# Actualización de la caché de fuentes:
fc-cache -f
```

### Fastfetch
Muestra información del sistema de manera visual y estética al abrir la terminal. Instala `fastfetch` y copia la plantilla de configuración `config.jsonc` a `~/.config/fastfetch/config.jsonc`.

---

## 3. Terminal Kitty (`kitty.sh`)

Instala y optimiza **Kitty**, un emulador de terminal moderno acelerado por GPU, con integración en GNOME y Nautilus.

1. **Instalación**:
   ```bash
   sudo dnf5 install -y kitty
   ```

2. **Configuración Estética**:
   - Opacidad al 75% con desenfoque (blur 32)
   - Tema de colores Catppuccin Mocha / Tokyo Night
   - Fuente JetBrainsMono Nerd Font
   - Tab bar con estilo powerline

3. **Integración con GNOME**:
   - Terminal predeterminado de GNOME
   - Atajo global Ctrl+Alt+T
   - Menú contextual en Nautilus: Scripts -> "Abrir en Kitty"

4. **Atajos de teclado**:
   - `Ctrl+Alt+Arriba/Abajo`: Ajustar opacidad
   - `Ctrl+Shift+F5`: Recargar configuración
   - `Ctrl+Shift+T`: Nueva pestaña en mismo directorio

---

## 4. Seguridad (`seguridad.sh`)

Endurecimiento del sistema con Firewalld exclusivo, DNS-over-TLS y soporte Podman/KVM.

- **Firewalld**: Zona `home` por defecto con mdns, ssh (`trusted` para Podman, `libvirt` para virbr0; UFW eliminado)
- **DNS-over-TLS**: Opportunistic con systemd-resolved
- **Kernel hardening**: dmesg_restrict, kptr_restrict, syncookies
- **Podman rootless**: user namespaces y puertos unprivileged (>=80) habilitados

---

## 5. Panel de Administración Cockpit (`cockpit.sh`)

Instala Cockpit para administrar el sistema mediante una interfaz web.

```bash
sudo dnf5 install -y cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```

Acceso: [https://localhost:9090](https://localhost:9090)

---

## 6. Soporte Multimedia y yt-dlp (`yt-dlp-setup.sh`)

Configura las herramientas para descargas de video y procesamiento de audio digital.

1. **Instalación de yt-dlp y FFMPEG**:
   ```bash
   sudo dnf5 install -y yt-dlp ffmpeg
   ```

2. **Motor de descifrado rápido JS**:
   Instala Deno mediante `mise` para permitir que `yt-dlp` procese la lógica JavaScript de plataformas de streaming.

---

## 7. Extensiones de GNOME Shell (`gnome-extensions.sh`)

Instala y gestiona las extensiones oficiales desde los repositorios de Fedora 44 Workstation (`dnf5`):

1. **Herramientas y Extensiones incluidas**:
   - `extension-manager`: Aplicación gráfica nativa para buscar, explorar y administrar extensiones de GNOME Shell.
   - `gnome-shell-extension-dash-to-dock`: Dock visible fuera del overview con autohide.
   - `gnome-shell-extension-appindicator`: Soporte de bandeja del sistema para aplicaciones.
   - `gnome-shell-extension-caffeine`: Desactivador de suspensión y bloqueo desde la barra superior.
   - `gnome-shell-extension-weather-oclock`: Información meteorológica integrada con el reloj central.
   - `gnome-shell-extension-bing-wallpaper`: Fondos de pantalla dinámicos diarios de Bing.
   - `gnome-shell-extension-blur-my-shell`: Efecto de desenfoque moderno en menús, panel y overview.
   - `gnome-shell-extension-logo-menu`: Menú de acceso rápido con icono de distribución (integrado con Extension Manager).

2. **Uso del script**:
   ```bash
   # Instalar y activar todas las extensiones
   ./Setup/gnome-extensions.sh

   # Ver estado de activación
   ./Setup/gnome-extensions.sh --status

   # Activar o desactivar en lote
   ./Setup/gnome-extensions.sh --enable
   ./Setup/gnome-extensions.sh --disable
   ```

---

## 8. Multimedia Completo y RPM Fusion (`multimedia.sh`)

Configura todos los repositorios multimedia privativos de **RPM Fusion** (Free, Nonfree y Tainted) y sustituye la versión recortada de FFmpeg por la completa con todos los codecs y aceleración por hardware:

1. **Repositorios habilitados**:
   - `rpmfusion-free-release` y `rpmfusion-nonfree-release`
   - `rpmfusion-free-release-tainted` y `rpmfusion-nonfree-release-tainted`
   - Repositorio OpenH264 de Cisco

2. **Stack de Codecs y Aceleración HW**:
   - **FFmpeg Full**: `dnf5 swap -y ffmpeg-free ffmpeg --allowerasing`
   - **GStreamer**: `gstreamer1-plugins-bad-freeworld`, `gstreamer1-plugins-ugly`, `gstreamer1-libav`, `gstreamer1-vaapi`
   - **Drivers VA-API / VDPAU freeworld**: `mesa-va-drivers-freeworld`, `mesa-vdpau-drivers-freeworld`
   - **Codecs y formatos**: `libdvdcss`, `lame`, `faac`, `faad2`, `x264`, `x265`, `libde265`

3. **Uso**:
   ```bash
   ./Setup/multimedia.sh          # Instalación y swap completo
   ./Setup/multimedia.sh --status # Comprueba repositorios y codecs instalados
   ```

---

## 9. Navegador Google Chrome (`chrome.sh`)

Activa el repositorio oficial de Google para Fedora e instala la versión nativa estable de Google Chrome:

1. **Configuración de repositorio**:
   - Descarga e importa la clave pública oficial de Google (`RPM-GPG-KEY-google-chrome`).
   - Configura el repositorio `/etc/yum.repos.d/google-chrome.repo`.

2. **Instalación de paquete**:
   - Instala `google-chrome-stable`.

3. **Uso**:
   ```bash
   ./Setup/chrome.sh          # Instala repositorio y navegador
   ./Setup/chrome.sh --status # Verifica estado del repositorio y binario
   ```

---

## 10. Steam y Juegos (`steam.sh`)

Prepara el sistema para videojuegos nativos de PC y Proton/Wine mediante Steam:

1. **Repositorios y componentes**:
   - Repositorio `rpmfusion-nonfree-steam` activado.
   - Paquetes de ejecución: `steam`, `gamemode`, `mangohud`.
   - **Librerías Vulkan de 32 bits**: `mesa-vulkan-drivers.i686` y `mesa-dri-drivers.i686` para garantizar compatibilidad con títulos x86 de 32 bits.

2. **Uso**:
   ```bash
   ./Setup/steam.sh          # Instala Steam y componentes 32-bit
   ./Setup/steam.sh --status # Verifica estado de instalación
   ```

---

## Verificación

Para comprobar que los componentes principales se instalaron y configuraron correctamente:

- **Terminal y Utilidades**: Abre una nueva terminal. Deberías ver el prompt de **Starship** cargado y el resumen de **Fastfetch** en pantalla. Prueba utilidades ejecutando `eza` o `bat --version`.
- **Extensiones GNOME**: Ejecuta `./Setup/gnome-extensions.sh --status` o `gnome-extensions list --enabled`.
- **Kitty**: Ejecuta `kitty --version`. Debería abrirse con opacidad y tema Catppuccin.
- **Cockpit**: Abre tu navegador e ingresa a [https://localhost:9090](https://localhost:9090). Inicia sesión con tus credenciales de usuario del sistema.
- **Firewalld**: Verifica con `sudo firewall-cmd --state`.
- **Multimedia y Codecs**: Ejecuta `./Setup/multimedia.sh --status` y prueba `ffmpeg -codecs | grep -E "hevc|h264"`.
- **Google Chrome**: Ejecuta `./Setup/chrome.sh --status` o `google-chrome --version`.
- **Steam**: Ejecuta `./Setup/steam.sh --status` o `steam`.

