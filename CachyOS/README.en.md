# 🔧 CachyOS Environment Configuration (GNOME Desktop)

This repository contains a modular collection of configuration scripts for **CachyOS** systems (Arch Linux based, optimized for x86-64-v3/v4 performance) running the **GNOME** desktop environment. The objective is to automate the setup of a professional, performant, and aesthetically pleasing development environment.

---

## 📂 Repository Structure

### 🐚 [Bash.Setup](./Bash.Setup/)
Core Bash shell configuration.
- **`aliases.sh`**: Frequently used command shortcuts and package manager aliases (`pacman` / `paru`).
- **`environment.sh`**: Global environment variables (`EDITOR`, `PATH`, etc.).
- **`functions.sh`**: Advanced shell functions and multimedia processing utilities.
- **`gnome_settings.sh`**: GNOME desktop environment tweaks and shortcuts.
- **`history.sh`**: Bash history settings.
- **`options.sh`**: Shell options (`shopt`, `bind`).
- **`podman-functions.sh`**: Container management shortcuts and functions.
- **`rclone_aliases.sh`**: Cloud storage synchronization shortcuts.
- **`yt-dlp_aliases.sh`**: Optimized video/audio downloader shortcuts.

### 🐳 [Podman](./Podman/)
Isolated container deployment scripts:
- **Core**: `podman.sh` (CachyOS Podman rootless setup)
- **Databases**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Monitoring & Management**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-dozzle.sh`, `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`
- **Infrastructure**: `podman-nginx.sh`, `podman-keycloak.sh`, `podman-rabbitmq.sh`, `podman-minio.sh`, `podman-mailhog.sh`, `podman-browserless.sh`
- **CMS/Frameworks**: `podman-wordpress.sh`, `podman-storybook.sh`

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU and `libvirtd` setup optimized for CachyOS.
- **`notas_virtualizacion_cachyos.md`**: Guide for KVM/QEMU virtualization on CachyOS.

### ⚙️ [Setup](./Setup/)
OS configuration, hardening, and styling scripts:
- **`post-install.sh`**: Master post-installation script for CachyOS.
- **`apariencia.sh`**: Papirus icon theme installation.
- **`cockpit.sh`**: Cockpit web management console setup.
- **`fastfetch.sh`**: System info fetch initialization.
- **`firefox.sh`**: Optimized Firefox build (`firefox-cachyos`).
- **`fonts.sh`**: Automated Nerd Fonts installer.
- **`ptyxis.sh`**: Ptyxis terminal appearance configuration.
- **`seguridad.sh`**: Firewall (UFW) configuration.
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`) & `Starship` prompt.
- **`yt-dlp-setup.sh`**: Multimedia dependencies.

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity setup.
- **`neovim.sh`**: Neovim & LazyVim setup.
- **`vscode.sh`**: Visual Studio Code installer.

### 🛠️ [Git](./Git/)
- **`git.sh`**: Git, Delta, and Lazygit setup.
- **`github-cli.sh`**: GitHub CLI installer.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Runtime management with **mise**.
- **`mise.sh`**: Mise version manager installer.
- **`angular.sh`**, **`dotnet.sh`**, **`gemini.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`rust.sh`**

### 📦 [Apps](./Apps/) & 🎮 [Juegos](./Juegos/)
- **`meld.sh`**: Diff tool.
- **`steam.sh`**: Steam with Proton CachyOS.

---

## 🚀 Quick Start

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/CachyOS
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/*.sh Git/*.sh Apps/*.sh Juegos/*.sh
just setup-all
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
