---
name: arch-system-maintenance
description: >-
  Use this skill when performing system updates, package cleaning, AUR management with yay/paru, hardware telemetry (Ryzen 7 PRO 4750U, amdgpu Vega 7), or checking systemd services on Arch Linux.
---

# Arch Linux System Maintenance & Telemetry Skill

Esta skill contiene los procedimientos y diagnósticos estándar para la estación de trabajo HP EliteBook 855 G7 con Arch Linux y AMD Ryzen.

## 1. Mantenimiento y Gestión de Paquetes
Operaciones con `pacman` y el helper AUR (`yay` / `paru`):

```bash
# Actualizar repositorios oficiales y AUR
yay -Syu

# Limpiar paquetes huérfanos sin dependencias
yay -Qtdq | yay -Rns -

# Limpiar caché de paquetes pacman preservando las últimas 2 versiones instaladas
paccache -r

# Buscar paquetes instalados explícitamente
pacman -Qe
```

---

## 2. Telemetría y Salud del Hardware (AMD Ryzen 7 PRO 4750U + Vega)
Monitoreo de frecuencia, temperaturas y carga de la GPU integrada:

```bash
# Frecuencias y gobernadores de los 8 núcleos / 16 hilos
cpupower frequency-info

# Sensores térmicos (CPU k10temp, batería, ventiladores)
sensors

# Monitor en tiempo real de la GPU AMD Radeon Vega
radeontop
# o amdgpu_top (si está instalado)
amdgpu_top --gui=tui

# Resumen de memoria RAM (32 GB) y swap/zram
free -h

# Estado del almacenamiento y particiones (1 TB)
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINTS,MODEL
```

---

## 3. Servicios y Contenedores
```bash
# Comprobar servicios de usuario fallidos
systemctl --user --failed

# Estado de contenedores Podman rootless y Quadlets
podman ps -a
systemctl --user list-units --type=service "podman-*"
```
