---
sidebar_position: 2
---

# System Configuration on CachyOS Workstation

This guide details the base setup, terminal optimizations, essential tooling, multimedia capabilities, and desktop customization applied to a **CachyOS Workstation** system (powered by **x86-64-v3** architecture, BORE / sched-ext kernel, and **Pacman / Paru** package management) running **GNOME Shell (Wayland / Dark Mode)**.

All configurations are automated through scripts located in the `Setup` directory.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by optimizing mirrors, installing essential packages, and configuring hardware acceleration. The script auto-detects CPU vendor (AMD Ryzen vs Intel Core):

1. **CPU Auto-Detection**:
   ```bash
   CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
   ```
   - `AuthenticAMD` → Executes `post-install-amd.sh`
   - `GenuineIntel` → Executes `post-install-intel.sh`

2. **Mirror & Pacman Optimization**:
   - Mirror ranking via `cachyos-rate-mirrors`.
   - Parallel downloads and color enabled in `/etc/pacman.conf`.

3. **Essential Software**:
   Installs developer tools, system monitoring, and utilities:
   - Build tools: `base-devel`, `cmake`
   - System monitoring: `btop`, `htop`, `inxi`
   - File utilities: `curl`, `fuse3`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`
   - Desktop tools: `vlc`, `gimp`, `gparted`
   - Universal packages: `flatpak` (with Flathub enabled)

4. **Multimedia Codecs & Hardware Acceleration**:
   ```bash
   # AMD (Radeon Graphics / Vega 8)
   sudo pacman -S --needed mesa libva-mesa-driver vulkan-radeon libva-utils vdpauinfo
   # Intel
   sudo pacman -S --needed intel-media-driver vulkan-intel libva-utils
   ```

5. **ZRAM**: Configured via `zram-generator` with `zstd` algorithm at 50% RAM.

---

## 2. Terminal Environment & Shell (`shell.sh`, `starship.sh`, `fastfetch.sh`, `fonts.sh`)

Installs modern command-line tools, developer fonts, and manages Starship prompt and Fastfetch.

### Modern CLI Tools (`shell.sh`)
- `eza` (modern `ls` replacement)
- `bat` (syntax-highlighting `cat`)
- `fzf` (fuzzy finder)
- `zoxide` (smart `cd`)
- `ripgrep` (`rg`, fast text search)
- `fd` (fast file search)
- `btop` and `jq`

---

## 3. Modern Terminals (`kitty.sh`, `ghostty.sh`, `ptyxis.sh`)

Deploys three GPU-accelerated terminal options integrated with GNOME Shell and Nautilus:
- **Kitty**: GPU-accelerated, 75% opacity, blur 32, Catppuccin Mocha.
- **Ghostty**: Native Wayland performance with GTK4 / Libadwaita rendering.
- **Ptyxis**: GNOME container-oriented terminal for Podman with palette tabs.

---

## 4. System & GNOME Tuning (`laptop-setup.sh`, `gnome-settings.sh`, `apariencia.sh`)

- **AMD Laptop**: Sets `power-profiles-daemon`, battery telemetry in Wh, AMD P-State EPP, and docked lid behavior without accidental suspension.
- **GNOME Settings**: Dark mode default, 24-hour clock, Mutter VRR, Wayland window optimizations, and Nautilus Python extensions via `python-nautilus`.
- **Appearance**: `adw-gtk3-dark` theme, `Papirus-Dark` icons, and `Bibata-Modern-Classic` cursors.

---

## 5. Cockpit Web Console (`cockpit.sh`)

Installs Cockpit for web-based system management:

```bash
sudo pacman -S --needed --noconfirm cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```

Access: [https://localhost:9090](https://localhost:9090)

---

## 6. Multimedia Support & yt-dlp (`yt-dlp-setup.sh`)

Configures video downloading and digital audio extraction tools:

```bash
sudo pacman -S --needed --noconfirm yt-dlp ffmpeg atomicparsley aria2 python-mutagen
```

Includes Deno JS runtime via `mise` for uninterrupted stream extraction.

---

## 7. GNOME Shell Extensions (`gnome-extensions.sh`)

Installs and manages GNOME Shell extensions:
- `extension-manager`: Native graphical app to discover and manage extensions.
- Dash to Dock, AppIndicator, Caffeine, Blur my Shell, Tiling Shell, and GSConnect.

---

## 8. Full Multimedia (`multimedia.sh`)

CachyOS provides complete multimedia packages without artificial patent/license restrictions:
- Full FFmpeg with VA-API hardware acceleration and commercial codecs.
- GStreamer complete plugin stack (base, good, bad, ugly).
- Video thumbnails for Nautilus via `ffmpegthumbnailer`.
- Wayland native media players (Showtime, Celluloid, VLC, MPV).

---

## 9. Google Chrome Browser (`chrome.sh`)

Deploys native, precompiled Google Chrome from **Chaotic-AUR** with Wayland hardware acceleration flags:
- Direct installation via `pacman` (from precompiled `[chaotic-aur]` repository) or `paru`, with Flatpak fallback.
- Flags configured in `~/.config/chrome-flags.conf` (`--ozone-platform-hint=auto`, `--enable-features=VaapiVideoDecodeLinuxGL`).

---

## 10. Steam & Gaming (`steam.sh`)

Prepares the system for native gaming and Proton/Wine compatibility:
- 32-bit multilib drivers enabled (`lib32-vulkan-radeon`, `lib32-mesa`, `lib32-pipewire`).
- Execution packages: `steam`, `gamemode`, `mangohud`.
- Proton-GE compatibility layer via Flathub.

---

## 11. Decoupled Flatpak Catalog (`flatpak.sh`)

Manages sandboxed user-space applications without polluting system dependencies:
- Official system-wide Flathub remote.
- Modular profiles: Flatseal, Podman Desktop, Warehouse, VLC, OBS Studio, LocalSend, etc.
- Commands: `--status`, `--update`, `--clean`, `--all`, `--core`, `--multimedia`.

---

## Verification

To verify that core components were installed and configured:
- **Terminal & Utilities**: Open a new terminal. You should see the **Starship** prompt and **Fastfetch** banner. Test `eza` and `bat --version`.
- **GNOME Extensions**: Run `./Setup/gnome-extensions.sh --status`.
- **Cockpit**: Open [https://localhost:9090](https://localhost:9090) in your browser.
- **Firewalld**: Verify with `sudo firewall-cmd --state`.
- **Hardware Acceleration**: Run `vainfo` to ensure VA-API on the Radeon Vega 8 is operational.
