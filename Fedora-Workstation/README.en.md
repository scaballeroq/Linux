# 🔧 Fedora Workstation Environment Configuration (GNOME)

Modular, automated, and high-performance workstation configuration scripts for **Fedora 44 Workstation** running **GNOME** on **Wayland** (optimized for developers, dark mode, AMD Ryzen laptops, and multimedia desktop hosts).

---

## 📂 Repository Layout

The configuration is structured modularly for easy maintenance and deployment:

### 🐚 [Bash.Setup](./Bash.Setup/)
Core terminal configuration optimized for **Bash** (default shell with dynamic `~/.bashrc.d` support) and **Zsh** (compatible if `~/.zshrc` exists).
- **`aliases.sh`**: Shortcuts for frequent tasks, dynamic reload, Nautilus file manager, and **DNF5** package manager.
- **`environment.sh`**: Global variables (`EDITOR`, `PATH`, Wayland/GNOME flags, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) and automated Mise activation.
- **`functions.sh`**: Advanced shell functions (`mkcd`, `up`, `hg`) and multimedia utilities (FFmpeg / ImageMagick).
- **`gnome_settings.sh`**: Quick aliases and CLI commands for GNOME Wayland (dark mode, night light, Wayland screenshots with grim/satty, Nautilus).
- **`history.sh`**: Optimized shell history (deduplication, instant sync, timestamps).
- **`options.sh`**: Advanced shell behavior (`autocd`, typo correction, case-insensitive tab completion).
- **`podman-functions.sh`**: Fast shortcuts for Podman rootless containers and Quadlets.
- **`rclone_aliases.sh`**: Cloud storage synchronization shortcuts (Google Drive / OneDrive).
- **`yt-dlp_aliases.sh`**: Optimized audio/video download helpers.

### 🐳 [Podman](./Podman/)
Native rootless container ecosystem using systemd Quadlets:
- **`install/podman-install.sh`**: Podman rootless provisioning, socket activation, linger persistence, registries, and passt network backend.
- **`install/quadlets-setup.sh`**: Systemd Quadlets directory setup and automated generators.
- **`lib/podman-utils.sh`**: Comprehensive CLI for project lifecycle management (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`services-shared/`**: Global shared services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Production project templates (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: Hardware-accelerated KVM/QEMU, modular Libvirt, virt-manager, and virtio-win setup for Fedora 44.
- **`notas_virtualizacion_fedora.md`**: Detailed technical manual for KVM/QEMU, VirtIO, network bridge, and storage on Fedora 44.

### ⚙️ [Setup](./Setup/)
Operating system provisioning, performance tuning, and hardening scripts:
- **`post-install.sh`**: Smart CPU architecture dispatcher (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: AMD Ryzen post-installation (ZRAM, RADV, Mesa, PipeWire, RPM Fusion, multimedia codecs).
- **`post-install-intel.sh`**: Intel Core post-installation (Intel i965 / media-driver VA-API, PipeWire, codecs, Kodi).
- **`gnome-settings.sh`**: GNOME customization (Dark theme `prefer-dark` & `adw-gtk3-dark`, Mutter VRR, window buttons, Ctrl+Alt+T shortcut, Nautilus).
- **`gnome-extensions.sh`**: GNOME Shell extensions manager supporting official Fedora packages and extensions.gnome.org (Dash to Dock, AppIndicator, Caffeine, Blur my Shell, etc.).
- **`laptop-setup.sh`**: Laptop optimizations (Touchpad gestures, Bluetooth FastConnectable, external display lid switch behavior, 95% brightness persistence).
- **`fedora-tuning.sh`**: Kernel tuning (`sysctl`), descriptor limits (`limits.d`), Systemd stop timeouts, massive Tracker 3 (LocalSearch) exclusions, and Distrobox.
- **`cockpit.sh`**: Cockpit web console with modules for Podman, KVM VMs, storage, and networking.
- **`fastfetch.sh` & `config.jsonc`**: Custom Fedora-themed fastfetch summary.
- **`fonts.sh`**: Nerd Fonts installer (JetBrainsMono, FiraCode, CascadiaCode).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with Catppuccin Mocha theme, blur 32, opacity controls, and GNOME / Nautilus integration.
- **`seguridad.sh`**: Firewalld hardening (zone `FedoraWorkstation` with GSConnect support), DNS-over-TLS, and rootless Podman sysctl.
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `btop`, `jq`).
- **`starship.sh` & `starship.toml`**: Starship prompt manager and configuration.
- **`yt-dlp-setup.sh`**: Full multimedia stack (yt-dlp, FFmpeg, AtomicParsley, aria2, Deno JS runtime).
- **`multimedia.sh`**: Complete multimedia codecs stack, unrestricted FFmpeg swap, GStreamer plugins, and decrypted DVD support (`libdvdcss`) via RPM Fusion (Free, Nonfree, and Tainted).
- **`chrome.sh`**: Official Google Chrome repository activation and `google-chrome-stable` installation.
- **`steam.sh`**: Native Steam from RPM Fusion Nonfree with GameMode, MangoHud, and 32-bit Vulkan drivers (`mesa-vulkan-drivers.i686`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop installer with sandbox and Nautilus context menu.
- **`antigravity-cli.sh`**: Google Antigravity CLI suite.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine installer.
- **`git.sh`**: Git, Delta, Lazygit, and GitHub CLI setup with default branch `develop`.
- **`opencode.sh`**: OpenCode AI CLI installer.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Runtime management powered by **Mise**:
- **`mise.sh`**: Mise polyglot tool version manager via official RPM repo with `environment.d` session support.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`python.sh`**, **`python-uv-init.sh`**, **`rust.sh`**

---

## 🚀 Quick Start with Just

Run automatic provisioning based on your machine profile:

```bash
git clone https://github.com/scaballeroq/Fedora-Workstation.git
cd Fedora-Workstation
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Developer Laptop (AMD Ryzen + GNOME + Virtualization + Podman):
just setup-laptop-amd

# Desktop Media Center (Intel Haswell / Media Center + Kodi - Without virtualization):
just setup-media-desktop

# Or default complete setup:
just setup-all
```

Or run individual components:
```bash
just post-install        # Base post-install with automatic CPU detection
just gnome-setup         # Apply GNOME settings, dark mode, clock, and shortcuts
just gnome-extensions    # Install and enable GNOME Shell extensions
just laptop              # Laptop optimization (Touchpad, Bluetooth, 95% brightness)
just tuning              # Apply sysctl, limits, systemd, and Tracker 3 exclusions
just kitty               # Configure Kitty terminal with blur and opacity
just virtualization      # Setup KVM/QEMU and libvirt
just multimedia         # Install complete codecs, FFmpeg, and proprietary drivers
just chrome             # Install official Google Chrome
just steam              # Install native Steam and 32-bit Vulkan drivers
just languages           # Install Node, Python, Rust, .NET, and Java
just podman-setup        # Configure rootless Podman and Quadlets
```

---

*Maintained by [caballero](https://github.com/scaballeroq)*
