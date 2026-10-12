---
name: soplos-system-maintenance
description: >-
  Use this skill when managing packages with APT, updating initramfs with dracut, configuring GRUB bootloader, updating system, or checking hardware telemetry on Soplos Linux Tyson.
---

# Soplos Linux Tyson System Maintenance Skill

Procedimientos operativos y diagnósticos estándar para Soplos Linux Tyson en HP EliteBook 855 G7.

## 1. Mantenimiento y Actualizaciones de APT
```bash
# Refrescar repositorios
sudo apt update

# Actualización completa resolviendo transiciones
sudo apt full-upgrade -y

# Limpiar huérfanos
sudo apt autoremove --purge -y
sudo apt autoclean

# Flatpak
flatpak update -y
flatpak uninstall --unused -y
```

## 2. Gestión de Initramfs y Arranque (dracut y GRUB)
```bash
# Reconstruir initramfs para el kernel actual con dracut
sudo dracut --force

# Reconstruir initramfs para todos los kernels instalados
sudo dracut --regenerate-all --force

# Actualizar configuración del gestor de arranque GRUB
sudo update-grub
```

## 3. Telemetría y Salud
```bash
df -h
free -h
zramctl
sensors
```
