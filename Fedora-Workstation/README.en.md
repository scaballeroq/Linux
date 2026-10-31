# 🔧 Fedora Workstation Environment Configuration (GNOME)

This repository contains an organized, modular, and automated collection of configuration scripts for **Fedora Workstation** systems running the **GNOME** desktop environment on **Wayland** (optimized for development workstations and laptops in dark mode).

---

## 📂 Repository Organization

### 🐚 [Bash.Setup](./Bash.Setup/)
Terminal configuration core, optimized for **Bash** (modular support via `~/.bashrc.d`) and **Zsh** (compatible if `~/.zshrc` exists).
- **`aliases.sh`**: Productivity aliases, dynamic shell reload, Nautilus, Git, Firewalld, and **DNF / DNF5** package manager shortcuts.
- **`environment.sh`**: Global variables (`EDITOR`, `PATH`, Wayland/GNOME, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) and Mise initialization.
- **`functions.sh`**: Advanced shell helper functions (`mkcd`, `up`, `hg`) and media processing utilities.
- **`gnome_settings.sh`**: Environment settings and keybindings for GNOME Wayland (dark theme, night light, Wayland capture with grim/satty, Nautilus).
- **`history.sh`**: Optimized shell history (deduplication, instant sync, timestamps).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction, case-insensitive completion with `shopt`).
- **`podman-functions.sh`**: Rootless Podman and Quadlet helper functions.
- **`rclone_aliases.sh`**: Cloud storage synchronization shortcuts (Google Drive / OneDrive).
- **`yt-dlp_aliases.sh`**: Media download helpers.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with native systemd Quadlets:
- **`install/podman-install.sh`**: Rootless Podman installation, socket, linger, registries, and passt network backend.
- **`install/quadlets-setup.sh`**: Directory structure and systemd Quadlet setup.
- **`lib/podman-utils.sh`**: Project management CLI (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directory for active project instances.
- **`services-shared/`**: Shared global services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Project templates (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU, modular Libvirt, virt-manager, and virtio-win configuration for Fedora.
- **`notas_virtualizacion_fedora.md`**: In-depth virtualization notes for KVM, VirtIO, bridge networking, and storage.

### ⚙️ [Setup](./Setup/)
Operating system setup, personalization, and hardening:
- **`post-install.sh`**: Intelligent dispatcher with CPU auto-detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-installation optimized for AMD Ryzen (ZRAM, RADV, Mesa, PipeWire, RPM Fusion, codecs).
- **`post-install-intel.sh`**: Post-installation optimized for Intel Core / Media Center (VA-API Intel i965 / media-driver, PipeWire, codecs, Kodi).
- **`gnome-settings.sh`**: GNOME customization (Dark mode `prefer-dark` and `adw-gtk3-dark`, Mutter VRR, Kitty shortcut Ctrl+Alt+T, Nautilus).
- **`gnome-extensions.sh`**: Extension manager and installer from official repos and extensions.gnome.org (Dash to Dock, AppIndicator, Blur my Shell, etc.).
- **`apariencia.sh`**: GTK themes, icon themes (Papirus / Adwaita), and modern cursors (Bibata-Modern-Classic).
- **`gsconnect.sh`**: Mobile integration with GSConnect (native KDE Connect for GNOME) and automatic Firewalld rules (1714-1764 TCP/UDP & mDNS).
- **`fingerprint-setup.sh`**: Biometric fingerprint authentication setup (fprintd + authselect PAM).
- **`hp-printer-setup.sh`**: HP printer installer and manager (CUPS, HPLIP, Avahi, proprietary plugin, and Firewalld).
- **`ptyxis.sh`**: Container-aware Ptyxis terminal styling (dark mode, 85% opacity, hidden scrollbars).
- **`laptop-setup.sh`**: Laptop optimizations (Touchpad gestures, Bluetooth FastConnectable, dock lid behavior, 95% brightness persistence).
- **`fedora-tuning.sh`**: Kernel tuning (`sysctl`), resource limits (`limits.d`), Systemd timeouts, Tracker exclusions, and Distrobox.
- **`cockpit.sh`**: Cockpit web management console with modules for Podman, KVM VMs, storage, and networking.
- **`fastfetch.sh` & `config-fedora.jsonc`**: Aesthetic system info summary for Fedora and compact mode (`config-compact.jsonc`).
- **`fonts.sh`**: Automated developer font installer (JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack Nerd Fonts).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with opacity/blur, Catppuccin Mocha theme, and GNOME / Nautilus integrations.
- **`seguridad.sh`**: Security hardening with Firewalld (`FedoraWorkstation` zone with GSConnect support), DNS-over-TLS, and rootless Podman sysctl.
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Modern Starship prompt with Fedora theme.
- **`yt-dlp-setup.sh`**: High-performance multimedia downloading stack (yt-dlp, FFmpeg, AtomicParsley, aria2, Deno JS engine).
- **`multimedia.sh`**: Complete multimedia suite, unrestricted FFmpeg, GStreamer plugins, freeworld VA-API acceleration, native players (Celluloid, MPV, VLC), and optimal MPV config.
- **`flatpak.sh`**: Decoupled Flathub application catalog (Flatseal, Podman Desktop, Warehouse, VLC, OBS Studio, LocalSend...).
- **`chrome.sh`**: Google Chrome official repo activation, Wayland Ozone flags, and VA-API hardware acceleration.
- **`firefox.sh`**: Mozilla Firefox native verification and hardware acceleration support.
- **`steam.sh`**: Steam installation from RPM Fusion Nonfree with GameMode, MangoHud, 32-bit Vulkan drivers (`mesa-vulkan-drivers.i686`), and Proton-GE.
- **`amd64v3.sh`**: x86-64-v3 microarchitecture diagnostic and native glibc-hwcaps support.

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop setup (with sandbox, update helper, and Nautilus context menu).
- **`antigravity-cli.sh`**: Google Antigravity CLI setup.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup.
- **`git.sh`**: Git, Delta, Lazygit, and GitHub CLI setup.
- **`opencode.sh`**: OpenCode AI CLI setup.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Modern runtime management via **Mise**:
- **`mise.sh`**: Official RPM Mise package via DNF5 with `environment.d` integration.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`python-uv-init.sh`**, **`rust.sh`**

---

## 🚀 Fast Deployment with Just

```bash
git clone https://github.com/scaballeroq/Fedora-Workstation.git
cd Fedora-Workstation
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Development Laptop (AMD Ryzen + GNOME + Virtualization + Podman):
just setup-laptop-amd

# Desktop Media Center (Intel Haswell / Media Center + Kodi):
just setup-media-desktop

# Or default full setup:
just setup-all
```
