---
name: debian-system-maintenance
description: >-
  Use this skill when managing packages with APT, performing system updates, cleaning package caches, verifying systemd services, or checking hardware telemetry on the HP Z230 SFF TV Workstation (Intel Core i7-4790, Intel HD 4600).
---

# Debian System Maintenance & Hardware Telemetry Skill (HP Z230 SFF TV)

Procedimientos operativos y diagnósticos estándar para Debian GNU/Linux en el centro multimedia **HP Z230 SFF Workstation** conectado a la televisión.

## 1. Mantenimiento y Actualizaciones del Sistema
```bash
# 1. Refrescar repositorios APT y actualizar sistema base
sudo apt update && sudo apt upgrade -y

# 2. Actualizar aplicaciones multimedia Flatpak (Kodi, Stremio, VLC)
flatpak update -y

# 3. Limpieza de paquetes huérfanos y cachés para preservar el SSD de 256 GB
sudo apt autoremove --purge -y
sudo apt autoclean
flatpak uninstall --unused -y

# 4. Verificar temporizador de TRIM para el SSD
systemctl is-active fstrim.timer || sudo systemctl enable --now fstrim.timer
```

## 2. Telemetría y Salud de Hardware (Intel Core i7-4790 & HD 4600)
```bash
# Espacio en disco SSD (256 GB) y memoria RAM (8 GB)
df -h / /boot /boot/efi
free -h
zramctl 2>/dev/null || true

# Diagnóstico de CPU y temperaturas
lscpu | grep "Model name\|CPU(s):\|Thread(s) per core"
sensors 2>/dev/null || true

# Diagnóstico de aceleración gráfica Intel Haswell (VA-API H.264)
vainfo 2>/dev/null | grep -E "Driver version|VAProfileH264|VAEntrypoint"
intel_gpu_top -s 1000 2>/dev/null || echo "intel-gpu-tools no instalado (sudo apt install intel-gpu-tools)"
```

## 3. Estado de Servicios Multimedia y Audio
```bash
# Verificar estado de PipeWire y WirePlumber (HDMI Sony TV)
systemctl --user status pipewire pipewire-pulse wireplumber --no-pager
wpctl status | grep -E "Audio|Sinks"
```
