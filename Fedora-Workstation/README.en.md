# 🔧 Fedora 45 Workstation Environment Configuration (GNOME Shell Wayland)

This repository contains an organized, modular, and automated collection of configuration scripts for **Fedora 45 Workstation** systems running the **GNOME Shell (Wayland / Mutter)** desktop environment, **DNF5** package manager, mandatory **RPM Fusion (Free, Non-Free & Tainted)** repositories, and hardware optimizations for **HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics)** workstations in dark mode.

---

## 📂 Repository Organization

### 🐚 [Bash.Setup](./Bash.Setup/)
Terminal configuration core, optimized for **Bash** (modular support via `~/.bashrc.d`) and **Zsh** (modular support via `~/.zshrc.d`):
- **`aliases.sh`**: Productivity aliases, dynamic shell reload, Nautilus, Git, Firewalld (`fw*`), Libvirt, Podman, and **DNF5** package manager shortcuts.
- **`environment.sh`**: Global variables (`EDITOR`, `PATH`, Wayland/GNOME, `QT_QPA_PLATFORMTHEME="gnome"`, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) and Mise initialization.
- **`functions.sh`**: Advanced shell helper functions (`mkcd`, `up`, `hg`) and media processing utilities.
- **`gnome_settings.sh`**: Environment settings and keybindings for GNOME Wayland (dark theme `adw-gtk3-dark`, Night Light 4000K, Wayland capture with `grim`/`slurp`/`satty`, Nautilus).
- **`history.sh`**: Optimized shell history (deduplication, instant sync, timestamps).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction, case-insensitive completion).
- **`podman-functions.sh`**: Rootless Podman and Quadlet helper functions.
- **`rclone_aliases.sh`**: Cloud storage synchronization shortcuts (Google Drive / OneDrive).
- **`yt-dlp_aliases.sh`**: Media download helpers.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with native systemd Quadlets:
- **`install/podman-install.sh`**: Rootless Podman installation, socket, linger, registries, and `passt` network backend (`--status`).
- **`install/quadlets-setup.sh`**: Directory structure and systemd Quadlet setup (`--status`).
- **`lib/podman-utils.sh`**: Project management CLI (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU, modular Libvirt, `virt-manager`, `virtio-win`, Btrfs NoCoW, and Firewalld configuration for Fedora 45 (`--status`).
- **`notas_virtualizacion_fedora.md`**: In-depth virtualization notes for KVM, VirtIO, bridge networking, and storage on Fedora 45.

### ⚙️ [Setup](./Setup/)
Operating system setup, GNOME Shell personalization, and hardening:
- **`post-install.sh`**: Intelligent dispatcher with CPU auto-detection (AMD Ryzen vs Intel Core, `--status`).
- **`post-install-amd.sh`**: Post-installation optimized for AMD Ryzen & Radeon (**mandatory RPM Fusion Free/Non-Free/Tainted**, `fedora-cisco-openh264`, AMD microcode, RADV Vulkan, `mesa-va-drivers-freeworld`, full FFmpeg, ZRAM zstd, Flathub, `--status`).
- **`post-install-intel.sh`**: Post-installation optimized for Intel Core / Media Center (**mandatory RPM Fusion**, Intel VA-API, full FFmpeg, PipeWire, `--status`).
- **`zram-setup.sh`**: Dedicated compressed RAM swap configurator via `zram-generator` (`zstd`, 50% RAM, priority 100, `vm.page-cluster=0`, `--status`, `--disable`).
- **`fedora-tuning.sh`**: Kernel tuning (`sysctl` inotify 1M, `max_map_count` 16M, TCP BBR), resource limits (`limits.d`), Systemd fast shutdown timeouts, and GNOME Tracker exclusions (`--status`, `--sysctl`, `--limits`, `--tracker`, `--zram`).
- **`laptop-setup.sh`**: Laptop optimizations (`tuned-ppd`/`power-profiles-daemon`, battery Wh health telemetry, AMD P-State EPP, DRM multi-monitor topology `DP-3`/`DP-4`/`eDP-1`, docked lid behavior with safe `systemctl reload systemd-logind`, Touchpad Wayland gestures, and Bluetooth `FastConnectable=true`, `--status`).
- **`apariencia.sh`**: Modular and interactive (`--interactive`) GTK theme (`adw-gtk3-dark`), icon (`Papirus-Dark`), and cursor (`Bibata-Modern-Classic` / `Bibata-Modern-Ice`) manager (`--status`).
- **`gnome-settings.sh`**: Comprehensive and interactive (`--interactive`) GNOME Shell Wayland configurator (dark mode, terminal selector `kitty`/`ghostty`/`ptyxis`/`gnome-terminal`, window buttons, Mutter VRR, Night Light 4000K, 24h clock, and Nautilus Python extensions, `--status`).
- **`gnome-extensions.sh`**: Extension manager and installer (GSConnect, Dash to Dock, AppIndicator, Blur my Shell, Tiling Shell, `--status`).
- **`gsconnect.sh`**: Mobile integration with GSConnect and automatic Firewalld rules (`--status`).
- **`fingerprint-setup.sh`**: Biometric fingerprint authentication setup (`fprintd` + `authselect` PAM, `--status`).
- **`hp-printer-setup.sh`**: HP printer installer and manager (CUPS, HPLIP, proprietary plugin, Firewalld, `--status`).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with 75% opacity, blur 32, Catppuccin Mocha theme, and top-level Nautilus context menu (`nautilus-python`, `--status`).
- **`ghostty.sh`**: Ghostty terminal with Catppuccin Mocha theme, 85% opacity, and top-level Nautilus context menu (`--status`, `--default-terminal`).
- **`ptyxis.sh`**: Native container-aware Ptyxis terminal with Catppuccin Mocha palette, 85% opacity, and top-level Nautilus context menu (`--status`, `--default-terminal`).
- **`zsh-setup.sh`**: Full Zsh replication (`zsh-autosuggestions`, `zsh-syntax-highlighting`, FZF, Zoxide, Mise, Starship, and modular `~/.zshrc.d/*.zsh`, `--status`, `--default-shell`).
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `btop`, `jq`, `--status`).
- **`starship.sh` & `starship.toml`**: Modern Starship prompt with Fedora theme (`--status`).
- **`fastfetch.sh` & `config-*.jsonc`**: System info summary with multi-theme support (`fedora` categorized Hero theme, `fedora-simple`, `modern`, `compact`, `--menu`, `--preview`, `--status`).
- **`fonts.sh`**: Automated Nerd Fonts installer (`--status`).
- **`seguridad.sh`**: Security hardening with exclusive Firewalld (`ufw` masked, `FedoraWorkstation` zone, GSConnect, `podman+` in `trusted`, `virbr0` in `libvirt`, `--dev-ports` for 3000/5173/8000/8080, DNS-over-TLS, and sysctl with `accept_ra=2`, `--status`).
- **`cockpit.sh`**: Cockpit web management console (`--status`).
- **`multimedia.sh`**: **Mandatory RPM Fusion (Free, Non-Free & Tainted)** + Cisco OpenH264, unrestricted `ffmpeg`, freeworld VA-API (`mesa-va-drivers-freeworld`), GStreamer 1.26+, Nautilus thumbnails (`glycin-loaders`, `ffmpegthumbnailer`), and Wayland players (Showtime, Loupe, Amberol, Celluloid, MPV Vulkan/VA-API, VLC, `--status`).
- **`flatpak.sh`**: Decoupled Flathub catalog (Flatseal, Podman Desktop, Warehouse, Kdenlive, Shotcut, VLC, OBS Studio, LocalSend...) with Wayland/GTK overrides (`--status`, `--all`).
- **`chrome.sh`**, **`firefox.sh`**, **`steam.sh`**

### 💻 [IDE](./IDE/) & ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
- **`antigravity.sh`**, **`antigravity-cli.sh`**, **`antigravity-ide.sh`**, **`git.sh`**, **`opencode.sh`**
- **`mise.sh`**, **`python.sh`** & **`python-uv-init.sh`**, **`nodejs.sh`**, **`rust.sh`**, **`java.sh`**, **`dotnet.sh`**, **`angular.sh`**

---

## 🚀 Fast Deployment with Just

```bash
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Development Laptop (AMD Ryzen + RPM Fusion + GNOME Wayland + Virtualization + Podman):
just setup-laptop-amd

# Full default setup:
just setup-all

# Provision mandatory RPM Fusion (Free, Non-Free, Tainted), FFmpeg & VA-API Freeworld:
just rpmfusion

# Check status across all subsystems:
just status
```
