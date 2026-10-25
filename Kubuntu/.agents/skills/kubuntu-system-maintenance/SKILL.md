---
name: kubuntu-system-maintenance
description: >-
  Use this skill when managing packages with APT, updating system, cleaning caches, or checking hardware telemetry on Kubuntu.
---

# Kubuntu System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Kubuntu en HP ProBook 455 G10.

## 1. Mantenimiento y Actualizaciones
```bash
# Actualizar lista de paquetes y sistema
sudo apt update
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
# Espacio y memoria
df -h
free -h
zramctl

# Sensores
sensors
```
