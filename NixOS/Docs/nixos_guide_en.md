# ❄️ NixOS Administration & Flakes Deployment Guide

This guide provides a comprehensive reference on managing **NixOS** using **Flakes** and declarative system modules.

---

## 📂 1. Configuration Layout

- **`flake.nix`**: System entry point defining inputs (`nixpkgs`, `home-manager`) and configured hosts.
- **`hosts/`**:
  - `laptop-amd/`: Profile for AMD Ryzen laptop (HP EliteBook 855 G7) with KVM, Podman, and KDE Plasma 6.
  - `desktop-intel/`: Profile for Intel Core desktop with Kodi Media Center.
- **`modules/`**: Modular decoupled components:
  - `core.nix`: Bootloader, Kernel, ZRAM, Locale, Users.
  - `desktop-kde.nix`: KDE Plasma 6 Wayland, SDDM, PipeWire, Fonts.
  - `hardware.nix`: GPU Mesa/RADV, Bluetooth, Power Profiles, Fingerprint, CUPS.
  - `virtualization.nix`: KVM/QEMU, Libvirtd, Virt-Manager, VirtioFS, Polkit.
  - `containers.nix`: Podman rootless, dockerCompat, OCI registries.
  - `development.nix`: nix-ld, Git, compilers, Mise, uv, Kitty terminal.
  - `security.nix`: Firewall (KDE Connect, SSH, Cockpit), PAM.
  - `gaming.nix`: Steam, GameMode, MangoHud.
  - `flatpak.nix`: Flatpak and Flathub support for desktop applications.

---

## 🚀 2. Workflow & Essential Commands

| Action | Just Command | Native NixOS Command |
|---|---|---|
| **Apply changes live** | `just switch` | `sudo nixos-rebuild switch --flake .#` |
| **Test configuration** | `just test` | `sudo nixos-rebuild test --flake .#` |
| **Set for next boot** | `just boot` | `sudo nixos-rebuild boot --flake .#` |
| **Update flake inputs** | `just update` | `nix flake update` |
| **Garbage collect store (GC)** | `just clean` | `sudo nix-collect-garbage -d && sudo nix-store --optimise` |
| **List system generations** | `just generations` | `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system` |
| **Rollback to previous** | `just rollback` | `sudo nixos-rebuild --rollback switch` |

---

## ⚡ 3. Ephemeral DevShell

To enter a management shell with all necessary administrative tools:

```bash
nix develop
```
