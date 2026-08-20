---
sidebar_position: 2
---

# Configuración del Sistema en OpenSUSE Tumbleweed

Esta guía detalla el proceso de configuración base, repositorios Packman y OPI, instantáneas Snapper/Btrfs, automontaje de partición de trabajo, compilación de kernel nativo `x86_64-v3`, personalización de GNOME, terminales Ptyxis/Kitty, extensiones GNOME Shell y panel de administración web aplicados a un sistema **OpenSUSE Tumbleweed** con **GNOME**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup` y el recetario `justfile`.

---

## 1. Post-Instalación Base (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepara el sistema base configurando el repositorio oficial Packman (prioridad 90), codecs multimedia completos, ZRAM, PipeWire, la suite GNOME y la pila gráfica optimizada según el procesador.

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
  - Repositorio Packman con prioridad 90 (`zypper ar -cfp 90 ...`).
  - Instalador OPI (Open Build Service Package Installer).
  - Microcódigo: `ucode-amd`, `kernel-firmware-amdgpu`, `kernel-firmware-radeon`.
  - Pila Gráfica: `Mesa`, `libvulkan_radeon`, `libva-vdpau-driver`, `radeontop`.
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

## 2. Automontaje de Partición Workspace (`mount-workspace.sh`)

Monta automáticamente la partición de datos `/home/caballero/Workspace` mediante `/etc/fstab` usando su UUID con opciones `defaults,noatime,nofail`.

```bash
just workspace
```

---

## 3. Optimizaciones de Sistema y Snapper (`tumbleweed-tuning.sh`)

Ajusta parámetros de kernel sysctl (`inotify`, `max_map_count`) y configura las políticas de retención de instantáneas en Snapper (Btrfs) para evitar saturación de almacenamiento.

```bash
just tuning
```

---

## 4. Compilador de Kernel Linux NATIVO x86_64-v3 (`build-custom-kernel.sh`)

Descarga la última versión estable oficial del Kernel Linux desde kernel.org y compila un kernel optimizado para arquitectura `x86_64-v3`, latencia a **1000Hz** y **Preemption Dinámica**.

```bash
just build-kernel
```

---

## 5. Instalación Limpia de Extensiones GNOME (`gnome-extensions.sh`)

Descarga e instala las extensiones de GNOME Shell mediante DBus y compila automáticamente los esquemas GSettings (`glib-compile-schemas`).

```bash
just extensions
```

---

## 6. Optimización para Portátiles y Brillo al 95% (`laptop-setup.sh`)

- **Brillo automático al 95%**: Servicio systemd `set-screen-brightness.service` + autostart de GNOME.
- **Gestión de energía**: `power-profiles-daemon`, `switcheroo-control`.
- **Touchpad y pantalla**: Tap-to-click, scroll natural, VRR en Wayland.

```bash
just laptop
```

---

## 7. Personalización de GNOME vía GSettings (`gnome-settings.sh`)

- Luz Nocturna a 3500K.
- Reloj 24h y porcentaje de batería.
- Botones de minimizar, maximizar y cerrar a la derecha.
- Tema oscuro preferido (`prefer-dark`).

```bash
just gnome
```

---

## 8. Terminales Modernas (Ptyxis y Kitty)

- **Ptyxis (`ptyxis.sh`)**: Perfil translúcido al 85%, atajo `Ctrl + Alt + T` e integración en Nautilus.
- **Kitty (`kitty.sh`)**: Perfil Tokyo Night / Catppuccin Mocha acelerado por GPU, opacidad al 85%, blur y Nerd Fonts.

```bash
just ptyxis
just kitty
```

---

## 9. Salvapantallas 3D y Bloqueo (`screensaver-setup.sh`)

Suite XScreenSaver 3D OpenGL vinculada al atajo `Super + L`.

```bash
just screensaver
```

---

## 10. Panel de Administración Web Cockpit (`cockpit.sh`)

Panel web de administración en [https://localhost:9090](https://localhost:9090) con soporte para Podman, máquinas virtuales KVM y almacenamiento.

```bash
just cockpit
```
