---
name: fedora-system-maintenance
description: Procedimientos de mantenimiento del sistema, gestión de paquetes DNF5, instalación obligatoria de RPM Fusion (Free, Non-Free, Tainted), Flatpak, limpieza de disco, diagnóstico de hardware AMD Ryzen/Radeon, ZRAM y gestión de contenedores Podman Rootless en Fedora 45 Workstation.
---

# Mantenimiento del Sistema, DNF5, RPM Fusion y Diagnóstico (Fedora 45 Workstation)

Esta skill define los procedimientos estándar para mantener, actualizar, aprovisionar y diagnosticar el sistema local **Fedora 45 Workstation** usando **DNF5** y **RPM Fusion**.

## 1. Instalación y Verificación Obligatoria de RPM Fusion (Free & Non-Free)
En Fedora 45 Workstation, **es obligatorio tener instalado y activo RPM Fusion (Free y Non-Free)** para disponer de FFmpeg completo, códecs GStreamer sin restricciones, aceleración por hardware VA-API/VDPAU en GPUs AMD Radeon (`mesa-va-drivers-freeworld`, `mesa-vdpau-drivers-freeworld`) y Steam.

- **Verificar si RPM Fusion está instalado:**
  ```bash
  rpm -q rpmfusion-free-release rpmfusion-nonfree-release
  dnf5 repolist --enabled | grep -i rpmfusion
  ```
- **Instalar RPM Fusion (Free + Non-Free + Tainted + AppStream + Cisco OpenH264):**
  ```bash
  sudo dnf5 install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
  sudo dnf5 config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
  sudo dnf5 install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data \
    rpmfusion-free-release-tainted rpmfusion-nonfree-release-tainted
  ```
- **Activar FFmpeg completo y aceleración VA-API AMD Radeon (Freeworld):**
  ```bash
  sudo dnf5 install -y --allowerasing ffmpeg ffmpeg-libs libavcodec-freeworld
  sudo dnf5 swap -y mesa-va-drivers mesa-va-drivers-freeworld || sudo dnf5 install -y --allowerasing mesa-va-drivers-freeworld
  sudo dnf5 swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld || sudo dnf5 install -y --allowerasing mesa-vdpau-drivers-freeworld
  ```

## 2. Gestión de Paquetes y Actualizaciones (`dnf5` y `flatpak`)
- **Actualizar todo el sistema (DNF5 + Flatpak + Mise):**
  ```bash
  sudo dnf5 upgrade --refresh -y && flatpak update -y && ~/.local/bin/mise upgrade
  ```
- **Limpiar paquetes huérfanos, cachés de DNF5 y runtimes Flatpak sin usar:**
  ```bash
  sudo dnf5 autoremove -y && sudo dnf5 clean all && flatpak uninstall --unused -y
  ```
- **Consultar qué paquete RPM provee un binario o librería:**
  ```bash
  dnf5 provides "*/<nombre_binario>"
  ```

## 3. Diagnóstico de Hardware, Energía y Memoria (AMD Ryzen 7 7730U / Radeon)
- **ZRAM Swap (`zram-generator` con algoritmo `zstd` al 50% de RAM):**
  ```bash
  ./Setup/zram-setup.sh --status
  zramctl
  swapon --show
  ```
- **Estado de CPU (`amd-pstate-epp`) y Perfil de Energía (`tuned-ppd` / `power-profiles-daemon`):**
  ```bash
  ./Setup/laptop-setup.sh --status
  powerprofilesctl get
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
  cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
  ```
- **Verificar aceleración por hardware de vídeo (VA-API y Vulkan RADV):**
  ```bash
  vainfo
  vulkaninfo --summary
  ```
- **Estado de optimización de Kernel (`sysctl`), límites y GNOME Tracker:**
  ```bash
  ./Setup/fedora-tuning.sh --status
  ```

## 4. Seguridad y Cortafuegos (`Firewalld` Exclusivo)
> **Regla estricta:** Prohibido usar `ufw`. Toda gestión de red se realiza mediante `firewall-cmd` y `./Setup/seguridad.sh`.
- **Estado de seguridad y zonas activas (`FedoraWorkstation`, `libvirt`, `trusted`):**
  ```bash
  ./Setup/seguridad.sh --status
  sudo firewall-cmd --list-all
  ```
- **Abrir puertos locales de desarrollo (3000, 5173, 8000, 8080):**
  ```bash
  ./Setup/seguridad.sh --dev-ports
  ```

## 5. Gestión de Contenedores (`Podman Rootless` + Quadlets) y Virtualización (`KVM/QEMU`)
- **Estado de Podman Rootless y Quadlets:**
  ```bash
  ./Podman/install/podman-install.sh --status
  ./Podman/install/quadlets-setup.sh --status
  systemctl --user status podman.socket
  ```
- **Estado de Virtualización KVM/QEMU y Libvirt modular:**
  ```bash
  ./Virtualizacion/virtualization.sh --status
  virsh -c qemu:///system list --all
  ```
