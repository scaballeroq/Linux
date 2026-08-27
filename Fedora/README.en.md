# 🔧 Fedora: Fedora 44 Workstation + GNOME Environment Configuration

This repository contains an organized, modular, and automated collection of configuration scripts for **Fedora 44 Workstation (Trixie)** systems with the **GNOME** desktop environment (optimized for workstation PCs and development ldnf5ops).

---

## 📂 Repository Structure

The configuration is modularly organized for easy maintenance and deployment:

### 🐚 [Bash.Setup](./Bash.Setup/)
The core of the Bash terminal configuration:
- **`aliases.sh`**: Common aliases and modern Rust CLI replacements (`eza`, `bat`, `duf`, `dust`).
- **`environment.sh`**: Global shell variables (`PATH`, `EDITOR`, colored `less` man pages).
- **`functions.sh`**: Advanced shell functions and multimedia tools (FFmpeg, ImageMagick, unified archive extraction).
- **`gnome_settings.sh`**: Environment configurations, night light, dark theme toggles, and shortcuts to GNOME Control Center.
- **`history.sh`**: Optimized Bash history (no duplicates, up to 20k entries).
- **`options.sh`**: Bash runtime options (`shopt` and `bind`).
- **`podman-functions.sh`**: Simplified container management aliases.
- **`rclone_aliases.sh`**: Cloud synchronization aliases with Google Drive.
- **`yt-dlp_aliases.sh`**: High-performance multimedia downloading.

### ⚙️ [Setup](./Setup/)
Operating system setup, GNOME personalization, and security hardening:
- **`post-install.sh`**: Smart dispatcher with automatic CPU vendor detection (AMD vs Intel) and CLI flags (`--amd`, `--intel`).
- **`post-install-amd.sh`**: Post-installation optimized for **AMD Ryzen** CPUs and Radeon Graphics (AMD microcode, GPU firmware, RADV, Mesa, ZRAM, PipeWire, GNOME).
- **`post-install-intel.sh`**: Post-installation optimized for **Intel Core** desktop PCs (Haswell i7-4790 / HD Graphics 4600) tailored for media center & streaming (Intel microcode, `i965` VA-API driver, codecs, Kodi, no virtualization).
- **`gnome-settings.sh`**: Automated GNOME personalization via GSettings (Night Light at 3500K, 24h clock, window buttons, prefer dark theme, VRR).
- **`gnome-extensions.sh`**: Clean, automated installation of 17 curated GNOME extensions with GSettings schema compilation (see [GNOME Extensions Guide](./Docs/gnome_extensions_en.md)).
- **`kitty.sh`**: GPU-accelerated Kitty terminal setup with 85% opacity, blur effects, JetBrainsMono Nerd Font, and GNOME/Nautilus integration.
- **`apariencia.sh`**: Themes, icons, and Qt/GTK style consistency (Adwaita-Dark and Papirus-Dark).
- **`ldnf5op-setup.sh`**: Development ldnf5op optimizations (Touchpad gestures, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, VRR on Wayland).
- **`fingerprint-setup.sh`**: Fingerprint unlocking and PAM authentication (`fprintd`, `sudo`, `polkit-1`, `pam-auth-update`).
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w printer USB setup (CUPS, HPLIP, proprietary plugin, and `system-config-printer`).
- **`fedora-tuning.sh`**: Kernel Sysctl tweaks (`inotify`, `max_map_count`) and `distrobox` container support.
- **`build-custom-kernel.sh`**: High-performance Linux kernel compiler optimized for `x86_64-v3` architecture, 1000Hz timer, and Dynamic Preemption.
- **`cockpit.sh`**: Cockpit web administration console with Podman, KVM, and Storage modules.
- **`fastfetch.sh`**: Aesthetic system information banner upon terminal launch.
- **`firefox.sh`**: Official Mozilla Firefox (.deb from Mozilla APT).
- **`fonts.sh`**: Developer typography (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`mount-workspace.sh`**: Safe auto-mounting of `/home/caballero/Workspace`.
- **`seguridad.sh`**: UFW Firewall hardening.
- **`seguridad-dot.sh`**: DNS-over-TLS via `systemd-resolved`.
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`) and Starship prompt.
- **`screensaver-setup.sh`**: 3D/Matrix screensaver upon locking GNOME session.
- **`plymouth-setup.sh`**: Visual boot splash screen installer and theme selector (Plymouth: BGRT UEFI OEM, Fedora 44 Ceratopsian, Spinner, and live desktop preview).
- **`yt-dlp-setup.sh`**: Multimedia dependencies (yt-dlp, ffmpeg, and Deno JS engine via mise).

### 🐳 [Podman](./Podman/)
Rootless container ecosystem and Systemd Quadlets:
- **Installation**: `podman-install.sh`, `quadlets-setup.sh`
- **Shared Services**: Traefik, PostgreSQL, Redis, Keycloak.
- **Templates**: Python-Postgres, Python-Postgres-Redis, Fullstack.

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: High-performance KVM/QEMU, Libvirt, modular sockets, VirtIO, and Nested KVM setup.
- **`notas_virtualizacion_debian.md`**: In-depth virtualization notes on Debian.

### 💻 [IDEs and Editors](./IDE/)
- **`neovim.sh`**: Neovim with LazyVim.
- **`vscode.sh`**: Visual Studio Code (.deb from Microsoft).
- **`antigravity.sh`**: Google Antigravity Desktop 2.0.
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Google Antigravity CLI and IDE engine.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### 🎮 [Gaming](./Juegos/)
- **`steam.sh`**: Sandboxed Steam via Flatpak with **Proton-GE** support.

---

## 🚀 Quick Deployment with Just

To deploy the environment tailored to your machine profile:

```bash
git clone https://github.com/scaballeroq/Fedora.git
cd Fedora
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Git/*.sh Juegos/*.sh

# Development Ldnf5op (AMD Ryzen + Fingerprint + Virtualization):
just setup-ldnf5op-amd

# Multimedia Desktop Workstation (Intel Haswell / Media Center + Kodi - No Virtualization):
just setup-media-desktop
```

Or run individual components:
```bash
just post-install-amd    # Post-installation exclusively for AMD Ryzen
just post-install-intel  # Post-installation for Intel Media Center
just kodi                # Install Kodi and streaming plugins
just gnome               # Apply GNOME GSettings configuration
just extensions          # Install and compile the 17 GNOME extensions
just plymouth            # Setup and activate graphical boot splash screen
just ides                # Install Neovim, VSCode, Antigravity, and OpenCode
just build-kernel        # Compile a native x86_64-v3 Linux kernel
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
