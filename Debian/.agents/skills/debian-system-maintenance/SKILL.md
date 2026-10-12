---
name: debian-system-maintenance
description: >-
  Use this skill when managing packages with APT, performing system updates, cleaning package caches, verifying systemd services, or checking hardware telemetry on Debian Stable.
---

# Debian Stable System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Debian GNU/Linux Stable en HP EliteBook 855 G7.

## 1. Mantenimiento y Actualizaciones de APT
```bash
# 1. Refrescar repositorios
sudo apt update

# 2. Actualizar sistema
sudo apt upgrade -y

# 3. Limpieza de paquetes
sudo apt autoremove --purge -y
sudo apt autoclean

# 4. Actualización Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Salud
```bash
# Espacio en disco y ZRAM
df -h / /boot /boot/efi
free -h
zramctl 2>/dev/null || true

# Sensores
sensors
```
