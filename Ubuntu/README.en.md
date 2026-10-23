# 🟠 Ubuntu Linux Environment Configuration (GNOME Shell Wayland)

This repository contains an organized, modular, and automated collection of configuration scripts for **Ubuntu Linux** systems featuring the **GNOME Shell (Wayland / Mutter)** desktop environment, optimized for development workstations and HP EliteBook laptops in dark mode.

---

## 📂 Repository Organization

The configuration has been structured modularly to guarantee maximum maintainability and readability:

### 🐚 [Bash.Setup](./Bash.Setup/)
The core terminal configuration, optimized for **Bash** (with modular support in `~/.bashrc.d`) and compatible with **Zsh** (in `~/.zshrc.d`).
- **`aliases.sh`**: Common shortcuts for navigation, modern Rust tools (`eza`, `bat`, `duf`, `dust`), Git, **APT** package management (`update`, `upgrade`, `install`, `clean`), Firewalld (`fw*`), Libvirt, and Podman.
- **`environment.sh`**: Global variables (`EDITOR`, `PATH`, Wayland, `QT_QPA_PLATFORMTHEME="gnome"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`), and automated Mise shims activation.
- **`functions.sh`**: Collection of advanced functions (`mkcd`, `up`, `extract`, `duh`, `backup_file`, `monitors`) with interactive shell guards.
- **`gnome_settings.sh`**: Environment configurations and shortcuts for GNOME Shell Wayland (Yaru-dark, Night Light 4000K, Shell restart, GNOME Control Center shortcuts).
- **`history.sh`**: Optimized history control (deduplication, instant sync, expanded capacity to 20k commands).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction with `cdspell`, extended globbing).
- **`podman-functions.sh`**: Functions and aliases for rootless Podman containers and Quadlets compatible with both shells.
- **`rclone_aliases.sh`**: Complete shortcuts for sync, copy, and dry-run with Google Drive and OneDrive.
- **`yt-dlp_aliases.sh`**: Optimized multimedia downloads with yt-dlp and FFmpeg.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with native systemd Quadlets:
- **`install/podman-install.sh`**: Rootless Podman installation, user socket, linger, registries, and CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Directory configuration and systemd Quadlet services (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: Complete project management CLI (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directory for active user projects.
- **`services-shared/`**: Global shared services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Project templates (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Virtualization stack setup (KVM/QEMU, Libvirt, virt-manager, virtio-win, Btrfs NoCoW, passwordless Polkit for `libvirt` group, safe Wi-Fi detection, Firewalld) with full CLI (`--status`, `--with-windows`, `--help`).

### ⚙️ [Setup](./Setup/)
Operating system configuration scripts, GNOME Shell personalization, and system hardening:
- **`post-install.sh`**: Smart dispatcher with CPU auto-detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-installation optimized for AMD Ryzen (ZRAM zstd, Mesa RADV, VA-API hardware acceleration, PipeWire, Flatpak Flathub, GNOME Software Flatpak plugin).
- **`post-install-intel.sh`**: Post-installation optimized for Intel Core / Media Center (Intel VA-API i965/iHD, PipeWire, Kodi).
- **`laptop-setup.sh`**: Development laptop optimizations (power-profiles-daemon, Bluetooth FastConnectable, smart lid close handling, Wayland touchpad gestures, Mutter VRR, `--status`).
- **`fingerprint-setup.sh`**: Biometric fingerprint authentication (fprintd + PAM, Synaptics sensor, `--status`, `--enroll`, `--verify`, `--disable`).
- **`hp-printer-setup.sh`**: Printing stack for HP printers (CUPS, HPLIP, proprietary plugin for LaserJet M15w, Firewalld USB/Wi-Fi, `--status`).
- **`gnome-settings.sh`**: GNOME Shell setup (Yaru-dark dark mode, minimize/maximize buttons, Nautilus context scripts for Kitty/Antigravity/VS Code, Night Light 4000K, 24h clock, `--status`, `--dark`, `--light`).
- **`gnome-extensions.sh`**: Installation and activation of essential GNOME extensions (GSConnect, Dash to Dock, AppIndicator, Blur my Shell, Tiling Shell, `--status`).
- **`gsconnect.sh`**: Native GSConnect integration (KDE Connect for GNOME with zero KDE/Qt dependencies) and Firewalld rules (1714-1764 TCP/UDP, `--status`, `--setup-firewall`, `--daemon`).
- **`ubuntu-tuning.sh`**: Kernel tuning (`sysctl` inotify 1M, max_map_count 16M, TCP BBR, ZRAM), system limits (`limits.d`), GNOME Tracker Miner exclusions in heavy dev trees (`~/Workspace`, `node_modules`, `.git`, `.venv`, `.cargo`), and ZRAM compression (`--status`, `--sysctl`, `--limits`, `--tracker`, `--zram`).
- **`zram-setup.sh`**: Compressed swap in RAM configuration using `zram-tools` with zstd algorithm.
- **`cockpit.sh`**: Cockpit Web Console and server management (Podman, KVM, storage, exclusive Firewalld, `--status`, `--open`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: Aesthetic system information banner supporting multiple themes (`ubuntu` official, `compact` FastCat, `--status`, `--theme`, `--diff`, `--force`).
- **`fonts.sh`**: Automated installation and diagnostics for developer fonts (JetBrainsMono, FiraCode, CascadiaCode, Meslo, and Hack Nerd Fonts, `--status`, `--list`, `--clean`).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with 75% opacity, blur 32, Catppuccin Mocha theme, Ctrl+Alt+T shortcut, and Nautilus context menu script (`--status`).
- **`ptyxis.sh`**: Modern Ptyxis terminal setup with transparency and dark mode.
- **`seguridad.sh`**: Security hardening with exclusive Firewalld enforcement (mandatory UFW disable, `kdeconnect`/GSConnect, `mdns`, `ssh`, `libvirt` zone for virbr0, `trusted` zone for `podman+`, unprivileged ports sysctl).
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`) and modular shell syncing.
- **`starship.sh` & `starship.toml`**: Modern Starship prompt with modular configuration (`--enable`, `--disable`, `--status`).
- **`multimedia.sh`**: Official multimedia codecs (`ubuntu-restricted-extras`, FFmpeg, GStreamer with VA-API), and decoupled Flatpak VLC (`--status`).
- **`flatpak.sh`**: Suite of decoupled desktop applications via Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Shotcut, Spotify, Vesktop...) preserving a clean base system (`--status`, `--all`, `--essential`, `--multimedia`, `--clean`, `--update`).
- **`chrome.sh`**: Official Google Chrome repository activation and `google-chrome-stable` installation with Ozone Wayland optimizations (`--status`, `--wayland`).
- **`firefox.sh`**: Native Mozilla Firefox (.deb) installation with APT Pin-Priority 1000 purging the Snap wrapper (`--status`).
- **`steam.sh`**: Native Steam installation with i386 multiarch, GameMode, MangoHud, Proton-GE, and Mesa 32-bit Vulkan drivers (`--status`).
- **`yt-dlp-setup.sh`**: Advanced multimedia stack (yt-dlp, FFmpeg, Mutagen, aria2, Deno JS engine via Mise, `--status`, `--config`, `--update`, `--clean-cache`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (Chromium sandbox, icons, and Nautilus script).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) rootless setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (GNOME launcher and Nautilus script).
- **`git.sh`**: Git, Delta, Lazygit, and GitHub CLI setup with global configurations.
- **`opencode.sh`**: OpenCode AI CLI setup integrated into PATH.
- **`vscode.sh`**: Visual Studio Code setup.
- **`neovim.sh`**: Modern Neovim setup with `wl-clipboard` (free of legacy X11 utilities).

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Modern runtime management with **Mise** and **uv**:
- **`mise.sh`**: Mise version manager setup with `environment.d` integration.
- **`python.sh` & `python-uv-init.sh`**: System Python protection, `uv@latest` via Mise, and `py-project` scaffolding CLI (FastAPI, CLI, Data Science).
- **`nodejs.sh`**: Active Node.js LTS with Corepack (`pnpm`, `yarn`).
- **`rust.sh`**: Rustup Stable channel with `rust-analyzer`, `clippy`, `rustfmt`, and `cargo-binstall`.
- **`dotnet.sh`**: .NET SDK LTS with `DOTNET_ROOT` in `environment.d`.
- **`java.sh`**: OpenJDK LTS (Java 21) with digital certificates (AutoFirma / DNIe) and Maven.
- **`angular.sh`**: Latest Angular CLI via npm managed by Mise.

---

## 🚀 Quick Deployment with Just

To execute the automated deployment tailored to your machine profile:

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/Ubuntu
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Development Laptop (AMD Ryzen + GNOME Shell Wayland + Virtualization + Podman):
just setup-laptop-amd

# Media Center Desktop (Intel Haswell / Media Center + Kodi - Without virtualization):
just setup-media-desktop

# Or complete default installation:
just setup-all
```

Or run individual components:
```bash
just post-install        # Base post-install with smart CPU detection
just gnome-setup         # Apply GNOME Shell settings, Yaru-dark, and shortcuts
just gnome-status        # Check GNOME Shell configuration status
just gnome-extensions    # Install and configure essential GNOME extensions
just gsconnect           # Configure GSConnect and Firewalld rules
just laptop              # Laptop optimization (Touchpad, Bluetooth, Mutter VRR)
just tuning              # Apply sysctl, limits, inotify, and Tracker exclusions
just tuning-status       # System optimization diagnostics
just kitty               # Configure Kitty terminal with opacity, blur, and Catppuccin theme
just virtualization      # Setup KVM/QEMU, Libvirt, and Btrfs NoCoW
just virtualization-status # Hypervisor diagnostics
just multimedia          # Setup official multimedia codecs and Flatpak VLC
just flatpak             # Install recommended Flatpaks (Flatseal, Podman Desktop, Warehouse, VLC...)
just flatpak-status      # Diagnostics of Flathub remotes and installed apps
just chrome              # Install official Google Chrome with Wayland flags
just firefox             # Install native Mozilla Firefox (.deb with Pin-Priority 1000)
just steam               # Install native Steam and 32-bit Mesa libraries (i386)
just languages           # Install Node, Python (uv), Rust, .NET, Java, and Angular
just python-uv           # Interactive py-project assistant to scaffold Python projects
just podman-setup        # Setup rootless Podman and Quadlets
just podman-status       # Comprehensive diagnostics of Podman and Quadlets
just update              # Full system update via APT
```
