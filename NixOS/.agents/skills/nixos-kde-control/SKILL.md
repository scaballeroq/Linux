---
name: nixos-kde-control
description: >-
  Use this skill when inspecting KDE Plasma 6 desktop configuration, multi-monitor outputs via KScreen, audio via PipeWire, or Wayland desktop settings on NixOS.
---

# KDE Plasma 6 & KWin Control Skill (NixOS)

Comandos para operar KDE Plasma 6 sobre Wayland en NixOS.

## 1. Monitores (KScreen)
```bash
# Diagnóstico de pantallas
kscreen-doctor -o

# Ajustar salida principal
kscreen-doctor output.DP-3.mode.1920x1080@60 output.DP-3.position.0,0
```

## 2. Apariencia y Audio
```bash
# Aplicar Breeze Dark
plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || plasma-apply-colorscheme BreezeDark

# PipeWire y WirePlumber
wpctl status
```
