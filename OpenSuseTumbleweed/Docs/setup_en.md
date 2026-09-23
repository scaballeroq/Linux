---
sidebar_position: 2
---

# System Setup in openSUSE Tumbleweed

This guide details the base configuration, Packman and OPI repositories, Snapper/Btrfs snapshots, kernel and sysctl tuning, **KDE Plasma 6 (Wayland)** customization, Kitty terminal, modern CLI utilities, and web administration console on **openSUSE Tumbleweed**.

All setups are automated through scripts in the `Setup/` directory and the [`justfile`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/justfile).

---

## 1. Base Post-Installation (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepares the base system by configuring the official Packman repository (priority 90), complete multimedia codecs, ZRAM, PipeWire, KDE Plasma 6 patterns (`kde_plasma`, `kde`), and the graphics stack optimized for your CPU/GPU architecture.

### Available scripts:

- **Smart Dispatcher (`post-install.sh`)**:
  Automatically detects the CPU (`AuthenticAMD` vs `GenuineIntel`) or allows explicit flag selection:
  ```bash
  ./Setup/post-install.sh          # Auto-detection
  ./Setup/post-install.sh --amd    # Force AMD mode
  ./Setup/post-install.sh --intel  # Force Intel mode
  ```

- **AMD Ryzen Profile (`post-install-amd.sh`)**:
  Optimized for AMD Ryzen processors and Radeon graphics:
  - Packman repository with priority 90 (`zypper ar -cfp 90 ...`).
  - OPI (Open Build Service Package Installer).
  - Microcode & firmware: `ucode-amd`, `kernel-firmware-amdgpu`, `kernel-firmware-radeon`.
  - Graphics stack: `Mesa`, `libvulkan_radeon`, `libva-vdpau-driver`, `radeontop`.
  - KDE Plasma 6 Apps: Dolphin, Kate, Spectacle, Gwenview, Ark, Okular, Discover (with Flathub backend).
  ```bash
  ./Setup/post-install-amd.sh
  # Or via just:
  just post-install-amd
  ```

- **Intel Core / Media Center Profile (`post-install-intel.sh`)**:
  Optimized for Intel Core machines (e.g. Haswell i7-4790 / HD Graphics 4600) configured as a media center:
  - Microcode: `ucode-intel`, `kernel-firmware-intel`.
  - Video hardware acceleration: `intel-vaapi-driver`, `libvulkan_intel`.
  - Streaming & Media: `kodi`, `ffmpeg` codecs, `gstreamer-plugins-*`.
  ```bash
  ./Setup/post-install-intel.sh
  # Or via just:
  just post-install-intel
  ```

---

## 2. KDE Plasma 6 Customization (`kde-settings.sh`)

Configures the **KDE Plasma 6** desktop experience on Wayland:

- **Theme & Colors**: Breeze Dark (`plasma-apply-lookandfeel -a org.kde.breezedark.desktop`) and GTK 3/4 Breeze-Dark integration.
- **KWin**: Window control buttons placed on the right.
- **Night Color**: Enabled at 4000K for eye comfort.
- **Dolphin**: Detailed view by default, hidden unnecessary panels, and KIO Servicemenus for contextual right-click actions:
  - "Open in Kitty" (`~/.local/share/kio/servicemenus/open-in-kitty.desktop`).
  - "Open in Antigravity" (`~/.local/share/kio/servicemenus/open-in-antigravity.desktop`).
  - "Open in Antigravity IDE" (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).
- **Shortcuts**: `Ctrl+Alt+T` globally assigned to launch Kitty.

```bash
# Apply complete KDE Plasma 6 setup
just kde-setup
# or ./Setup/kde-settings.sh

# Toggle dark or light theme
just kde-theme-dark
just kde-theme-light

# Diagnostic status
just kde-status
```

---

## 3. Laptop & Display Optimization (`laptop-setup.sh`)

Tailored for the **HP EliteBook 855 G7** laptop (AMD Ryzen 7 PRO 4750U):

- **KDE Touchpad (`kcminputrc`)**: Tap-to-click enabled, natural scrolling, and smooth acceleration.
- **PowerDevil (`powermanagementprofilesrc`)**: Auto-sleep timeouts adjusted for battery and AC power.
- **Bluetooth**: `FastConnectable = true` in `/etc/bluetooth/main.conf`.
- **Systemd logind**: Suspend on lid close.
- **Automatic 95% Brightness**: `set-screen-brightness.service` systemd unit restoring optimal screen brightness after boot.

```bash
just laptop
```

---

## 4. System Tuning & Btrfs/Snapper Policies (`tumbleweed-tuning.sh`)

Fine-tunes kernel sysctl parameters and Snapper retention policies via a complete CLI (`--status`, `--sysctl`, `--limits`, `--snapper`, `--baloo`):

- **Sysctl**: ZRAM (`vm.swappiness=150`, `vm.watermark_boost_factor=0`), expanded Inotify watches for IDEs (`fs.inotify.max_user_watches=524288`), BBR congestion control.
- **Btrfs Snapper Retention**: Limited timeline snapshots (maximum 10, 3 hourly, 3 daily) preventing root subvolume overflow.
- **Baloo File Indexer**: Automated exclusions in `~/.config/baloofilerc` for heavy development directories (`node_modules`, `target`, `.git`, `.venv`, `dist`, `build`).

```bash
just tuning
just tuning-status
```

---

## 5. Terminal Environment & Shell (`shell.sh`, `starship.sh`, `fastfetch.sh`, `fonts.sh`)

Installs modern Rust/Go CLI utilities and loads modular configs from `~/.bashrc.d/`:

- **Tools**: `eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`.
- **Starship Prompt (`starship.sh`)**:
  ```bash
  just starship          # Install and enable
  just starship-disable  # Disable and restore native prompt
  just starship-status   # Check status
  ```
- **Nerd Fonts (`fonts.sh`)**: Installs `JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo`, and `Hack` in `~/.local/share/fonts/`.
- **Fastfetch (`fastfetch.sh`)**: Aesthetic system overview for openSUSE and KDE Plasma.

---

## 6. Kitty Terminal (`kitty.sh`)

Installs and tunes **Kitty**, GPU-accelerated terminal with Catppuccin Mocha theme:

- 75% opacity with background blur (`blur 32`).
- JetBrainsMono Nerd Font.
- Global KDE shortcut `Ctrl+Alt+T`.
- Dolphin KIO Servicemenus integration.

```bash
just kitty
```

---

## 7. Security & Firewall (`seguridad.sh`)

Hardens system networking with Firewalld, DNS-over-TLS, and KDE Connect integration:

- **Firewalld**: Allowed services: `kdeconnect` (mobile phone integration), `mdns`, `ssh`.
- **Containers & Virtualization**: `podman+` and `virbr0` interfaces in trusted/libvirt zones.
- **DNS-over-TLS**: Enabled opportunistically via `systemd-resolved`.
- **Sysctl**: Unprivileged port binding enabled from port 80 upwards.

```bash
just security
```

---

## 8. Complete Multimedia Stack (`multimedia.sh`, `yt-dlp-setup.sh`)

- **Packman (`multimedia.sh`)**: Repository with priority 90, `zypper dup --from packman --allow-vendor-change`, full GStreamer and FFmpeg stacks with VA-API hardware acceleration.
- **yt-dlp (`yt-dlp-setup.sh`)**: Download stack with AtomicParsley, aria2, and Deno JS engine installed via Mise.

```bash
just multimedia
just multimedia-status
just yt-dlp
```

---

## 9. Google Chrome (`chrome.sh`) & Steam (`steam.sh`)

- **Google Chrome**: Official Google RPM repository and `google-chrome-stable` package.
- **Steam**: Native Steam, GameMode, MangoHud, Proton-GE, and 32-bit Mesa/Vulkan graphics libraries.

```bash
just chrome
just steam
```

---

## 10. Web Management with Cockpit (`cockpit.sh`)

Web administration console at [https://localhost:9090](https://localhost:9090):

- Modules included: `cockpit-podman`, `cockpit-machines` (KVM), `cockpit-snapshots` (Snapper Btrfs).
- CLI control:
  ```bash
  just cockpit         # Start and enable
  just cockpit-status  # Check status
  ```

---

## Verification

- **KDE Plasma 6**: Verify with `just kde-status` or in `systemsettings`.
- **Terminal & Shell**: Launch Kitty (`Ctrl+Alt+T`), verify Starship prompt and Fastfetch banner.
- **Performance**: Run `just tuning-status`.
- **Virtualization**: Run `just virtualization-status`.
- **Containers**: Run `just podman-status`.
- **Multimedia**: Run `just multimedia-status`.
