---
name: cachy-system-maintenance
description: >-
  Use this skill when performing system updates, package cleaning, AUR management with yay/paru, hardware telemetry (Ryzen 7 PRO 4750U, amdgpu Vega 7), Firewalld network security rules/ports, or checking systemd services on CachyOS Linux.
---

# CachyOS Linux System Maintenance & Telemetry Skill

Esta skill contiene los procedimientos y diagnósticos estándar para la estación de trabajo HP EliteBook 855 G7 con CachyOS Linux y AMD Ryzen.

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

---

## 4. Gestión de Seguridad y Firewall (Firewalld Obligatorio)
El firewall del sistema es **Firewalld** (zona `home` por defecto para red doméstica):

```bash
# Comprobar estado y zonas activas
sudo firewall-cmd --state
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=home --list-all

# Abrir puertos para servidores de desarrollo local en la LAN
sudo firewall-cmd --zone=home --add-port=3000/tcp --permanent
sudo firewall-cmd --zone=home --add-port=8000/tcp --permanent
sudo firewall-cmd --reload

# Comprobar si un puerto está abierto
sudo firewall-cmd --zone=home --query-port=3000/tcp

# Verificar NAT / Masquerade (para VMs de KVM y contenedores Podman)
sudo firewall-cmd --zone=home --query-masquerade

# Ejecutar diagnóstico completo del script de seguridad
./Setup/seguridad.sh --status
```
