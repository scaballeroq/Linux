---
name: debian-testing-system-maintenance
description: >-
  Use this skill when performing system updates with APT (full-upgrade), package cleaning, verifying systemd services, or checking hardware telemetry on Debian Testing.
---

# Debian Testing System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Debian Testing (Trixie/Forky) en HP ProBook 455 G10.

## 1. Mantenimiento y Actualizaciones de APT
```bash
# 1. Refrescar repositorios
sudo apt update

# 2. Actualización completa resolviendo transiciones
sudo apt full-upgrade -y

# 3. Limpieza de paquetes huérfanos y paquetes de instalación
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
zramctl

# Sensores térmicos
sensors
```
