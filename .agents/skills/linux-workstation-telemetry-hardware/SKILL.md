---
name: linux-workstation-telemetry-hardware
description: >-
  Use this skill when checking HP EliteBook 855 G7 workstation telemetry (AMD Ryzen 7 PRO 4750U, Vega 7 GPU), NVMe ext4/btrfs storage, ZRAM memory usage, multi-monitor topology (DP-3, DP-4, eDP-1), PipeWire/WirePlumber audio status, or Firewalld network firewall rules across Linux distributions.
---

# Workstation Telemetry & Hardware Diagnostics Skill

Esta skill contiene los comandos unificados para inspeccionar y diagnosticar la salud de la estación de trabajo **HP EliteBook 855 G7** con procesador **AMD Ryzen 7 PRO 4750U**, gráficos **Radeon Vega 7** y triple monitor.

---

## 1. Telemetría de CPU y GPU (AMD Renoir)

```bash
# Frecuencias en tiempo real de los 8 núcleos / 16 hilos Zen 2
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | awk '{printf "CPU%02d: %.1f MHz\n", NR-1, $1/1000}'

# Sensores térmicos (temperatura CPU k10temp, batería, ventiladores)
sensors

# Monitor en tiempo real de la GPU AMD Radeon Vega (si está disponible)
radeontop 2>/dev/null || cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null

# Perfil energético activo (power-profiles-daemon)
powerprofilesctl status 2>/dev/null || true

# Salud y estado de carga de la batería del portátil
upower -i $(upower -e | grep battery | head -n 1) | grep -E "state|to\ full|percentage|energy-rate|capacity"
```

---

## 2. Memoria, Swap y Almacenamiento NVMe

```bash
# Estado de la memoria RAM (32 GB) y paginación en ZRAM
free -h
zramctl 2>/dev/null || true
swapon --show

# Espacio disponible en disco y puntos de montaje
df -h / /boot /boot/efi 2>/dev/null || df -h

# Particionamiento y tipo de sistema de archivos
lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS,MODEL

# Salud SMART del disco NVMe
sudo nvme smart-log /dev/nvme0n1 2>/dev/null || sudo smartctl -a /dev/nvme0n1 2>/dev/null || true
```

---

## 3. Disposición de Monitores (Triple Pantalla Full HD)

La estación cuenta con tres pantallas a 1080p:
1. **DP-3**: Monitor principal de trabajo (1920x1080 @ 60Hz, posición `0,0`)
2. **DP-4**: Monitor secundario extendido (1920x1080 @ 60Hz, posición `1920,0`)
3. **eDP-1**: Pantalla integrada del portátil (1920x1080 @ 60Hz, posición `0,1080`)

```bash
# En entornos KDE Plasma 6:
kscreen-doctor -o 2>/dev/null

# En entornos GNOME Shell (Wayland):
cat ~/.config/monitors.xml 2>/dev/null

# En entornos Niri:
niri msg outputs 2>/dev/null

# En entornos Hyprland:
hyprctl monitors 2>/dev/null
```

---

## 4. Control de Audio (PipeWire & WirePlumber)

```bash
# Diagnóstico de servidores y nodos de audio
wpctl status

# Subir / bajar volumen en salida predeterminada
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

# Alternar silenciado (mute)
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

---

## 5. Cortafuegos y Seguridad de Red (Firewalld)

Todas las distribuciones del repositorio utilizan exclusivamente **Firewalld** (`firewall-cmd`):

```bash
# Estado del demonio firewalld
sudo firewall-cmd --state

# Resumen de reglas, servicios y puertos en la zona activa
sudo firewall-cmd --list-all

# Habilitar servicios habituales de desarrollo:
sudo firewall-cmd --permanent --add-service=kdeconnect
sudo firewall-cmd --permanent --add-service=cockpit
sudo firewall-cmd --permanent --zone=trusted --add-interface=virbr0
sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+
sudo firewall-cmd --reload

# Apertura temporal de puertos para servidores web:
sudo firewall-cmd --add-port=3000/tcp   # Next.js / Node
sudo firewall-cmd --add-port=5173/tcp   # Vite
sudo firewall-cmd --add-port=8000/tcp   # FastAPI / Python
```
