---
name: opensuse-system-maintenance
description: >-
  Use this skill when performing system updates with Zypper dup, managing Snapper Btrfs snapshots/rollbacks, package management with Zypper & Flatpak, hardware telemetry (Ryzen 7 PRO 4750U, amdgpu Vega 7), Firewalld network rules, or checking systemd services on openSUSE Tumbleweed Linux.
---

# openSUSE Tumbleweed Linux System Maintenance & Telemetry Skill

Esta skill contiene los procedimientos y diagnósticos estándar para la estación de trabajo HP EliteBook 855 G7 con openSUSE Tumbleweed (Rolling Release), KDE Plasma 6 y AMD Ryzen.

## 1. Mantenimiento y Gestión de Paquetes (Zypper & Flatpak)
Operaciones estándar con `zypper` y Flatpak:

```bash
# Refrescar repositorios oficiales y OpenH264
sudo zypper --gpg-auto-import-keys refresh

# Actualizar el sistema completo (Tumbleweed rolling release SIEMPRE con dup)
sudo zypper --non-interactive dup

# Comprobar actualizaciones disponibles sin aplicar
zypper list-updates

# Actualizar aplicaciones Flatpak
flatpak update -y

# Limpiar paquetes huérfanos y dependencias innecesarias
sudo zypper packages --unneeded
sudo zypper rm -u <paquete>

# Limpiar caché de metadatos y paquetes descargados
sudo zypper clean -a
```

---

## 2. Gestión de Instantáneas Btrfs (Snapper)
openSUSE crea snapshots automáticos antes y después de cada transacción de Zypper.

```bash
# Listar todas las instantáneas disponibles
snapper list

# Crear una instantánea manual antes de cambios críticos
snapper create -d "Antes de actualizar kernel/stack gráfico"

# Comparar diferencias entre dos instantáneas
snapper diff <id_antiguo>..<id_nuevo>

# Revertir el sistema a una instantánea anterior (Rollback completo)
sudo snapper rollback <id>
# (Posteriormente reiniciar el sistema para arrancar en el snapshot restaurado)

# Limpieza manual de instantáneas antiguas
sudo snapper cleanup timeline
sudo snapper cleanup number
```

---

## 3. Telemetría y Salud del Hardware (AMD Ryzen 7 PRO 4750U + Vega)
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

# Estado del almacenamiento y subvolúmenes Btrfs (1 TB)
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINTS,MODEL
btrfs filesystem usage /
```

---

## 4. Servicios y Contenedores
```bash
# Comprobar servicios del sistema fallidos
systemctl --failed

# Comprobar servicios de usuario fallidos
systemctl --user --failed

# Estado del servidor gráfico Plasma y KWin
systemctl --user status plasma-plasmashell.service plasma-kwin_wayland.service

# Estado de contenedores Podman rootless y Quadlets
podman ps -a
systemctl --user list-units --type=service "*-project*"
```

---

## 5. Gestión de Red y Cortafuegos (Firewalld)
```bash
# Estado activo del firewall
sudo firewall-cmd --state

# Listar servicios y puertos en zona activa
sudo firewall-cmd --list-all

# Habilitar servicio para KDE Connect
sudo firewall-cmd --permanent --add-service=kdeconnect
sudo firewall-cmd --reload

# Abrir puerto temporalmente para desarrollo
sudo firewall-cmd --add-port=3000/tcp

# Abrir puerto permanentemente y recargar
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```
