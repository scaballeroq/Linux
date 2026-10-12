---
name: hyprland-control
description: >-
  Use this skill when managing Hyprland compositor, window dispatcher commands with hyprctl, workspaces, multi-monitor configuration, or Wayland desktop settings on Omarchy.
---

# Hyprland Control Skill (Omarchy)

Instrucciones y comandos para inspeccionar y controlar Hyprland mediante `hyprctl`.

## 1. Comandos de Despacho (hyprctl dispatch)
```bash
# Cambiar de espacio de trabajo
hyprctl dispatch workspace 1

# Mover la ventana activa a un espacio de trabajo
hyprctl dispatch movetoworkspace 2

# Cerrar la ventana activa
hyprctl dispatch killactive

# Alternar pantalla completa o flotante
hyprctl dispatch fullscreen 1
hyprctl dispatch togglefloating
```

## 2. Inspección de Monitores y Clientes
```bash
# Listar monitores conectados, resoluciones y coordenadas
hyprctl monitors

# Listar todas las ventanas abiertas y sus clases
hyprctl clients

# Recargar configuración de Hyprland
hyprctl reload
```

## 3. Capturas de Pantalla
```bash
grim -g "$(slurp)" - | satty --filename - &
```
