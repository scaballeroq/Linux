---
name: debian-kde-control
description: >-
  Use this skill when managing KDE Plasma 6 desktop environment, KWin window manager, multi-monitor configuration via KScreen, or Wayland desktop settings on Debian.
---

# KDE Plasma 6 & KWin Control Skill (Debian)

Comandos para configurar KDE Plasma 6 y KWin sobre Wayland en Debian.

## 1. Gestión de Pantallas (KScreen)
```bash
# Diagnóstico de salidas y resoluciones
kscreen-doctor -o

# Activar salida principal
kscreen-doctor output.DP-3.mode.1920x1080@60 output.DP-3.position.0,0
```

## 2. Apariencia y Temas
```bash
# Tema oscuro Breeze Dark
plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || plasma-apply-colorscheme BreezeDark

# Recargar KWin
qdbus org.kde.KWin /KWin reconfigure
```
