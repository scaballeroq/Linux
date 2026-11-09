---
sidebar_position: 9
---

# Applications, Flatpak, and Gaming on CachyOS Workstation

This guide details the deployment of desktop applications, visual tools, and gaming platforms on **CachyOS Workstation (GNOME Wayland)** combining **Pacman / Paru**, optimized **x86-64-v3 / multilib** repositories, and **Flatpak / Flathub**.

---

## 1. Decoupled Flatpak Catalog (`./Setup/flatpak.sh`)

The `./Setup/flatpak.sh` script enables the official unfiltered **Flathub** repository and deploys modular application profiles with GNOME overrides (Bibata cursors, PipeWire integration, Wayland, and GPU/DRI hardware acceleration):

```bash
./Setup/flatpak.sh            # Standard recommended profile
./Setup/flatpak.sh --all      # Full catalog (Essentials, Development, Multimedia, Productivity)
./Setup/flatpak.sh --status   # Quick status of installed catalog
```

---

## 2. Steam, GameMode, MangoHud, and Proton-GE (`./Setup/steam.sh`)

On **CachyOS Workstation**, Steam is installed natively from CachyOS repositories alongside 32-bit multilib drivers (`lib32-vulkan-radeon`, `lib32-mesa`), **GameMode**, **MangoHud**, and the **Proton-GE** compatibility layer:

```bash
# Automated installation using the setup script or Justfile:
./Setup/steam.sh
# or:
just steam
```

### Manual equivalent commands (Pacman):
```bash
sudo pacman -S --needed --noconfirm steam gamemode mangohud lib32-vulkan-radeon lib32-mesa lib32-pipewire
flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
```
