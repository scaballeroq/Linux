# 🔧 CachyOS Environment Configuration (KDE Plasma 6)

This repository contains a modular collection of configuration scripts for **CachyOS** systems (Arch Linux based, optimized for x86-64-v3/v4 performance) running the **KDE Plasma 6** desktop environment. The objective is to automate the setup of a professional, performant, and aesthetically pleasing development environment.

---

## 📂 Repository Structure

### 🐚 [Bash.Setup](./Bash.Setup/)
Core Bash shell configuration.
- **`aliases.sh`**: Frequently used command shortcuts and package manager aliases (`pacman` / `paru`).
- **`environment.sh`**: Global environment variables (`EDITOR`, `PATH`, Wayland/Qt flags, etc.).
- **`functions.sh`**: Advanced shell functions and multimedia processing utilities.
- **`kde_settings.sh`**: KDE Plasma 6 desktop environment tweaks, KWin, Spectacle, and shortcuts.
- **`history.sh`**: Bash history settings.
- **`options.sh`**: Shell options (`shopt`, `bind`).
- **`podman-functions.sh`**: Container management shortcuts and Quadlets functions.
- **`rclone_aliases.sh`**: Cloud storage synchronization shortcuts.
- **`yt-dlp_aliases.sh`**: Optimized video/audio downloader shortcuts.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with Quadlets (systemd native):
- **`install/podman-install.sh`**: Rootless Podman setup, socket, linger, registries, environment.d.
- **`install/quadlets-setup.sh`**: Systemd Quadlets directories and shared services setup.
- **`lib/podman-utils.sh`**: Full CLI for project management (create, start, stop, logs, status, destroy).
- **`projects/`**: Directory for active projects.
- **`services-shared/`**: Global shared services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Project templates (python-postgres, python-postgres-redis, fullstack).

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU and `libvirtd` setup optimized for CachyOS.
- **`notas_virtualizacion_cachyos.md`**: Guide for KVM/QEMU virtualization on CachyOS.

### ⚙️ [Setup](./Setup/)
OS configuration, hardening, and styling scripts:
- **`post-install.sh`**: Smart dispatcher with auto CPU detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: AMD Ryzen optimized post-install (ZRAM, RADV, Mesa, PipeWire).
- **`post-install-intel.sh`**: Intel Core optimized post-install (VA-API Intel, PipeWire).
- **`laptop-setup.sh`**: Laptop optimization (Touchpad, Bluetooth, HiDPI, VRR).
- **`cachyos-tuning.sh`**: Kernel sysctl, Baloo, Systemd, Distrobox, and system limits tuning.
- **`cockpit.sh`**: Cockpit web management console setup.
- **`fastfetch.sh`**: System info fetch initialization.
- **`fonts.sh`**: Automated Nerd Fonts installer.
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity/blur and Catppuccin theme.
- **`seguridad.sh`**: Security hardening with Firewalld, DNS-over-TLS, MAC Randomization and sysctl.
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `btop`, `jq`).
- **`starship.sh`**: Optional Starship prompt with enable/disable commands.
- **`yt-dlp-setup.sh`**: Multimedia setup dependencies (yt-dlp, ffmpeg, deno).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup.
- **`antigravity-cli.sh`**: Google Antigravity CLI setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta, Lazygit and GitHub CLI setup.
- **`opencode.sh`**: OpenCode AI CLI setup.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Runtime management with **mise**.
- **`mise.sh`**: Mise version manager installer.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`rust.sh`**

### 🎮 [Juegos](./Juegos/)
- **`steam.sh`**: Steam with Proton CachyOS.

---

## 🚀 Quick Start

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/CachyOS
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh Juegos/*.sh
just setup-all
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
