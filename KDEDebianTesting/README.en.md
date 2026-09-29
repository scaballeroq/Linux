# 🌀 Debian Testing Environment Configuration (KDE Plasma 6)

This repository contains an organized, modular, and automated collection of configuration scripts for **Debian Testing (Trixie/Sid)** systems running the **KDE Plasma 6** desktop environment on **Wayland** (optimized for developer laptops and dark-mode workstations).

---

## 📂 Repository Organization

The configuration is modularly structured for ease of maintenance and clarity:

### 🐚 [Bash.Setup](./Bash.Setup/)
Core terminal configuration, optimized for **Bash** (default project shell with modular loader in `~/.bashrc.d`) and **Zsh** (compatible when `~/.zshrc` exists).
- **`aliases.sh`**: Common shortcuts, modern Rust tools (`eza`, `bat`, `duf`, `dust`, `procs`, `btop`), Dolphin (`kioclient6`), Wayland clipboard (`wl-clipboard`), and **APT** package management (`update`, `upgrade`, `install`, `remove`, `clean`, `list`, `installed`, `pkg-info`).
- **`environment.sh`**: Global environment variables (`EDITOR`, `PATH`, Wayland/KDE Qt, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) and automatic Mise activation.
- **`functions.sh`**: Advanced shell functions (`mkcd`, `up`, `backup`, `extract`, `duh`) and multimedia utilities (FFmpeg / ImageMagick).
- **`kde_settings.sh`**: Session settings and shortcuts for KDE Plasma 6 Wayland (Breeze Dark/Light, Night Color, Plasma/KWin restarts, KCM shortcuts).
- **`history.sh`**: Optimized command history (deduplication, instant sync, 20k entries).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction with `cdspell`, extended globbing).
- **`podman-functions.sh`**: Container shortcuts and helpers for Rootless Podman and Systemd Quadlets (`pps`, `pexec`, `quadlet-*`).
- **`rclone_aliases.sh`**: Cloud sync shortcuts for Google Drive / OneDrive.
- **`yt-dlp_aliases.sh`**: Optimized multimedia downloads with yt-dlp and FFmpeg.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with native systemd Quadlets:
- **`install/podman-install.sh`**: Installation and configuration of Rootless Podman, user socket, linger, pasta/passt networking, and CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Directory setup and systemd Quadlet unit management (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: Full CLI project manager (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directory for active projects.
- **`services-shared/`**: Global shared services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Project templates (`python-postgres`, `python-postgres-redis`, `fullstack`).
- **`scripts-standalone/`**: Catalog of 17 individual pre-configured containers for development.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: High-performance virtualization setup (KVM/QEMU, modular Libvirt, virt-manager, virtio-win, Btrfs NoCoW, Polkit) with complete CLI (`--status`, `--with-windows`, `--help`).
- **`notas_virtualizacion_opensuse.md`**: Architectural reference for KVM/QEMU, VirtIO, networking, and storage.

### ⚙️ [Setup](./Setup/)
Operating system setup, KDE Plasma 6 customization, and hardening:
- **`post-install.sh`**: Smart dispatcher with CPU auto-detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-installation optimized for AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, official Debian repos, Flatpak Flathub, KDE Plasma 6, KDE Gear suite).
- **`post-install-intel.sh`**: Post-installation optimized for Intel Core / Media Center (VA-API Intel i965 / media-driver, PipeWire, codecs, and Kodi).
- **`kde-settings.sh`**: KDE Plasma 6 desktop customization (Breeze Dark, KWin titlebar buttons `IAX`, Dolphin KIO servicemenus for Kitty and Antigravity, Night Color at 4000K, Ctrl+Alt+T shortcut).
- **`laptop-setup.sh`**: Developer laptop optimizations (power-profiles-daemon, Bluetooth FastConnectable/battery, smart lid close with multi-monitor, Wayland Touchpad, PowerDevil profiles in Plasma 6, `--status`).
- **`fingerprint-setup.sh`**: Biometric authentication and unlocking (fprintd + PAM on KDE Plasma 6 via `pam-auth-update`, SDDM bypass for instant password + KWallet unlocking, `--status`, `--enroll`, `--verify`, `--disable`, `--sddm-bypass`).
- **`debian-tuning.sh`**: Kernel tuning (`sysctl` ZRAM/BBR/Inotify), file descriptor limits (1M), Baloo exclusions in KDE Plasma 6, and ZRAM compression (`--status`, `--sysctl`, `--limits`, `--baloo`, `--zram`).
- **`cockpit.sh`**: Cockpit web console and desktop client launcher (Podman, KVM, storage, `--status`, `--open`, `--client`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: System summary with `debian` (official spiral) and `compact` (FastCat) themes (`--status`, `--theme`, `--diff`, `--force`).
- **`fonts.sh`**: Developer fonts manager and diagnostics (JetBrainsMono, FiraCode, CascadiaCode, Meslo, and Hack Nerd Fonts, `--status`, `--list`, `--clean`).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity/blur, Catppuccin Mocha theme, Ctrl+Alt+T shortcut, and Dolphin servicemenu (`--status`).
- **`seguridad.sh`**: Hardening with Firewalld / UFW (services `kdeconnect`, `mdns`, `ssh`, Cockpit 9090, `trusted` zone for virbr0 and `podman+`), and sysctl unprivileged ports for development (`--status`).
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Starship prompt with Debian-themed styling (`--enable`, `--disable`, `--status`).
- **`yt-dlp-setup.sh`**: Multimedia downloading stack (yt-dlp, FFmpeg, aria2, mutagen, Mise-integrated Deno JS runtime).
- **`multimedia.sh`**: Official Debian multimedia packages, FFmpeg, GStreamer plugins, and decoupled Flatpak players (`--status`).
- **`flatpak.sh`**: Decoupled desktop applications suite via Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Spotify, Vesktop...) without polluting base system (`--status`, `--all`, `--essential`, `--multimedia`, `--clean`, `--update`).
- **`chrome.sh`**: Official Google Chrome repository and `google-chrome-stable` with dearmored keyring (`--status`).
- **`steam.sh`**: Native Steam via `i386` multiarch, GameMode, MangoHud, Proton-GE, and 32-bit Vulkan drivers (`--status`).
- **`hp-printer-setup.sh`**: HP printing stack (CUPS, HPLIP, proprietary plugin for LaserJet M15w, Firewalld USB/Wi-Fi, `--status`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (Chromium sandbox SUID `4755`, native libraries, Dolphin KIO servicemenu).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (KDE launcher and Dolphin servicemenu).
- **`git.sh`**: Git, Delta, Lazygit, and GitHub CLI setup with global best practices.
- **`opencode.sh`**: OpenCode AI CLI setup integrated into PATH.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Modern runtime management with **Mise** and **Rustup**:
- **`mise.sh`**: Mise version manager via official APT repository with `environment.d` integration.
- **`python.sh` & `python-uv-init.sh`**: System Python protection (PEP 668), `uv@latest` via Mise (`UV_LINK_MODE=copy`), and `py-project` CLI for project scaffolding (FastAPI, CLI, Data Science).
- **`nodejs.sh`**: Active Node.js LTS with Corepack (`pnpm`, `yarn`).
- **`rust.sh`**: Rustup Stable channel with `rust-analyzer`, `clippy`, `rustfmt`, and `cargo-binstall`.
- **`dotnet.sh`**: .NET SDK LTS with `DOTNET_ROOT` in `environment.d`.
- **`java.sh`**: OpenJDK LTS (Java 21) with digital certificate support (AutoFirma / DNIe) and Maven.
- **`angular.sh`**: Angular CLI latest version via Mise-managed npm.

---

## 🚀 Quick Deployment with Just

```bash
git clone https://github.com/scaballeroq/KDEDebianTesting.git
cd KDEDebianTesting
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Juegos/*.sh

# Developer Laptop (AMD Ryzen + KDE Plasma 6 + Virtualization + Podman):
just setup-laptop-amd

# Multimedia Desktop (Intel Haswell / Media Center + Kodi - Without virtualization):
just setup-media-desktop

# Or complete default installation:
just setup-all
```

Or run individual recipes:
```bash
just post-install        # Base post-installation with CPU auto-detection
just kde-setup           # KDE Plasma 6, Breeze Dark, and shortcuts
just kde-status          # Check KDE Plasma configuration status
just laptop              # Laptop optimization (Touchpad, Bluetooth)
just fingerprint-status  # Biometric authentication status
just tuning              # Apply sysctl, limits, Baloo exclusions, and ZRAM
just tuning-status       # Performance tuning diagnostics
just kitty               # Kitty terminal with opacity, blur, and Catppuccin
just virtualization      # KVM/QEMU, modular Libvirt, and Btrfs NoCoW
just virtualization-status # Hypervisor diagnostics
just multimedia          # Codecs and Flatpak multimedia
just flatpak             # Install recommended Flatpak suite
just flatpak-status      # Diagnose Flathub repositories and installed apps
just chrome              # Official Google Chrome
just steam               # Native Steam and 32-bit drivers
just languages           # Node, Python (uv), Rust, .NET, Java, and Angular
just python-uv           # Interactive py-project assistant
just podman-setup        # Rootless Podman and Quadlets
just podman-status       # Full container diagnostics
just update              # Update packages (apt update && apt upgrade)
just dist-upgrade        # Distribution upgrade (apt dist-upgrade)
```

---

*Maintained by [caballero](https://github.com/scaballeroq)*
