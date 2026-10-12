---
name: ubuntu-gnome-control
description: >-
  Use this skill when managing GNOME Shell, Mutter window manager, extensions, display/monitor settings, or Wayland desktop settings on Ubuntu.
---

# GNOME Shell & Mutter Control Skill (Ubuntu)

Instrucciones y comandos para inspeccionar y configurar GNOME Shell y Mutter sobre Wayland en Ubuntu.

## 1. Configuración de Apariencia
```bash
# Modo oscuro
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Tipografía Mono
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'

# Disposición de botones
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
```

## 2. Gestión de Pantallas y Capturas
```bash
# Abrir panel de pantallas
gnome-control-center display &

# Captura con grim y satty
grim -g "$(slurp)" - | satty --filename - &
```
