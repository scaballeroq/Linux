---
name: soplos-gnome-control
description: >-
  Use this skill when managing GNOME Shell, Mutter window manager, GNOME extensions, display/monitor settings, or Wayland desktop settings on Soplos Linux Boro.
---

# GNOME Shell & Mutter Control Skill (Soplos Linux Boro)

Instrucciones y comandos para inspeccionar y configurar GNOME Shell y Mutter sobre Wayland en Soplos Linux Boro.

## 1. Configuración de Apariencia
```bash
# Activar tema oscuro
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Tipografía Mono
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10'

# Disposición de botones
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
```

## 2. Gestión de Monitores y Extensiones
```bash
# Abrir panel de pantallas
gnome-control-center display &

# Listar extensiones activas
gnome-extensions list --enabled 2>/dev/null || true
```
