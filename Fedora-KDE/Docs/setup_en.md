---
sidebar_position: 2
---

# System Setup on Fedora 44 Workstation (KDE Plasma 6)

This guide details base provisioning, hardware optimizations, Kitty terminal, Cockpit administration, and desktop appearance applied to a **Fedora 44** system running **KDE Plasma 6** on **Wayland**.

Configurations are automated via scripts located in the `Setup` directory.

---

## 1. Base Post-Installation (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepares the base operating system by configuring official Fedora and **RPM Fusion** (free & nonfree) repositories, essential developer packages, ZRAM memory compression, PipeWire audio, KDE Plasma 6 utilities, and processor-tailored GPU acceleration.

### Available Scripts:

- **Smart Dispatcher (`post-install.sh`)**:
  Automatically detects CPU vendor (`AuthenticAMD` vs `GenuineIntel`) or allows manual CLI flags:
  ```bash
  ./Setup/post-install.sh          # Smart auto-detection
  ./Setup/post-install.sh --amd    # Force AMD Ryzen mode
  ./Setup/post-install.sh --intel  # Force Intel Core mode
  ```

- **AMD Ryzen Profile (`post-install-amd.sh`)**:
  Tailored for AMD Ryzen processors and Radeon Graphics:
  - Microcode: `microcode_ctl`
  - GPU Firmware: `linux-firmware`
  - Graphics Stack: `mesa-dri-drivers`, `mesa-vulkan-drivers` (RADV), `mesa-va-drivers`, `radeontop`.
  ```bash
  just post-install-amd
  ```

- **Intel Core / Media Center Profile (`post-install-intel.sh`)**:
  Tailored for Intel Core desktop workstations (specifically 4th Gen Haswell i7-4790 with HD Graphics 4600) for media center and streaming duties (Kodi, Netflix, Prime Video):
  - Microcode: `microcode_ctl`
  - Video VA-API Acceleration: `libva-intel-driver` (`i965`), `intel-media-driver`, `intel-gpu-tools`.
  - Media & Streaming: `kodi`, `kodi-inputstream-adaptive`, `kodi-inputstream-rtmp`, `kodi-pvr-iptvsimple`, `ffmpeg`, `gstreamer1-plugins-*`.
  - **No KVM Virtualization**: Stripped of virtualization overhead and laptop battery daemons to keep the media workstation lean and responsive.
  ```bash
  just post-install-intel
  ```

### Common Installed Packages:
- **Compilation**: `@development-tools`, `cmake`, `gcc`, `gcc-c++`, `make`, `kernel-devel`, `kernel-headers`.
- **Memory**: `zram-generator` (ZRAM with ZSTD algorithm allocated to 50% RAM).
- **Audio**: `pipewire`, `pipewire-alsa`, `pipewire-pulseaudio`, `pipewire-jack-audio-connection-kit`, `wireplumber`.
- **Monitoring**: `btop`, `htop`, `inxi`, `plasma-systemmonitor`.
- **Utilities**: `curl`, `fuse3`, `exfatprogs`, `p7zip`, `p7zip-plugins`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`.
- **Graphics & Utilities**: `vlc`, `gimp`, `gparted`, `kate`, `ark`, `kcalc`, `spectacle`.
- **KDE Plasma 6 Suite**: `plasma-desktop`, `dolphin`, `konsole`, `kwriteconfig6`, `plasma-nm`, `plasma-pa`, `tuned-ppd`.
- **Universal Packages**: `flatpak`, `plasma-discover-flatpak` with active Flathub remote.

---

## 2. Laptop Optimization & Battery Management (`laptop-setup.sh`)

Configures essential features for developer laptops:
- **95% Brightness Persistence**: Systemd service (`persist-screen-brightness.service`) restoring display brightness to 95% at boot.
- **Power Management & Profiles**: Installs and activates `tuned` with `tuned-ppd` for native power profile switching (Power Save / Balanced / Performance) inside KDE Plasma battery widget.
- **Hybrid Graphics**: Activates `switcheroo-control` for dynamic GPU switching.
- **KDE Plasma 6 Touchpad**: Configures tap-to-click, natural scrolling, and idle suspension timeouts across `kcminputrc`, `touchpadrsrc`, and `powerdevilrc`.

```bash
just laptop
# or ./Setup/laptop-setup.sh
```

---

## 3. GPU-Accelerated Terminal (Kitty) (`kitty.sh`)

Installs and configures Kitty with GPU rendering, Tokyo Night / Catppuccin Mocha dark theme, 75% translucent background with soft blur (32), JetBrainsMono Nerd Font, and Powerline tab bar.

- **Commands & Flags**:
  ```bash
  just kitty
  # Custom opacity (e.g., 70%):
  ./Setup/kitty.sh --opacity 0.70
  # Interactive help:
  ./Setup/kitty.sh --help
  ```

- **Live Hotkeys in Kitty**:
  - `Ctrl+Alt+Up` / `Ctrl+Shift+F11`: Increase opacity (+5%).
  - `Ctrl+Alt+Down` / `Ctrl+Shift+F10`: Decrease opacity (-5%).
  - `Ctrl+Alt+0` / `Ctrl+Shift+F9`: Restore default opacity.
  - `Ctrl+Alt+1`: 100% opaque mode.
  - `Ctrl+Shift+F5`: Hot-reload configuration.
  - `Ctrl+Shift+T` / `Ctrl+Shift+Enter`: New tab or split pane preserving current directory.
- **KDE Plasma Integration**:
  - Dolphin context menu: Right-click -> *Open in Kitty*.
  - Global desktop shortcut: `Ctrl+Alt+T` opens Kitty instantly.

---

## 4. Advanced System Performance & Kernel Tuning (`fedora-tuning.sh`)

Applies deep optimizations across Kernel Sysctl, user file limits, Systemd, and KDE Plasma:

- **Kernel Sysctl (`/etc/sysctl.d/99-fedora-dev.conf`)**:
  - `fs.inotify.max_user_watches=524288` and `instances=1024` (massive inotify monitoring for IDEs and KDE).
  - `fs.file-max=2097152`.
  - `vm.max_map_count=16777216` (support for gaming, emulators, and in-memory databases).
  - `vm.swappiness=100` (optimized for Fedora ZRAM compression).
  - `vm.vfs_cache_pressure=50` (directory cache retention to accelerate `git status` and builds).
  - `net.core.default_qdisc=fq` and `net.ipv4.tcp_congestion_control=bbr` (low latency TCP).
- **User Limits (`/etc/security/limits.d/99-dev-limits.conf`)**:
  - `nofile`: soft 524288, hard 1048576.
  - `memlock`: `unlimited`.
- **Systemd Stop Timeouts (`/etc/systemd/system.conf.d/99-fast-shutdown.conf`)**:
  - `DefaultTimeoutStopSec=10s` preventing 90-second shutdown hangs.
- **KDE Baloo Indexer (`baloofilerc`)**:
  - Automatic exclusion of heavy project directories (`node_modules`, `.git`, `.venv`, `target`, `vendor`, `.cache`) avoiding CPU/disk spikes.
- **Containers**:
  - Verification and installation of `distrobox` and `podman`.

```bash
just tuning
# or ./Setup/fedora-tuning.sh

# Check current status:
./Setup/fedora-tuning.sh --status
```

---

## 5. HP LaserJet Pro M15w Setup (`hp-printer-setup.sh`)

Sets up HP LaserJet Pro M15w printer over USB or local network on Fedora 44:
- Installs CUPS, HPLIP, `plasma-print-manager`, and printing utilities.
- Enables `cups.service` and `cups.socket`.
- Adds user to `lp` group and reloads udev rules.
- Downloads and silently configures proprietary HP plugin (`hp-plugin -i -q`).

```bash
just printer
# or ./Setup/hp-printer-setup.sh
```

---

## 6. Shell & Terminal Environment (`shell.sh`, `fastfetch.sh`, `fonts.sh`)

- **Modern Utilities (`shell.sh`)**: Installs `eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd-find`, `duf`, `du-dust`, `procs`, `btop`, `jq`, and **Starship** prompt with `.bashrc` integration.
- **Developer Fonts (`fonts.sh`)**: Installs JetBrainsMono Nerd Font, FiraCode, and CascadiaCode in `~/.local/share/fonts`.
- **Fastfetch (`fastfetch.sh`)**: Displays clean hardware, kernel, and desktop information on terminal launch.

```bash
just shell
just fonts
just fastfetch
```

---

## 7. Cockpit Web Management Console (`cockpit.sh`)

Installs and manages Cockpit web console with on-demand socket activation (`cockpit.socket`) at [https://localhost:9090](https://localhost:9090):
- `cockpit-podman`: Container, pod, and image management.
- `cockpit-machines`: KVM/QEMU and Libvirt VM administration.
- `cockpit-storaged`: Disk partitioning and SMART health telemetry.
- `cockpit-networkmanager`: Network interface and connection monitoring.
- `cockpit-selinux`: Guided SELinux policy diagnosis.
- `cockpit-files`: Web-based file browser.

```bash
just cockpit
# Check status:
./Setup/cockpit.sh status
```

---

## 8. Desktop Appearance & Themes (`apariencia.sh`)

Manages global themes, Kvantum SVG theme engine (Qt5/Qt6), color schemes, and icon packs on KDE Plasma 6 ensuring consistent visual integration with GTK 3/4 applications and Flatpaks:
- Qt Widget Engine: **Kvantum** (with SVG themes like `KvFlatDark`, `KvMojaveDark`, `MateriaDark`) / **Breeze**
- Global Theme: **Breeze Dark** / **Breeze Light**
- Icons: **Papirus-Dark** / **Breeze-Dark**
- Cursors: `breeze_cursors`

```bash
just apariencia
# CLI Options:
./Setup/apariencia.sh --status              # Show active appearance configuration (KDE, Kvantum, GTK)
./Setup/apariencia.sh --list                # List installed themes, icons, and Kvantum themes
./Setup/apariencia.sh --dark                # Apply dark mode with Kvantum (KvFlatDark + Papirus-Dark)
./Setup/apariencia.sh --light               # Apply light mode with Kvantum (KvFlatLight + Papirus)
./Setup/apariencia.sh --kvantum-theme KvArcDark  # Apply a custom Kvantum theme
./Setup/apariencia.sh --breeze-widgets      # Restore native Breeze widgets (no Kvantum)
```

---

## 9. Plymouth Boot Splash (`plymouth-setup.sh`)

Installs and manages boot splash screens (Plymouth) on Fedora 44 + KDE Plasma with support for `breeze`, `bgrt`, and `spinner` themes, automatically updating initramfs via Dracut:

```bash
just plymouth
# CLI Options:
./Setup/plymouth-setup.sh --list     # List available themes
./Setup/plymouth-setup.sh --preview  # Preview boot splash
./Setup/plymouth-setup.sh --disable  # Disable visual splash (details)
./Setup/plymouth-setup.sh breeze     # Apply Breeze theme
```

---

## 10. YT-DLP Multimedia Stack (`yt-dlp-setup.sh`)

Automated setup for the complete video downloading and processing toolchain:
- Packages: `yt-dlp`, `ffmpeg`, `atomicparsley`, `aria2` multi-connection downloader, and `deno` JavaScript runtime.
- Configuration at `~/.config/yt-dlp/config`: SponsorBlock integration, subtitle extraction, smart naming, and metadata formatting.
- Command aliases configured in `Bash.Setup/yt-dlp_aliases.sh`.

```bash
just yt-dlp
# or ./Setup/yt-dlp-setup.sh
```
