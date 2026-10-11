---
sidebar_position: 2
---

# System Setup on Debian Testing (KDE Plasma 6)

This guide details the base configuration, microcode, hardware graphics acceleration, kernel sysctl tuning, **KDE Plasma 6 (Wayland)** customization, Kitty terminal, modern CLI utilities, and web administration panel on **Debian Testing (Trixie/Sid)**.

All setups are automated through the scripts in the `Setup` directory and the root [`justfile`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/justfile).

---

## 1. Base Post-Installation (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Prepares the base system with official Debian Testing repositories (`main`, `contrib`, `non-free`, `non-free-firmware`), ZRAM, PipeWire, Flatpak/Flathub, the KDE Plasma 6 desktop suite (`kde-plasma-desktop`, `plasma-workspace`), and hardware-optimized graphics drivers.

### Available Scripts:

- **Smart Dispatcher (`post-install.sh`)**:
  Auto-detects CPU (`AuthenticAMD` vs `GenuineIntel`) or allows explicit flags:
  ```bash
  ./Setup/post-install.sh          # Auto-detection
  ./Setup/post-install.sh --amd    # Force AMD mode
  ./Setup/post-install.sh --intel  # Force Intel mode
  ```

- **AMD Ryzen Profile (`post-install-amd.sh`)**:
  - Firmware and microcode: `firmware-amd-graphics`, `amd64-microcode`.
  - Graphics stack: `mesa-va-drivers`, `mesa-vulkan-drivers`, `radeontop`.
  - Flatpak & Flathub integration for decoupled software.
  - KDE Plasma 6 suite: Dolphin, Kate, Spectacle, Gwenview, Ark, Okular, Discover (Flatpak backend).
  ```bash
  just post-install-amd
  ```

- **Intel Core / Media Center Profile (`post-install-intel.sh`)**:
  - Microcode: `intel-microcode`, `firmware-misc-nonfree`.
  - Video VA-API: `intel-media-va-driver`, `i965-va-driver-shaders`, `mesa-vulkan-drivers`.
  - Multimedia: `kodi`, codecs `ffmpeg`, `gstreamer1.0-plugins-*`.
  ```bash
  just post-install-intel
  ```

---

## 2. KDE Plasma 6 Desktop Customization (`kde-settings.sh`)

- **Theme & Appearance**: Full Breeze Dark (`org.kde.breezedark.desktop`) and GTK 3/4 Breeze-Dark sync.
- **KWin**: Right titlebar buttons (`ButtonsOnRight "IAX"`).
- **Night Color**: Set to 4000K for eye comfort.
- **Dolphin**: Details view by default, streamlined UI, and right-click KIO Servicemenus:
  - "Open in Kitty" (`~/.local/share/kio/servicemenus/open-in-kitty.desktop`).
  - "Open in Antigravity" (`~/.local/share/kio/servicemenus/open-in-antigravity.desktop`).
  - "Open in Antigravity IDE" (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).
- **Shortcuts**: Global `Ctrl+Alt+T` to spawn Kitty.

```bash
just kde-setup
just kde-theme-dark
just kde-theme-light
just kde-status
```

---

## 3. Laptop Optimization (`laptop-setup.sh`) & Fingerprint (`fingerprint-setup.sh`)

- **Power Profiles Daemon**: Native integration with KDE battery applet.
- **Touchpad (Wayland)**: Tap-to-click enabled, dynamic Natural Scrolling via KWin D-Bus and `kcminputrc`.
- **PowerDevil**: AC sleep disabled, battery sleep 30m.
- **Smart Lid Close**: Inhibits suspend when external monitors are connected.
- **Bluetooth (BlueZ)**: `FastConnectable` and `Experimental` battery reporting.

```bash
just laptop
just fingerprint          # Full biometric PAM configuration (SDDM password-only, lockscreen dual)
just fingerprint-status   # Detailed diagnostics (sensor hardware, PAM, SDDM, lockscreen, fingerprints)
just fingerprint-enroll   # Enroll fingerprint in CLI (9 touch stages)
just fingerprint-verify   # Test verification on sensor
just fingerprint-sddm-bypass # Apply SDDM password-only bypass (KWallet auto-unlock)
just plymouth             # Install and enable debian-spinner theme (Debian logo + animated spinner)
just plymouth --swirl     # Minimalist red swirl variant (no text)
just plymouth-status      # Diagnostic of theme, KMS, and initramfs
just plymouth-preview     # Live window preview of splash animation
```

---

## 4. Performance Tuning (`debian-tuning.sh`)

CLI-driven system tuning (`--status`, `--sysctl`, `--limits`, `--baloo`, `--zram`):
- **Sysctl**: ZRAM (`vm.swappiness=180`), Inotify expanded (`fs.inotify.max_user_watches=1048576`), TCP BBR.
- **Limits**: File descriptors increased to 1,048,576 for large builds and containers.
- **Systemd**: `DefaultTasksMax=infinity` and `DefaultTimeoutStopSec=10s`.
- **Baloo**: Automated exclusions for heavy developer folders (`node_modules`, `target`, `.git`, `.venv`, `Workspace`).

```bash
just tuning
just tuning-status
```

---

## 5. Shell & Terminal (`shell.sh`, `starship.sh`, `fastfetch.sh`, `fonts.sh`)

- **CLI Tools**: `eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`, `dust`, `btop`, `jq`.
- **Starship Prompt**:
  ```bash
  just starship
  just starship-disable
  just starship-status
  ```
- **Nerd Fonts**: Manages `JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo`, `Hack`.
- **Fastfetch**: Themes `debian` (official spiral) and `compact` (FastCat).

---

## 6. Kitty Terminal (`kitty.sh`)

GPU-accelerated terminal with Catppuccin Mocha theme, opacity 0.75, blur 32, JetBrainsMono Nerd Font, and `Ctrl+Alt+T` shortcut.

```bash
just kitty
```

---

## 7. Security & Firewall (`seguridad.sh`)

Firewalld / UFW hardening with rules for KDE Connect, mDNS, SSH, Cockpit 9090, Podman rootless, and KVM `virbr0`.

```bash
just security
just security-status
```

---

## 8. Multimedia & YouTube Downloads (`multimedia.sh`, `yt-dlp-setup.sh`)

- Native Debian Testing packages, GStreamer, FFmpeg, VA-API acceleration, decoupled Flatpak players.
- yt-dlp stack with mutagen, aria2, and Mise-integrated Deno JS runtime.

```bash
just multimedia
just multimedia-status
just yt-dlp
```

---

## 9. Google Chrome (`chrome.sh`) & Steam (`steam.sh`)

- **Chrome**: Official Google repository and `google-chrome-stable`.
- **Steam**: Multiarch `i386`, GameMode, MangoHud, and Proton-GE.

```bash
just chrome
just steam
```

---

## 10. Cockpit Web Administration (`cockpit.sh`)

Web administration at [https://localhost:9090](https://localhost:9090) with modules for Podman, KVM machines, storage, networking, and SOS reports.

```bash
just cockpit
just cockpit-status
just cockpit-open
just cockpit-client
```

---

## Verification

- **KDE Plasma 6**: `just kde-status`
- **Tuning**: `just tuning-status`
- **Virtualization**: `just virtualization-status`
- **Containers**: `just podman-status`
- **Multimedia**: `just multimedia-status`
