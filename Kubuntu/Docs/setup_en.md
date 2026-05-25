---
sidebar_position: 2
---

# Debian 13 System Configuration

This guide details the base system setup, terminal optimization, essential software installation, multimedia support, and desktop user environment customization applied to a Debian 13 (Trixie) system.

These settings are automated through the scripts located in the `Setup` folder.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by configuring additional official repositories, installing essential software, and setting up hardware acceleration.

1. **Base System Update**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Enabling Extra Repositories** (Contrib, Non-Free, Non-Free-Firmware, and Backports):
   ```bash
   sudo apt-add-repository -y contrib non-free non-free-firmware
   # Add Backports repository
   CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)
   echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list
   sudo apt update
   ```

3. **Essential Software**:
   Installs compilation utilities, system monitoring tools, and compatibility packages:
   - Compilation: `build-essential`, `cmake`
   - Monitoring: `btop`, `htop`, `inxi`
   - Utilities: `curl`, `fuse3`, `libfuse2t64`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Graphics & Multimedia: `vlc`, `gimp`, `gparted`
   - Universal Packages: `flatpak`, `gnome-software-plugin-flatpak`

4. **Multimedia Codecs and HW Acceleration**:
   ```bash
   sudo apt install -y libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers
   ```

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
- `fd-find` (`fd`, simple replacement for `find`)
- `tealdeer` (`tldr`, simplified man pages/cheat sheets)
- `duf` (visual replacement for `df`)
- `du-dust` (`dust`, disk space visualizer)
- `procs` (modern replacement for `ps`)

To avoid naming conflicts in Debian, symbolic links are configured:
```bash
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat
ln -sf /usr/bin/fdfind ~/.local/bin/fd
```

### Starship Prompt
Downloads and configures the latest version of the Starship prompt:
```bash
curl -sS https://starship.rs/install.sh | sh -s -- -y
```
The configuration is modular. If the system supports `.bashrc.d`, the file `~/.bashrc.d/starship.sh` is created:
```bash
# Starship Prompt Configuration
eval "$(starship init bash)"
```
Additionally, the design configuration is copied from `Setup/starship.toml` to `~/.config/starship.toml`.

### Development Fonts (Nerd Fonts)
Downloads and installs fonts optimized for programming and terminal symbols (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo`, and `Hack`):
```bash
# Automatic download and extraction to ~/.local/share/fonts
# Refreshing font cache:
fc-cache -f
```

### Fastfetch
Displays system information in an aesthetic and visual way upon terminal startup. Installs `fastfetch` and copies the custom configuration template `config.jsonc` to `~/.config/fastfetch/config.jsonc`.

---

## 3. Web Administration Panel Cockpit (`cockpit.sh`)

Installs Cockpit to administer the server or local machine via a convenient web interface.

1. **Cockpit and Extensions Installation**:
   Installs support for package management, storage, networking, virtual machines (`cockpit-machines`), and containers (`cockpit-podman`):
   ```bash
   sudo apt install -y cockpit cockpit-podman cockpit-machines cockpit-packagekit cockpit-storaged cockpit-networkmanager
   ```

2. **Socket Activation**:
   To save system resources, Cockpit only starts when its port is accessed:
   ```bash
   sudo systemctl enable --now cockpit.socket
   ```

3. **Firewall Rule**:
   ```bash
   sudo ufw allow 9090/tcp
   ```

---

## 4. Multimedia Support and yt-dlp (`yt-dlp-setup.sh`)

Configures tools for video downloads and digital audio processing.

1. **yt-dlp (Backports) and FFMPEG Installation**:
   The Backports version is required so that `yt-dlp` stays updated with constant changes on streaming platforms:
   ```bash
   sudo apt install -y -t trixie-backports yt-dlp
   sudo apt install -y ffmpeg
   ```

2. **Fast JS Decryption Engine**:
   Installs Deno via `mise` (or system-wide NodeJS as a fallback) to allow `yt-dlp` to process platform JavaScript logic ultra-fast:
   ```bash
   mise use --global deno@latest
   ```

---

## 5. Desktop Themes and Icons (`apariencia.sh`)

Applies design packages for a clean and cohesive visual environment.

1. **Icon Themes Installation**:
   ```bash
   sudo apt install -y papirus-icon-theme
   ```

---

## Verification

To verify that the main components have been installed and configured correctly:

- **Terminal and Utilities**: Open a new terminal. You should see the **Starship** prompt loaded and the **Fastfetch** summary displayed. Test utilities by running `eza` or `bat --version`.
- **Cockpit**: Open your browser and go to [https://localhost:9090](https://localhost:9090). Log in with your Debian system user credentials.
