---
sidebar_position: 2
---

# Configuración del Sistema en Manjaro Linux (Manjaro)

Esta guía detalla el proceso de configuración base, automontaje de la partición de trabajo, compilación de kernel nativo `x86_64-v3`, personalización de GNOME, terminales Ptyxis y Kitty, extensiones GNOME Shell y panel de administración web aplicados a un sistema **Manjaro Linux** con entorno de escritorio **GNOME**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepara el sistema base optimizando los servidores espejo más rápidos (`pacman-mirrors`), instalando software esencial, ZRAM, PipeWire, la suite GNOME, Flatpak y la pila gráfica/multimedia optimizada según el procesador y tarjeta gráfica.

### Scripts disponibles:

- **Despachador Inteligente (`post-install.sh`)**:
  Detecta automáticamente el fabricante del procesador (`AuthenticAMD` vs `GenuineIntel`) o permite selección manual:
  ```bash
  ./Setup/post-install.sh          # Auto-detección
  ./Setup/post-install.sh --amd    # Forzar modo AMD
  ./Setup/post-install.sh --intel  # Forzar modo Intel
  ```

- **Perfil AMD Ryzen (`post-install-amd.sh`)**:
  Optimizado para portátiles y estaciones con CPU AMD Ryzen y GPU Radeon:
  - Espejos: `sudo pacman-mirrors --fasttrack 5`
  - Microcódigo: `amd-ucode`
  - Firmware GPU: `linux-firmware`
  - Pila Gráfica: `mesa`, `lib32-mesa`, `vulkan-radeon`, `lib32-vulkan-radeon`, `libva-mesa-driver`, `radeontop`.
  - Paquetes: `pamac-cli`, `flatpak`, `libpamac-flatpak-plugin`.
  ```bash
  just post-install-amd
  ```

- **Perfil Intel Core / Media Center (`post-install-intel.sh`)**:
  Optimizado para equipos sobremesa Intel Core (Haswell i7-4790 / HD Graphics 4600) dedicados a centro multimedia:
  - Microcódigo: `intel-ucode`
  - Aceleración VA-API de vídeo: `intel-media-driver`, `libva-intel-driver`, `libva-utils`, `vulkan-intel`.
  - Multimedia: `kodi` con addons nativos (`inputstream-adaptive`, `inputstream-rtmp`, `pvr-iptvsimple`), `ffmpeg`.
  - Sin virtualización KVM pesada ni ajustes de batería de portátil.
  ```bash
  just post-install-intel
  ```

---

## 2. Automontaje de Partición Workspace (`mount-workspace.sh`)

Monta permanentemente la partición `/home/caballero/Workspace` mediante `/etc/fstab` utilizando su UUID y las banderas `defaults,noatime,nofail`.

```bash
just workspace
```

---

## 3. Compilador de Kernel Linux x86_64-v3 (`build-custom-kernel.sh`)

Descarga la última versión del kernel estable desde `kernel.org`, aplica recortes con `localmodconfig`, activa optimizaciones `x86_64-v3`, frecuencia a **1000Hz** y **Preemption Dinámica**, instalando y actualizando `mkinitcpio` y `GRUB`.

```bash
just build-kernel
```

---

## 4. Instalación Limpia de Extensiones GNOME (`gnome-extensions.sh`)

Instala `gnome-browser-connector`, `extension-manager` y descarga 17 extensiones personalizadas compilando esquemas GSettings (`glib-compile-schemas`).

```bash
just extensions
```

---

## 5. Optimización para Portátiles (`laptop-setup.sh`)

Configura `power-profiles-daemon`, `switcheroo-control`, `bluez`, `brightnessctl`, gestos de touchpad, VRR y suspensión eficiente en batería.

```bash
just laptop
```

---

## 6. Autenticación por Huella Dactilar (`fingerprint-setup.sh`)

Configura `fprintd` y los módulos PAM para autenticación en consola (`sudo`), ventanas de diálogo de GNOME (`polkit-1`) y pantalla de desbloqueo GDM.

```bash
just fingerprint
```

---

## 7. Impresora HP LaserJet Pro M15w USB (`hp-printer-setup.sh`)

Instala CUPS, HPLIP, librerías de impresión y ayuda a descargar el plugin propietario necesario para la serie LaserJet M15w.

```bash
just printer
```

---

## 8. Splash Screen de Arranque Plymouth (`plymouth-setup.sh`)

Configura y activa el Splash Screen visual (BGRT OEM UEFI o tema oficial de Manjaro) regenerando el hook en `/etc/mkinitcpio.conf` y actualizando GRUB.

```bash
just plymouth
```

---

## 9. Terminales Modernas (Ptyxis y Kitty)

- **Ptyxis (`ptyxis.sh`)**: Terminal nativa de GNOME con transparencia al 85%, atajo `Ctrl+Alt+T` e integración contextual en Nautilus.
- **Kitty (`kitty.sh`)**: Terminal acelerada por GPU con tema Catppuccin Mocha, blur, soporte para Nerd Fonts y atajos rápidos de opacidad.
