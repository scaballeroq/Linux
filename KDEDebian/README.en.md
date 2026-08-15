# 🔧 KDEDebian: Debian Testing + KDE Plasma 6 Environment Configuration

This repository contains an organized, modular, and automated collection of configuration scripts for **Debian Testing (Trixie)** systems with the **KDE Plasma 6** desktop environment (optimized for workstation PCs and development laptops).

---

## 📂 Repository Structure

The configuration is modularly organized for easy maintenance and deployment:

### 🐚 [Bash.Setup](./Bash.Setup/)
The core of the Bash terminal configuration:
- **`aliases.sh`**: Common aliases and modern Rust CLI replacements (`eza`, `bat`, `duf`, `dust`).
- **`environment.sh`**: Global shell variables (`PATH`, `EDITOR`, colored `less` man pages).
- **`functions.sh`**: Advanced shell functions and multimedia tools (FFmpeg, ImageMagick, unified archive extraction).
- **`kde_settings.sh`**: Environment configurations, night color, dark theme toggles, and shortcuts to KDE KCM Settings.
- **`history.sh`**: Optimized Bash history (no duplicates, up to 20k entries).
- **`options.sh`**: Bash runtime options (`shopt` and `bind`).
- **`podman-functions.sh`**: Simplified container management aliases.
- **`rclone_aliases.sh`**: Cloud synchronization aliases with Google Drive.
- **`yt-dlp_aliases.sh`**: High-performance multimedia downloading.

### ⚙️ [Setup](./Setup/)
Operating system setup, KDE Plasma 6 personalization, and security hardening:
- **`post-install.sh`**: Master post-installation script (Enables `contrib`, `non-free`, `non-free-firmware`, ZRAM, PipeWire, Mesa, and KDE Plasma Suite).
- **`kde-settings.sh`**: Automated KDE Plasma personalization (Night Color, 24h clock, window buttons, Breeze Dark).
- **`kde-widgets.sh`**: Widget setup, Klipper clipboard manager, KWin tiling, and global shortcuts (see [KDE Widgets Guide](./Docs/kde_widgets_en.md)).
- **`konsole.sh`**: Modern Konsole setup (85% translucent profile with blur, JetBrainsMono Nerd Font, no scrollbar, `Ctrl+Alt+T` shortcut, and Dolphin `F4` integration).
- **`apariencia.sh`**: Themes, icons, and Qt/GTK style consistency (Breeze Dark and Papirus-Dark).
- **`laptop-setup.sh`**: Development laptop optimizations (Touchpad gestures, Bluetooth, `power-profiles-daemon`, HiDPI, VRR on Wayland).
- **`fingerprint-setup.sh`**: Fingerprint unlocking and PAM authentication (`fprintd`, `sudo`, `sddm`, `kde`, `polkit-1`).
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w printer USB setup (CUPS, HPLIP, proprietary plugin, and KDE `print-manager`).
- **`debian-tuning.sh`**: Kernel Sysctl tweaks (`inotify`, `max_map_count`) and `distrobox` container support.
- **`build-custom-kernel.sh`**: High-performance Linux kernel compiler optimized for `x86_64-v3` architecture, 1000Hz timer, and Dynamic Preemption.
- **`install-backports-kernel.sh`**: Rolling kernel updater from Debian Testing repositories.
- **`cockpit.sh`**: Cockpit web administration console with Podman, KVM, and Storage modules.
- **`fastfetch.sh`**: Aesthetic system information banner upon terminal launch.
- **`firefox.sh`**: Official Mozilla Firefox (.deb from Mozilla APT).
- **`fonts.sh`**: Developer typography (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`mount-workspace.sh`**: Safe auto-mounting of `/home/caballero/Workspace`.
- **`seguridad.sh`**: UFW Firewall hardening.
- **`seguridad-dot.sh`**: DNS-over-TLS via `systemd-resolved`.
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`) and Starship prompt.
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

To deploy the entire environment:

```bash
git clone https://github.com/scaballeroq/KDEDebian.git
cd KDEDebian
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Git/*.sh Juegos/*.sh
just setup-all
```

Or run individual components:
```bash
just kde          # Apply KDE Plasma 6 configuration
just konsole      # Configure translucent Konsole terminal
just widgets      # Configure widgets, Klipper, and KWin shortcuts
just ides         # Install Neovim, VSCode, Antigravity, and OpenCode
just build-kernel # Compile a native x86_64-v3 Linux kernel
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
