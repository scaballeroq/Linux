---
name: cachy-system-maintenance
description: >-
  Use this skill when managing packages with Pacman/Paru, clearing package cache, running system updates on CachyOS, checking hardware telemetry, or inspecting systemd services.
---

# CachyOS System Maintenance Skill

Operaciones de mantenimiento y optimización para CachyOS x86-64-v3/v4 en HP EliteBook 855 G7.

## 1. Mantenimiento de Paquetes
```bash
# Actualización del sistema base y AUR
sudo pacman -Syu
paru -Syu --noconfirm

# Limpieza de paquetes huérfanos
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true

# Limpieza de caché
sudo paccache -r 2>/dev/null || sudo pacman -Sc --noconfirm

# Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Rendimiento
```bash
# Monitoreo de CPU Zen 2 y GPU Vega
sensors
radeontop 2>/dev/null || true

# Memoria ZRAM
free -h
zramctl
```
