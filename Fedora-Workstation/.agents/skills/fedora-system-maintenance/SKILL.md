---
name: fedora-system-maintenance
description: Procedimientos de mantenimiento del sistema, gestión de paquetes DNF5, instalación obligatoria de RPM Fusion (Free, Non-Free, Tainted, AppStream), Flatpak, limpieza de disco, diagnóstico de hardware AMD Ryzen 7 7730U y Radeon Vega 8, ZRAM (zram-generator) y cortafuegos Firewalld en Fedora 45 Workstation con GNOME 51.
---

# Mantenimiento del Sistema, DNF5, RPM Fusion y Diagnóstico (Fedora 45 Workstation + GNOME 51)

Esta skill define los procedimientos estándar para mantener, actualizar, aprovisionar y diagnosticar la estación de trabajo **Fedora 45 Workstation (GNOME Shell 51 Wayland)** utilizando el gestor moderno **DNF5**, los repositorios obligatorios de **RPM Fusion**, **Flatpak**, **ZRAM** y **Firewalld**.

---

## 1. Instalación y Verificación Obligatoria de RPM Fusion (Free & Non-Free)

En Fedora 45 Workstation, **es obligatorio tener instalado y activo RPM Fusion (Free y Non-Free)** para disponer de FFmpeg completo, códecs GStreamer sin restricciones, aceleración por hardware VA-API/VDPAU en GPUs AMD Radeon (`mesa-va-drivers-freeworld`, `mesa-vdpau-drivers-freeworld`) y clientes de juegos (Steam).

### 1.1. Verificar Repositorios RPM Fusion:
```bash
rpm -q rpmfusion-free-release rpmfusion-nonfree-release
dnf5 repolist --enabled | grep -i rpmfusion
```

### 1.2. Instalación de RPM Fusion (Free + Non-Free + Tainted + AppStream + Cisco OpenH264):
```bash
sudo dnf5 install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf5 config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
sudo dnf5 install -y --skip-unavailable \
  rpmfusion-free-appstream-data \
  rpmfusion-nonfree-appstream-data \
  rpmfusion-free-release-tainted \
  rpmfusion-nonfree-release-tainted
```

### 1.3. FFmpeg Completo y Aceleración VA-API AMD Radeon (Freeworld):
```bash
sudo dnf5 install -y --allowerasing ffmpeg ffmpeg-libs libavcodec-freeworld
sudo dnf5 swap -y mesa-va-drivers mesa-va-drivers-freeworld || sudo dnf5 install -y --allowerasing mesa-va-drivers-freeworld
sudo dnf5 swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld || sudo dnf5 install -y --allowerasing mesa-vdpau-drivers-freeworld
```

### 1.4. Script y Receta de Automatización:
```bash
./Setup/multimedia.sh --status
just rpmfusion
just multimedia
```

---

## 2. Gestión de Paquetes y Actualizaciones (`dnf5` y `flatpak`)

Fedora 45 utiliza de manera nativa **DNF5** (`/usr/bin/dnf5`), que ofrece mayor velocidad, menor consumo de memoria y resolución transaccional optimizada.

### 2.1. Actualización Integral del Sistema (DNF5 + Flatpak + Mise):
```bash
sudo dnf5 upgrade --refresh -y && flatpak update -y && ~/.local/bin/mise upgrade
```
*O mediante la receta Justfile:*
```bash
just upgrade
```

### 2.2. Limpieza de Disco y Mantenimiento de Paquetes:
```bash
# Limpiar paquetes huérfanos, caché de metadatos y runtimes Flatpak no utilizados
sudo dnf5 autoremove -y && sudo dnf5 clean all && flatpak uninstall --unused -y
```
*O mediante la receta Justfile:*
```bash
just clean
```

### 2.3. Búsqueda e Inspección de Paquetes con DNF5:
```bash
# Averiguar qué paquete provee un binario o archivo específico:
dnf5 provides "*/<nombre_binario>"

# Buscar paquetes disponibles:
dnf5 search <termino>

# Inspeccionar dependencias de un paquete instalado:
dnf5 repoquery --requires <paquete>
```

---

## 3. Diagnóstico de Hardware AMD Ryzen / Radeon y Rendimiento

### 3.1. ZRAM Swap (`zram-generator` con algoritmo `zstd` al 50% de RAM):
En el HP ProBook 455 G10 con 32 GB de RAM, ZRAM provee 16 GB de swap ultrarrápida comprimida en RAM.
```bash
# Diagnóstico de ZRAM y dispositivos de swap activos
./Setup/zram-setup.sh --status
zramctl
swapon --show
```

### 3.2. CPU AMD Ryzen 7 7730U y Perfil de Energía (`amd-pstate-epp`):
```bash
# Diagnóstico de batería, CPU scaling y perfiles de energía
./Setup/laptop-setup.sh --status

# Consultar y modificar perfil de energía activo (power-profiles-daemon / tuned-ppd)
powerprofilesctl get
powerprofilesctl set balanced   # o 'performance' / 'power-saver'

# Driver de escalado y preferencia de rendimiento de la CPU
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
```

### 3.3. GPU AMD Radeon Graphics (Mesa RADV Vulkan y VA-API por Hardware):
```bash
# Verificar aceleración de decodificación/codificación por hardware de vídeo
vainfo

# Resumen de capacidades Vulkan (Mesa RADV)
vulkaninfo --summary
```

### 3.4. Optimización de Kernel (`sysctl`), Límites y GNOME Tracker:
```bash
./Setup/fedora-tuning.sh --status
```

---

## 4. Seguridad de Red y Cortafuegos (`Firewalld` Exclusivo)

> **Regla estricta:** Está terminantemente prohibido utilizar `ufw` o reglas crudas de `iptables`. Toda la configuración se realiza mediante `firewall-cmd`.

### 4.1. Inspección de Zonas Activas (`FedoraWorkstation`, `trusted`, `libvirt`):
```bash
./Setup/seguridad.sh --status
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=FedoraWorkstation --list-all
```

### 4.2. Apertura Idempotente de Puertos Locales para Desarrollo:
```bash
# Apertura automatizada de puertos comunes de desarrollo (3000, 5173, 8000, 8080)
./Setup/seguridad.sh --dev-ports

# Comandos directos con firewall-cmd:
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=5173/tcp  # Vite
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=3000/tcp  # Next.js
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=8000/tcp  # FastAPI / Django
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=cockpit # Cockpit 9090
sudo firewall-cmd --reload
```

---

## 5. Diagnóstico Global con Justfile

El repositorio dispone de un orquestador centralizado mediante `justfile`:
```bash
# Diagnóstico integral de la estación de trabajo
just status

# Diagnóstico de audio, multimedia y Flatpak
just multimedia-status
just flatpak-status
```
