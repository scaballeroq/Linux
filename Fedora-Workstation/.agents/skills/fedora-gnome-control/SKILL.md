---
name: fedora-gnome-control
description: Control, personalización y diagnóstico del entorno de escritorio GNOME Shell (Wayland / Mutter), temas, extensiones, pantallas, terminales (Kitty, Ghostty, Ptyxis), audio PipeWire y atajos en Fedora 45 Workstation.
---

# Control de GNOME Shell, Wayland y Multimedia (Fedora 45 Workstation)

Esta skill proporciona los comandos exactos para gestionar la interfaz gráfica, pantallas, temas, terminales y audio del sistema local en **Fedora 45 Workstation (GNOME Wayland)** desde la terminal.

## 1. Gestión de Apariencia y Temas (`gsettings` y `./Setup/apariencia.sh`)
- **Activar Modo Oscuro (Dark Mode + `adw-gtk3-dark`):**
  ```bash
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  ```
- **Activar Modo Claro (Light Mode):**
  ```bash
  gsettings set org.gnome.desktop.interface color-scheme 'default'
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
  ```
- **Iconos y Cursor (Papirus + Bibata):**
  ```bash
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
  gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
  gsettings set org.gnome.desktop.interface cursor-size 24
  ```
- **Script interactivo y modular del repositorio:**
  ```bash
  ./Setup/apariencia.sh --status
  ./Setup/apariencia.sh --interactive
  ./Setup/gnome-settings.sh --status
  ./Setup/gnome-settings.sh --interactive
  ```

## 2. Gestión de Pantallas y Mutter en Wayland
> **Importante:** En Wayland `xrandr` solo afecta a XWayland. La configuración real reside en `~/.config/monitors.xml` y se gestiona mediante Mutter.
- **Topología Multi-Monitor del Equipo (HP ProBook 455 G10):**
  1. `DP-3` (Monitor Principal 1920x1080 @ 60Hz, `0,0`)
  2. `DP-4` (Monitor Secundario 1920x1080 @ 60Hz, `1920,0`)
  3. `eDP-1` (Pantalla Interna Portátil 1920x1080 @ 60Hz, `0,1080`)
- **Inspeccionar conectores DRM en el Kernel (`amdgpu`):**
  ```bash
  for p in /sys/class/drm/card*-*; do [ -f "$p/status" ] && echo "$(basename "$p"): $(cat "$p/status")"; done
  ```
- **Características Experimentales de Mutter (VRR + Escalado Fraccional + XWayland Nativo):**
  ```bash
  gsettings get org.gnome.mutter experimental-features
  gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']"
  ```
- **Luz Nocturna (Night Light a 4000K):**
  ```bash
  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
  gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
  ```

## 3. Gestión de Extensiones de GNOME Shell (`gnome-extensions` y `./Setup/gnome-extensions.sh`)
- **Listar extensiones activas:**
  ```bash
  gnome-extensions list --enabled
  ```
- **Estado completo e instalación automatizada:**
  ```bash
  ./Setup/gnome-extensions.sh --status
  ./Setup/gnome-extensions.sh
  ```
- **Extensiones principales en Fedora 45 Workstation:**
  - `gsconnect@andyholmes.github.io` (GSConnect nativo + Firewalld `1714-1764/tcp` y `udp`)
  - `dash-to-dock@micxgx.gmail.com` (Dash to Dock)
  - `appindicatorsupport@rgcjonas.gmail.com` (AppIndicator / Tray Icons)
  - `blur-my-shell@aunetx` (Blur my Shell)
  - `caffeine@patapon.info` (Caffeine)
  - `tilingshell@ferrarodomenico.com` (Tiling Shell)
  - `clipboard-indicator@tudmotu.com` (Clipboard Indicator)

## 4. Terminales Nativas en Wayland e Integración con Nautilus (`nautilus-python`)
En Fedora 45, las extensiones de menú contextual de primer nivel para Nautilus requieren el paquete RPM **`nautilus-python`** (`sudo dnf5 install -y nautilus-python`) y se alojan en `~/.local/share/nautilus-python/extensions/`:
- **Kitty (`./Setup/kitty.sh`):**
  - Configuración: `~/.config/kitty/kitty.conf` (Catppuccin Mocha, opacidad 0.75, blur 32)
  - Extensión Nautilus: `~/.local/share/nautilus-python/extensions/open-kitty.py`
- **Ghostty (`./Setup/ghostty.sh`):**
  - Instalación: `sudo dnf5 copr enable -y pgdev/ghostty && sudo dnf5 install -y ghostty`
  - Configuración: `~/.config/ghostty/config` (Catppuccin Mocha, opacidad 0.85, GTK single-instance)
  - Extensión Nautilus: `~/.local/share/nautilus-python/extensions/open-ghostty.py`
- **Ptyxis (`./Setup/ptyxis.sh`):**
  - Instalación: `sudo dnf5 install -y ptyxis`
  - Paleta personalizada: `~/.local/share/org.gnome.Ptyxis/palettes/catppuccin-mocha.palette`
  - Extensión Nautilus: `~/.local/share/nautilus-python/extensions/open-ptyxis.py`

## 5. Control de Audio (PipeWire + WirePlumber)
- **Ver estado general de dispositivos de audio:**
  ```bash
  wpctl status
  ```
- **Control de volumen del dispositivo por defecto:**
  ```bash
  wpctl get-volume @DEFAULT_AUDIO_SINK@
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  ```
