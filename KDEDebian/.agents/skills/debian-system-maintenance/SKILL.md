---
name: debian-system-maintenance
description: >-
  Use this skill when performing system updates with APT, cleaning packages, verifying systemd services, or checking hardware telemetry on Debian KDE.
---

# Debian System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Debian con KDE en HP EliteBook 855 G7.

## 1. Mantenimiento y Actualizaciones de APT
```bash
# Refrescar repositorios
sudo apt update

# Actualizar sistema
sudo apt upgrade -y

# Limpiar huérfanos
sudo apt autoremove --purge -y
sudo apt autoclean

# Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Salud
```bash
# Espacio en disco y ZRAM
df -h
free -h
zramctl

# Sensores
sensors
```
