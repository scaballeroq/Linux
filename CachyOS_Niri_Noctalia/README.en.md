# 🔧 CachyOS Environment Configuration (Niri + Noctalia Shell)

This repository contains a modular collection of configuration scripts for **CachyOS** systems (Arch Linux based, optimized for x86-64-v3/v4 performance) running the **Niri** scrollable-tiling Wayland compositor and the **Noctalia Shell** modern desktop environment. The objective is to automate the setup of a professional, performant, and aesthetically pleasing development environment.

---

## 📂 Repository Structure

### 🐚 [ZSH.Setup](./ZSH.Setup/)
Core terminal configuration, optimized primarily for **Zsh** (default shell in CachyOS) with fallback compatibility for **Bash**.
- **`aliases.sh`**: Navigation shortcuts (`project`, `cachyos`, `repo`), global pipes (`G`, `L`, `H`, `J`), reload shortcuts, and package manager aliases (`pacman` / `paru`).
- **`environment.sh`**: Global environment variables (`EDITOR`, `PATH`, path deduplication with `typeset -U path`, native Wayland/Qt flags) and Mise activation.
- **`functions.sh`**: Advanced shell functions (`mkcd`, `up`, `hg`) and multimedia processing utilities.
- **`niri_noctalia.sh`**: Niri (`niri msg`) and Noctalia Shell (`noctalia msg`) IPC shortcuts, native Wayland interactive screenshots (`grim` + `slurp`), and screen recording (`wl-screenrec`).
- **`history.sh`**: Optimized command history (50k entries, `EXTENDED_HISTORY`, deduplication, instant saving to `~/.zsh_history`).
- **`options.sh`**: Advanced Zsh options (`autocd`, typo correction, `extended_glob`, colored menus).
- **`podman-functions.sh`**: Container management shortcuts and Quadlets functions compatible with Zsh and Bash arrays.
- **`rclone_aliases.sh`**: Cloud storage synchronization shortcuts.
- **`yt-dlp_aliases.sh`**: Optimized video/audio downloader shortcuts.

### ⚙️ [Setup](./Setup/)
OS configuration, hardening, and styling scripts:
- **`post-install.sh`**: Smart dispatcher with auto CPU detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: AMD Ryzen optimized post-install (ZRAM, RADV, Mesa, PipeWire, Niri stack).
- **`post-install-intel.sh`**: Intel Core optimized post-install (VA-API Intel, PipeWire, Niri stack).
- **`cockpit.sh`**: Cockpit web management console setup.
- **`fastfetch.sh`**: System info fetch initialization.
- **`fonts.sh`**: Automated Nerd Fonts installer.
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity/blur and Catppuccin theme.
- **`seguridad.sh`**: Firewalld configuration (home LAN), QEMU/KVM and Podman integration, and Sysctl.
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`, `btop`, `jq`).
- **`yt-dlp-setup.sh`**: Multimedia setup dependencies (yt-dlp, ffmpeg, deno).

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with Quadlets (systemd native):
- **`install/podman-install.sh`**: Rootless Podman setup, socket, linger, registries, environment.d.
- **`install/quadlets-setup.sh`**: Systemd Quadlets directories and shared services setup.
- **`lib/podman-utils.sh`**: Full CLI for project management (create, start, stop, logs, status, destroy).
- **`projects/`**: Directory for active projects.
- **`services-shared/`**: Global shared services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Project templates (python-postgres, python-postgres-redis, fullstack).

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU and `libvirtd` setup optimized for CachyOS and Wayland.
- **`notas_virtualizacion_cachyos.md`**: Guide for KVM/QEMU virtualization on CachyOS.

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

---

## 🚀 Quick Start

```bash
git clone https://github.com/scaballeroq/CachyOS_Niri_Noctalia.git
cd CachyOS_Niri_Noctalia
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh
just setup-all
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
