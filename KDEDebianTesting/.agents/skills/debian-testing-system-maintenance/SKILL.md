---
name: debian-testing-system-maintenance
description: >-
  Use this skill when performing system updates with APT (full-upgrade/dist-upgrade), package management with APT & Flatpak, checking kernel/boot health, NVMe ext4 storage and ZRAM maintenance, hardware telemetry (Ryzen 7 PRO 4750U, amdgpu Vega 7), Firewalld network rules, or checking systemd services on Debian Testing (forky/sid) with KDE Plasma 6.
---

# Debian Testing (forky/sid) Linux System Maintenance & Telemetry Skill

Esta skill contiene los procedimientos operativos y diagnósticos estándar para la estación de trabajo HP EliteBook 855 G7 con **Debian Testing (forky/sid)**, **KDE Plasma 6 (Wayland)** y procesador **AMD Ryzen 7 PRO 4750U**.

---

## 1. Mantenimiento y Gestión de Paquetes (APT & Flatpak)

Debian Testing recibe actualizaciones continuas de paquetes desde la rama de desarrollo (actualmente *forky*). Se utilizan los repositorios oficiales (`forky`, `forky-updates`, `forky-security`, `forky-backports`) con las componentes `main contrib non-free non-free-firmware`.

### Actualización del Sistema:

```bash
# 1. Refrescar listas de paquetes de los repositorios
sudo apt update

# 2. Comprobar qué paquetes tienen actualizaciones pendientes
apt list --upgradable

# 3. Actualización estándar y segura (sin alterar dependencias críticas)
sudo apt upgrade --without-new-pkgs

# 4. Actualización completa resolviendo dependencias de nuevas versiones (recomendado en Testing)
sudo apt full-upgrade

# 5. Limpieza de paquetes huérfanos y configuraciones residuales
sudo apt autoremove --purge -y

# 6. Limpieza de archivos de instalación descargados (.deb en /var/cache/apt/archives)
sudo apt autoclean
sudo apt clean

# 7. Actualización de aplicaciones Flatpak (Flathub) y limpieza de runtimes huérfanos
flatpak update -y
flatpak uninstall --unused -y
```

### Diagnóstico y Resolución de Incidencias con APT:

```bash
# Reparar dependencias rotas tras una transacción interrumpida
sudo dpkg --configure -a
sudo apt --fix-broken install

# Localizar paquetes desconfigurados o con estado inconsistente
dpkg -l | grep -v ^ii

# Verificar si alguna actualización requiere reinicio del sistema (ej. kernel, systemd, libc)
[ -f /var/run/reboot-required ] && echo "Reinicio requerido por:" && cat /var/run/reboot-required.pkgs

# Retener (hold) un paquete específico ante una regresión en Testing
sudo apt-mark hold <paquete>
# Liberar la retención
sudo apt-mark unhold <paquete>
# Ver paquetes retenidos
apt-mark showhold

# Consultar historial reciente de instalaciones/actualizaciones de APT
tail -n 50 /var/log/dpkg.log
```

---

## 2. Almacenamiento, Particiones NVMe y Memoria ZRAM

El almacenamiento del sistema reside en un SSD NVMe de 1 TB formateado en **ext4** (con particiones independientes para `/boot/efi` y `/boot`), complementado con paginación comprimida **ZRAM** y swap en disco.

```bash
# Comprobar espacio disponible en los sistemas de archivos montados
df -h / /boot /boot/efi

# Comprobar uso de inodos (crucial en sistemas de desarrollo)
df -ih /

# Estructura de particiones, etiquetas y puntos de montaje
lsblk -o NAME,FSTYPE,LABEL,SIZE,FSUSE%,MOUNTPOINTS,MODEL

# Estado de la memoria RAM (32 GB) y paginación en ZRAM
free -h
zramctl
swapon --show

# Limpieza de registros del sistema (systemd journal) para evitar sobrellenado
journalctl --disk-usage
sudo journalctl --vacuum-time=14d
sudo journalctl --vacuum-size=500M

# Estado de salud SMART del disco NVMe (WD Blue SN570 / SanDisk)
sudo nvme smart-log /dev/nvme0n1 2>/dev/null || sudo smartctl -a /dev/nvme0n1
```

---

## 3. Telemetría y Salud del Hardware (AMD Ryzen 7 PRO 4750U + Radeon Vega)

Supervisión de temperaturas, gobernadores de frecuencia y carga de la GPU integrada Renoir:

```bash
# Frecuencias en tiempo real de los 8 núcleos / 16 hilos (Zen 2)
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | awk '{printf "CPU%02d: %.1f MHz\n", NR-1, $1/1000}'
cpupower frequency-info 2>/dev/null

# Sensores térmicos (temperatura CPU k10temp, batería, ventiladores)
sensors

# Monitor en tiempo real de la GPU AMD Radeon Vega (requiere radeontop)
radeontop

# Perfil energético activo (power-profiles-daemon)
powerprofilesctl status

# Salud y estado de carga de la batería del portátil
upower -i $(upower -e | grep battery) | grep -E "state|to\ full|percentage|energy-rate|capacity"
```

---

## 4. Servicios del Sistema y Contenedores

```bash
# Comprobar servicios del sistema fallidos
systemctl --failed

# Comprobar servicios de usuario fallidos
systemctl --user --failed

# Estado de la sesión gráfica KDE Plasma 6 y KWin Wayland
systemctl --user status plasma-plasmashell.service plasma-kwin_wayland.service

# Servidor de audio PipeWire y gestor de sesiones WirePlumber
systemctl --user status pipewire.service wireplumber.service pipewire-pulse.service
wpctl status

# Estado de contenedores Podman rootless y Quadlets de systemd
podman ps -a
systemctl --user list-units --type=service "*project*"

# Estado del hipervisor KVM/QEMU y máquinas virtuales Libvirt
virsh -c qemu:///system list --all
```

---

## 5. Gestión de Red y Cortafuegos (Firewalld)

Debian Testing está configurado con **Firewalld** (`firewall-cmd`) como motor exclusivo de seguridad de red:

```bash
# Estado activo de Firewalld
sudo firewall-cmd --state

# Listar servicios, puertos e interfaces en la zona activa predeterminada
sudo firewall-cmd --list-all

# Habilitar servicios clave de forma permanente:
# KDE Connect (puertos UDP/TCP 1714-1764)
sudo firewall-cmd --permanent --add-service=kdeconnect

# Cockpit Web Console (puerto 9090)
sudo firewall-cmd --permanent --add-service=cockpit

# Interfaz de virtualización Libvirt (virbr0) y Podman en zona de confianza
sudo firewall-cmd --permanent --zone=trusted --add-interface=virbr0
sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+

# Recargar configuración permanente tras añadir reglas
sudo firewall-cmd --reload

# Abrir puertos temporalmente durante sesiones de desarrollo:
sudo firewall-cmd --add-port=3000/tcp   # Next.js / Node
sudo firewall-cmd --add-port=5173/tcp   # Vite
sudo firewall-cmd --add-port=8000/tcp   # FastAPI / Python
sudo firewall-cmd --add-port=8080/tcp   # Desarrollo general

# Abrir un puerto de forma permanente:
sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload
```
