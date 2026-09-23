# 🦎 openSUSE Tumbleweed Environment Configuration (KDE Plasma 6)

This repository contains an organized, modular, and automated collection of configuration scripts for **openSUSE Tumbleweed (Rolling Release)** systems with the **KDE Plasma 6** desktop environment over **Wayland** (optimized for HP EliteBook laptops and dark-mode development workstations).

---

## 📂 Repository Organization

The configuration is structured modularly for easy maintenance and readability:

### 🐚 [Bash.Setup](./Bash.Setup/)
The core of the terminal configuration, optimized for **Bash** (project default shell with modular support via `~/.bashrc.d`) and **Zsh** (compatible if `~/.zshrc` exists).
- **`aliases.sh`**: Common navigation shortcuts, Rust utilities (`eza`, `bat`, `duf`, `dust`), Dolphin (`kioclient6`), `snapper`, and **Zypper** package manager (`dup`, `update`, `install`, `clean`).
- **`environment.sh`**: Global variables (`EDITOR`, `PATH`, Wayland/KDE Qt, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) and automatic Mise activation.
- **`functions.sh`**: Advanced utility functions (`mkcd`, `up`, `extract`, `duh`) and media processing (FFmpeg / ImageMagick).
- **`kde_settings.sh`**: Desktop environment settings and shortcuts for KDE Plasma 6 Wayland (Breeze Dark/Light, Night Color, Plasma/KWin restarts, KCM modules).
- **`history.sh`**: Optimized command history (deduplication, instant append, expanded 20k entries).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction via `cdspell`, extended globbing).
- **`podman-functions.sh`**: Rootless Podman and Quadlets helper functions compatible with both shells.
- **`rclone_aliases.sh`**: Cloud synchronization shortcuts for Google Drive and OneDrive.
- **`yt-dlp_aliases.sh`**: Optimized multimedia download helpers with yt-dlp and FFmpeg.

### 🐳 [Podman](./Podman/)
Complete ecosystem for Rootless containers and native systemd Quadlets:
- **`install/podman-install.sh`**: Installation and configuration of rootless Podman, socket, linger, registries, and CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Setup of systemd Quadlet unit directories and shared services (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: Comprehensive CLI for project lifecycles (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directory for active project workspaces.
- **`services-shared/`**: Global shared services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Project templates (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: High-performance virtualization setup (KVM/QEMU, modular Libvirt, virt-manager, virtio-win, Btrfs NoCoW, Polkit) with full CLI (`--status`, `--with-windows`, `--help`).
- **`notas_virtualizacion_opensuse.md`**: In-depth virtualization guide for openSUSE Tumbleweed.

### ⚙️ [Setup](./Setup/)
Operating system configuration, KDE Plasma 6 customization, and hardening scripts:
- **`post-install.sh`**: Smart dispatcher with automatic CPU architecture detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-installation optimized for AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, Packman priority 90, KDE Plasma 6 patterns, KDE Gear suite).
- **`post-install-intel.sh`**: Post-installation optimized for Intel Core / Media Center (Intel i965 / media-driver VA-API, PipeWire, codecs, Kodi).
- **`kde-settings.sh`**: KDE Plasma 6 customization (Breeze Dark, KWin buttons on the right, Dolphin KIO servicemenus for Kitty and Antigravity, Night Color at 4000K, Ctrl+Alt+T shortcut).
- **`laptop-setup.sh`**: Optimization for development laptops (KDE Touchpad `kcminputrc`, PowerDevil `powermanagementprofilesrc`, Bluetooth FastConnectable, logind lid switch, 95% brightness persistence).
- **`tumbleweed-tuning.sh`**: Kernel tuning (`sysctl` ZRAM/BBR/Inotify), system limits (`limits.d`), Snapper Btrfs retention policies, Baloo file indexing exclusions in KDE Plasma 6, and ZRAM compression (`--status`, `--sysctl`, `--limits`, `--snapper`, `--baloo`, `--zram`).
- **`cockpit.sh`**: Cockpit web administration console with modules for Podman, KVM machines, storage, and Snapper snapshots (`--status`, `--open`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: Aesthetic system summary with openSUSE and KDE Plasma branding.
- **`fonts.sh`**: Automated developer fonts installation (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with Catppuccin Mocha theme, opacity, blur, Ctrl+Alt+T shortcut, and Dolphin servicemenu.
- **`seguridad.sh`**: System hardening with Firewalld (`kdeconnect`, `mdns`, `ssh` services, `libvirt` zone for virbr0, `trusted` zone for `podman+`), and unprivileged port binding for development.
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Starship prompt manager (`--enable`, `--disable`, `--status`).
- **`yt-dlp-setup.sh`**: Multimedia dependencies (yt-dlp, FFmpeg, AtomicParsley, aria2, Deno JS engine via Mise).
- **`multimedia.sh`**: Official OpenH264 (Cisco) codecs, official FFmpeg, GStreamer plugins, and decoupled media players via Flatpak without Packman (`--status`).
- **`chrome.sh`**: Official Google Chrome RPM repository activation and `google-chrome-stable` installation (`--status`).
- **`steam.sh`**: Native Steam with GameMode, MangoHud, Proton-GE, and 32-bit Vulkan/Mesa drivers (`--status`).
- **`apariencia.sh`**: Papirus-Dark icons, Breeze-Dark, and GTK 3/4 / Qt integration.
- **`mount-workspace.sh`**: Permanent, safe auto-mounting of `/home/caballero/Workspace` in `/etc/fstab`.

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (Chromium sandbox permissions, pixmap icons, Dolphin KIO servicemenu).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (KDE launcher, Dolphin servicemenu).
- **`git.sh`**: Git, Delta, Lazygit, and GitHub CLI setup with recommended global configs.
- **`opencode.sh`**: OpenCode AI CLI setup integrated into system PATH.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Modern runtime management via **Mise** and **Rustup**:
- **`mise.sh`**: Mise version manager via official Zypper RPM with `environment.d` integration.
- **`python.sh` & `python-uv-init.sh`**: Protected system Python, `uv@latest` via Mise, and `py-project` scaffolding CLI (FastAPI, CLI, Data Science).
- **`nodejs.sh`**: Node.js active LTS with Corepack (`pnpm`, `yarn`).
- **`rust.sh`**: Rustup Stable channel with `rust-analyzer`, `clippy`, `rustfmt`, and `cargo-binstall`.
- **`dotnet.sh`**: .NET SDK LTS with `DOTNET_ROOT` in `environment.d`.
- **`java.sh`**: OpenJDK LTS (Java 21) with digital certificates (AutoFirma / DNIe) and Maven.
- **`angular.sh`**: Angular CLI latest version via Mise-managed npm.

---

## 🚀 Quick Deployment with Just

To run the automated deployment according to your hardware profile:

```bash
git clone https://github.com/scaballeroq/OpenSuseTumbleweed.git
cd OpenSuseTumbleweed
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Git/*.sh Juegos/*.sh

# Development Laptop (AMD Ryzen + KDE Plasma 6 + Virtualization + Podman):
just setup-laptop-amd

# Multimedia Desktop (Intel Haswell / Media Center + Kodi - No virtualization):
just setup-media-desktop

# Or complete default installation:
just setup-all
```

Or execute individual tasks:
```bash
just post-install        # Base post-install with automatic CPU detection
just kde-setup           # Apply KDE Plasma 6 configuration, Breeze Dark, and shortcuts
just kde-status          # Check KDE Plasma configuration status
just laptop              # Development laptop optimization (Touchpad, Bluetooth, 95% brightness)
just tuning              # Apply sysctl, limits, Btrfs Snapper, and Baloo exclusions
just tuning-status       # Diagnostic of system performance metrics
just kitty               # Configure Kitty terminal with opacity, blur, and Catppuccin theme
just virtualization      # Setup KVM/QEMU, modular Libvirt, and Btrfs NoCoW
just virtualization-status # Diagnostic of KVM hypervisor
just multimedia          # Install Packman at priority 90, full codecs, and FFmpeg
just chrome              # Install official Google Chrome
just steam               # Install native Steam and 32-bit graphics stack
just languages           # Install Node, Python (uv), Rust, .NET, Java, and Angular
just python-uv           # Interactive py-project assistant for creating Python projects
just podman-setup        # Configure rootless Podman and Quadlets
just podman-status       # Full diagnostic of Podman and Quadlets
just dup                 # Upgrade rolling release system (zypper dup)
just snapshots           # List Snapper Btrfs snapshots
```

---

*Maintained by [caballero](https://github.com/scaballeroq)*
