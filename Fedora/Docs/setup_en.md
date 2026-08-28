---
sidebar_position: 2
---

# System Setup on Fedora 44 Workstation (FedoraTesting)

This guide details the base setup process, automatic workspace mount, custom `x86_64-v3` kernel compilation, Kitty terminal, and Cockpit web administration panel on **Fedora 44** with **KDE Plasma**.

Configurations are automated via scripts located in the `Setup` directory.

---

## 1. Base Post-Installation (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepares the base system by enabling additional official repositories (`contrib`, `non-free`, `non-free-firmware`), installing essential packages, ZRAM memory compression, PipeWire audio, GNOME suite, and tailored GPU/media acceleration.

### Available Scripts:

- **Smart Dispatcher (`post-install.sh`)**:
  Automatically detects CPU vendor (`AuthenticAMD` vs `GenuineIntel`) or allows CLI flags:
  ```bash
  ./Setup/post-install.sh          # Auto-detection
  ./Setup/post-install.sh --amd    # Force AMD mode
  ./Setup/post-install.sh --intel  # Force Intel mode
  ```

- **AMD Ryzen Profile (`post-install-amd.sh`)**:
  Tailored for AMD Ryzen CPUs and Radeon Graphics:
  - Microcode: `amd64-microcode`
  - GPU Firmware: `firmware-amd-graphics`
  - Graphics Stack: `mesa-va-drivers`, `mesa-vdpau-drivers`, `mesa-vulkan-drivers` (RADV), `radeontop`, `va-driver-all`.
  ```bash
  just post-install-amd
  ```

- **Intel Core / Media Center Profile (`post-install-intel.sh`)**:
  Tailored for Intel Core desktop PCs (specifically 4th Gen Haswell i7-4790 with Intel HD Graphics 4600) used as a media center for Kodi, Netflix, and Prime Video:
  - Microcode: `intel-microcode`
  - Video VA-API Acceleration: `i965-va-driver`, `i965-va-driver-shaders`, `intel-media-va-driver`, `intel-gpu-tools` (`intel_gpu_top`).
  - Media & Streaming: `kodi`, `kodi-inputstream-addnf5ive`, `kodi-inputstream-rtmp`, `kodi-pvr-iptvsimple`, codecs `ffmpeg`, `libavcodec-extra`, `gstreamer1.0-*`.
  - **No KVM Virtualization**: Stripped of virtualization overhead and ldnf5op battery daemon to keep the media workstation lean and snappy.
  ```bash
  just post-install-intel
  ```

### Common Installed Packages:
- **Compilation**: `build-essential`, `cmake`
- **Memory**: `zram-tools` (ZRAM with ZSTD at 50%)
- **Audio**: `pipewire`, `pipewire-alsa`, `pipewire-pulse`, `pipewire-jack`, `wireplumber`
- **Monitoring**: `btop`, `htop`, `inxi`, `gnome-system-monitor`
- **Utilities**: `curl`, `fuse3`, `exfatprogs`, `p7zip-full`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
- **Graphics & Multimedia**: `vlc`, `gimp`, `gparted`, `evince`, `seahorse`
- **GNOME Suite**: `gnome-core`, `gnome-shell`, `gnome-control-center`, `gnome-tweaks`, `nautilus`, `file-roller`, `gnome-text-editor`, `gnome-calculator`, `gnome-disk-utility`, `power-profiles-daemon`, `ffmpegthumbnailer`
- **Universal Packages**: `flatpak`, `gnome-software`, `gnome-software-plugin-flatpak` with Flathub repo.

---

## 2. Workspace Partition Auto-mount (`mount-workspace.sh`)

Automatically mounts the `/home/caballero/Workspace` data partition in `/etc/fstab` using UUID identification and safe `defaults,noatime,nofail` flags.

```bash
just workspace
```

---

## 3. Native x86_64-v3 Linux Kernel Builder (`build-custom-kernel.sh`)

Fetches the latest official stable release from `kernel.org`, applies `x86_64-v3` microarchitecture optimizations, **1000Hz** timer frequency, and dynamic preemption.

```bash
just build-kernel
```

---

---

## 4. Modern Terminal (Kitty)

### Kitty (`kitty.sh`)
Installs and configures GPU-accelerated Kitty terminal with Catppuccin Mocha / Tokyo Night dark theme, 85% background opacity with blur, JetBrainsMono Nerd Font typography, slanted powerline tab bar, and on-the-fly opacity adjustments (`Ctrl+Shift+A` + `M`/`L`/`1`).

```bash
just kitty
```

---

## 7. 3D Screensaver and Lock Screen (`screensaver-setup.sh`)

Installs XScreenSaver 3D/GL suite, registers the autostart daemon, and maps `Super + L` to lock the screen with active screensavers.

```bash
just screensaver
```

---

## 8. Shell Environment (`shell.sh`, `fastfetch.sh`, `fonts.sh`)

Installs modern terminal CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`), Nerd Fonts, and Starship prompt.

```bash
just shell
just fonts
just fastfetch
```

---

## 9. Cockpit Web Management (`cockpit.sh`)

Deploys Cockpit admin console with modules for Podman, KVM/QEMU VMs, and storage disks at [https://localhost:9090](https://localhost:9090).

```bash
just cockpit
```

---

## 10. Themes and Desktop Appearance (`apariencia.sh`)

Installs themes, color schemes, and icon packs (Breeze Dark, Papirus-Dark) and establishes unified visual consistency across KDE Plasma 6 (Qt6/Qt5), GTK 3/4 applications, and Flatpaks.

- **Apply full recommended dark theme**:
  ```bash
  just apariencia
  # or ./Setup/apariencia.sh
  ```
- **Show visual state and active themes**:
  ```bash
  ./Setup/apariencia.sh --status
  ```
- **List all installed global themes, color schemes, and icons**:
  ```bash
  ./Setup/apariencia.sh --list
  ```
- **Apply light theme**:
  ```bash
  ./Setup/apariencia.sh --light
  ```

---

## 11. Graphical Boot Splash (`plymouth-setup.sh`)

Installs, configures, and activates Plymouth boot splash with support for multiple official and modern themes (`bgrt`, `ceratopsian`, `spinner`, etc.), ensuring a smooth, flicker-free startup.

- **Install and activate default theme (BGRT / Ceratopsian)**:
  ```bash
  just plymouth
  # or ./Setup/plymouth-setup.sh
  ```
- **List all available themes**:
  ```bash
  ./Setup/plymouth-setup.sh --list
  ```
- **Activate a specific theme**:
  ```bash
  ./Setup/plymouth-setup.sh ceratopsian
  ```
- **Preview splash screen on desktop**:
  ```bash
  ./Setup/plymouth-setup.sh --preview
  ```

