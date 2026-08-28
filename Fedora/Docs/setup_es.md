---
sidebar_position: 2
---

# Configuración del Sistema en Fedora 44 Workstation (FedoraTesting)

Esta guía detalla el proceso de configuración base, automontaje de partición de trabajo, compilación de kernel nativo `x86_64-v3`, terminal Kitty y panel de administración web aplicados a un sistema **Fedora 44** con **KDE Plasma**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepara el sistema base configurando repositorios oficiales adicionales (`contrib`, `non-free`, `non-free-firmware`), instalando software esencial, ZRAM, PipeWire, la suite GNOME y la pila gráfica/multimedia optimizada según el fabricante de la CPU/GPU.

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
  - Microcódigo: `amd64-microcode`
  - Firmware GPU: `firmware-amd-graphics`
  - Pila Gráfica: `mesa-va-drivers`, `mesa-vdpau-drivers`, `mesa-vulkan-drivers` (RADV), `radeontop`, `va-driver-all`.
  ```bash
  ./Setup/post-install-amd.sh
  # O usando just:
  just post-install-amd
  ```

- **Perfil Intel Core / Media Center (`post-install-intel.sh`)**:
  Optimizado para equipos de sobremesa con procesadores Intel Core (especialmente 4ª Gen Haswell i7-4790 y gráficos integrados Intel HD Graphics 4600) dedicados a centro multimedia y streaming (Kodi, Netflix, Prime Video):
  - Microcódigo: `intel-microcode`
  - Aceleración VA-API de vídeo: `i965-va-driver`, `i965-va-driver-shaders`, `intel-media-va-driver`, `intel-gpu-tools` (`intel_gpu_top`).
  - Multimedia y Streaming: `kodi`, `kodi-inputstream-addnf5ive`, `kodi-inputstream-rtmp`, `kodi-pvr-iptvsimple`, codecs `ffmpeg`, `libavcodec-extra`, `gstreamer1.0-*`.
  - **Sin virtualización KVM**: Excluye herramientas de virtualización y optimizaciones de batería de portátiles para mantener el sistema ligero y enfocado en multimedia.
  ```bash
  ./Setup/post-install-intel.sh
  # O usando just:
  just post-install-intel
  ```

### Paquetes Comunes Instalados:
- **Compilación**: `build-essential`, `cmake`
- **Memoria**: `zram-tools` (ZRAM con ZSTD al 50%)
- **Audio**: `pipewire`, `pipewire-alsa`, `pipewire-pulse`, `pipewire-jack`, `wireplumber`
- **Monitorización**: `btop`, `htop`, `inxi`, `gnome-system-monitor`
- **Utilidades**: `curl`, `fuse3`, `exfatprogs`, `p7zip-full`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
- **Gráficos y Multimedia**: `vlc`, `gimp`, `gparted`, `evince`, `seahorse`
- **Entorno GNOME**: `gnome-core`, `gnome-shell`, `gnome-control-center`, `gnome-tweaks`, `nautilus`, `file-roller`, `gnome-text-editor`, `gnome-calculator`, `gnome-disk-utility`, `power-profiles-daemon`, `ffmpegthumbnailer`
- **Paquetes universales**: `flatpak`, `gnome-software`, `gnome-software-plugin-flatpak` con repositorio Flathub activo.

---

## 2. Automontaje de Partición Workspace (`mount-workspace.sh`)

Monta automáticamente la partición de datos `/home/caballero/Workspace` mediante `/etc/fstab` usando su UUID.
Utiliza las opciones `defaults,noatime,nofail` para evitar cualquier bloqueo del sistema durante el arranque si la partición secundaria estuviese desconectada.

```bash
./Setup/mount-workspace.sh
# O usando just:
just workspace
```

---

## 3. Compilador de Kernel Linux NATIVO x86_64-v3 (`build-custom-kernel.sh`)

Script que consulta la API de `kernel.org` (`https://www.kernel.org/releases.json`) para descargar la última versión estable oficial del Kernel Linux, compilar paquetes `.rpm` nativos con optimizaciones de arquitectura `x86_64-v3`, latencia a **1000Hz** y **Preemption Dinámica**.

```bash
./Setup/build-custom-kernel.sh
# O usando just:
just build-kernel
```

---

---

## 4. Optimización para Portátiles y Brillo al 95% (`laptop-setup.sh`)

Configura componentes esenciales para portátiles:
- **Brillo automático al 95% al encender**: Registra un servicio systemd (`persist-screen-brightness.service`) que fija el brillo de pantalla al 95% al iniciar el sistema.
- **Gestión de energía**: Instala y activa `power-profiles-daemon` y `switcheroo-control` (gráficos híbridos).
- **Herramientas de brillo**: Instala `brightnessctl` y utilidades de hardware.
- **Touchpad y energía**: Tap-to-click, scroll natural y suspensión en batería vía KDE Plasma (`kcminputrc` y `powerdevilrc`).

```bash
./Setup/laptop-setup.sh
# O usando just:
just laptop
```

---

## 5. Terminal Moderna (Kitty)

### Kitty (`kitty.sh`)
Instala y configura Kitty (emulador acelerado por GPU) con perfil Catppuccin Mocha / Tokyo Night translúcido (85% opacidad) con efectos blur, tipografía JetBrainsMono Nerd Font, barra de pestañas Powerline inclinada y control dinámico de opacidad al vuelo (`Ctrl+Shift+A` + `M`/`L`/`1`).

```bash
just kitty
```

---

## 8. Salvapantallas 3D y Bloqueo (`screensaver-setup.sh`)

Instala la suite XScreenSaver con efectos 3D OpenGL (Matrix, Tuberías, Flurry), registra el demonio en autostart de GNOME y vincula el atajo `Super + L` para activar el salvapantallas animado al bloquear la pantalla.

```bash
just screensaver
```

---

## 9. Entorno de Shell (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`), tipografías para desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode) y el prompt interactivo Starship.

```bash
just shell
just fonts
just fastfetch
```

---

## 10. Panel de Administración Web Cockpit (`cockpit.sh`)

Instala Cockpit con módulos para administrar el equipo desde el navegador ([https://localhost:9090](https://localhost:9090)):
- `cockpit-podman`: Gestión de contenedores Podman.
- `cockpit-machines`: Gestión de MVs en KVM/QEMU.
- `cockpit-storaged`: Estado de discos SSD/NVMe y datos SMART.

```bash
just cockpit
```

---

## 11. Temas e Iconos de Escritorio (`apariencia.sh`)

Instala temas, esquemas de color e iconos (Breeze Dark, Papirus-Dark) y asegura una homogeneización visual nativa y coherente entre KDE Plasma 6 (Qt6/Qt5), aplicaciones GTK 3/4 y paquetes Flatpak.

- **Aplicar tema oscuro recomendado completo**:
  ```bash
  just apariencia
  # o ./Setup/apariencia.sh
  ```
- **Ver estado visual y temas configurados**:
  ```bash
  ./Setup/apariencia.sh --status
  ```
- **Listar todos los temas globales, esquemas de color e iconos**:
  ```bash
  ./Setup/apariencia.sh --list
  ```
- **Aplicar tema claro**:
  ```bash
  ./Setup/apariencia.sh --light
  ```

---

## 12. Splash Screen Visual de Arranque (`plymouth-setup.sh`)

Instala y activa Plymouth con soporte para múltiples temas oficiales y modernos (`bgrt`, `ceratopsian`, `spinner`, etc.), asegurando un arranque gráfico limpio y silencioso sin parpadeos.

- **Instalar y activar tema recomendado (BGRT / Ceratopsian)**:
  ```bash
  just plymouth
  # o ./Setup/plymouth-setup.sh
  ```
- **Listar todos los temas disponibles**:
  ```bash
  ./Setup/plymouth-setup.sh --list
  ```
- **Activar un tema específico**:
  ```bash
  ./Setup/plymouth-setup.sh ceratopsian
  ```
- **Previsualizar el splash screen en el escritorio**:
  ```bash
  ./Setup/plymouth-setup.sh --preview
  ```

