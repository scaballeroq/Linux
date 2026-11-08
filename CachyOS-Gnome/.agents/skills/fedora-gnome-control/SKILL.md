---
name: fedora-gnome-control
description: Control, personalización y diagnóstico del entorno de escritorio GNOME Shell 51 (Wayland / Mutter 51), colores de acento Libadwaita, temas, extensiones EGO/DNF5, topología multimonitor triple pantalla (HP ProBook 455 G10), terminales (Kitty, Ghostty, Ptyxis), audio PipeWire/WirePlumber y atajos en Fedora 45 Workstation.
---

# Control de GNOME Shell 51, Wayland y Multimedia (Fedora 45 Workstation)

Esta skill proporciona las directrices operativas y comandos exactos para gestionar la interfaz gráfica, pantallas, personalización, extensiones, terminales y subsistema de audio en **Fedora 45 Workstation** con **GNOME Shell 51 (Mutter 51 sobre Wayland)**.

---

## 1. Gestión de Apariencia, Colores de Acento y Temas (`gsettings`)

GNOME 51 integra soporte completo para colores de acento (*Accent Colors*) en la especificación Libadwaita y modo oscuro unificado.

### 1.1. Color de Acento (*Accent Color*)
En GNOME 51, los colores de acento soportados son: `'blue'`, `'teal'`, `'green'`, `'yellow'`, `'orange'`, `'red'`, `'pink'`, `'purple'`, `'slate'`:
```bash
# Consultar color de acento actual
gsettings get org.gnome.desktop.interface accent-color

# Establecer color de acento (ej. Azul o Pizarra)
gsettings set org.gnome.desktop.interface accent-color 'blue'
gsettings set org.gnome.desktop.interface accent-color 'slate'
```

### 1.2. Modo Oscuro y Modo Claro
```bash
# Activar Modo Oscuro (Dark Mode + adw-gtk3-dark para apps legacy GTK3)
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'

# Activar Modo Claro (Light Mode)
gsettings set org.gnome.desktop.interface color-scheme 'default'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
```

### 1.3. Iconos, Tipografías y Cursores
```bash
# Iconos Papirus Dark y Cursor Bibata Modern Classic
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface cursor-size 24

# Tipografía del sistema
gsettings set org.gnome.desktop.interface font-name 'Inter Display Regular 10.5'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10.5'
```

### 1.4. Scripts Modulares del Repositorio
```bash
# Diagnóstico de apariencia y configuración GNOME
./Setup/apariencia.sh --status
./Setup/gnome-settings.sh --status

# Menús interactivos
./Setup/apariencia.sh --interactive
./Setup/gnome-settings.sh --interactive
```

---

## 2. Gestión de Pantallas y Mutter 51 en Wayland

En GNOME 51 Wayland, `xrandr` solo refleja la capa de emulación XWayland. La configuración fidedigna y persistente reside en `~/.config/monitors.xml` y es gestionada directamente por el compositor **Mutter 51**.

### 2.1. Topología Multi-Monitor de la Estación (HP ProBook 455 G10)
1. **`DP-3` (Principal / Trabajo):** Monitor externo 1920x1080 @ 60Hz (Posición `0,0`)
2. **`DP-4` (Secundaria / Lateral):** Monitor externo 1920x1080 @ 60Hz (Posición `1920,0`)
3. **`eDP-1` (Pantalla Integrada Portátil):** Pantalla interna 15.6" HP ProBook 455 G10 (1920x1080 @ 60Hz, Posición `0,1080`)

### 2.2. Inspección de Conectores DRM del Kernel (`amdgpu`)
```bash
for p in /sys/class/drm/card*-*; do 
    [ -f "$p/status" ] && echo "$(basename "$p"): $(cat "$p/status")"
done
```

### 2.3. Características Experimentales de Mutter 51
GNOME 51 y Mutter 51 incorporan mejoras críticas en VRR (*Variable Refresh Rate*), escalado fraccional y escalado nativo para XWayland:
```bash
# Consultar flags experimentales activos
gsettings get org.gnome.mutter experimental-features

# Habilitar VRR, escalado de framebuffer y escalado nativo XWayland
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']"
```

### 2.4. Luz Nocturna (*Night Light*)
```bash
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
```

---

## 3. Extensiones de GNOME Shell 51 (`gnome-extensions`)

### 3.1. Diagnóstico y Control CLI
```bash
# Listar extensiones activas con su UUID
gnome-extensions list --enabled

# Inspeccionar información detallada de una extensión
gnome-extensions show <UUID>

# Habilitar o deshabilitar una extensión específica
gnome-extensions enable <UUID>
gnome-extensions disable <UUID>
```

### 3.2. Compatibilidad y Validación de Versión en GNOME 51
Durante transiciones y actualizaciones de GNOME Shell 51, es recomendable permitir la ejecución de extensiones que aún no hayan actualizado el tag `51` en su archivo `metadata.json`:
```bash
gsettings set org.gnome.shell disable-user-extensions false
gsettings set org.gnome.shell disable-extension-version-validation true
```

### 3.3. Despliegue Automatizado del Repositorio
```bash
# Diagnóstico de estado de extensiones instaladas
./Setup/gnome-extensions.sh --status

# Instalación y habilitación desatendida
./Setup/gnome-extensions.sh
```

### 3.4. Extensiones Principales en el Perfil Fedora 45 / GNOME 51:
- `gsconnect@andyholmes.github.io` (Integración KDE Connect con firewall en puertos 1714-1764 TCP/UDP)
- `dash-to-dock@micxgx.gmail.com` (Dock persistente fuera del overview)
- `appindicatorsupport@rgcjonas.gmail.com` (Iconos de bandeja del sistema / Tray)
- `blur-my-shell@aunetx` (Efecto de desenfoque y translucidez)
- `caffeine@patapon.info` (Inhibidor rápido de suspensión de pantalla)
- `tilingshell@ferrarodomenico.com` (Gestión de ventanas tipo tiling avanzado)
- `clipboard-indicator@tudmotu.com` (Historial del portapapeles)
- `just-perfection@just-perfection` (Ajustes finos de la interfaz y animaciones del Shell)

---

## 4. Terminales Wayland e Integración en Nautilus 51 (`nautilus-python`)

En Fedora 45 y GNOME 51, la integración de menús contextuales en Nautilus requiere el paquete oficial **`nautilus-python`** (`sudo dnf5 install -y nautilus-python`) y los scripts se alojan en `~/.local/share/nautilus-python/extensions/`.

### 4.1. Ptyxis (Terminal Predeterminada de GNOME / Fedora 45)
- **Instalación:** `sudo dnf5 install -y ptyxis`
- **Configuración:** Integración con contenedores Podman/Flatpak y pestañas Libadwaita.
- **Paleta Catppuccin Mocha:** `~/.local/share/org.gnome.Ptyxis/palettes/catppuccin-mocha.palette`
- **Menú contextual Nautilus:** `~/.local/share/nautilus-python/extensions/open-ptyxis.py`
- **Script del repo:** `./Setup/ptyxis.sh --status`

### 4.2. Kitty (Terminal con Aceleración GPU AMD Radeon)
- **Instalación:** `sudo dnf5 install -y kitty`
- **Configuración:** `~/.config/kitty/kitty.conf` (Catppuccin Mocha, opacidad 0.75, blur 32, JetBrainsMono Nerd Font)
- **Menú contextual Nautilus:** `~/.local/share/nautilus-python/extensions/open-kitty.py`
- **Script del repo:** `./Setup/kitty.sh --status`

### 4.3. Ghostty (Terminal GTK4 / Wayland Nativa de Alto Rendimiento)
- **Instalación:** `sudo dnf5 copr enable -y pgdev/ghostty && sudo dnf5 install -y ghostty`
- **Configuración:** `~/.config/ghostty/config` (Catppuccin Mocha, GTK single-instance, opacidad 0.85)
- **Menú contextual Nautilus:** `~/.local/share/nautilus-python/extensions/open-ghostty.py`
- **Script del repo:** `./Setup/ghostty.sh --status`

### 4.4. Reinicio de Nautilus tras Modificar Extensiones
```bash
nautilus -q
```

---

## 5. Control de Audio PipeWire y WirePlumber en GNOME 51

El servidor multimedia PipeWire y el gestor de sesiones WirePlumber gestionan el audio sin capas pulseaudio residentes:

```bash
# Diagnóstico completo de nodos, sinks, sources y clientes de audio
wpctl status

# Consultar volumen del dispositivo de salida por defecto
wpctl get-volume @DEFAULT_AUDIO_SINK@

# Ajustar volumen en incrementos (+5% / -5%)
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

# Alternar silencio (Mute / Unmute)
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```
