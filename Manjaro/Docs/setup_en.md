---
sidebar_position: 2
---

# System Configuration in Manjaro Linux (Manjaro)

This guide details the base configuration, permanent workspace mounting, native `x86_64-v3` kernel compilation, GNOME personalization, Ptyxis and Kitty terminals, GNOME Shell extensions, and web admin panels applied to **Manjaro Linux** with the **GNOME** desktop environment.

---

## 1. Base Post-Installation (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepares the system by ranking the fastest mirrors (`pacman-mirrors`), installing essential utilities, ZRAM, PipeWire, GNOME suite, Flatpak, and hardware-accelerated graphics stacks tailored to the system CPU and GPU.

### Available Scripts:

- **Smart Dispatcher (`post-install.sh`)**:
  Automatically detects CPU vendor (`AuthenticAMD` vs `GenuineIntel`) or allows CLI flags:
  ```bash
  ./Setup/post-install.sh          # Auto-detection
  ./Setup/post-install.sh --amd    # Force AMD Ryzen profile
  ./Setup/post-install.sh --intel  # Force Intel Media Center profile
  ```

- **AMD Ryzen Profile (`post-install-amd.sh`)**:
  Optimized for AMD Ryzen laptops and desktops with Radeon Graphics:
  - Mirrors: `sudo pacman-mirrors --fasttrack 5`
  - Microcode: `amd-ucode`
  - GPU Firmware: `linux-firmware`
  - Graphics Stack: `mesa`, `lib32-mesa`, `vulkan-radeon`, `lib32-vulkan-radeon`, `libva-mesa-driver`, `radeontop`.
  - Package Managers: `pamac-cli`, `flatpak`, `libpamac-flatpak-plugin`.
  ```bash
  just post-install-amd
  ```

- **Intel Core / Media Center Profile (`post-install-intel.sh`)**:
  Optimized for Intel Core desktop PCs (Haswell i7-4790 / HD Graphics 4600) configured as a home media and streaming hub:
  - Microcode: `intel-ucode`
  - Hardware Video Acceleration: `intel-media-driver`, `libva-intel-driver`, `libva-utils`, `vulkan-intel`.
  - Media: `kodi` with native streaming addons (`inputstream-adaptive`, `inputstream-rtmp`, `pvr-iptvsimple`), `ffmpeg`.
  - Excludes heavy KVM virtualization and laptop battery optimizations.
  ```bash
  just post-install-intel
  ```

---

## 2. Permanent Workspace Mounting (`mount-workspace.sh`)

Permanently auto-mounts `/home/caballero/Workspace` in `/etc/fstab` using its partition UUID with `defaults,noatime,nofail` flags.

```bash
just workspace
```

---

## 3. Native Linux Kernel Compiler (`build-custom-kernel.sh`)

Fetches the latest official stable release from `kernel.org`, optimizes module selection via `localmodconfig`, compiles with `x86_64-v3` architecture flags, **1000Hz** timer frequency, and **Dynamic Preemption**, then automatically rebuilds initramfs (`mkinitcpio`) and updates GRUB.

```bash
just build-kernel
```

---

## 4. GNOME Extensions Installation (`gnome-extensions.sh`)

Installs `gnome-browser-connector`, `extension-manager`, and downloads 17 custom GNOME extensions while compiling GSettings schemas (`glib-compile-schemas`).

```bash
just extensions
```

---

## 5. Laptop Optimizations (`laptop-setup.sh`)

Configures `power-profiles-daemon`, `switcheroo-control`, `bluez`, `brightnessctl`, touchpad gestures, VRR, and efficient battery suspend.

```bash
just laptop
```

---

## 6. Fingerprint Authentication (`fingerprint-setup.sh`)

Sets up `fprintd` and PAM authentication for terminal `sudo`, GNOME `polkit-1` dialogs, and GDM screen unlocking.

```bash
just fingerprint
```

---

## 7. HP LaserJet Pro M15w USB Printer (`hp-printer-setup.sh`)

Configures CUPS, HPLIP, printing libraries, and assists with installing the proprietary plugin required for the LaserJet M15w series.

```bash
just printer
```

---

## 8. Plymouth Visual Boot Splash Screen (`plymouth-setup.sh`)

Enables and configures OEM UEFI BGRT or Manjaro Plymouth splash screens, updating `/etc/mkinitcpio.conf` and GRUB boot parameters.

```bash
just plymouth
```

---

## 9. Modern Terminal Emulators (Ptyxis & Kitty)

- **Ptyxis (`ptyxis.sh`)**: Native GNOME terminal with 85% opacity, `Ctrl+Alt+T` shortcut, and Nautilus context menu integration.
- **Kitty (`kitty.sh`)**: GPU-accelerated terminal with Catppuccin Mocha theme, blur, Nerd Fonts support, and dynamic opacity hotkeys.
