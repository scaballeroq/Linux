---
sidebar_position: 2
---

# System Setup on CachyOS (Niri + Noctalia Shell)

This guide details the base system setup, deployment of the **Niri** compositor, **Noctalia Shell**, terminal optimization with **Zsh**, essential development tools, multimedia acceleration, and user environment configuration on **CachyOS** (Arch Linux, x86-64-v3/v4 optimized).

All configurations are automated through the scripts located in the `Setup` directory.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by optimizing mirrors, installing core development utilities, and configuring hardware acceleration. The script automatically detects the CPU architecture (AMD Ryzen vs Intel Core) and applies the corresponding profile:

1. **CPU Auto-Detection**:
   - `AuthenticAMD` → Runs `post-install-amd.sh` (AMD microcode, RADV Vulkan, Mesa, PipeWire)
   - `GenuineIntel` → Runs `post-install-intel.sh` (Intel microcode, Intel VA-API, PipeWire)

2. **Pacman Optimization**:
   - `ParallelDownloads = 10`
   - Colorized terminal output enabled
   - Complete system base upgrade

3. **Core Software**:
   - Build tools: `base-devel`, `cmake`
   - Monitoring & hardware diagnostics: `btop`, `htop`, `inxi`
   - Archive & compression utilities: `curl`, `fuse2`, `fuse3`, `exfatprogs`, `7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`, `ca-certificates`, `gnupg`
   - Graphics & Multimedia: `vlc`, `mpv`, `gimp`, `gparted`
   - Wayland & Niri Stack: `niri`, `xwayland-satellite`, GNOME/GTK portals, `wl-clipboard`, `grim`, `slurp`, `satty`, `pavucontrol`, `qt6ct`, `kvantum`

---

## 2. Desktop Environment: Niri Compositor & Noctalia Shell

The Wayland tiling environment based on **Niri** (Rust scrollable-tiling window manager) and **Noctalia Shell** comes preinstalled and configured out of the box via CachyOS's official `cachyos-niri-noctalia` package with modular architecture in `~/.config/niri/`:

- **Niri**: Infinite horizontal scrolling tiling window manager.
- **Noctalia Shell**: Top status bar, application launcher, hardware control center (native Wi-Fi and Bluetooth), and lock screen.
- **Xwayland Satellite**: Clean and lightweight management for legacy X11 applications.
- **Wayland Portals**: `xdg-desktop-portal-gnome` and `xdg-desktop-portal-gtk` for file pickers and screen casting.
- **Desktop Toolchain**: `wl-clipboard`, `grim` and `slurp` (screen capture), `satty` (annotation), `brightnessctl`, `playerctl`.
- **Hardware Control GUIs**: `pavucontrol` (PipeWire audio). Wi-Fi and Bluetooth are managed and integrated natively by Noctalia Shell.
- **Theming**: `qt5-wayland`, `qt6-wayland`, `qt6ct`, `kvantum`, and `papirus-icon-theme`.

---

## 3. Hardware & Laptop Tuning (`cachyos-tuning.sh` and `laptop-setup.sh`)

1. **System Performance Tuning (`cachyos-tuning.sh`)**:
   - Kernel sysctl parameters for reduced latency and improved virtual memory management.
   - NVMe queue optimizations and scheduling tweaks for CachyOS BORE/EEVDF kernels.
   - Status diagnosis: `./Setup/cachyos-tuning.sh --status`.

2. **Laptop Optimization (`laptop-setup.sh`)**:
   - Wayland touchpad gestures configuration.
   - Power management with `tuned-ppd` / `power-profiles-daemon`.
   - Screen and keyboard backlight state persistence via `systemd-backlight`.

---

## 4. Terminal Environment & Zsh (`shell.sh`, `fastfetch.sh`, and `fonts.sh`)

Installs modern console utilities, programmer fonts, and links the modular **Zsh** environment from `ZSH.Setup`, keeping **Powerlevel10k** as CachyOS's native prompt.

### Modern Terminal Tools (`shell.sh`)
Installs modern CLI alternatives and configures modular loading inside `~/.zshrc.d/`:
- `eza` (modern `ls` replacement with Git status)
- `bat` (syntax-highlighted `cat`)
- `fzf` (interactive fuzzy finder)
- `zoxide` (smart directory jumping with `z`)
- `ripgrep` (`rg`, blazing fast text search)
- `fd` (fast file finder)
- `duf` (visual disk usage analyzer)
- `dust` (interactive directory size explorer)
- `procs` (modern `ps` replacement)
- `btop` (interactive terminal resource monitor)

Automatically symlinks all modules from `ZSH.Setup/` to `~/.zshrc.d/`:
```bash
./Setup/shell.sh
# or via justfile:
just shell
```

### Programmer Fonts (Nerd Fonts)
Installs Nerd Fonts with programming ligatures and terminal icons (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo`, `Hack`):
```bash
./Setup/fonts.sh
```

### Fastfetch
Displays system specifications and logos upon opening new terminal tabs:
```bash
./Setup/fastfetch.sh
```

---

## 5. Kitty Terminal (`kitty.sh`)

Installs and configures **Kitty**, a GPU-accelerated Wayland-native terminal emulator:

1. **Aesthetic Enhancements**:
   - 75% opacity with background blur (`blur 32`)
   - Catppuccin Mocha color scheme
   - JetBrainsMono Nerd Font
   - Powerline style tab bar

2. **Niri Integration**:
   - Set as default terminal emulator (`TERMINAL=kitty` in `environment.d`)
   - Global Niri keybinding: `Mod+Return` (or `Super+Enter`)

3. **Keybindings**:
   - `Ctrl+Alt+Up/Down`: Adjust background opacity
   - `Ctrl+Shift+F5`: Live reload configuration
   - `Ctrl+Shift+T`: Open new tab in current working directory

---

## 6. Security & Hardening (`seguridad.sh`)

Firewalld, secure DNS, and networking optimizations for a home development laptop:
- **Firewalld**: Default `home` zone with SSH, mDNS, Cockpit, dev servers (3000-3010, 5173, 8000-8080, 8501), and LocalSend/KDE Connect.
- **Virtualization (QEMU/KVM)**: Integrates `virbr0` into the `libvirt` zone with automatic NAT forwarding (`--add-forward`).
- **Containers (Podman Rootless)**: Bridge networks (`podman+`) in `trusted` zone, unprivileged port access (`ip_unprivileged_port_start=80`).
- **Kernel Sysctl**: `rp_filter=2` (Loose mode for virtual bridges), `ip_forward=1`, `somaxconn=4096`, and frictionless `dmesg`.
- **Local DNS & Privacy**: `systemd-resolved` with mDNS (`.local`) support and opportunistic DoT without breaking home router resolution.

---

## 7. Web Management with Cockpit (`cockpit.sh`)

Deploys Cockpit for browser-based monitoring and management:
```bash
sudo pacman -S --needed --noconfirm cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```
Access URL: [https://localhost:9090](https://localhost:9090)

---

## 8. Multimedia & yt-dlp (`yt-dlp-setup.sh`)

Sets up video and audio streaming extractors:
- Latest `yt-dlp` and `ffmpeg`.
- Deno installed via `mise` as the JavaScript engine for stream deciphering.
- Shell aliases and functions loaded via `ZSH.Setup/yt-dlp_aliases.sh`.

---

## Verification

To confirm the installation of all system components:
- **Niri and Noctalia**: Run `just niri-status`.
- **Zsh Shell**: Open a new Kitty window and ensure modules load from `~/.zshrc.d/`.
- **Cockpit**: Visit [https://localhost:9090](https://localhost:9090).
- **Firewall**: Run `sudo firewall-cmd --state`.
