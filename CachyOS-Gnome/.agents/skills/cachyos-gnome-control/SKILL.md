---
name: cachyos-gnome-control
description: Control, personalización y diagnóstico del entorno de escritorio GNOME Shell (Wayland / Mutter), colores de acento Libadwaita, temas, extensiones EGO/Pacman, topología multimonitor triple pantalla (HP ProBook 455 G10), terminales (Kitty, Ghostty, Ptyxis), audio PipeWire/WirePlumber y atajos en CachyOS Workstation.
---

# Control de GNOME Shell, Wayland y Multimedia (CachyOS Workstation)

Esta skill proporciona las directrices operativas y comandos exactos para gestionar la interfaz gráfica, pantallas, personalización, extensiones, terminales y subsistema de audio en **CachyOS Workstation** con **GNOME Shell sobre Wayland (Mutter)**.

---

## 1. Gestión de Apariencia, Colores de Acento y Temas (`gsettings`)

### 1.1. Color de Acento (*Accent Color*)
Colores soportados: `'blue'`, `'teal'`, `'green'`, `'yellow'`, `'orange'`, `'red'`, `'pink'`, `'purple'`, `'slate'`:
```bash
# Consultar color de acento actual
gsettings get org.gnome.desktop.interface accent-color

# Establecer color de acento (ej. Teal o Slate)
gsettings set org.gnome.desktop.interface accent-color 'teal'
```

### 1.2. Modo Oscuro Global:
```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
```

---

## 2. Topología Multimonitor Triple Pantalla (HP ProBook 455 G10)

1. **DP-3 (Principal / Trabajo):** 1920x1080 @ 60Hz (`0,0`)
2. **DP-4 (Secundaria / Lateral):** 1920x1080 @ 60Hz (`1920,0`)
3. **eDP-1 (Pantalla Portátil):** 1920x1080 @ 60Hz (`0,1080`)

### 2.1. Reglas Mutter Wayland:
```bash
# Mutter: Espacios de trabajo solo en monitor primario o extendidos
gsettings set org.gnome.mutter workspaces-only-on-primary false

# Frecuencia variable (VRR) en Mutter si está soportada
gsettings set org.gnome.mutter.wayland experimental-features "['variable-refresh-rate']"
```

---

## 3. Extensiones de GNOME Shell

En CachyOS / Arch Linux, las extensiones oficiales se instalan vía Pacman o EGO:
- `gnome-shell-extension-dash-to-dock`
- `gnome-shell-extension-appindicator`
- `gnome-shell-extension-caffeine`
- `gnome-shell-extension-blur-my-shell`

```bash
# Listar extensiones activas
gnome-extensions list --enabled

# Diagnóstico automatizado
./Setup/gnome-extensions.sh --status
```

---

## 4. Terminales e Integración con Nautilus

- **Ptyxis, Ghostty y Kitty**: Configuradas con Catppuccin Mocha y JetBrainsMono Nerd Font.
- **Nautilus Context Menu**: Utiliza `python-nautilus` (`sudo pacman -S --needed python-nautilus`) con extensiones de script en `~/.local/share/nautilus-python/extensions/`.
