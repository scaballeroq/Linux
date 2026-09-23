---
sidebar_position: 2
---

# Configuración del Sistema en openSUSE Tumbleweed

Esta guía detalla el proceso de configuración base, repositorio oficial OpenH264, instantáneas Snapper/Btrfs, optimización del kernel y sysctl, personalización de **KDE Plasma 6 (Wayland)**, terminal Kitty, utilidades modernas de consola y panel de administración web aplicados a un sistema **openSUSE Tumbleweed**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup` y el recetario [`justfile`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/justfile).

---

## 1. Post-Instalación Base (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepara el sistema base configurando el repositorio oficial OpenH264 (Cisco), codecs oficiales, ZRAM, PipeWire, Flatpak/Flathub, los patrones de KDE Plasma 6 (`kde_plasma`, `kde`) y la pila gráfica optimizada según el procesador.

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
  - Repositorio oficial OpenH264 (`openSUSE-repos-openh264`, `mozilla-openh264`, `gstreamer-plugin-openh264`).
  - Integración de Flatpak & Flathub para software desacoplado (VLC, OBS).
  - Microcódigo y firmware: `ucode-amd`, `kernel-firmware-amdgpu`, `kernel-firmware-radeon`.
  - Pila Gráfica: `Mesa`, `libvulkan_radeon`, `libva-vdpau-driver`, `radeontop`.
  - Aplicaciones KDE Plasma 6: Dolphin, Kate, Spectacle, Gwenview, Ark, Okular, Discover (con backend Flatpak).
  ```bash
  ./Setup/post-install-amd.sh
  # O usando just:
  just post-install-amd
  ```

- **Perfil Intel Core / Media Center (`post-install-intel.sh`)**:
  Optimizado para equipos Intel Core (Haswell i7-4790 / HD Graphics 4600) dedicados a centro multimedia:
  - Microcódigo: `ucode-intel`, `kernel-firmware-intel`.
  - Aceleración VA-API de vídeo: `intel-vaapi-driver`, `libvulkan_intel`.
  - Multimedia y Streaming: `kodi`, codecs `ffmpeg`, `gstreamer-plugins-*`.
  ```bash
  ./Setup/post-install-intel.sh
  # O usando just:
  just post-install-intel
  ```

---

## 2. Personalización de KDE Plasma 6 (`kde-settings.sh`)

Configura la experiencia de escritorio en **KDE Plasma 6** bajo Wayland:

- **Tema y colores**: Breeze Dark completo (`plasma-apply-lookandfeel -a org.kde.breezedark.desktop`) e integración GTK 3/4 Breeze-Dark.
- **KWin**: Botones de ventana a la derecha (`kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"`).
- **Luz Nocturna (Night Color)**: Activada a 4000K para comodidad visual.
- **Dolphin**: Vista detallada por defecto, paneles ocultos innecesarios, e instalación de KIO Servicemenus para acciones rápidas en clic derecho:
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

## 3. Optimización para Portátiles y Brillo (`laptop-setup.sh`)

Diseñado específicamente para el portátil **HP EliteBook 855 G7** (AMD Ryzen 7 PRO 4750U):

- **KDE Touchpad (`kcminputrc`)**: Tap-to-click activado, desplazamiento natural y aceleración suave.
- **PowerDevil (`powermanagementprofilesrc`)**: Suspensión automática ajustada en batería y corriente.
- **Bluetooth**: `FastConnectable = true` en `/etc/bluetooth/main.conf`.
- **Systemd logind**: Acción `suspend` al cerrar la tapa.
- **Brillo automático al 95%**: Servicio systemd `set-screen-brightness.service` que restaura el brillo de la pantalla tras el arranque.

```bash
just laptop
```

---

## 4. Optimizaciones de Rendimiento y Btrfs/Snapper (`tumbleweed-tuning.sh`)

Ajusta parámetros avanzados del sistema operativo con CLI completa (`--status`, `--sysctl`, `--limits`, `--snapper`, `--baloo`):

- **Sysctl**: ZRAM (`vm.swappiness=150`, `vm.watermark_boost_factor=0`), Inotify aumentado para IDEs (`fs.inotify.max_user_watches=524288`), BBR para TCP.
- **Snapper en Btrfs**: Políticas de retención optimizadas (máximo 10 snapshots de timeline, 3 por hora, 3 diarios) para prevenir que la partición raíz se llene.
- **Baloo (Indexador de KDE)**: Exclusiones automáticas en `~/.config/baloofilerc` para directorios de desarrollo pesados (`node_modules`, `target`, `.git`, `.venv`, `dist`, `build`).

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
- **Nerd Fonts (`fonts.sh`)**: Descarga e instala `JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo` y `Hack` en `~/.local/share/fonts/`.
- **Fastfetch (`fastfetch.sh`)**: Resumen estético del sistema con soporte para openSUSE y KDE Plasma.

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

Endurecimiento del sistema con Firewalld, DNS-over-TLS y reglas para KDE Connect:

- **Firewalld**: Servicios permitidos: `kdeconnect` (descubrimiento y sincronización con móvil), `mdns`, `ssh`.
- **Contenedores y VMs**: Interfaces `podman+` y `virbr0` en zona de confianza (`trusted` / `libvirt`).
- **DNS-over-TLS**: Activado oportunistamente en `systemd-resolved`.
- **Sysctl**: Puertos sin privilegios a partir del 80 (`net.ipv4.ip_unprivileged_port_start=80`).

```bash
just security
```

---

## 8. Multimedia Oficial y Desacoplada (`multimedia.sh`, `yt-dlp-setup.sh`)

- **Multimedia (`multimedia.sh`)**: Repositorio oficial OpenH264 de Cisco, stack oficial de GStreamer y FFmpeg con aceleración por hardware VA-API y reproductores completos vía Flatpak (sin Packman).
- **yt-dlp (`yt-dlp-setup.sh`)**: Stack de descarga con AtomicParsley, aria2 y motor JavaScript Deno instalado vía Mise.

```bash
just multimedia
just multimedia-status
just yt-dlp
```

---

## 9. Navegador Google Chrome (`chrome.sh`) y Steam (`steam.sh`)

- **Google Chrome**: Repositorio RPM oficial de Google e instalación de `google-chrome-stable`.
- **Steam**: Steam nativo, GameMode, MangoHud, Proton-GE y librerías Mesa/Vulkan de 32 bits.

```bash
just chrome
just steam
```

---

## 10. Panel Web Cockpit (`cockpit.sh`)

Administración web del sistema disponible en [https://localhost:9090](https://localhost:9090):

- Módulos incluidos: `cockpit-podman`, `cockpit-machines` (KVM), `cockpit-snapshots` (Snapper Btrfs).
- Gestión por CLI:
  ```bash
  just cockpit         # Iniciar y habilitar
  just cockpit-status  # Diagnóstico del servicio
  ```

---

## Verificación

- **KDE Plasma 6**: Comprueba con `just kde-status` o en `systemsettings`.
- **Terminal y Utilidades**: Abre Kitty (`Ctrl+Alt+T`), verifica Starship y Fastfetch.
- **Rendimiento**: Ejecuta `just tuning-status`.
- **Virtualización**: Ejecuta `just virtualization-status`.
- **Contenedores**: Ejecuta `just podman-status`.
- **Multimedia**: Ejecuta `just multimedia-status`.
