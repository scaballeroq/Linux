---
name: fedora-system-maintenance
description: >-
  Use this skill when performing system updates, package cleaning with DNF5, hardware telemetry, Firewalld rules, or checking systemd services on Fedora 44 Linux.
---

# Fedora 44 System Maintenance & Telemetry Skill

Procedimientos operativos y diagnósticos estándar para Fedora 44 Workstation en HP ProBook 455 G10.

## 1. Mantenimiento y Actualizaciones de DNF5
```bash
# Comprobar actualizaciones
sudo dnf5 check-upgrade --refresh

# Actualizar sistema
sudo dnf5 upgrade --refresh -y

# Limpiar paquetes huérfanos
sudo dnf5 autoremove -y

# Actualizar Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Telemetría y Salud
```bash
# Espacio en disco y ZRAM
df -h
free -h
zramctl

# Sensores térmicos
sensors
```
