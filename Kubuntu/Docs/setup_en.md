---
sidebar_position: 2
---

# System Configuration in Kubuntu (KDE Plasma)

This guide details the base setup, terminal optimization, essential tool installations, multimedia support, hardware integrations, and user environment customizations for Kubuntu (KDE Plasma 6 / 5).

All configurations are automated through scripts in the `Setup` directory.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the system by configuring additional official repositories, installing essential packages, and enabling hardware acceleration.

1. **System update**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Enable Extra Repositories** (Universe, Multiverse, and Restricted):
   ```bash
   sudo add-apt-repository -y universe
   sudo add-apt-repository -y multiverse
   sudo add-apt-repository -y restricted
   sudo apt update
   ```

3. **Essential Software**:
   - Compilation: `build-essential`, `cmake`
   - Monitoring: `btop`, `htop`, `inxi`
   - Utilities: `curl`, `fuse3`, `libfuse2t64`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Graphics & Multimedia: `vlc`, `gimp`, `gparted`
   - Universal Packages: `flatpak`, `plasma-discover-backend-flatpak`

4. **Multimedia Codecs and HW Acceleration**:
   ```bash
   sudo apt install -y kubuntu-restricted-extras libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers
   ```

---

## 2. KDE Plasma Customization (`kde-settings.sh` & `apariencia.sh`)

Applies recommended configuration for KDE Plasma 6 / 5 via CLI:
- **Night Color** set to 3500K.
- **Breeze Dark theme** and **Papirus** / **Breeze** icon themes.
- **Power Management**: Disables automatic suspend when connected to AC power.
- **Global Terminal Shortcut**: Meta + T for Konsole.

```bash
just kde
just apariencia
```

---

## 3. Terminal & Shell Environment (`shell.sh`, `fastfetch.sh`, `fonts.sh`)

Installs modern command line utilities, development typography, and the Starship prompt.

### Modern Terminal Tools
- `eza` (modern `ls` replacement)
- `bat` (enhanced `cat` with syntax highlighting)
- `fzf` (fuzzy finder)
- `zoxide` (smart `cd` directory jumper)
- `ripgrep` (`rg`, blazing fast text search)
- `fd-find` (`fd`, simple and fast file search)
- `tealdeer` (`tldr`, quick cheat sheets)
- `duf` (visual disk usage tables)
- `du-dust` (`dust`, graphical directory disk usage)
- `procs` (modern process viewer)

### Starship Prompt
Downloads and deploys the latest Starship prompt with custom configuration in `~/.config/starship.toml`.

### Nerd Fonts
Installs top developer typefaces (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo`, `Hack`).

### Fastfetch
Displays aesthetic system details upon opening the terminal.

---

## 4. Hardware and System Utilities

### Native Firefox (.deb) (`firefox.sh`)
Installs the official Mozilla APT repository version with APT Pinning (Pin-Priority 900) and removes the Snap package for optimal performance:
```bash
just firefox
```

### Laptop Optimization (`laptop-setup.sh`)
Enables battery savings (`power-profiles-daemon`), bluetooth, hybrid graphics, and touchpad gestures:
```bash
just laptop
```

### Fingerprint Authentication (`fingerprint-setup.sh`)
Configures `fprintd`, PAM for `sudo`, `polkit-1`, and SDDM lockscreen:
```bash
just fingerprint
```

### HP LaserJet Pro M15w Printer (`hp-printer-setup.sh`)
Configures CUPS, HPLIP drivers, and proprietary HP plugin:
```bash
just printer
```

### Workspace Automount (`mount-workspace.sh`)
Configures permanent automounting of `/home/caballero/Workspace` partition in `/etc/fstab`.

---

## 5. Web Management Cockpit (`cockpit.sh`)

Installs Cockpit with support for storage, network, KVM virtual machines (`cockpit-machines`), and containers (`cockpit-podman`):
```bash
just cockpit
```
Access locally at [https://localhost:9090](https://localhost:9090).

---

## 6. Multimedia and yt-dlp (`yt-dlp-setup.sh`)

Installs `yt-dlp`, `ffmpeg`, and configures the JS engine (Deno) via `mise`.

---

## Verification

- **Terminal**: Open a new Konsole window to see **Starship** and **Fastfetch**.
- **KDE Plasma**: Confirm Breeze Dark and Night Color in System Settings.
- **Cockpit**: Open [https://localhost:9090](https://localhost:9090).
