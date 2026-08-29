---
sidebar_position: 2
---

# CachyOS System Configuration

This guide details the base system setup, terminal optimization, essential software installation, multimedia support, and desktop user environment customization applied to a **CachyOS** system (Arch Linux, optimized for x86-64-v3/v4) with **KDE Plasma 6**.

These settings are automated through the scripts located in the `Setup` folder.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by optimizing mirrors, installing essential software, and setting up hardware acceleration. The script auto-detects the CPU (AMD Ryzen vs Intel Core) and runs the corresponding configuration.

1. **CPU Auto-Detection**:
   ```bash
   CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
   ```
   - `AuthenticAMD` → Runs `post-install-amd.sh`
   - `GenuineIntel` → Runs `post-install-intel.sh`

2. **Pacman Optimization**:
   - ParallelDownloads = 10
   - Color enabled
   - Mirrors optimized with `cachyos-rate-mirrors`

3. **Essential Software**:
   - Compilation: `base-devel`, `cmake`
   - Monitoring: `btop`, `htop`, `inxi`
   - Utilities: `curl`, `fuse2`, `fuse3`, `exfatprogs`, `7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`
   - Graphics & Multimedia: `vlc`, `gimp`, `gparted`
   - Universal Packages: `flatpak`

4. **Multimedia Codecs and HW Acceleration**:
   ```bash
   # AMD
   sudo pacman -S --needed --noconfirm mesa libva-mesa-driver vulkan-radeon
   # Intel
   sudo pacman -S --needed --noconfirm mesa libva-intel-driver intel-media-driver vulkan-intel
   ```

5. **ZRAM**: Configured with ZSTD algorithm at 50% of RAM.

---

## 2. Terminal and Shell Environment (`shell.sh`, `fastfetch.sh`, and `fonts.sh`)

Installs modern console utilities, development fonts, and the Starship interactive prompt.

### Modern Terminal Utilities
Modern alternatives to classic commands are installed:
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

### Starship Prompt
Downloads and configures the latest version of the Starship prompt:
```bash
curl -sS https://starship.rs/install.sh | sudo sh -s -- -y -b /usr/local/bin
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

Installs and optimizes **Kitty**, a modern GPU-accelerated terminal emulator, with KDE Plasma and Dolphin integration.

1. **Installation**:
   ```bash
   sudo pacman -S --needed --noconfirm kitty
   ```

2. **Aesthetic Configuration**:
   - 75% opacity with blur (32)
   - Catppuccin Mocha color scheme
   - JetBrainsMono Nerd Font
   - Powerline tab bar style

3. **KDE Plasma Integration**:
   - Default terminal for KDE
   - Global shortcut Ctrl+Alt+T
   - Dolphin context menu: "Open in Kitty"

4. **Keyboard Shortcuts**:
   - `Ctrl+Alt+Up/Down`: Adjust opacity
   - `Ctrl+Shift+F5`: Reload configuration
   - `Ctrl+Shift+T`: New tab in same directory

---

## 4. Security (`seguridad.sh`)

System hardening with Firewalld, DNS-over-TLS, and MAC Randomization.

- **Firewalld**: FedoraWorkstation zone with kdeconnect, mdns, ssh
- **DNS-over-TLS**: Opportunistic with systemd-resolved
- **MAC Randomization**: Wi-Fi scan and connection
- **Kernel hardening**: dmesg_restrict, kptr_restrict, syncookies
- **Podman rootless**: user namespaces enabled

---

## 5. Web Administration Panel Cockpit (`cockpit.sh`)

Installs Cockpit for system administration via a web interface.

```bash
sudo pacman -S --needed --noconfirm cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```

Access: [https://localhost:9090](https://localhost:9090)

---

## 6. Multimedia Support and yt-dlp (`yt-dlp-setup.sh`)

Configures tools for video downloads and digital audio processing.

1. **yt-dlp and FFMPEG Installation**:
   ```bash
   sudo pacman -S --needed --noconfirm yt-dlp ffmpeg
   ```

2. **Fast JS Decryption Engine**:
   Installs Deno via `mise` for `yt-dlp` to process streaming platform JavaScript logic.

---

## Verification

- **Terminal and Utilities**: Open a new terminal. You should see the **Starship** prompt and **Fastfetch** summary. Test with `eza` or `bat --version`.
- **Kitty**: Run `kitty --version`. Should open with opacity and Catppuccin theme.
- **Cockpit**: Open browser and go to [https://localhost:9090](https://localhost:9090). Log in with system credentials.
- **Firewalld**: Verify with `sudo firewall-cmd --state`.
