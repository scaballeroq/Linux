---
sidebar_position: 2
---

# System Setup on Debian Testing (KDEDebian)

This guide details the base configuration process, workspace partition auto-mounting, native `x86_64-v3` kernel compilation, KDE Plasma 6 personalization, translucent Konsole terminal, and web administration panel applied to a **Debian Testing (Trixie)** system with **KDE Plasma 6**.

All configurations are automated through the scripts in the `Setup` directory.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the system by enabling official repositories, installing essential software, PipeWire audio, the complete KDE Plasma suite, and hardware graphics acceleration.

1. **System Update**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Enable Extra Repositories** (Contrib, Non-Free, Non-Free-Firmware):
   ```bash
   sudo apt install -y curl ca-certificates gnupg lsb-release
   # Debian Testing main repositories provide rolling and updated packages
   ```

3. **Essential Software & Utilities**:
   - Compilation: `build-essential`, `cmake`
   - Memory: `zram-tools` (ZRAM with ZSTD at 50%)
   - Monitoring: `btop`, `htop`, `inxi`, `plasma-systemmonitor`
   - Utilities: `curl`, `fuse3`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Graphics & Multimedia: `vlc`, `gimp`, `gparted`
   - KDE Suite & Apps: `kde-plasma-desktop`, `plasma-workspace`, `dolphin`, `konsole`, `ark`, `spectacle`, `gwenview`, `kate`, `kcalc`, `kdeconnect`
   - Universal Packages: `flatpak`, `plasma-discover`, `plasma-discover-backend-flatpak`

4. **Multimedia Codecs & HW Acceleration**:
   ```bash
   sudo apt install -y libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers vainfo
   ```

---

## 2. Workspace Partition Auto-Mounting (`mount-workspace.sh`)

Automatically mounts the `/home/caballero/Workspace` partition via `/etc/fstab` using its UUID.
Uses `defaults,noatime,nofail` to ensure safe, non-blocking boots.

```bash
just workspace
```

---

## 3. NATIVE x86_64-v3 Linux Kernel Compiler (`build-custom-kernel.sh`)

Downloads the latest official Linux Kernel release from `kernel.org`, building native `.deb` packages with `x86_64-v3` architecture optimizations, **1000Hz** timer frequency, and **Dynamic Preemption**.

```bash
just build-kernel
```

---

## 4. KDE Plasma 6 Customization & Widgets (`kde-settings.sh` & `kde-widgets.sh`)

Configures:
- **Night Color** set to 3500K.
- **24-hour clock** and battery percentage in tray.
- **Window title bar buttons**: minimize, maximize, close on the right.
- **Touchpad**: Tap-to-click, natural scrolling, and multi-touch gestures.
- **Klipper**: Advanced persistent clipboard manager.
- **KWin Effects**: Frosted blur and translucency at 60/120 FPS.

```bash
just kde
just widgets
```

---

## 5. Translucent Konsole Terminal & Dolphin Integration (`konsole.sh`)

Configures Konsole with an 85% opacity dark translucent profile with blur, JetBrainsMono Nerd Font, global shortcut `Ctrl + Alt + T`, and seamless Dolphin file manager terminal panel integration (`F4`).

```bash
just konsole
```

---

## 6. Shell & CLI Environment (`shell.sh`, `fastfetch.sh`, `fonts.sh`)

Installs modern command-line utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`), Nerd Fonts, and the Starship interactive prompt.

---

## 7. Cockpit Web Administration (`cockpit.sh`)

Deploys Cockpit at [https://localhost:9090](https://localhost:9090) with Podman container management, KVM virtual machines, and storage analytics.

---

## 8. Desktop Themes & Appearance (`apariencia.sh`)

Applies Breeze Dark, Papirus-Dark icon themes, and ensures Qt and GTK application visual consistency.

```bash
just apariencia
```
