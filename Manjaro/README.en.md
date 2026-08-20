# 🔧 Manjaro: Manjaro Linux + GNOME Environment Configuration

This repository provides an organized, modular, and automated collection of configuration scripts for **Manjaro Linux** running the **GNOME** desktop environment (optimized for development workstations and laptops based on Arch Linux).

---

## 📂 Repository Structure

The configuration is structured in independent modules:

### 🐚 [Zsh.Setup](./Zsh.Setup/) *(Default Shell in Manjaro)*
Modular configuration for **ZSH**:
- **`aliases.zsh`**: Package shortcuts (`pacman`, `pamac`), modern Rust CLI tools (`eza`, `bat`, `duf`, `dust`, `procs`), kernel status monitor, and safety guards.
- **`environment.zsh`**: Global environment variables (`PATH`, `EDITOR`, `PAGER`, Mise, Cargo, Go).
- **`functions.zsh`**: Advanced navigation (`mkcd`, `up`), universal archive extractor (`extract`), disk management (`iso2sd`, `format-drive`), multimedia tools (`ffmpeg`, `ImageMagick`), and Manjaro utilities (`manjaro-mirrors-fast`, `pacman-clean-all`, `aur-search`, `pamac-build-aur`, `check-kernel`).
- **`gnome_settings.zsh`**: GNOME quick settings and Shell restart helper.
- **`history.zsh`**: High-capacity ZSH history (50,000 lines, duplicate-free, shared across terminals).
- **`options.zsh`**: Advanced ZSH options (`autocd`, spelling correction, interactive menu completion).
- **`podman-functions.zsh`**: Podman container and Quadlet management functions.
- **`rclone_aliases.zsh`**: Cloud synchronization aliases for Google Drive and OneDrive.
- **`yt-dlp_aliases.zsh`**: High-quality multimedia downloads with yt-dlp and ffmpeg.

### 🐚 [Bash.Setup](./Bash.Setup/) *(Secondary Bash Compatibility)*
Equivalent modular configuration for **Bash** when running Bash subshells or recovery sessions.

### ⚙️ [Setup](./Setup/)
OS setup, GNOME tuning, and hardware hardening scripts:
- **`post-install.sh`**: Smart CPU dispatcher (AMD Ryzen vs Intel Core) with CLI flag support (`--amd`, `--intel`).
- **`post-install-amd.sh`**: Post-installation optimized for **AMD Ryzen** CPUs and Radeon GPUs (`pacman-mirrors`, AMD microcode, GPU firmware, RADV, Mesa, ZRAM, PipeWire, GNOME, Pamac, Flatpak).
- **`post-install-intel.sh`**: Post-installation optimized for **Intel Core** desktops (Haswell i7-4790 / HD Graphics 4600) configured as media hubs (`intel-ucode`, `intel-media-driver`, codecs, Kodi, no virtualization).
- **`gnome-settings.sh`**: Automated GNOME GSettings (Night light at 3500K, 24h clock, battery percentage, window buttons, VRR).
- **`gnome-extensions.sh`**: Clean installation of 17 GNOME Shell extensions with compiled GSettings schemas (see [GNOME Extensions Guide](./Docs/gnome_extensions_en.md)).
- **`ptyxis.sh`**: Modern Ptyxis terminal profile (85% translucent, `Ctrl+Alt+T` shortcut, Nautilus integration).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity (85%), blur, JetBrainsMono Nerd Font, and GNOME integration.
- **`apariencia.sh`**: Theme and icon installation (Adwaita-Dark, Papirus-Dark, GTK/Qt consistency).
- **`laptop-setup.sh`**: Developer laptop optimizations (Touchpad, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, VRR on Wayland).
- **`fingerprint-setup.sh`**: Fingerprint unlock and authentication (`fprintd`, PAM for `sudo`, `polkit-1`, and GDM).
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w USB printer (CUPS, HPLIP, proprietary plugin, `system-config-printer`).
- **`manjaro-tuning.sh`**: Sysctl kernel parameters (`inotify`, `max_map_count`), parallel downloads in `pacman.conf`, and `distrobox`.
- **`build-custom-kernel.sh`**: Native Linux kernel compiler for `x86_64-v3`, 1000Hz timer frequency, and dynamic preemption.
- **`cockpit.sh`**: Cockpit Web Admin with Podman, Virtualization, and Storage modules.
- **`fastfetch.sh`**: Fastfetch system information displayed in terminal.
- **`firefox.sh`**: Native Mozilla Firefox with Spanish language package.
- **`fonts.sh`**: Developer Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode).
- **`mount-workspace.sh`**: Permanent auto-mounting of `/home/caballero/Workspace`.
- **`seguridad.sh`**: UFW Firewall hardening.
- **`seguridad-dot.sh`**: DNS-over-TLS using `systemd-resolved`.
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`), ZSH plugins, and Starship prompt.
- **`screensaver-setup.sh`**: 3D/Matrix GL screensaver on GNOME lock screen.
- **`plymouth-setup.sh`**: Visual Plymouth boot splash screen (BGRT OEM UEFI and Manjaro themes).
- **`yt-dlp-setup.sh`**: Multimedia dependencies (yt-dlp, ffmpeg, Deno JS runtime via mise).

### 🐳 [Podman](./Podman/)
Rootless container ecosystem and Systemd Quadlets:
- **Installation**: `podman-install.sh`, `quadlets-setup.sh`
- **Shared Services**: Traefik, PostgreSQL, Redis, Keycloak.
- **Templates**: Python-Postgres, Python-Postgres-Redis, Fullstack.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU, Libvirt, modular sockets, VirtIO, Nftables, and Nested KVM for Manjaro.
- **`notas_virtualizacion_manjaro.md`**: Virtualization guide for Manjaro Linux.

### 💻 [IDEs & Editors](./IDE/)
- **`neovim.sh`**: Modern Neovim with LazyVim.
- **`vscode.sh`**: Visual Studio Code (AUR / Pacman).
- **`antigravity.sh`**: Google Antigravity Desktop 2.0.
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Antigravity CLI and IDE engine suite.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### 🎮 [Gaming](./Juegos/)
- **`steam.sh`**: Native Manjaro Steam with **GameMode**, **MangoHud**, **Vulkan**, and **Lutris**.

---

## 🚀 Quick Deployment with Just
 
```bash
git clone https://github.com/scaballeroq/Manjaro.git
cd Manjaro
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Git/*.sh Juegos/*.sh

# Developer Laptop (AMD Ryzen + Fingerprint + Virtualization):
just setup-laptop-amd

# Desktop Media Center (Intel Haswell / Media Center + Kodi - No virtualization):
just setup-media-desktop
```
