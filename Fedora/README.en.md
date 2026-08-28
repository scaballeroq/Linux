# 🔧 Fedora: Environment Setup for Fedora 44 Workstation + KDE Plasma 6

Organized, modular, and automated collection of configuration scripts for **Fedora 44 Workstation** running **KDE Plasma 6** on **Wayland** (tailored for developer workstations and laptops).

---

## 📂 Repository Structure

The configuration is modularly organized for easy deployment and maintenance:

### 🐚 [Bash.Setup](./Bash.Setup/)
The core modular Bash shell configuration (dynamically loaded via `~/.bashrc.d`):
- **`aliases.sh`**: Everyday shortcuts for DNF5, KDE Plasma/Dolphin integration, Wayland clipboard (`wl-copy`/`wl-paste`), and modern Rust CLI tools (`eza`, `bat`, `duf`, `dust`, `procs`, `btop`, `zoxide`).
- **`kde_settings.sh`**: Interactive CLI management tool for KDE Plasma 6, Wayland/KWin settings, direct shortcuts to System Settings modules (`kcmshell6`), shell restart, and Spectacle shortcuts.
- **`environment.sh`**: Global environment variables (`PATH`, `EDITOR`, `mise`, `GPG_TTY`, `DOCKER_HOST`, Wayland/Qt/Electron flags).
- **`functions.sh`**: Advanced shell functions and media utilities (FFmpeg, ImageMagick, universal multi-format extraction).
- **`history.sh`**: Optimized Bash history configuration (up to 20,000 lines, no duplicates, immediate sync).
- **`options.sh`**: Internal Bash shell options via `shopt` (`autocd`, `globstar`, `dirspell`, secure line editing).
- **`podman-functions.sh`**: Quick container management commands (`pps`, `pexec`, `plogs`, `pclean-total`, `quadlet-reload`).
- **`rclone_aliases.sh`**: Cloud synchronization and backup aliases for Google Drive and OneDrive.
- **`yt-dlp_aliases.sh`**: Optimized media downloader aliases (1080p, MP3, playlists, and Deno JS engine detection).

### ⚙️ [Setup](./Setup/)
Operating system provisioning, visual customization, and performance hardening scripts:
- **`post-install.sh`**: Smart CPU dispatcher with automatic architecture detection (AMD vs Intel) and CLI flags (`--amd`, `--intel`).
- **`post-install-amd.sh`**: Post-installation tailored for **AMD Ryzen** CPUs and Radeon Graphics (AMD microcode, GPU firmware, RADV, Mesa, PipeWire, ZRAM, RPM Fusion).
- **`post-install-intel.sh`**: Post-installation tailored for **Intel Core** desktop PCs (Haswell i7-4790 / HD Graphics 4600) for media center & streaming (Intel microcode, VA-API `i965`/`intel-media-driver`, codecs, Kodi, no virtualization overhead).
- **`apariencia.sh`**: Theme manager, Kvantum SVG style engine (Qt5/Qt6), Papirus-Dark icons, cursors, and visual synchronization with GTK 3/4 and Flatpaks.
- **`kitty.sh`**: GPU-accelerated Kitty terminal with customizable opacity (`--opacity`), blur effects, JetBrainsMono Nerd Font, on-the-fly hotkeys, and Dolphin file manager integration.
- **`laptop-setup.sh`**: Laptop performance and battery optimizations (Touchpad gestures, Bluetooth, hybrid graphics via `switcheroo-control`, energy management via `tuned-ppd`, and 95% brightness persistence service).
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w printer configuration via USB/Network (CUPS, HPLIP, KDE Print Manager, and proprietary plugin download).
- **`fedora-tuning.sh`**: Kernel Sysctl tuning (`inotify`, `max_map_count`, ZRAM `swappiness`, BBR), user limits (`limits.d`), Systemd stop timeouts, Baloo exclusion rules, and Distrobox support.
- **`seguridad.sh`**: Comprehensive security hardening (Firewalld in `FedoraWorkstation` zone supporting KDE Connect, mDNS, and SSH; DNS-over-TLS in `systemd-resolved`; Wi-Fi MAC Randomization; rootless Podman sysctl namespaces).
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `duf`, `du-dust`, `btop`, `jq`), Starship prompt, and `.bashrc` integration.
- **`plymouth-setup.sh`**: Graphical boot splash installer and interactive theme manager (Breeze, BGRT, Spinner) with automated Dracut initramfs regeneration.
- **`cockpit.sh`**: Cockpit web administration console with modules for Podman, KVM VMs, Storage, and Networking ([https://localhost:9090](https://localhost:9090)).
- **`fonts.sh`**: Developer Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode).
- **`fastfetch.sh`**: Terminal startup system summary banner.
- **`yt-dlp-setup.sh`**: Full-stack yt-dlp + FFmpeg + AtomicParsley + aria2c + Deno JS engine installer and configuration.

### 📦 [ProgrammingLanguages](./ProgrammingLanguages/)
Modern programming languages and SDK toolchains:
- **`mise.sh`**: High-performance polyglot version manager with KDE Plasma Wayland session integration (`environment.d`) and global shims.
- **`nodejs.sh`**: Dynamic Node.js LTS resolution, Corepack (`pnpm`/`yarn`), and CLI status/update capabilities.
- **`python.sh`**: Stable Python LTS release, `uv` fast package manager, `pipx`, and build dependencies.
- **`rust.sh`**: Rustup tracking Stable channel, `rust-analyzer`, `clippy`, `cargo-binstall`, and environment variables.
- **`dotnet.sh`**: .NET SDK LTS for CoreCLR cross-platform development.
- **`java.sh`**: OpenJDK LTS with support for FNMT / AutoFirma certificates.
- **`angular.sh`**: Angular CLI integrated globally via Mise.
- **`gemini.sh`**: Google Gemini command-line interface.

### 💻 [IDEs & Developer Tools](./IDE/)
- **`neovim.sh`**: Modular Neovim setup powered by the LazyVim starter distribution.
- **`vscode.sh`**: Native Visual Studio Code via Microsoft's official DNF5 RPM repository.
- **`antigravity.sh`**: Google Antigravity Desktop 2.0 (complete installer with sandbox and desktop launcher).
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Antigravity CLI and standalone IDE engine.
- **`opencode.sh`**: OpenCode AI client and editor with version management.
- **`git.sh`**: Global Git configuration, Git-Delta diff visualizer (`zdiff3`, `side-by-side`), and Lazygit TUI.
- **`github-cli.sh`**: Official GitHub CLI (`gh`).

### 🐳 [Podman](./Podman/)
Professional rootless container ecosystem and Systemd Quadlets:
- **Installation**: `install/podman-install.sh` and `install/quadlets-setup.sh`.
- **Management CLI**: `lib/podman-utils.sh` (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **Shared Global Services**: Traefik (Reverse Proxy), Global PostgreSQL, Global Redis, and Keycloak (OAuth2/OIDC).
- **Project Templates**: `python-postgres`, `python-postgres-redis`, and `fullstack` (FastAPI + React/Node + Traefik + Keycloak + Hot Reload).

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: Complete KVM/QEMU acceleration, modular Libvirt, native VirtIO, native PipeWire audio, Tuned `virtual-host` profile, nftables backend, and Nested KVM.
- **`Notas_Virtualizacion_Fedora.md`**: Technical virtualization guide and reference manual.

---

## 🚀 Quick Deployment with Just

To deploy the environment according to your hardware profile:

```bash
git clone https://github.com/scaballeroq/Fedora.git
cd Fedora
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Developer Laptop (AMD Ryzen + KDE Plasma + Virtualization + Podman):
just setup-laptop-amd

# Media Desktop (Intel Haswell / Media Center + Kodi - No virtualization):
just setup-media-desktop
```

Or trigger individual components:
```bash
just post-install-amd    # AMD Ryzen specific post-install
just post-install-intel  # Intel Media Center post-install
just apariencia          # Apply themes, Kvantum (KvFlatDark), and Papirus-Dark icons in KDE and GTK
just kitty               # Setup Kitty terminal with custom opacity & blur
just tuning              # Apply sysctl, user limits, systemd timeouts, and Baloo
just plymouth            # Configure and enable graphical boot splash
just ides                # Install Neovim, VSCode, Antigravity, and OpenCode
just languages           # Install Node, Python, Rust, .NET, and Java
just podman-setup        # Setup Rootless Podman and Systemd Quadlets
```
