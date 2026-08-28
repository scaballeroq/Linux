---
sidebar_position: 2
---

# Configuración del Sistema en Fedora 44 Workstation (KDE Plasma 6)

Esta guía detalla el proceso de aprovisionamiento base, optimización de hardware, terminal Kitty, administración Cockpit y personalización visual aplicados a un sistema **Fedora 44** con **KDE Plasma 6** sobre **Wayland**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepara el sistema base configurando los repositorios oficiales de Fedora y **RPM Fusion** (free y nonfree), instalando software esencial, ZRAM, PipeWire, la suite de utilidades de KDE Plasma 6 y la pila gráfica/multimedia optimizada según el procesador.

### Scripts disponibles:

- **Despachador Inteligente (`post-install.sh`)**:
  Detecta automáticamente el fabricante del procesador (`AuthenticAMD` vs `GenuineIntel`) o permite selección manual mediante banderas:
  ```bash
  ./Setup/post-install.sh          # Auto-detección inteligente
  ./Setup/post-install.sh --amd    # Forzar modo AMD Ryzen
  ./Setup/post-install.sh --intel  # Forzar modo Intel Core
  ```

- **Perfil AMD Ryzen (`post-install-amd.sh`)**:
  Optimizado para procesadores AMD Ryzen y gráficos Radeon:
  - Microcódigo: `microcode_ctl`
  - Firmware GPU: `linux-firmware`
  - Pila Gráfica: `mesa-dri-drivers`, `mesa-vulkan-drivers` (RADV), `mesa-va-drivers`, `radeontop`.
  ```bash
  just post-install-amd
  ```

- **Perfil Intel Core / Media Center (`post-install-intel.sh`)**:
  Optimizado para equipos de sobremesa Intel Core (especialmente 4ª Gen Haswell i7-4790 con gráficos HD Graphics 4600) para centro multimedia y streaming (Kodi, Netflix, Prime Video):
  - Microcódigo: `microcode_ctl`
  - Aceleración VA-API de vídeo: `libva-intel-driver` (`i965`), `intel-media-driver`, `intel-gpu-tools`.
  - Multimedia y Streaming: `kodi`, `kodi-inputstream-adaptive`, `kodi-inputstream-rtmp`, `kodi-pvr-iptvsimple`, codecs `ffmpeg`, `gstreamer1-plugins-*`.
  - **Sin virtualización KVM**: Excluye herramientas de virtualización y demonios de batería de portátiles para mantener el sistema ligero y enfocado en reproducción de contenidos.
  ```bash
  just post-install-intel
  ```

### Paquetes Comunes Instalados:
- **Compilación**: `@development-tools`, `cmake`, `gcc`, `gcc-c++`, `make`, `kernel-devel`, `kernel-headers`.
- **Memoria**: `zram-generator` (ZRAM con algoritmo ZSTD al 50% de RAM).
- **Audio**: `pipewire`, `pipewire-alsa`, `pipewire-pulseaudio`, `pipewire-jack-audio-connection-kit`, `wireplumber`.
- **Monitorización**: `btop`, `htop`, `inxi`, `plasma-systemmonitor`.
- **Utilidades**: `curl`, `fuse3`, `exfatprogs`, `p7zip`, `p7zip-plugins`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`.
- **Gráficos y Multimedia**: `vlc`, `gimp`, `gparted`, `kate`, `ark`, `kcalc`, `spectacle`.
- **Entorno KDE Plasma 6**: `plasma-desktop`, `dolphin`, `konsole`, `kwriteconfig6`, `plasma-nm`, `plasma-pa`, `tuned-ppd`.
- **Paquetes universales**: `flatpak`, `plasma-discover-flatpak` con repositorio Flathub activo.

---

## 2. Optimización para Portátiles y Batería (`laptop-setup.sh`)

Configura componentes esenciales para portátiles de desarrollo:
- **Persistencia de Brillo al 95%**: Servicio systemd (`persist-screen-brightness.service`) que fija automáticamente el brillo de la pantalla al 95% al arrancar el equipo.
- **Gestión de Energía y Perfiles**: Instala y activa `tuned` junto con `tuned-ppd` para traducción transparente de perfiles (Ahorro / Equilibrado / Rendimiento) en el widget de batería de KDE Plasma.
- **Gráficos Híbridos**: Activa `switcheroo-control` para conmutación dinámica de GPUs.
- **Touchpad en KDE Plasma 6**: Configura pulsar para hacer clic (*tap-to-click*), desplazamiento natural (*natural scroll*) y tiempos de suspensión por inactividad en `kcminputrc`, `touchpadrsrc` y `powerdevilrc`.

```bash
just laptop
# o ./Setup/laptop-setup.sh
```

---

## 3. Terminal Acelerada por GPU (Kitty) (`kitty.sh`)

Instala y configura la terminal Kitty con renderizado por GPU, esquema oscuro Tokyo Night / Catppuccin Mocha, fondo translúcido al 75% con blur suave (32), fuente tipográfica JetBrainsMono Nerd Font y barra de pestañas Powerline.

- **Comandos y Banderas**:
  ```bash
  just kitty
  # O configurar opacidad personalizada (ej: 70%):
  ./Setup/kitty.sh --opacity 0.70
  # O ver ayuda interactiva:
  ./Setup/kitty.sh --help
  ```

- **Atajos en Vivo dentro de Kitty**:
  - `Ctrl+Alt+Arriba` / `Ctrl+Shift+F11`: Aumentar opacidad (+5%).
  - `Ctrl+Alt+Abajo` / `Ctrl+Shift+F10`: Reducir opacidad (-5%).
  - `Ctrl+Alt+0` / `Ctrl+Shift+F9`: Restaurar opacidad por defecto.
  - `Ctrl+Alt+1`: Modo 100% opaco.
  - `Ctrl+Shift+F5`: Recargar configuración en caliente.
  - `Ctrl+Shift+T` / `Ctrl+Shift+Enter`: Nueva pestaña o división manteniendo el directorio actual.
- **Integración con KDE Plasma**:
  - Acción de menú contextual en Dolphin: Clic derecho -> *Abrir en Kitty*.
  - Atajo global del escritorio: `Ctrl+Alt+T` para abrir Kitty inmediatamente.

---

## 4. Optimizaciones Avanzadas de Rendimiento (`fedora-tuning.sh`)

Aplica optimizaciones profundas a nivel de Kernel Sysctl, límites de descriptores de archivos, Systemd y KDE Plasma:

- **Sysctl Kernel (`/etc/sysctl.d/99-fedora-dev.conf`)**:
  - `fs.inotify.max_user_watches=524288` e `instances=1024` (monitorización masiva de ficheros para IDEs y KDE).
  - `fs.file-max=2097152`.
  - `vm.max_map_count=16777216` (soporte para gaming, emuladores y bases de datos).
  - `vm.swappiness=100` (optimizado para compresión ZRAM en Fedora).
  - `vm.vfs_cache_pressure=50` (retención de caché para agilizar `git status` y compilaciones).
  - `net.core.default_qdisc=fq` y `net.ipv4.tcp_congestion_control=bbr` (reducción de latencia TCP).
- **Límites de Usuario (`/etc/security/limits.d/99-dev-limits.conf`)**:
  - `nofile`: soft 524288, hard 1048576.
  - `memlock`: `unlimited`.
- **Systemd Timeouts (`/etc/systemd/system.conf.d/99-fast-shutdown.conf`)**:
  - `DefaultTimeoutStopSec=10s` para evitar bloqueos de 90 segundos al apagar o reiniciar.
- **Indexador KDE Baloo (`baloofilerc`)**:
  - Exclusión automática de directorios pesados (`node_modules`, `.git`, `.venv`, `target`, `vendor`, `.cache`) para eliminar picos de CPU y uso de disco.
- **Contenedores y Entornos Aislados**:
  - Verificación e instalación de `distrobox` y `podman`.

```bash
just tuning
# o ./Setup/fedora-tuning.sh

# Ver diagnóstico actual:
./Setup/fedora-tuning.sh --status
```

---

## 5. Impresora HP LaserJet Pro M15w (`hp-printer-setup.sh`)

Configura la impresora HP LaserJet Pro M15w por USB o red local en Fedora 44:
- Instala CUPS, HPLIP, `plasma-print-manager` y utilidades de impresión.
- Habilita los servicios `cups.service` y `cups.socket`.
- Añade el usuario al grupo `lp` y recarga reglas udev.
- Descarga e instala automáticamente el plugin privativo de HP (`hp-plugin -i -q`).

```bash
just printer
# o ./Setup/hp-printer-setup.sh
```

---

## 6. Entorno de Terminal y Shell (`shell.sh`, `fastfetch.sh`, `fonts.sh`)

- **Utilidades Modernas (`shell.sh`)**: Instala `eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `duf`, `du-dust`, `procs`, `btop`, `jq` y el prompt **Starship** con integración en `~/.bashrc`.
- **Fuentes Tipográficas (`fonts.sh`)**: Instala JetBrainsMono Nerd Font, FiraCode y CascadiaCode en `~/.local/share/fonts`.
- **Fastfetch (`fastfetch.sh`)**: Muestra un resumen visual de hardware, kernel y entorno de escritorio.

```bash
just shell
just fonts
just fastfetch
```

---

## 7. Panel de Administración Web Cockpit (`cockpit.sh`)

Instala y gestiona la consola web Cockpit con activación bajo demanda (`cockpit.socket`) en [https://localhost:9090](https://localhost:9090):
- `cockpit-podman`: Gestión de contenedores, pods e imágenes.
- `cockpit-machines`: Gestión de MVs en KVM/QEMU y libvirt.
- `cockpit-storaged`: Telemetría SMART y particiones de disco.
- `cockpit-networkmanager`: Estado de conexiones e interfaces de red.
- `cockpit-selinux`: Diagnóstico guiado de alertas SELinux.
- `cockpit-files`: Gestor de archivos web.

```bash
just cockpit
# O ver estado del servicio:
./Setup/cockpit.sh status
```

---

## 8. Temas e Integración Visual (`apariencia.sh`)

Aplica y gestiona temas globales, motor de estilos SVG Kvantum (Qt5/Qt6), esquemas de color e iconos en KDE Plasma 6 asegurando coherencia visual con aplicaciones GTK 3/4 y Flatpaks:
- Motor de Widgets Qt: **Kvantum** (con temas SVG como `KvFlatDark`, `KvMojaveDark`, `MateriaDark`) / **Breeze**
- Tema Global KDE: **Breeze Dark** / **Breeze Light**
- Iconos: **Papirus-Dark** / **Breeze-Dark**
- Cursores: `breeze_cursors`

```bash
just apariencia
# Opciones CLI:
./Setup/apariencia.sh --status              # Muestra la apariencia activa (KDE, Kvantum, GTK)
./Setup/apariencia.sh --list                # Lista temas globales, iconos y temas Kvantum
./Setup/apariencia.sh --dark                # Aplica modo oscuro con Kvantum (KvFlatDark + Papirus-Dark)
./Setup/apariencia.sh --light               # Aplica modo claro con Kvantum (KvFlatLight + Papirus)
./Setup/apariencia.sh --kvantum-theme KvArcDark  # Aplica un tema Kvantum personalizado
./Setup/apariencia.sh --breeze-widgets      # Restablece widgets nativos Breeze (sin Kvantum)
```

---

## 9. Splash Screen de Arranque Plymouth (`plymouth-setup.sh`)

Instala y gestiona el splash screen de inicio (Plymouth) en Fedora 44 + KDE Plasma con soporte para temas `breeze`, `bgrt` y `spinner`, regenerando automáticamente los initramfs con Dracut:

```bash
just plymouth
# Opciones CLI:
./Setup/plymouth-setup.sh --list     # Lista temas disponibles
./Setup/plymouth-setup.sh --preview  # Previsualiza el splash screen
./Setup/plymouth-setup.sh --disable  # Desactiva el splash visual
./Setup/plymouth-setup.sh breeze     # Aplica tema Breeze
```

---

## 10. Stack Multimedia YT-DLP (`yt-dlp-setup.sh`)

Instalación automatizada del ecosistema completo de descarga y procesamiento de vídeo:
- Paquetes: `yt-dlp`, `ffmpeg`, `atomicparsley`, acelerador multiproceso `aria2` y runtime JavaScript `deno`.
- Configuración en `~/.config/yt-dlp/config`: Integración con SponsorBlock, extracción de subtítulos, nombrado inteligente y conversión de metadatos.
- Suite de alias en `Bash.Setup/yt-dlp_aliases.sh`.

```bash
just yt-dlp
# o ./Setup/yt-dlp-setup.sh
```
