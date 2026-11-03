---
sidebar_position: 9
---

# Applications, Flatpak, and Gaming on Fedora 45 Workstation

This guide details the installation of desktop applications, visual utilities, and gaming platforms on **Fedora 45 Workstation (GNOME Wayland)** combining **DNF5**, the mandatory **RPM Fusion (Free & Non-Free)** repositories, and **Flatpak / Flathub**.

---

## 1. Decoupled Flatpak Catalog (`./Setup/flatpak.sh`)

The `./Setup/flatpak.sh` script enables the unfiltered official **Flathub** remote and installs modular application profiles with automatic overrides for the GNOME dark theme (`adw-gtk3-dark`), Bibata cursors, and Wayland/DRI GPU acceleration:

```bash
./Setup/flatpak.sh            # Default recommended profile
./Setup/flatpak.sh --all      # Full catalog (Essential, Dev, Multimedia, Office/Social)
./Setup/flatpak.sh --status   # Fast O(1) catalog status check
```

---

## 2. Steam, GameMode, MangoHud, and Proton-GE (`./Setup/steam.sh`)

On **Fedora 45 Workstation**, Steam is installed natively from **RPM Fusion Non-Free** alongside 32-bit Mesa Vulkan/DRI drivers (`mesa-vulkan-drivers.i686`, `mesa-dri-drivers.i686`), **GameMode**, **MangoHud**, and **Proton-GE**:

```bash
# Automated installation via repository script or Justfile:
./Setup/steam.sh
# or:
just steam
```

### Equivalent Manual Commands (DNF5 + RPM Fusion):
```bash
sudo dnf5 install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
sudo dnf5 install -y steam gamemode mangohud mesa-vulkan-drivers.i686 mesa-dri-drivers.i686 pipewire-alsa.i686
flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
```
