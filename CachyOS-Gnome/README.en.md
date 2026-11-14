# 🔧 CachyOS Workstation Environment Configuration (GNOME Shell Wayland)

This repository contains an organized, modular, and automated collection of configuration scripts for **CachyOS Linux** systems (optimized **x86-64-v3** architecture with BORE / sched-ext kernel) running the **GNOME Shell (Wayland / Mutter)** desktop environment, **Pacman / Paru** package managers, official CachyOS performance repositories, and hardware optimizations for **HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)** workstations in dark mode.

---

## 📂 Repository Organization

### 🐚 [Bash.Setup](./Bash.Setup/)
Terminal configuration core, optimized for **Zsh as the primary shell** (modular support via `~/.zshrc.d`) and dual compatibility with **Bash** (via `~/.bashrc.d`):
- **`aliases.sh`**: Productivity aliases, dynamic shell reload, Nautilus, Git, Firewalld (`fw*`), Libvirt, Podman, and **Pacman / Paru** shortcuts (`update`, `upgrade`, `install`, `remove`, `pacup`, `pacin`, `pacrem`, `mirrors`).
- **`environment.sh`**: Global variables (`EDITOR`, `PATH`, Wayland/GNOME, `QT_QPA_PLATFORMTHEME="gnome"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) and Mise initialization.
- **`functions.sh`**: Advanced shell helper functions (`mkcd`, `up`, `hg`) and media processing utilities.
- **`gnome_settings.sh`**: Environment settings and keybindings for GNOME Wayland (dark theme `adw-gtk3-dark`, Night Light 4000K, Wayland capture with `grim`/`slurp`/`satty`, Nautilus).
- **`history.sh`**: Optimized shell history (deduplication, instant sync, timestamps).
- **`options.sh`**: Advanced shell options (`autocd`, typo correction, case-insensitive completion).
- **`podman-functions.sh`**: Rootless Podman and Quadlet helper functions.
- **`rclone_aliases.sh`**: Cloud storage synchronization shortcuts (Google Drive / OneDrive).
- **`yt-dlp_aliases.sh`**: Media download helpers.

### 🐳 [Podman](./Podman/)
Rootless container ecosystem with native systemd Quadlets:
- **`install/podman-install.sh`**: Rootless Podman installation, socket, linger, registries, and `passt` network backend (`--status`).
- **`install/quadlets-setup.sh`**: Directory structure and systemd Quadlet setup (`--status`).
- **`lib/podman-utils.sh`**: Project management CLI (`create`, `start`, `stop`, `restart`, `logs`, `status`, `destroy`, `doctor`).

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: KVM/QEMU, modular Libvirt, `virt-manager`, `virtio-win`, Btrfs NoCoW, and Firewalld configuration for CachyOS (`--status`).
- **`notas_virtualizacion_cachyos.md`**: In-depth virtualization notes for KVM, VirtIO, bridge networking, and storage on CachyOS.

### ⚙️ [Setup](./Setup/)
Operating system setup, GNOME Shell personalization, and hardening:
- **`post-install.sh`**: Intelligent dispatcher with CPU auto-detection (AMD Ryzen vs Intel Core, `--status`).
- **`post-install-amd.sh`**: Post-installation optimized for AMD Ryzen & Radeon (AMD microcode, RADV Vulkan `vulkan-radeon`, `libva-mesa-driver`, full FFmpeg, ZRAM zstd, Flathub, CachyOS v3 repos, `--status`).
- **`post-install-intel.sh`**: Post-installation optimized for Intel Core / Media Center (Intel VA-API, full FFmpeg, PipeWire, `--status`).
- **`zram-setup.sh`**: Dedicated compressed RAM swap configurator via `zram-generator` (`zstd`, 50% RAM, priority 100, `vm.page-cluster=0`, `--status`, `--disable`).
- **`cachyos-tuning.sh`**: Kernel tuning (`sysctl` inotify 1M, `max_map_count` 16M, TCP BBR), resource limits (`limits.d`), Systemd fast shutdown timeouts, and BORE/sched-ext optimizations (`--status`).
- **`laptop-setup.sh`**: Laptop optimizations (`power-profiles-daemon`, battery Wh health telemetry, AMD P-State EPP, DRM multi-monitor topology `DP-3`/`DP-4`/`eDP-1`, docked lid behavior with safe `systemctl reload systemd-logind`, Touchpad Wayland gestures, and Bluetooth `FastConnectable=true`, `--status`).
- **`apariencia.sh`**: Modular and interactive (`--interactive`) GTK theme (`adw-gtk3-dark`), icon (`Papirus-Dark`), and cursor (`Bibata-Modern-Classic`) manager (`--status`).
- **`gnome-settings.sh`**: Comprehensive and interactive (`--interactive`) GNOME Shell Wayland configurator (dark mode, terminal selector `kitty`/`ghostty`/`ptyxis`/`gnome-terminal`, window buttons, Mutter VRR, Night Light 4000K, 24h clock, and Nautilus Python extensions via `python-nautilus`, `--status`).
- **`gnome-extensions.sh`**: Extension manager and installer (GSConnect, Dash to Dock, AppIndicator, Blur my Shell, Tiling Shell, `--status`).
- **`gsconnect.sh`**: Mobile integration with GSConnect and automatic Firewalld rules (`--status`).
- **`fingerprint-setup.sh`**: Biometric fingerprint authentication setup (`fprintd` + PAM on CachyOS/Arch, `--status`).
- **`hp-printer-setup.sh`**: HP printer installer and manager (CUPS, HPLIP, proprietary plugin, Firewalld, `--status`).
- **`kitty.sh`**: GPU-accelerated Kitty terminal with 75% opacity, blur 32, Catppuccin Mocha theme, and top-level Nautilus context menu (`python-nautilus`, `--status`).
- **`ghostty.sh`**: Ghostty terminal with Catppuccin Mocha theme, 85% opacity, and top-level Nautilus context menu (`--status`, `--default-terminal`).
- **`ptyxis.sh`**: Native container-aware Ptyxis terminal with Catppuccin Mocha palette, 85% opacity, and top-level Nautilus context menu (`--status`, `--default-terminal`).
- **`zsh-setup.sh`**: Full Zsh replication (`zsh-autosuggestions`, `zsh-syntax-highlighting`, FZF, Zoxide, Mise, Starship, and modular `~/.zshrc.d/*.zsh`, `--status`, `--default-shell`).
- **`shell.sh`**: Modern terminal utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `btop`, `jq`, `--status`).
- **`starship.sh` & `starship.toml`**: Modern Starship prompt with CachyOS theme (`--status`).
- **`fastfetch.sh` & `config-*.jsonc`**: Aesthetic system summary with theme selector (`cachyos` Hero, `modern`, `compact`, `--menu`, `--preview`, `--status`).
- **`fonts.sh`**: Automated developer fonts installation (JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack Nerd Fonts, `--status`).
- **`seguridad.sh`**: System hardening with Firewalld (`ufw` permanently masked, active zone configuration, GSConnect, Podman in `trusted`, Libvirt `virbr0`, `--dev-ports` flag, `--status`).
- **`cockpit.sh`**: Cockpit web management console for Podman, KVM VMs, storage, and networking (`--status`).
- **`multimedia.sh`**: Full hardware multimedia acceleration (VA-API `libva-mesa-driver`, full FFmpeg, GStreamer, Nautilus video thumbnails, and native Wayland players, `--status`).
- **`yt-dlp-setup.sh`**: Optimized multimedia download dependencies (`yt-dlp`, FFmpeg, AtomicParsley, Deno JS runtime, `--status`).
- **`flatpak.sh`**: Decoupled Flathub application catalog with Wayland/GTK overrides (`--status`, `--all`).
- **`chrome.sh`**: Precompiled Google Chrome from **Chaotic-AUR** via Pacman/Paru with Wayland Ozone flags and VA-API acceleration (`--status`).
- **`firefox.sh`**: Native Mozilla Firefox on Wayland with VA-API enterprise policies (`/etc/firefox/policies/policies.json`, `--status`).
- **`steam.sh`**: Native Steam gaming setup with 32-bit multilib libraries, GameMode, MangoHud, and Proton-GE (`--status`).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop 2.0 setup (`--status`).
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`) setup (`--status`).
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine setup (`--status`).
- **`git.sh`**: Git, Delta, Lazygit, and GitHub CLI (`gh`) setup (`--status`).
- **`opencode.sh`**: OpenCode AI CLI setup (`--status`).

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Modern runtime management via **Mise** and Python project isolation via **uv**:
- **`mise.sh`**: Mise version manager with `environment.d` and shell integration (`--status`).
- **`python.sh`** & **`python-uv-init.sh`**: System Python verification and `uv` project isolation (`UV_LINK_MODE=copy`) complying with PEP 668.
- **`angular.sh`**, **`dotnet.sh`**, **`java.sh`**, **`nodejs.sh`**, **`rust.sh`**

---

## 🚀 Quick Deployment with Justfile

```bash
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/install/*.sh Podman/lib/*.sh

# Full Workstation Setup for AMD Ryzen & GNOME Wayland:
just setup-laptop-amd

# Default full installation:
just setup-all

# CachyOS mirror speed optimization:
just rate-mirrors

# Run full multi-subsystem status diagnosis:
just status
```

---

## 🔒 Monorepo Rules on CachyOS Workstation

* **Pacman + Paru Mandatory:** Scripts use native `pacman` and `paru` with idempotence checks (`pacman -T`), leveraging x86-64-v3 packages.
* **Firewalld Mandatory:** All network ports are managed via `firewall-cmd`. `ufw` is masked and disabled.
* **Native Wayland:** No legacy X11 utilities (`xclip`, `xrandr`, `xdotool`).
* **Protected System Python:** Exclusive use of `uv` per-project virtual environments respecting PEP 668.
* **Rootless Podman:** Unprivileged containers orchestrated with native systemd Quadlets.
