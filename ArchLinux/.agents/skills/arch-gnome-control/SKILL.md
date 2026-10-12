---
name: arch-gnome-control
description: >-
  Use this skill when managing GNOME Shell, Mutter window manager, GNOME extensions, display/monitor settings, or Wayland desktop settings on Arch Linux.
---

# GNOME Shell & Mutter Control Skill (Arch Linux)

Instrucciones y comandos para inspeccionar y configurar GNOME Shell y Mutter sobre Wayland en Arch Linux.

## 1. Configuración de Escritorio y Temas
```bash
# Modo oscuro
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Tipografía Mono (JetBrainsMono Nerd Font)
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'

# Botones de ventana (minimizar, maximizar, cerrar a la derecha)
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
```

## 2. Gestión de Monitores y Extensiones
```bash
# Abrir configuración de pantallas
gnome-control-center display &

# Listar extensiones activas
gnome-extensions list --enabled

# Captura de pantalla en Wayland
grim -g "$(slurp)" - | satty --filename - &
```
