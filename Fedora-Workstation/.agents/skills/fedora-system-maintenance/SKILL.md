---
name: fedora-system-maintenance
description: >-
  Use this skill when performing system updates, package cleaning with DNF5, hardware telemetry (Ryzen 7 PRO 4750U, amdgpu Vega 7), Firewalld network security rules/ports, or checking systemd services on Fedora 44 Linux.
---

# Fedora 44 Linux System Maintenance & Telemetry Skill

Esta skill contiene los procedimientos y diagnósticos estándar para la estación de trabajo HP EliteBook 855 G7 con Fedora 44 Workstation y AMD Ryzen.

## 1. Mantenimiento y Gestión de Paquetes (DNF5)
Operaciones estándar con `dnf5` y Flatpak:

```bash
# Comprobar actualizaciones disponibles
sudo dnf5 check-upgrade --refresh

# Actualizar el sistema completo
sudo dnf5 upgrade --refresh -y

# Actualizar aplicaciones Flatpak
flatpak update -y

# Limpiar paquetes huérfanos y paquetes no requeridos
sudo dnf5 autoremove -y

# Limpiar caché de metadatos y paquetes descargados
sudo dnf5 clean all

# Historial de transacciones de DNF5
dnf5 history
```

---

## 2. Telemetría y Salud del Hardware (AMD Ryzen 7 PRO 4750U + Vega)
Monitoreo de frecuencia, temperaturas y carga de la GPU integrada:

```bash
# Frecuencias y gobernadores de los 8 núcleos / 16 hilos
cpupower frequency-info 2>/dev/null || cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq

# Sensores térmicos (CPU k10temp, batería, ventiladores)
sensors

# Monitor en tiempo real de la GPU AMD Radeon Vega
radeontop

# Resumen de memoria RAM (32 GB) y compresión ZRAM
free -h
zramctl

# Estado del almacenamiento y particiones (1 TB)
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINTS,MODEL
```

---

## 3. Servicios y Contenedores
```bash
# Comprobar servicios del sistema fallidos
systemctl --failed

# Comprobar servicios de usuario fallidos
systemctl --user --failed

# Estado de contenedores Podman rootless y Quadlets
podman ps -a
systemctl --user list-units --type=service "*-project*"
```

---

## 4. Gestión de Red y Cortafuegos (Firewalld)
```bash
# Estado activo del firewall
sudo firewall-cmd --state

# Listar servicios y puertos en zona predeterminada (FedoraWorkstation)
sudo firewall-cmd --zone=FedoraWorkstation --list-all

# Abrir puerto temporalmente para desarrollo
sudo firewall-cmd --zone=FedoraWorkstation --add-port=3000/tcp

# Abrir puerto permanentemente y recargar
sudo firewall-cmd --zone=FedoraWorkstation --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```
