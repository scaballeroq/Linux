# 🔴 Soplos Linux Boro Environment Configuration (GNOME Shell Wayland)

This repository contains an organized, modular, and automated collection of configuration scripts for **Soplos Linux Boro** systems running the **GNOME Shell (Wayland / Mutter)** desktop environment, optimized for HP ProBook 455 G10 laptops and workstations in dark mode.

---

## 📂 Repository Structure

The configuration is modularly organized for maximum maintainability:

### 🐚 [Bash.Setup](./Bash.Setup/)
Core terminal configuration optimized for **Bash** (with modular `~/.bashrc.d` support) and compatible with **Zsh** (`~/.zshrc.d`).
- **`aliases.sh`**: Common shortcuts for navigation, Rust CLI tools (`eza`, `bat`, `duf`, `dust`), Git, **APT** package management (`update`, `upgrade`, `install`, `clean`), Firewalld (`fw*`), Libvirt, and Podman.
- **`environment.sh`**: Global variables (`EDITOR`, `PATH`, Wayland, `QT_QPA_PLATFORMTHEME="gnome"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`), and automatic Mise shims activation.
- **`functions.sh`**: Advanced shell functions (`mkcd`, `up`, `extract`, `duh`, `backup_file`, `monitors`) with interactive session guards.
- **`gnome_settings.sh`**: Environment settings and shortcuts for GNOME Shell Wayland (Adwaita-dark, 4000K Night Light, shell reload, GNOME Control Center shortcuts).
- **`history.sh`**: Optimized history handling (deduplication, instant sync, expanded 20k entries).
- **`options.sh`**: Shell options (`autocd`, typo correction with `cdspell`, extended globbing).
- **`podman-functions.sh`**: Helper functions and shortcuts for rootless Podman containers and Quadlets.
- **`rclone_aliases.sh`**: Shortcuts for Google Drive and OneDrive sync, copy, and dry-run operations.
- **`yt-dlp_aliases.sh`**: Media download shortcuts with yt-dlp and FFmpeg.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with native systemd Quadlets:
- **`install/podman-install.sh`**: Installation and configuration of rootless Podman, user socket, linger, registries, and CLI (`--status`, `--help`).
- **`install/quadlets-setup.sh`**: Systemd Quadlets directory and service deployment (`--status`, `--install-shared`).
- **`lib/podman-utils.sh`**: Full CLI project manager (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).
- **`projects/`**: Directory for active container projects.
- **`services-shared/`**: Global shared services (PostgreSQL, Redis, Traefik, Keycloak).
- **`templates/`**: Project templates (`python-postgres`, `python-postgres-redis`, `fullstack`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: High-performance virtualization setup (KVM/QEMU, Libvirt, virt-manager, virtio-win, Btrfs NoCoW, passwordless Polkit for `libvirt` group, Firewalld) with full CLI (`--status`, `--with-windows`, `--help`).

### ⚙️ [Setup](./Setup/)
System provisioning, GNOME Shell customization, and hardening:
- **`post-install.sh`**: Smart dispatcher with CPU auto-detection (AMD Ryzen vs Intel Core).
- **`post-install-amd.sh`**: Post-installation optimized for AMD Ryzen (ZRAM zstd, `contrib non-free non-free-firmware` repositories, official AMD firmware, amd64-microcode, Mesa RADV, hardware VA-API, PipeWire, Flathub Flatpak integration).
- **`post-install-intel.sh`**: Post-installation optimized for Intel Core / Media Center (Intel VA-API i965/iHD, PipeWire, Kodi).
- **`laptop-setup.sh`**: Laptop optimizations (power-profiles-daemon, Bluetooth FastConnectable, smart multi-monitor lid switch handling, Wayland touchpad gestures, Mutter VRR, `--status`).
- **`fingerprint-setup.sh`**: Biometric authentication (fprintd + PAM, Synaptics sensor, `--status`, `--enroll`, `--verify`, `--disable`).
- **`hp-printer-setup.sh`**: HP printer stack (CUPS, HPLIP, proprietary plugin for LaserJet M15w, Firewalld rules, `--status`).
- **`gnome-settings.sh`**: GNOME Shell configuration (Adwaita-dark theme, window button layout, Nautilus right-click scripts for Kitty/Antigravity/VS Code, 4000K Night Light, 24h clock, `--status`, `--dark`, `--light`).
- **`gnome-extensions.sh`**: GNOME Shell extensions manager (`gnome-shell-extensions`, GSConnect, Dash to Dock, AppIndicator, Blur my Shell, Tiling Shell, `--status`).
- **`gsconnect.sh`**: Native GSConnect integration (KDE Connect protocol for GNOME without KDE/Qt dependencies) and Firewalld rules (1714-1764 TCP/UDP, `--status`, `--setup-firewall`, `--daemon`).
- **`soplos-tuning.sh`**: Kernel tuning (`sysctl` inotify 1M, max_map_count 16M, TCP BBR, ZRAM), system limits (`limits.d`), GNOME Tracker Miner exclusions on code directories (`~/Workspace`, `node_modules`, `.git`, `.venv`, `.cargo`), and ZRAM compression (`--status`, `--sysctl`, `--limits`, `--tracker`, `--zram`).
- **`cockpit.sh`**: Web management console and modular dashboard (Podman, KVM VMs, storage, Firewalld exclusive, `--status`, `--open`, `--start`, `--stop`, `--disable`).
- **`fastfetch.sh`**: System summary with theme support (Soplos Linux Boro official Ruby theme, FastCat `compact`, `--status`, `--theme`, `--diff`, `--force`).
- **`fonts.sh`**: Automated installer and diagnostics for developer fonts (JetBrainsMono, FiraCode, CascadiaCode, Meslo, and Hack Nerd Fonts, `--status`, `--list`, `--clean`).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with 75% opacity, blur 32, Catppuccin Mocha theme, global Ctrl+Alt+T shortcut, and Nautilus integration (`--status`).
- **`ptyxis.sh`**: Modern transparent Ptyxis terminal.
- **`seguridad.sh`**: Hardening with exclusive Firewalld (mandatory UFW disable and mask, services for `kdeconnect`/GSConnect, `mdns`, `ssh`, trusted zones for `podman+`, virbr0, and unprivileged port sysctl).
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`) and modular shell syncing.
- **`starship.sh` & `starship.toml`**: Modern Starship prompt with modular configuration (`--enable`, `--disable`, `--status`).
- **`multimedia.sh`**: Codecs (FFmpeg, libavcodec-extra, complete GStreamer with VA-API) and decoupled VLC via Flatpak (`--status`).
- **`flatpak.sh`**: Decoupled desktop apps suite via Flatpak/Flathub (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Shotcut, Spotify, Vesktop...) keeping the base system pristine (`--status`, `--all`, `--essential`, `--multimedia`, `--clean`, `--update`).
- **`chrome.sh`**: Official Google Chrome APT repository and `google-chrome-stable` with Ozone Wayland flags (`--status`, `--wayland`).
- **`firefox.sh`**: Native Firefox (.deb) from the official Mozilla repository with APT Pin-Priority 900 (`--status`).
- **`steam.sh`**: Native Steam setup with i386 multiarch, `contrib non-free` repositories, GameMode, MangoHud, Proton-GE, and 32-bit Mesa Vulkan drivers (`--status`).
- **`amd64v3.sh`**: CPU microarchitecture compatibility verification and transparent glibc-hwcaps diagnostics for Soplos Linux Boro (`--status`).

### 📦 [ProgrammingLanguages](./ProgrammingLanguages/)
Runtime managers and isolated environments:
- **`mise.sh`**: Modern polyglot runtime manager (`mise`).
- **`python.sh`**: System native Python 3 verification and `uv` manager via Mise with `UV_LINK_MODE=copy` for isolated per-project workflows without breaking APT or GNOME dependencies.
- **`python-uv-init.sh`**: Interactive standalone Python project initializer.
- **`nodejs.sh`**: Node.js LTS, pnpm, and JavaScript toolchain.
- **`rust.sh`**: Rustup stable toolchain, cargo, and Mold linker.
- **`java.sh`**: OpenJDK LTS with canonical `JAVA_HOME` resolution.
- **`dotnet.sh` & `angular.sh`**: .NET SDK and Angular CLI.

### 💻 [IDE](./IDE/)
Developer tooling:
- **`git.sh`**: Installation, optimization, and setup for Git, Delta, Lazygit, and GitHub CLI.
- **`antigravity.sh`**: Google Antigravity Desktop 2.0 suite (installer and updater).
- **`antigravity-cli.sh`**: Official Google Antigravity CLI.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine.
- **`opencode.sh`**: OpenCode AI CLI / Editor.

---

## ⚡ Automation via Justfile

The repository root includes a **`justfile`** with declarative recipes:

```bash
# Full automated environment setup
just setup-all

# AMD Ryzen laptop profile
just setup-laptop-amd

# Component health checks
just tuning-status
just security-status
just podman-status
just virtualization-status
just flatpak-status
just fastfetch
```

---

## 🔒 Monorepo Standards

* **Firewalld Only:** All ports and rules are managed exclusively via `firewall-cmd`. The `ufw` service is permanently disabled and masked.
* **Pure Wayland:** No legacy X11 utilities (`xclip`, `xrandr`, `xdotool`).
* **Protected System Python:** Never register global shims in Mise for Python. Use `uv` on a per-project basis.
* **Rootless Podman:** Containers run rootless in user space managed by systemd Quadlets.
