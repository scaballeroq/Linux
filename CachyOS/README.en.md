# 🔧 CachyOS Environment Configuration (GNOME Workstation)

This repository contains a modular collection of configuration scripts for **CachyOS** systems (Arch Linux based, optimized for x86-64-v3/v4 performance) running the **GNOME** desktop environment. The objective is to automate the setup of a professional, performant, and dark-themed development workstation.

---

## 📂 Repository Structure

### 🐚 [Bash.Setup](./Bash.Setup/)
Core terminal configuration, optimized for **Bash** (default shell of the project) and **Zsh** (compatible if `~/.zshrc` exists).
- **`aliases.sh`**: Frequently used command shortcuts, dynamic reload, Nautilus, and package manager aliases (`pacman` / `paru`).
- **`environment.sh`**: Global environment variables (`EDITOR`, `PATH`, Wayland/GNOME flags, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) and smart Mise activation in Bash and Zsh.
- **`functions.sh`**: Advanced shell functions (`mkcd`, `up`, `hg`) and multimedia processing utilities.
- **`gnome_settings.sh`**: GNOME desktop environment tweaks, dark mode, Wayland screenshot tools (grim/satty), and Nautilus shortcuts.
- **`history.sh`**: Optimized command history (10k/20k entries, deduplication, `~/.bash_history` and `~/.zsh_history`).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction, case-insensitive completions with `shopt`/`zstyle`).
- **`podman-functions.sh`**: Container management shortcuts and Quadlets functions compatible with both shells.
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
- **`virtualization.sh`**: KVM/QEMU, `libvirt`, and `virt-manager` setup optimized for CachyOS.
- **`notas_virtualizacion_cachyos.md`**: Guide for KVM/QEMU virtualization and VirtioFS on CachyOS.

### ⚙️ [Setup](./Setup/)
OS configuration, hardening, and styling scripts:
- **`post-install.sh`**: Smart dispatcher with auto CPU detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: AMD Ryzen optimized post-install (ZRAM, RADV, Mesa, PipeWire, GNOME, Early KMS amdgpu).
- **`post-install-intel.sh`**: Intel Core optimized post-install (VA-API Intel, PipeWire, GNOME).
- **`gnome-settings.sh`**: GNOME customization (Dark theme `prefer-dark` & `adw-gtk3-dark`, Mutter VRR, Kitty Ctrl+Alt+T shortcut, Nautilus).
- **`gnome-extensions.sh`**: Official GNOME Shell extensions installer and manager from repos (Dash to Dock, AppIndicator, Caffeine, Weather O'Clock, Bing Wallpaper, Blur my Shell, Logo Menu).
- **`laptop-setup.sh`**: Laptop optimization for GNOME (Touchpad, Bluetooth, AC power sleep override, brightness persistence).
- **`cachyos-tuning.sh`**: Kernel sysctl, Tracker exclusions, Systemd, Distrobox, and system limits tuning.
- **`cockpit.sh`**: Cockpit web management console setup (Firewalld `home` zone).
- **`fastfetch.sh`**: System info fetch initialization.
- **`fonts.sh`**: Automated Nerd Fonts installer.
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity/blur, Catppuccin Mocha theme, and GNOME integration.
- **`seguridad.sh`**: Security hardening with exclusive Firewalld (default `home` zone), DNS-over-TLS, Podman/KVM sysctl.
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `btop`, `jq`).
- **`starship.sh`**: Optional Starship prompt with enable/disable commands.
- **`yt-dlp-setup.sh`**: Multimedia setup dependencies (yt-dlp, ffmpeg, deno).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (with Nautilus context script).
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
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Apps/*.sh Podman/install/*.sh Podman/lib/*.sh
just setup-all
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
