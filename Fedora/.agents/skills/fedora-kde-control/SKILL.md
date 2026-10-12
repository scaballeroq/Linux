---
name: fedora-kde-control
description: >-
  Use this skill when managing KDE Plasma 6 desktop environment, KWin window manager, multi-monitor configuration via KScreen, Plasma themes/colorschemes, or Wayland desktop settings on Fedora 44.
---

# KDE Plasma 6 & KWin Control Skill (Fedora 44)

Instrucciones y comandos para configurar KDE Plasma 6 y KWin sobre Wayland en Fedora 44.

## 1. Gestión de Pantallas (KScreen)
```bash
# Diagnóstico de monitores y resoluciones
kscreen-doctor -o

# Activar o mover salidas
kscreen-doctor output.DP-3.mode.1920x1080@60 output.DP-3.position.0,0
```

## 2. Apariencia y Modo Oscuro
```bash
# Aplicar Breeze Dark
plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || plasma-apply-colorscheme BreezeDark

# Tipografía Mono (JetBrainsMono Nerd Font)
kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"

# Recargar KWin
qdbus org.kde.KWin /KWin reconfigure
```
