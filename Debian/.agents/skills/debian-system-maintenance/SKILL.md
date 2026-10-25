---
name: debian-system-maintenance
description: >-
  Use this skill when performing system updates with APT, cleaning package caches, verifying systemd services, or checking hardware telemetry on Debian.
---

# Debian System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Debian en HP ProBook 455 G10.

## 1. Mantenimiento y Actualizaciones de APT
```bash
# Refrescar repositorios
sudo apt update

# Actualizar paquetes
sudo apt upgrade -y

# Limpiar paquetes huérfanos
sudo apt autoremove --purge -y
sudo apt autoclean

# Actualizar Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Salud
```bash
df -h
free -h
zramctl
sensors
```
