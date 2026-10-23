---
name: arch-system-maintenance
description: >-
  Use this skill when managing packages with Pacman/Yay, cleaning caches, or inspecting hardware telemetry on Arch Linux (Omarchy).
---

# Arch Linux Maintenance Skill (Omarchy)

Operaciones estándar para Arch Linux en la estación de trabajo HP ProBook 455 G10.

## 1. Mantenimiento y Actualizaciones
```bash
# Actualización del sistema base y AUR
sudo pacman -Syu
yay -Syu --noconfirm

# Limpiar paquetes huérfanos
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true

# Limpiar caché
sudo paccache -r 2>/dev/null || sudo pacman -Sc --noconfirm

# Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Salud
```bash
df -h
free -h
sensors
```
