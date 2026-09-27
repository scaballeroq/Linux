# ❄️ NixOS Environment Configuration (KDE Plasma 6 & Flakes)

This repository contains an organized, modular, declarative, and automated collection of configuration scripts for **NixOS** systems with the **KDE Plasma 6** desktop environment on **Wayland** (optimized for HP EliteBook laptops and dark-mode development workstations).

---

## 📂 Repository Organization

The configuration is structured in a modular, reproducible manner using **Nix Flakes** and complementary environment scripts:

### ❄️ [Declarative NixOS Architecture](./flake.nix)
- **`flake.nix`**: Declarative entry point orchestrating inputs (`nixpkgs-unstable`, `nixpkgs-24.11`, `home-manager`), devshells, and system host outputs.
- **`configuration.nix`**: Unified system configuration importing essential modules.
- **`hosts/`**: Decoupled hardware profiles:
  - **`laptop-amd/`**: Development laptop (AMD Ryzen 7 PRO 4750U / HP EliteBook 855 G7) with KVM, Podman, and KDE Plasma 6.
  - **`desktop-intel/`**: Media Center Desktop (Intel Core / Haswell + Kodi).
- **`modules/`**: Independent system modules:
  - **`core.nix`**: systemd-boot bootloader, optimized Linux kernel, ZRAM swap with ZSTD compression, sysctl tweaks, and localization (`es_ES.UTF-8`).
  - **`desktop-kde.nix`**: Native KDE Plasma 6 Wayland, SDDM Wayland, PipeWire + WirePlumber audio, XDG portals, and typography.
  - **`hardware.nix`**: Mesa/RADV/VA-API graphics drivers, Bluetooth with battery reporting and fast connect, `power-profiles-daemon`, `fprintd` fingerprint authentication, and CUPS/HPLIP.
  - **`virtualization.nix`**: KVM/QEMU hypervisor, modular Libvirtd, Virt-Manager, VirtioFS, and Polkit rules for the `libvirtd` group.
  - **`containers.nix`**: Rootless Podman engine, Docker API emulation (`podman-docker`), registries, and overlay storage.
  - **`development.nix`**: `nix-ld` support for dynamic ELF binaries (VS Code, Google Antigravity, OpenCode), Git, compilers, Mise, uv, and modern CLI tools.
  - **`security.nix`**: Network firewall (KDE Connect, SSH, Cockpit, virtual interfaces `virbr0`, `podman+`) and PAM hardening.
  - **`gaming.nix`**: Native Steam, GameMode, MangoHud, and 32-bit Vulkan support.
  - **`flatpak.nix`**: Flatpak service and Flathub catalog integration for decoupled desktop applications.

### 🐚 [Bash.Setup](./Bash.Setup/)
Modular shell setup for **Bash** (default via `~/.bashrc.d`) and **Zsh**:
- **`aliases.sh`**: Navigation shortcuts, modern Rust utilities (`eza`, `bat`, `duf`, `dust`), Dolphin integration (`kioclient6`), declarative NixOS commands (`switch`, `rebuild`, `test-build`, `nix-update`, `nix-clean`, `generations`, `rollback`), and ephemeral searches (`nshell`, `nrun`).
- **`environment.sh`**: Global variables (`EDITOR`, `PATH` prioritizing `~/.local/bin`, `~/.nix-profile/bin`, `/run/current-system/sw/bin`, Wayland Qt, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`), and Mise activation.
- **`functions.sh`**: Advanced functions (`mkcd`, `up`, `extract`, `duh`, `nix-where`, `nix-diff-generations`), and media utilities (FFmpeg / ImageMagick).
- **`kde_settings.sh`**: Shortcuts for KDE Plasma 6 Wayland (Breeze Dark/Light, Night Color, Plasma/KWin restart, KCM access).
- **`history.sh`**: Optimized history retention (deduplication, 20k commands capacity).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction with `cdspell`, extended globbing).
- **`podman-functions.sh`**: Functions and aliases for rootless Podman containers and Quadlets.
- **`rclone_aliases.sh`**: Cloud synchronization aliases for Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Optimized multimedia download aliases with yt-dlp and FFmpeg.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with native systemd Quadlets:
- **`install/podman-install.sh`**: Rootless Podman configuration, Docker API socket, linger, and CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Directory setup and systemd Quadlet service generator.
- **`lib/podman-utils.sh`**: CLI for project management (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directory for active projects.
- **`templates/`**: Project templates (`python-postgres`, `python-postgres-redis`, `fullstack`).
- **`scripts-standalone/`**: Standalone scripts to deploy PostgreSQL, Redis, Adminer, MinIO, RabbitMQ, MongoDB, etc.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Virtualization diagnostics and management (KVM/QEMU, modular Libvirt, virt-manager, virtio-win) with full CLI (`--status`, `--with-windows`, `--help`).
- **`notas_virtualizacion_nixos.md`**: In-depth virtualization notes for NixOS.

### ⚙️ [Setup](./Setup/)
System provisioning, KDE Plasma 6 customization, and diagnostics:
- **`post-install.sh`**: Smart CPU dispatcher (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-installation for AMD Ryzen (flake `laptop-amd`, Flatpak Flathub, Kitty, Starship, Fastfetch).
- **`post-install-intel.sh`**: Post-installation for Intel Core / Media Center (flake `desktop-intel`, Kodi, Flatpak).
- **`kde-settings.sh`**: KDE Plasma 6 configuration (Breeze Dark, KWin buttons, Dolphin servicemenus for Kitty and Antigravity, Night Color at 4000K, Ctrl+Alt+T shortcut).
- **`laptop-setup.sh`**: Laptop optimization (power-profiles-daemon, Bluetooth FastConnectable, smart lid management, Wayland Touchpad).
- **`fingerprint-setup.sh`**: Fingerprint enrollment and PAM status (`fprintd` on NixOS, `--status`, `--enroll`, `--verify`, `--delete`).
- **`nixos-tuning.sh`**: System maintenance (garbage collection in `/nix/store`, hard link optimization, ZRAM, sysctl, `--status`, `--gc`, `--optimise`, `--generations`, `--verify`).
- **`cockpit.sh`**: Cockpit web console (`--status`, `--open`, `--start`, `--stop`).
- **`fastfetch.sh`**: Aesthetic system info summary with Snowflake Hero Theme (`--theme nix`, `--theme compact`, `--status`, `--run`).
- **`fonts.sh`**: Developer font diagnostics (JetBrainsMono, FiraCode, CascadiaCode, Meslo, and Hack Nerd Fonts).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity/blur, Catppuccin Mocha theme, Ctrl+Alt+T shortcut, and Dolphin servicemenu.
- **`seguridad.sh`**: Firewall diagnostics and open ports check (KDE Connect, SSH, Cockpit, virbr0, podman).
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Modern Starship prompt with NixOS snowflake theme (`--enable`, `--disable`, `--status`).
- **`yt-dlp-setup.sh`**: Multimedia stack dependencies (yt-dlp, FFmpeg, aria2).
- **`multimedia.sh`**: Multimedia codecs and VA-API hardware acceleration diagnostics.
- **`flatpak.sh`**: Suite of decoupled desktop applications via Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Spotify, Vesktop...).
- **`chrome.sh`**: Official Google Chrome launcher and manager with native Wayland support.
- **`steam.sh`**: Native Steam configuration with GameMode, MangoHud, and 32-bit Vulkan drivers.
- **`hp-printer-setup.sh`**: Printing stack for HP printers (CUPS, HPLIP, LaserJet M15w).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (compatible with NixOS via `nix-ld` and Chromium sandbox).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) rootless setup in `~/.local/bin`.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta, Lazygit, and GitHub CLI setup with recommended global configuration.
- **`opencode.sh`**: OpenCode AI CLI setup integrated into PATH.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Modern runtime management with **Mise**, **uv**, and **Rustup**:
- **`mise.sh`**: Mise version manager with `environment.d` integration.
- **`python.sh` & `python-uv-init.sh`**: Python environment and `uv` package manager with interactive project scaffolding (FastAPI, CLI, Data Science).
- **`nodejs.sh`**: Active Node.js LTS with Corepack (`pnpm`, `yarn`).
- **`rust.sh`**: Rustup Stable channel with `rust-analyzer`, `clippy`, and `cargo-binstall`.
- **`dotnet.sh`**: .NET SDK LTS.
- **`java.sh`**: OpenJDK LTS (Java 21).
- **`angular.sh`**: Angular CLI.

---

## 🚀 Quick Deployment with Just

To run the automated deployment based on your hardware profile:

```bash
git clone https://github.com/scaballeroq/NixOS.git
cd NixOS
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Juegos/*.sh

# Development Laptop (AMD Ryzen + KDE Plasma 6 + Virtualization + Podman):
just setup-laptop-amd

# Media Center Desktop (Intel Core / Media Center - Without virtualization):
just setup-media-desktop

# Or complete default installation:
just setup-all
```

Or run declarative NixOS operations:
```bash
just switch              # Apply current host configuration live
just test                # Test configuration without modifying bootloader
just boot                # Stage configuration for next boot
just update              # Update flake inputs (nix flake update)
just clean               # Garbage collect and optimize /nix/store
just generations         # List active generations in system profile
just rollback            # Rollback to previous generation immediately
```

---

*Maintained by [caballero](https://github.com/scaballeroq)*
