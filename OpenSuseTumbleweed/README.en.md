# 🦎 OpenSuseTumbleweed: OpenSUSE Tumbleweed + GNOME Environment Configuration

This repository contains an organized, modular, and automated collection of configuration scripts for **OpenSUSE Tumbleweed (Rolling Release)** systems with the **GNOME** desktop environment (optimized for development workstations and laptops).

---

## 📂 Repository Organization

The configuration is structured modularly for easy maintenance and deployment:

### 🐚 [Bash.Setup](./Bash.Setup/)
Core Bash terminal configuration:
- **`aliases.sh`**: Common shortcuts, `zypper` aliases (`update`, `dup`, `install`, `clean`), `snapper` snapshots, and modern Rust tools (`eza`, `bat`, `duf`, `dust`).
- **`environment.sh`**: Global shell variables (`PATH`, `EDITOR`, colored `less` pager).
- **`functions.sh`**: Advanced functions and multimedia tools (FFmpeg, ImageMagick, unified extraction).
- **`gnome_settings.sh`**: GNOME environment settings, night light, dark theme, shell restart, and quick settings access.
- **`history.sh`**: Controls Bash command history.
- **`options.sh`**: Configures Bash internal behavior with `shopt` and `bind`.
- **`podman-functions.sh`**: Functions for simplified container management.
- **`rclone_aliases.sh`**: Cloud synchronization shortcuts for Google Drive.
- **`yt-dlp_aliases.sh`**: Optimized multimedia download shortcuts.

### ⚙️ [Setup](./Setup/)
Operating system configuration, GNOME customization, and hardening:
- **`post-install.sh`**: Intelligent dispatcher detecting CPU architecture (AMD Ryzen vs Intel Core) with CLI flags (`--amd`, `--intel`).
- **`post-install-amd.sh`**: Post-installation optimized for **AMD Ryzen** processors and Radeon graphics (Packman repository, multimedia codecs, Mesa, RADV, ZRAM, PipeWire, OPI, GNOME).
- **`post-install-intel.sh`**: Post-installation optimized for **Intel Core** desktops (Haswell i7-4790 / HD Graphics 4600) dedicated to media center and streaming (Intel microcode, VA-API `i965` driver, Packman codecs, Kodi, no virtualization).
- **`gnome-settings.sh`**: Automated GNOME customization via GSettings (Night light at 3500K, 24h clock, battery %, window buttons, VRR).
- **`gnome-extensions.sh`**: Automated and clean installation of GNOME Shell extensions with schema compilation (see [GNOME Extensions Guide](./Docs/gnome_extensions_en.md)).
- **`ptyxis.sh`**: Modern Ptyxis terminal installation and styling (85% translucency, no scrollbars, `Ctrl+Alt+T` shortcut, Nautilus integration).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with 85% opacity, blur effects, JetBrainsMono Nerd Font, and GNOME integration.
- **`apariencia.sh`**: Themes and icons installation (Adwaita-Dark, Papirus-Dark, GTK/Qt visual integration).
- **`laptop-setup.sh`**: Optimization for development laptops (Touchpad, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, Wayland VRR, 95% screen brightness).
- **`fingerprint-setup.sh`**: Fingerprint unlock and authentication (`fprintd`, `pam-config` for openSUSE, GNOME).
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w printer via USB (CUPS, HPLIP, proprietary plugin, and `system-config-printer`).
- **`tumbleweed-tuning.sh`**: Sysctl kernel tuning (`inotify`, `max_map_count`), Snapper (Btrfs) retention policies, and `distrobox`.
- **`build-custom-kernel.sh`**: Official Linux Kernel compiler optimized for `x86_64-v3`, 1000Hz latency, and dynamic preemption.
- **`cockpit.sh`**: Cockpit web admin panel with Podman, Virtualization, and Storage modules.
- **`fastfetch.sh`**: Aesthetic system info on terminal startup (Fastfetch).
- **`firefox.sh`**: Official native Mozilla Firefox installation via Zypper.
- **`fonts.sh`**: Development fonts (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`mount-workspace.sh`**: Safe auto-mounting of `/home/caballero/Workspace`.
- **`seguridad.sh`**: Hardening with Firewalld (KVM/Podman friendly) and Fail2ban.
- **`seguridad-dot.sh`**: DNS-over-TLS via `systemd-resolved`.
- **`shell.sh`**: Modern terminal tools (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`) and Starship prompt.
- **`screensaver-setup.sh`**: 3D/Matrix screensaver upon screen lock in GNOME.
- **`plymouth-setup.sh`**: Installation, configuration, and selector for boot splash screens (Plymouth: BGRT UEFI OEM, openSUSE theme, Spinner).
- **`yt-dlp-setup.sh`**: Multimedia dependencies (yt-dlp, ffmpeg from Packman, and Deno JS engine via mise).

### 🐳 [Podman](./Podman/)
Complete ecosystem for Rootless containers and Systemd Quadlets:
- **Installation**: `podman-install.sh`, `quadlets-setup.sh`
- **Shared Services**: Traefik, PostgreSQL, Redis, Keycloak.
- **Templates**: Python-Postgres, Python-Postgres-Redis, Fullstack.

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: Installation and configuration of KVM/QEMU, Libvirt, modular sockets, VirtIO, and Nested KVM optimized for OpenSUSE Tumbleweed.
- **`notas_virtualizacion_opensuse.md`**: Detailed virtualization guide for OpenSUSE.

### 💻 [IDEs & Editors](./IDE/)
- **`neovim.sh`**: Modern Neovim with LazyVim.
- **`vscode.sh`**: Native Visual Studio Code (official Microsoft RPM repository).
- **`antigravity.sh`**: Google Antigravity Desktop 2.0.
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Antigravity CLI and IDE engine suite.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### 🎮 [Gaming](./Juegos/)
- **`steam.sh`**: Steam with 32-bit libraries and **Proton-GE** support.

---

## 🚀 Quick Deployment with Just
 
Run installation according to your machine profile:

```bash
git clone https://github.com/scaballeroq/OpenSuseTumbleweed.git
cd OpenSuseTumbleweed
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Git/*.sh Juegos/*.sh

# Development Laptop (AMD Ryzen + Fingerprint + Virtualization):
just setup-laptop-amd

# Multimedia Desktop (Intel Haswell / Media Center + Kodi - No virtualization):
just setup-media-desktop
```

Or run individual components:
```bash
just post-install-amd    # Post-install for AMD Ryzen with Packman & OPI
just post-install-intel  # Post-install for Intel Media Center
just kodi                # Install Kodi & streaming add-ons
just gnome               # Apply GNOME settings via GSettings
just extensions          # Install and compile GNOME extensions
just ptyxis              # Install and configure Ptyxis terminal
just plymouth            # Configure and enable boot splash screen
just ides                # Install Neovim, VSCode, Antigravity, and OpenCode
just build-kernel        # Compile a native x86_64-v3 Linux kernel
just dup                 # Upgrade system (zypper dup)
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
