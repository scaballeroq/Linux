---
sidebar_position: 2
---

# Configuración del Sistema en Debian Testing (KDE Plasma 6)

Esta guía detalla el proceso de configuración base, microcódigo, aceleración gráfica por hardware, optimización del kernel y sysctl, personalización de **KDE Plasma 6 (Wayland)**, terminal Kitty, utilidades modernas de consola y panel de administración web aplicados a un sistema **Debian Testing (Trixie/Sid)**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup` y el recetario [`justfile`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/justfile).

---

## 1. Post-Instalación Base (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepara el sistema base configurando los repositorios oficiales de Debian Testing (`main`, `contrib`, `non-free`, `non-free-firmware`), ZRAM, PipeWire, Flatpak/Flathub, la suite de KDE Plasma 6 (`kde-plasma-desktop`, `plasma-workspace`) y la pila gráfica optimizada según el procesador.

### Scripts disponibles:

- **Despachador Inteligente (`post-install.sh`)**:
  Detecta automáticamente el procesador (`AuthenticAMD` vs `GenuineIntel`) o permite selección por banderas:
  ```bash
  ./Setup/post-install.sh          # Auto-detección
  ./Setup/post-install.sh --amd    # Forzar modo AMD
  ./Setup/post-install.sh --intel  # Forzar modo Intel
  ```

- **Perfil AMD Ryzen (`post-install-amd.sh`)**:
  Optimizado para procesadores AMD Ryzen y gráficos Radeon:
  - Firmware y microcódigo: `firmware-amd-graphics`, `amd64-microcode`.
  - Pila Gráfica: `mesa-va-drivers`, `mesa-vulkan-drivers`, `radeontop`.
  - Integración de Flatpak & Flathub para software desacoplado (VLC, OBS).
  - Aplicaciones KDE Plasma 6: Dolphin, Kate, Spectacle, Gwenview, Ark, Okular, Discover (con backend Flatpak).
  ```bash
  ./Setup/post-install-amd.sh
  # O usando just:
  just post-install-amd
  ```

- **Perfil Intel Core / Media Center (`post-install-intel.sh`)**:
  Optimizado para equipos Intel Core (Haswell i7-4790 / HD Graphics 4600) dedicados a centro multimedia:
  - Microcódigo: `intel-microcode`, `firmware-misc-nonfree`.
  - Aceleración VA-API de vídeo: `intel-media-va-driver`, `i965-va-driver-shaders`, `mesa-vulkan-drivers`.
  - Multimedia y Streaming: `kodi`, codecs `ffmpeg`, `gstreamer1.0-plugins-*`.
  ```bash
  ./Setup/post-install-intel.sh
  # O usando just:
  just post-install-intel
  ```

---

## 2. Personalización de KDE Plasma 6 (`kde-settings.sh`)

Configura la experiencia de escritorio en **KDE Plasma 6** bajo Wayland:

- **Tema y colores**: Breeze Dark completo (`plasma-apply-lookandfeel -a org.kde.breezedark.desktop`) e integración GTK 3/4 Breeze-Dark.
- **KWin**: Botones de ventana a la derecha (`ButtonsOnRight "IAX"`).
- **Luz Nocturna (Night Color)**: Activada a 4000K para comodidad visual.
- **Dolphin**: Vista detallada por defecto, paneles optimizados, e instalación de KIO Servicemenus para acciones rápidas en clic derecho:
  - "Abrir en Kitty" (`~/.local/share/kio/servicemenus/open-in-kitty.desktop`).
  - "Abrir en Antigravity" (`~/.local/share/kio/servicemenus/open-in-antigravity.desktop`).
  - "Abrir en Antigravity IDE" (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).
- **Atajos**: `Ctrl+Alt+T` configurado globalmente para abrir Kitty.

```bash
# Aplicar configuración completa de KDE Plasma 6
just kde-setup
# o ./Setup/kde-settings.sh

# Alternar a tema oscuro o claro
just kde-theme-dark
just kde-theme-light

# Diagnóstico de configuración
just kde-status
```

---

## 3. Optimización para Portátiles (`laptop-setup.sh`)

Diseñado específicamente para portátiles de desarrollo (como HP EliteBook con AMD Ryzen 7 PRO):

- **Power Profiles Daemon**: Integración nativa con el applet de batería de KDE Plasma 6 (perfiles Rendimiento, Equilibrado y Ahorro).
- **KDE Touchpad (Wayland)**: Tap-to-click nativo por defecto en Plasma 6 y desplazamiento natural configurado dinámicamente vía KWin D-Bus y `kcminputrc`.
- **PowerDevil (`powerdevilrc`)**: Suspensión automática ajustada para corriente (AC deshabilitada) y batería (30 min).
- **Cierre de Tapa Inteligente**: Inhibe la suspensión si hay monitores externos conectados (docking station) tanto en `logind` como en `powerdevilrc`.
- **Bluetooth (BlueZ)**: `Experimental = true` para reporte de batería de dispositivos en BlueDevil y `FastConnectable = true` para reconexión rápida.

```bash
just laptop
```

### Autenticación por Huella Dactilar (`fingerprint-setup.sh`)

Configura el lector biométrico USB Synaptics mediante `fprintd` y el módulo oficial `pam_fprintd.so` a través de `pam-auth-update`:

```bash
just fingerprint          # Habilita el módulo en PAM
just fingerprint-status   # Diagnóstico de sensor, PAM y huellas registradas
just fingerprint --enroll # Registra una huella en terminal
just fingerprint --verify # Prueba el sensor biométrico
just fingerprint-sddm-bypass # Optimiza SDDM para contraseña sin retardo y desbloqueo de KWallet
```

---

## 4. Optimizaciones de Rendimiento (`debian-tuning.sh`)

Ajusta parámetros avanzados del sistema operativo con CLI completa (`--status`, `--sysctl`, `--limits`, `--baloo`, `--zram`):

- **Sysctl**: ZRAM (`vm.swappiness=180`, `vm.watermark_boost_factor=0`), Inotify aumentado para IDEs (`fs.inotify.max_user_watches=1048576`), BBR para TCP.
- **Límites de Sistema**: Descriptores de archivos aumentados a 1,048,576 para compilaciones pesadas y contenedores.
- **Systemd**: `DefaultTasksMax=infinity` y `DefaultTimeoutStopSec=10s`.
- **Baloo (Indexador de KDE)**: Exclusiones automáticas en `~/.config/baloofilerc` para directorios de desarrollo pesados (`node_modules`, `target`, `.git`, `.venv`, `dist`, `build`, `Workspace`).

```bash
just tuning
just tuning-status
```

---

## 5. Entorno de Terminal y Shell (`shell.sh`, `starship.sh`, `fastfetch.sh`, `fonts.sh`)

Instala utilidades modernas de consola escritas en Rust/Go y activa la integración modular en `~/.bashrc.d/`:

- **Herramientas**: `eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`.
- **Starship Prompt (`starship.sh`)**:
  ```bash
  just starship          # Instalar y activar
  just starship-disable  # Desactivar y restaurar prompt nativo
  just starship-status   # Ver estado actual
  ```
- **Nerd Fonts (`fonts.sh`)**: Gestión e instalación optimizada de `JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo` y `Hack` en `~/.local/share/fonts/`. Admite diagnóstico (`just fonts-status`), listado (`--list`), limpieza (`--clean`) o instalación individual (`./Setup/fonts.sh CascadiaCode`).
- **Fastfetch (`fastfetch.sh`)**: Resumen estético del sistema con temas `debian` (espiral oficial) y `compact` (FastCat). Admite diagnóstico (`just fastfetch-status`), cambio de tema (`--theme debian|compact`) y comparación (`--diff`).

---

## 6. Terminal Kitty (`kitty.sh`)

Instala y optimiza **Kitty**, emulador acelerado por GPU con tema Catppuccin Mocha:

- Opacidad al 75% con desenfoque (`blur 32`).
- Fuente JetBrainsMono Nerd Font.
- Atajo global en KDE `Ctrl+Alt+T`.
- KIO Servicemenu en Dolphin para abrir directorios directamente en Kitty.

```bash
just kitty
```

---

## 7. Seguridad y Cortafuegos (`seguridad.sh`)

Endurecimiento del sistema con Firewalld / UFW, optimización de red para desarrollo y reglas para KDE Connect:

- **Cortafuegos**: Servicios permitidos: `kdeconnect` (descubrimiento y sincronización con móvil), `mdns`, `ssh`, `cockpit` (9090).
- **Contenedores y VMs**: Interfaces `podman+` y `virbr0` en zona de confianza (`trusted`).
- **Sysctl**: Puertos sin privilegios a partir del 80 (`net.ipv4.ip_unprivileged_port_start=80`), IP forwarding y namespaces de usuario.
- **Red local doméstica**: Sin Fail2ban ni MAC randomization forzada para garantizar IPs estables en el router.

```bash
just security
```

---

## 8. Multimedia Oficial y Desacoplada (`multimedia.sh`, `yt-dlp-setup.sh`)

- **Multimedia (`multimedia.sh`)**: Paquetes oficiales de Debian Testing, stack completo de GStreamer y FFmpeg con aceleración por hardware VA-API y reproductores desacoplados vía Flatpak (sin dependencias conflictivas de deb-multimedia).
- **yt-dlp (`yt-dlp-setup.sh`)**: Stack de descarga con mutagen, FFmpeg, aria2 y motor JavaScript Deno integrado vía Mise.

```bash
just multimedia
just multimedia-status
just yt-dlp
```

---

## 9. Navegador Google Chrome (`chrome.sh`) y Steam (`steam.sh`)

- **Google Chrome**: Repositorio APT oficial de Google con clave dearmored e instalación de `google-chrome-stable`.
- **Steam**: Steam nativo mediante multiarch `i386`, GameMode, MangoHud y Proton-GE.

```bash
just chrome
just steam
```

---

## 10. Panel Web Cockpit y Cliente de Escritorio (`cockpit.sh`)

Administración del sistema disponible vía web y a través del cliente de escritorio nativo:

- **Acceso web**: [https://localhost:9090](https://localhost:9090)
- **Módulos incluidos**: `cockpit-podman`, `cockpit-machines` (KVM), `cockpit-storaged`, `cockpit-networkmanager`, `cockpit-packagekit`, `cockpit-sosreport`.
- **Gestión por CLI**:
  ```bash
  just cockpit                   # Verificación y estado general (idempotente)
  just cockpit-status            # Diagnóstico detallado del socket, puerto y módulos
  just cockpit-open              # Abrir en el navegador web
  just cockpit-client            # Lanzar cliente de escritorio
  ```

---

## Verificación

- **KDE Plasma 6**: Comprueba con `just kde-status` o en `systemsettings`.
- **Terminal y Utilidades**: Abre Kitty (`Ctrl+Alt+T`), verifica Starship y Fastfetch.
- **Rendimiento**: Ejecuta `just tuning-status`.
- **Virtualización**: Ejecuta `just virtualization-status`.
- **Contenedores**: Ejecuta `just podman-status`.
- **Multimedia**: Ejecuta `just multimedia-status`.
