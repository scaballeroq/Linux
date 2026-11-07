---
name: debian-gnome-control
description: >-
  Use this skill when managing GNOME Shell, Mutter window manager, TV display scaling, audio routing to Sony TV, screen timeout/power policies, or Wayland desktop settings on Debian TV.
---

# GNOME Shell & TV Display Control Skill (Sony TV / Wayland)

Instrucciones y comandos para inspeccionar y configurar GNOME Shell sobre Wayland optimizado para visualización en televisión (Sony TV) y uso como centro multimedia.

## 1. Ajustes de Pantalla y Comportamiento HTPC
```bash
# Desactivar apagado de pantalla e inactividad en modo multimedia
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Escala de texto adecuada para lectura cómoda a distancia de salón (televisor)
gsettings set org.gnome.desktop.interface text-scaling-factor 1.15

# Modo oscuro para visualización óptima en televisión
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# Disposición de botones estándar
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
```

## 2. Enrutamiento de Audio a la Sony TV (PipeWire & WirePlumber)
```bash
# Listar salidas de audio (Sinks) y localizar HDMI / DisplayPort a la Sony TV
wpctl status

# Establecer la salida HDMI de la televisión como predeterminada (sustituir <ID> por el número del Sink HDMI)
# wpctl set-default <ID>

# Ajustar volumen al 100% en la salida predeterminada
wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
```

## 3. Inspección de Monitores y Extensiones
```bash
# Inspeccionar monitores activos y resolución (Sony TV 1080p @ 60Hz)
cat ~/.config/monitors.xml 2>/dev/null || true

# Listar extensiones activas de GNOME Shell
gnome-extensions list --enabled 2>/dev/null || true
```
