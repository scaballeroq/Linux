---
sidebar_position: 2
---

# System Configuration in Soplos Linux Boro (GNOME Shell Wayland)

This guide details the base system setup, terminal optimization, essential tooling, multimedia support, and desktop personalization applied to an **Soplos Linux Boro** workstation with **GNOME Shell**.

Configurations are automated via scripts in the `Setup/` folder and orchestrated with the `justfile`.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by detecting host CPU architecture and executing the tailored installer:
- **`post-install-amd.sh`**: For AMD Ryzen 7 7730U / Radeon Graphics (Vega 8) (Mesa RADV, VA-API hardware acceleration, PipeWire, ZRAM, Flatpak Flathub).
- **`post-install-intel.sh`**: For Intel Core processors (i965/iHD VA-API, Kodi, PipeWire).

Command:
```bash
just post-install
```

---

## 2. Terminal Environment & Shell (`shell.sh`, `fastfetch.sh`, and `fonts.sh`)

Installs modern console utilities, developer typefaces, Starship prompt, and optimizes the workflow for the native Ghostty terminal.

### Modern Terminal Utilities
- `eza` (modern `ls` replacement with git integration and glyphs)
- `bat` (syntax-highlighted `cat` replacement via `batcat`)
- `fzf` (interactive fuzzy finder for Ctrl+R, Ctrl+T, Alt+C)
- `zoxide` (smart `cd` directory jumping)
- `ripgrep` (`rg`, blazing fast text search)
- `fd-find` (`fd`, user-friendly file search)
- `duf` & `du-dust` (modern disk usage visualization)
- `procs` (modern `ps` replacement)
- `btop` (resource monitor)

### Ghostty Terminal (Native in Soplos Linux Boro)
Ghostty comes preinstalled and configured out of the box with:
- 85% background opacity with background blur accelerated via Wayland / Mutter.
- Native GNOME Shell / Libadwaita integration.
- Global `Ctrl+Alt+T` keybinding in GNOME Shell.
- Nautilus context menu script ("Open in Ghostty").

### Developer Fonts (Nerd Fonts)
Automated installation of:
`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo`, and `Hack`.

### Fastfetch
Aesthetic hardware and system banner supporting official Soplos Linux Boro theme (`soplos`) and minimalist mode (`compact`).

---

## 3. GNOME Shell Desktop & GSConnect (`gnome-settings.sh` & `gsconnect.sh`)

- **Dark Mode**: Enforces `prefer-dark` and system dark theme.
- **Night Light**: Warm 4000K color temperature for eye comfort.
- **Window Controls**: Visible minimize and maximize buttons.
- **Nautilus Scripts**: Right-click context actions for Ghostty, Google Antigravity, and VS Code.
- **GSConnect**: Native GNOME KDE Connect daemon with zero KDE/Qt dependencies, integrated into Firewalld (ports 1714-1764 TCP/UDP).
- **Extensions**: Support for Dash to Dock, AppIndicator, Blur my Shell, and Tiling Shell.

---

## 4. Browsers & Decoupled Software

- **Google Chrome**: Official Google repository with Ozone Wayland flags (`--ozone-platform-hint=auto` and VA-API hardware acceleration).
- **Mozilla Firefox**: Native `.deb` package from Mozilla with APT Pin-Priority 1000, eliminating the Snap wrapper.
- **Flatpak**: Complete catalog (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Shotcut, Spotify, Vesktop).
- **Steam**: Native client with 32-bit architecture (`i386`), Mesa RADV 32-bit drivers, GameMode, and MangoHud.

---

## 5. Summary of Commands with Just

```bash
just post-install        # Smart post-install dispatcher
just gnome-setup         # Configure GNOME desktop
just gnome-extensions    # Install and activate extensions
just gsconnect           # Configure GSConnect and Firewalld
just shell               # Install modern CLI tools
just ghostty-status      # Ghostty terminal diagnostics
just fonts               # Install Nerd Fonts
just fastfetch           # Configure Fastfetch banner
just flatpak             # Install Flatpak applications
just chrome              # Install official Google Chrome
just firefox             # Install native Firefox (.deb)
just steam               # Install Steam and 32-bit drivers
```
