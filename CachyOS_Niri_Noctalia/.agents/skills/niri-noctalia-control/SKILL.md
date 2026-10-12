---
name: niri-noctalia-control
description: >-
  Use this skill when managing Niri scrollable-tiling window manager, Noctalia Shell IPC, window layout, monitor outputs, screenshots, or Wayland desktop controls on CachyOS.
---

# Niri & Noctalia Shell Control Skill (CachyOS)

Comandos y pautas para operar Niri y Noctalia Shell sobre Wayland.

## 1. Control de Niri por Mensajería IPC
```bash
# Navegación entre columnas y ventanas
niri msg action focus-column-left
niri msg action focus-column-right
niri msg action focus-window-up
niri msg action focus-window-down

# Cerrar o maximizar ventana
niri msg action close-window
niri msg action maximize-column
niri msg action fullscreen-window

# Salidas de pantalla
niri msg outputs
```

## 2. Noctalia Shell y Capturas
```bash
# Enviar mensajes a Noctalia Shell
noctalia msg toggle-launcher 2>/dev/null || true

# Capturas de pantalla
grim -g "$(slurp)" - | satty --filename - &
```
