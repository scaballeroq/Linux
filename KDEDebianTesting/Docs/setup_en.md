---
sidebar_position: 2
---

# System Setup on Debian Testing (DebianTesting)

This guide details the base setup process, automatic workspace mount, custom `x86_64-v3` kernel compilation, GNOME desktop customization, Ptyxis terminal, GNOME Shell extensions, and Cockpit web administration panel on **Debian Testing (Trixie)** with **GNOME**.

Configurations are automated via scripts located in the `Setup` directory.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by enabling additional official repositories, installing essential packages, PipeWire audio, GNOME desktop suite, and hardware acceleration.

1. **System update**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Enable Extra Repositories** (Contrib, Non-Free, Non-Free-Firmware):
   ```bash
   sudo apt install -y curl ca-certificates gnupg lsb-release
   # On Debian Testing, main repositories provide the newest packages directly
   ```

3. **Essential Software and Utilities**:
   - Compilation: `build-essential`, `cmake`
   - Memory: `zram-tools` (ZRAM with ZSTD at 50%)
   - Monitoring: `btop`, `htop`, `inxi`, `gnome-system-monitor`
   - Utilities: `curl`, `fuse3`, `exfatprogs`, `p7zip-full`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Graphics & Multimedia: `vlc`, `gimp`, `gparted`, `evince`, `seahorse`
   - GNOME Environment: `gnome-core`, `gnome-shell`, `gnome-control-center`, `gnome-tweaks`, `ptyxis`, `nautilus`, `file-roller`, `gnome-text-editor`, `gnome-calculator`, `gnome-disk-utility`, `power-profiles-daemon`, `switcheroo-control`, `ffmpegthumbnailer`
   - Universal Packages: `flatpak`, `gnome-software`, `gnome-software-plugin-flatpak`

4. **Multimedia Codecs and HW Acceleration**:
   ```bash
   sudo apt install -y libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers vainfo vulkan-tools
   ```

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

## 4. Clean GNOME Extensions Installation (`gnome-extensions.sh`)

Installs `gnome-browser-connector`, `extension-manager`, and cleanly downloads/registers the 17 curated GNOME extensions with GSettings schema compilation (`glib-compile-schemas`). See [GNOME Extensions Guide](./gnome_extensions_en.md).

```bash
just extensions
```

---

## 5. GNOME Personalization via GSettings (`gnome-settings.sh`)

Configures:
- **Night Light** at 3500K.
- **24-hour clock** and battery percentage.
- **Window controls**: minimize, maximize, close on the right.
- **Touchpad**: Tap-to-click, natural scrolling, two-finger gestures.
- **Mutter**: Variable Refresh Rate (VRR) & fractional scaling.
- **Dark Mode**: Prefer dark theme.

```bash
just gnome
```

---

## 6. Ptyxis Modern Terminal & Nautilus Integration (`ptyxis.sh`)

Installs and configures Ptyxis with translucent dark styling (85% opacity), no scrollbar, global `Ctrl + Alt + T` shortcut, and Nautilus context menu integration via `nautilus-open-any-terminal`.

```bash
just ptyxis
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

Applies Papirus-Dark and Adwaita styling across GTK and Qt applications.

```bash
just apariencia
```
