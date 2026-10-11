---
sidebar_position: 2
---

# Fedora 44 Workstation System Configuration

This guide details the base system setup, terminal optimization, essential software installation, multimedia support, and desktop user environment customization applied to a **Fedora 44 Workstation** system (powered by DNF5 package management) with **GNOME** (Dark Mode).

These settings are automated through the scripts located in the `Setup` folder.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by optimizing repositories, installing essential software, and setting up hardware acceleration. The script auto-detects the CPU (AMD Ryzen vs Intel Core) and runs the corresponding configuration.

1. **CPU Auto-Detection**:
   ```bash
   CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
   ```
   - `AuthenticAMD` → Runs `post-install-amd.sh`
   - `GenuineIntel` → Runs `post-install-intel.sh`

2. **DNF5 Optimization**:
   - `max_parallel_downloads=10`
   - `fastestmirror=True`
   - `clean_requirements_on_remove=True`

3. **Essential Software**:
   - Compilation: `@development-tools`, `cmake`, `gcc-c++`
   - Monitoring: `btop`, `htop`, `inxi`
   - Utilities: `curl`, `fuse`, `fuse3`, `exfatprogs`, `p7zip`, `p7zip-plugins`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`
   - Graphics & Multimedia: `vlc`, `gimp`, `gparted`
   - Universal Packages: `flatpak` (with Flathub remote enabled)

4. **Multimedia Codecs and HW Acceleration**:
   ```bash
   # AMD
   sudo dnf5 install -y mesa-va-drivers mesa-vdpau-drivers vulkan-loader mesa-vulkan-drivers
   # Intel
   sudo dnf5 install -y libva-intel-driver intel-media-driver libvdpau-va-gl vulkan-loader mesa-vulkan-drivers
   ```

5. **ZRAM**: Configured with ZSTD algorithm natively in Fedora.

---

## 2. Terminal and Shell Environment (`shell.sh`, `starship.sh`, `fastfetch.sh`, and `fonts.sh`)

Installs modern console utilities, development fonts, and provides an optional manager for the Starship prompt.

### Modern Terminal Utilities (`shell.sh`)
Modern alternatives to classic commands are installed with modular integration for Bash (by default) and Zsh (if `~/.zshrc` exists) along with `zoxide`:
- `eza` (replaces `ls`)
- `bat` (replaces `cat` with syntax highlighting)
- `fzf` (fuzzy finder)
- `zoxide` (smart replacement for `cd`)
- `ripgrep` (`rg`, fast text search)
- `fd` (simple replacement for `find`)
- `duf` (visual replacement for `df`)
- `dust` (disk space visualizer)
- `procs` (modern replacement for `ps`)
- `btop` (resource monitor)

### Optional Starship Prompt (`starship.sh`)
Easily enable or disable the **Starship** prompt in Bash (and Zsh if `~/.zshrc` exists):
```bash
# Install and enable Starship
./Setup/starship.sh

# Disable and restore native prompt
./Setup/starship.sh --disable

# Check current status
./Setup/starship.sh --status
```
Configuration is copied from `Setup/starship.toml` to `~/.config/starship.toml`.

### Development Fonts (Nerd Fonts)
Downloads and installs fonts optimized for programming and terminal symbols (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo`, and `Hack`):
```bash
fc-cache -f
```

### Fastfetch
Displays system information visually upon terminal startup. Installs `fastfetch` and copies `config.jsonc` to `~/.config/fastfetch/config.jsonc`.

---

## 3. Kitty Terminal (`kitty.sh`)

Installs and optimizes **Kitty**, a modern GPU-accelerated terminal emulator, with GNOME and Nautilus integration.

1. **Installation**:
   ```bash
   sudo dnf5 install -y kitty
   ```

2. **Aesthetic Configuration**:
   - 75% opacity with blur (32)
   - Catppuccin Mocha / Tokyo Night color scheme
   - JetBrainsMono Nerd Font
   - Powerline tab bar style

3. **GNOME Integration**:
   - Default terminal for GNOME (`org.gnome.desktop.default-applications.terminal`)
   - Global shortcut Ctrl+Alt+T
   - Nautilus context script: Scripts -> "Abrir en Kitty"

4. **Keyboard Shortcuts**:
   - `Ctrl+Alt+Up/Down`: Adjust opacity
   - `Ctrl+Shift+F5`: Reload configuration
   - `Ctrl+Shift+T`: New tab in same directory

---

## 4. Security (`seguridad.sh`)

System hardening with exclusive Firewalld, DNS-over-TLS, and Podman/KVM support.

- **Firewalld**: Default `home` zone with mdns, ssh (`trusted` for Podman, `libvirt` for virbr0; UFW removed)
- **DNS-over-TLS**: Opportunistic with systemd-resolved
- **Kernel hardening**: dmesg_restrict, kptr_restrict, syncookies
- **Podman rootless**: user namespaces and unprivileged ports (>=80) enabled

---

## 5. Web Administration Panel Cockpit (`cockpit.sh`)

Installs Cockpit for system administration via a web interface.

```bash
sudo dnf5 install -y cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```

Access: [https://localhost:9090](https://localhost:9090)

---

## 6. Multimedia Support and yt-dlp (`yt-dlp-setup.sh`)

Configures tools for video downloads and digital audio processing.

1. **yt-dlp and FFMPEG Installation**:
   ```bash
   sudo dnf5 install -y yt-dlp ffmpeg
   ```

2. **Fast JS Decryption Engine**:
   Installs Deno via `mise` for `yt-dlp` to process streaming platform JavaScript logic.

---

## 7. GNOME Shell Extensions (`gnome-extensions.sh`)

Installs and manages official extensions directly from Fedora 44 Workstation repositories (`dnf5`):

1. **Included Tools and Extensions**:
   - `extension-manager`: Native GTK application to browse, install, and manage GNOME Shell extensions.
   - `gnome-shell-extension-dash-to-dock`: Visible dock outside the overview with autohide.
   - `gnome-shell-extension-appindicator`: System tray / AppIndicator support.
   - `gnome-shell-extension-caffeine`: Quick toggle to inhibit auto-suspend and screensaver from the top bar.
   - `gnome-shell-extension-weather-oclock`: Integrated weather conditions displayed next to the top-bar clock.
   - `gnome-shell-extension-bing-wallpaper`: Daily Bing dynamic desktop wallpapers.
   - `gnome-shell-extension-blur-my-shell`: Modern blur effect for top bar, menus, and overview.
   - `gnome-shell-extension-logo-menu`: Quick access menu with distribution logo (integrated with Extension Manager).

2. **Script Usage**:
   ```bash
   # Install and enable all extensions
   ./Setup/gnome-extensions.sh

   # Check extension status
   ./Setup/gnome-extensions.sh --status

   # Batch enable or disable
   ./Setup/gnome-extensions.sh --enable
   ./Setup/gnome-extensions.sh --disable
   ```

---

## 8. Full Multimedia Stack & RPM Fusion (`multimedia.sh`)

Configures all proprietary **RPM Fusion** repositories (Free, Nonfree, and Tainted) and swaps out Fedora's constrained FFmpeg with full unrestricted FFmpeg and hardware codecs:

1. **Enabled Repositories**:
   - `rpmfusion-free-release` and `rpmfusion-nonfree-release`
   - `rpmfusion-free-release-tainted` and `rpmfusion-nonfree-release-tainted`
   - Cisco OpenH264 repository

2. **Codecs & Hardware Acceleration Stack**:
   - **Full FFmpeg**: `dnf5 swap -y ffmpeg-free ffmpeg --allowerasing`
   - **GStreamer**: `gstreamer1-plugins-bad-freeworld`, `gstreamer1-plugins-ugly`, `gstreamer1-libav`, `gstreamer1-vaapi`
   - **Freeworld VA-API / VDPAU drivers**: `mesa-va-drivers-freeworld`, `mesa-vdpau-drivers-freeworld`
   - **Proprietary formats**: `libdvdcss`, `lame`, `faac`, `faad2`, `x264`, `x265`, `libde265`

3. **Usage**:
   ```bash
   ./Setup/multimedia.sh          # Full install and FFmpeg swap
   ./Setup/multimedia.sh --status # Check repos and installed codecs
   ```

---

## 9. Google Chrome Browser (`chrome.sh`)

Enables the official Google Chrome repository for Fedora and installs the native stable Google Chrome package:

1. **Repository Configuration**:
   - Downloads and imports the official Google public key (`RPM-GPG-KEY-google-chrome`).
   - Configures `/etc/yum.repos.d/google-chrome.repo`.

2. **Package Installation**:
   - Installs `google-chrome-stable`.

3. **Usage**:
   ```bash
   ./Setup/chrome.sh          # Setup repository and install browser
   ./Setup/chrome.sh --status # Verify repository and binary status
   ```

---

## 10. Steam & Gaming (`steam.sh`)

Prepares the system for native Linux gaming and Proton/Wine via Steam:

1. **Repositories and Components**:
   - `rpmfusion-nonfree-steam` repository enabled.
   - Runtime tooling: `steam`, `gamemode`, `mangohud`.
   - **32-bit Vulkan libraries**: `mesa-vulkan-drivers.i686` and `mesa-dri-drivers.i686` for 32-bit game compatibility.

2. **Usage**:
   ```bash
   ./Setup/steam.sh          # Install Steam and 32-bit drivers
   ./Setup/steam.sh --status # Check installation status
   ```

---

## Verification

- **Terminal and Utilities**: Open a new terminal. You should see the **Starship** prompt and **Fastfetch** summary. Test with `eza` or `bat --version`.
- **GNOME Extensions**: Run `./Setup/gnome-extensions.sh --status` or `gnome-extensions list --enabled`.
- **Kitty**: Run `kitty --version`. Should open with opacity and Catppuccin theme.
- **Cockpit**: Open browser and go to [https://localhost:9090](https://localhost:9090). Log in with system credentials.
- **Firewalld**: Verify with `sudo firewall-cmd --state`.
- **Multimedia & Codecs**: Run `./Setup/multimedia.sh --status` and test `ffmpeg -codecs | grep -E "hevc|h264"`.
- **Google Chrome**: Run `./Setup/chrome.sh --status` or `google-chrome --version`.
- **Steam**: Run `./Setup/steam.sh --status` or `steam`.

