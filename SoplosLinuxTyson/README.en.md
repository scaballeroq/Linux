# 🐧 Soplos Linux Tyson: Debian Testing + KDE Plasma 6 Environment Setup

This repository contains an organized, modular, and automated collection of configuration scripts for **Soplos Linux Tyson** (derived directly from **Debian Testing**) with **KDE Plasma 6**, **dracut** initramfs management, **GRUB** bootloader, and service/container management with **systemd** and **Podman**.

---

## 📂 Repository Structure

The configuration is modularly structured for ease of maintenance and deployment:

### 🐚 [Bash.Setup](./Bash.Setup/)
Core terminal configuration (shared between Bash and Zsh).
- **`aliases.sh`**: Common shortcuts and modern Rust utilities (`eza`, `bat`, `duf`, `dust`).
- **`environment.sh`**: Global environment variables (`PATH`, `EDITOR`, colored `less` pager).
- **`functions.sh`**: Multi-purpose utilities (FFmpeg, ImageMagick, unified extraction).
- **`kde_settings.sh`**: KDE Plasma 6 environment settings, night light, themes, shell reload.
- **`history.sh`**: Shell history management (no duplicates, up to 20k lines).
- **`options.sh`**: Internal shell behaviors (`autocd`, `globstar`).
- **`podman-functions.sh`**: Streamlined Podman container and pod management.
- **`rclone_aliases.sh`**: Cloud sync shortcuts with Google Drive.
- **`yt-dlp_aliases.sh`**: Optimized video (1080p) and audio (MP3) downloads.

### ⚙️ [Setup](./Setup/)
Operating system setup, KDE Plasma 6 customization, and security hardening:
- **`kde-settings.sh`**: Automated KDE Plasma 6 customization (Night color disabled, 24h clock, window buttons, dark themes).
- **`kde-widgets.sh`**: Widgets, Klipper (100 items clipboard history), KWin tiling, and global shortcuts.
- **`kde-plasma-customization.sh`**: Advanced visual customization (Klassy, Kvantum Fluent-Dark, Material You, Panel Colorizer, Tela Icons).
- **`konsole.sh`**: Konsole modern profile (85% translucent with blur, JetBrainsMono Nerd Font, no scrollbar, `Ctrl+Alt+T` shortcut, Dolphin `F4` integration).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity, blur, and Dolphin context menu.
- **`apariencia.sh`**: Themes and icons installation (Breeze Dark, Papirus-Dark, Qt/GTK consistency).
- **`laptop-setup.sh`**: Developer laptop optimizations (Touchpad gestures, Bluetooth, `power-profiles-daemon`, HiDPI, VRR on Wayland).
- **`fingerprint-setup.sh`**: Fingerprint unlock and authentication (`fprintd`, PAM for `sudo`, `sddm`, `kde`, and `polkit-1`).
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w printer via USB (CUPS, HPLIP proprietary plugin, and KDE `print-manager`).
- **`debian-tuning.sh`**: Kernel Sysctl tuning (`inotify`, `max_map_count`, swappiness) and `distrobox` support.
- **`cockpit.sh`**: Cockpit web administration console with Podman, Virtualization, and Storage modules.
- **`fastfetch.sh`**: Aesthetic system info upon opening terminal (Fastfetch).
- **`firefox.sh`**: Official Mozilla Firefox (.deb from Mozilla APT repository).
- **`fonts.sh`**: Development typography (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`seguridad.sh`**: Hardening with UFW Firewall and Fail2ban adapted for a development laptop with Podman and KDE Connect.
- **`shell.sh`**: Modern terminal tools (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`) and unified Starship prompt for Bash and Zsh.
- **`yt-dlp-setup.sh`**: Multimedia dependencies (yt-dlp, ffmpeg, and JS runtime Deno via mise).

### 🐳 [Podman](./Podman/)
Complete ecosystem for rootless containers and Systemd Quadlets:
- **Installation**: `podman-install.sh`, `quadlets-setup.sh`
- **Shared Services**: Traefik, PostgreSQL, Redis, Keycloak.
- **Templates**: Python-Postgres, Python-Postgres-Redis, Fullstack.

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU, Libvirt, modular sockets, VirtIO, and Nested KVM optimized for Debian.

### 💻 [IDEs and Editors](./IDE/)
- **`neovim.sh`**: Modern Neovim with LazyVim.
- **`vscode.sh`**: Native Visual Studio Code (.deb from official Microsoft repo).
- **`antigravity.sh`**: Google Antigravity Desktop 2.0.
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Antigravity CLI and IDE engine suite.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### 🎮 [Gaming](./Juegos/)
- **`steam.sh`**: Isolated Steam via Flatpak with **Proton-GE** support.

---

## 🚀 Quick Deployment with Just

To run full environment setup:

```bash
just setup-all
```

Or individual components:
```bash
just shell        # Unified Starship prompt for Bash & Zsh
just security     # Laptop + Podman UFW firewall setup
just kde          # Apply KDE Plasma 6 configuration
just konsole      # Configure translucent Konsole terminal
just widgets      # Configure widgets, Klipper, and KWin shortcuts
just ides         # Install Neovim, VSCode, Antigravity, and OpenCode
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
