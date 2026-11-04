---
sidebar_position: 9
---

# Aplicaciones, Flatpak y Juegos en Fedora 45 Workstation

Esta guía detalla la instalación de aplicaciones de escritorio, herramientas visuales y plataformas de juegos en **Fedora 45 Workstation (GNOME Wayland)** combinando **DNF5**, los repositorios obligatorios **RPM Fusion (Free y Non-Free)** y **Flatpak / Flathub**.

---

## 1. Catálogo Desacoplado Flatpak (`./Setup/flatpak.sh`)

El script `./Setup/flatpak.sh` habilita el repositorio oficial **Flathub** sin filtros y despliega perfiles modulares de aplicaciones con overrides para GNOME (cursores Bibata, integración PipeWire, Wayland y aceleración gráfica GPU/DRI):

```bash
./Setup/flatpak.sh            # Perfil estándar recomendado
./Setup/flatpak.sh --all      # Catálogo completo (Esenciales, Desarrollo, Multimedia, Productividad)
./Setup/flatpak.sh --status   # Diagnóstico rápido del catálogo instalado
```

---

## 2. Steam, GameMode, MangoHud y Proton-GE (`./Setup/steam.sh`)

En **Fedora 45 Workstation**, Steam se instala de forma nativa desde **RPM Fusion Non-Free** junto con los controladores gráficos Mesa Vulkan/DRI de 32 bits (`mesa-vulkan-drivers.i686`, `mesa-dri-drivers.i686`), **GameMode**, **MangoHud** y la capa de compatibilidad **Proton-GE**:

```bash
# Instalación automatizada mediante el script del repositorio o Justfile:
./Setup/steam.sh
# o bien:
just steam
```

### Comandos manuales equivalentes (DNF5 + RPM Fusion):
```bash
sudo dnf5 install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf5 install -y steam gamemode mangohud mesa-vulkan-drivers.i686 mesa-dri-drivers.i686 pipewire-alsa.i686
flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
```
