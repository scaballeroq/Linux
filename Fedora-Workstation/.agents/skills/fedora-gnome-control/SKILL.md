---
name: fedora-gnome-control
description: >-
  Use this skill when managing GNOME Shell, Mutter window manager, GNOME extensions, display/monitor settings (LG 32", Sony TV 32", Laptop), gsettings/dconf configurations, and Wayland desktop integration on Fedora 44 Linux.
---

# GNOME Shell & Mutter Control Skill (Fedora 44 Linux)

Esta skill proporciona los comandos y directrices para inspeccionar, configurar y gestionar el entorno de escritorio **GNOME Shell** y el compositor/gestor de ventanas **Mutter** sobre **Wayland** en Fedora 44 Workstation.

---

## 1. Gestión de Monitores y Salidas (Triple Monitor 1080p)

La estación de trabajo cuenta con una topología de tres pantallas Full HD (1920x1080):
1. **Pantalla LG 32"**: Monitor principal / extendido de trabajo.
2. **TV Sony 32"**: Monitor secundario / multimedia.
3. **Pantalla Integrada Portátil 15.6"**: Pantalla del HP EliteBook (eDP-1).

### Consultas y configuración de pantallas:
GNOME gestiona las salidas y resoluciones a través de Mutter y almacena la disposición persistente en `~/.config/monitors.xml`:

```bash
# Abrir el panel de configuración gráfica de pantallas
gnome-control-center display &

# Habilitar características experimentales de Mutter (VRR y escalado fraccionario)
gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate', 'scale-monitor-framebuffer']"

# Comprobar estado de características activas de Mutter
gsettings get org.gnome.mutter experimental-features

# Inspeccionar la configuración guardada de monitores
cat ~/.config/monitors.xml
```

---

## 2. Gestión y Control de Extensiones GNOME Shell

El entorno utiliza extensiones gestionadas tanto desde repositorios oficiales de Fedora 44 (DNF5) como desde extensions.gnome.org (EGO).

### Herramientas y scripts del repositorio:
- **Gestor gráfico:** `extension-manager`
- **Script automatizado del repositorio:** `Setup/gnome-extensions.sh`

### Comandos CLI con `gnome-extensions`:
```bash
# Diagnóstico del estado de extensiones con el script del repositorio
./Setup/gnome-extensions.sh --status

# Listar todas las extensiones instaladas y activas
gnome-extensions list --enabled

# Listar todas las extensiones con información detallada
gnome-extensions list -d

# Habilitar o deshabilitar una extensión específica por su UUID
gnome-extensions enable <uuid>
gnome-extensions disable <uuid>

# Consultar información de una extensión
gnome-extensions info <uuid>

# Habilitar soporte global de extensiones de usuario
gsettings set org.gnome.shell disable-user-extensions false
```

---

## 3. Configuración del Entorno, GSettings y DConf

Ajustes del sistema para productividad y desarrollo (modo oscuro, ventanas y comportamiento):

```bash
# Apariencia y tema oscuro global (prefer-dark y adw-gtk3)
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'

# Tipografía para programación
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'

# Botones de ventana completos (minimizar, maximizar, cerrar a la derecha)
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

# Comportamiento de ventanas en Mutter
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.mutter attach-modal-dialogs true

# Barra superior: reloj 24h, fecha y porcentaje de batería
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Luz nocturna (4000K para fatiga visual)
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000
```

---

## 4. Integración Wayland, Terminal Kitty y Capturas

La sesión se ejecuta sobre Wayland nativo. Descartar utilidades incompatibles de X11 (`xdotool`, `xclip`, `xrandr`, `wmctrl`).

### Terminal Kitty:
```bash
# Abrir Kitty con atajo configurado en GNOME: Ctrl+Alt+T
# Configuración del atajo en GNOME media-keys:
KB_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$KB_PATH']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH name 'Kitty Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH command 'kitty'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$KB_PATH binding '<Primary><Alt>t'
```

### Herramientas nativas de Wayland para captura y grabación:
```bash
# Captura de región con Satty o copiado directo al portapapeles
grim -g "$(slurp)" - | satty --filename -
grim -g "$(slurp)" - | wl-copy

# Grabación de pantalla Wayland acelerada por hardware
wl-screenrec --filename grabacion.mp4
```

---

## 5. Diagnóstico de Sesión y Servicios de GNOME

```bash
# Comprobar tipo de sesión gráfica (debe ser wayland)
echo $XDG_SESSION_TYPE
echo $XDG_CURRENT_DESKTOP

# Comprobar versión de GNOME Shell
gnome-shell --version

# Logs de Mutter y GNOME Shell en la sesión actual
journalctl --user -u gnome-shell.service -n 50 --no-pager
journalctl --user -b -e /usr/bin/gnome-shell
```
