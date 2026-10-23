---
name: arch-system-maintenance
description: >-
  Use this skill when updating system packages (pacman/yay), cleaning package caches, verifying systemd services, or checking hardware telemetry on Arch Linux.
---

# Arch Linux System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Arch Linux en la estación de trabajo HP ProBook 455 G10.

## 1. Mantenimiento de Paquetes
```bash
# Actualización del sistema base y AUR
sudo pacman -Syu
yay -Syu --noconfirm

# Limpieza de paquetes huérfanos
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true

# Limpieza de caché manteniendo 2 versiones
sudo paccache -r 2>/dev/null || sudo pacman -Sc --noconfirm

# Comprobación de aplicaciones Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Salud del Sistema
```bash
# Espacio en disco y ZRAM
df -h / /boot /boot/efi
free -h
zramctl

# Sensores térmicos y frecuencias AMD
sensors
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | awk '{printf "CPU%02d: %.1f MHz\n", NR-1, $1/1000}'

# Servicios fallidos
systemctl --failed
systemctl --user --failed
```
