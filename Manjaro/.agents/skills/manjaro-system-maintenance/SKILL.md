---
name: manjaro-system-maintenance
description: >-
  Use this skill when managing packages with Pacman/Pamac, updating kernels with mhwd-kernel, cleaning caches, or checking hardware telemetry on Manjaro.
---

# Manjaro Linux System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Manjaro Linux en HP ProBook 455 G10.

## 1. Mantenimiento y Actualizaciones
```bash
# Actualizar lista de mirrors más rápidos
sudo pacman-mirrors --fasttrack 5

# Actualizar sistema completo
sudo pacman -Syu

# Limpiar paquetes huérfanos
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true

# Limpiar caché de pacman
sudo paccache -r 2>/dev/null || sudo pacman -Sc --noconfirm

# Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Salud
```bash
# Espacio y ZRAM
df -h
free -h
zramctl

# Kernels instalados y disponibles
mhwd-kernel -li
```
