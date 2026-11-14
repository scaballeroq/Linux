---
name: cachyos-system-maintenance
description: Procedimientos de mantenimiento del sistema, gestión de paquetes Pacman y Paru, repositorios optimizados CachyOS (x86-64-v3, multilib, chaotic-aur), cachyos-rate-mirrors, Flatpak, limpieza de disco, diagnóstico de hardware AMD Ryzen 7 7730U y Radeon Vega 8, ZRAM (zram-generator) y cortafuegos Firewalld en CachyOS Workstation con GNOME.
---

# Mantenimiento del Sistema, Pacman, Repositorios CachyOS y Diagnóstico

Esta skill define los procedimientos estándar para mantener, actualizar, aprovisionar y diagnosticar la estación de trabajo **CachyOS Workstation (GNOME Shell Wayland)** utilizando los gestores **Pacman** y **Paru**, los repositorios optimizados para **x86-64-v3**, **Flatpak**, **ZRAM**, **Ananicy-CPP**, **UKSMD** y **Firewalld**.

---

## 1. Repositorios Optimizados y Espejos de CachyOS

CachyOS proporciona paquetes compilados con flags de optimización avanzada (`-O3`, LTO, PGO y microarquitectura `x86-64-v3`).

### 1.1. Verificar Repositorios Activos:
```bash
pacman -Qe cachyos-keyring cachyos-mirrorlist
grep -E '^\[.*\]' /etc/pacman.conf
```

### 1.2. Optimización de Espejos con Rate Mirrors:
```bash
# Calibrar y ordenar los mejores servidores espejo de CachyOS y Arch
sudo cachyos-rate-mirrors
```

### 1.3. Actualización Integral del Sistema:
```bash
# Actualización del sistema base y paquetes AUR
paru -Syu --noconfirm
# O con pacman oficial
sudo pacman -Syu --noconfirm
```

---

## 2. Limpieza y Mantenimiento de Almacenamiento (NVMe Kioxia)

### 2.1. Limpieza de Caché de Paquetes:
```bash
# Mantener únicamente las 2 últimas versiones en caché
sudo paccache -r
# O limpieza interactiva
sudo pacman -Sc
```

### 2.2. Huérfanos y Archivos Temporales:
```bash
# Eliminar paquetes huérfanos sin dependencias activas
sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || true

# Ejecutar TRIM en SSD NVMe Kioxia
sudo fstrim -va
```

---

## 3. Telemetría de Hardware y Rendimiento (HP ProBook 455 G10)

### 3.1. CPU AMD Ryzen 7 7730U y Gobernador EPP:
```bash
# Frecuencias y perfiles energéticos
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | sort -u
powerprofilesctl
```

### 3.2. Aceleración Gráfica VA-API y Vulkan (Radeon Vega 8 Barcelo):
```bash
# Diagnóstico de VA-API por hardware
vainfo --display drm --device /dev/dri/renderD128

# Diagnóstico de Vulkan RADV
vulkaninfo --summary
```

### 3.3. Memoria RAM y ZRAM Swap:
```bash
zramctl
free -h
systemctl status uksmd
systemctl status ananicy-cpp
```

---

## 4. Cortafuegos Exclusivo: Firewalld

```bash
# Comprobar zona activa
sudo firewall-cmd --get-active-zones

# Estado y puertos en la zona activa (home o public)
sudo firewall-cmd --zone=home --list-all 2>/dev/null || sudo firewall-cmd --list-all
```
