---
name: debian-testing-gnome-control
description: >-
  Use this skill when managing GNOME Shell, Mutter window manager, display/monitor settings, or Wayland desktop settings on Debian Testing.
---

# GNOME Shell & Mutter Control Skill (Debian Testing)

Instrucciones y comandos para inspeccionar y configurar GNOME Shell y Mutter sobre Wayland en Debian Testing.

## 1. Configuración de Apariencia
```bash
# Modo oscuro
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Tipografía Mono
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'

# Botones de ventana
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
```

## 2. Gestión de Pantallas y Extensiones
```bash
# Abrir panel de pantallas
gnome-control-center display &

# Listar extensiones activas
gnome-extensions list --enabled 2>/dev/null || true
```
