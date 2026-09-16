---
sidebar_position: 2
---

# System Setup on CachyOS (Niri + Dank Material Shell)

This guide details the base system setup, deployment of the **Niri** compositor, **Dank Material Shell (DMS)**, terminal optimization with **Zsh** and **Bash**, essential development tools, multimedia acceleration, and user environment configuration on **CachyOS**.

All configurations are automated through the scripts located in the `Setup` folder.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by optimizing Pacman downloads, installing essential software, and configuring hardware acceleration. The script automatically detects the processor (AMD Ryzen vs. Intel Core) and executes the corresponding profile:

1. **CPU Auto-Detection**:
   - `AuthenticAMD` → Runs `post-install-amd.sh` (AMD microcode, RADV, Mesa, PipeWire)
   - `GenuineIntel` → Runs `post-install-intel.sh` (Intel microcode, VA-API Intel, PipeWire)

2. **Pacman Optimization**:
   - `ParallelDownloads = 10`
   - Color output and `ILoveCandy` visual progress enabled
   - Complete system update (`pacman -Syu`)

3. **Essential Software**:
   - Build tools: `base-devel`, `cmake`, `git`
   - Monitoring & diagnosis: `btop`, `htop`, `inxi`
   - File utilities & compression: `curl`, `wget`, `fuse2`, `fuse3`, `sshfs`, `dosfstools`, `mtools`, `exfatprogs`, `ntfs-3g`, `7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`, `ca-certificates`, `gnupg`
   - Graphics & Multimedia: `vlc`, `mpv`, `gimp`, `gparted`
   - Wayland & Niri Stack: `niri`, `xwayland-satellite`, GNOME/GTK portals, `wl-clipboard`, `grim`, `slurp`, `satty`, `pavucontrol`, `qt5-wayland`, `qt6-wayland`, `qt6ct`, `kvantum`

---

## 2. Desktop Environment: Niri Compositor & Dank Material Shell (DMS)

The Wayland graphical environment couples **Niri** (Rust scrollable-tiling window manager) with **Dank Material Shell (DMS)**, a modern desktop environment built on Quickshell following Material 3 (Material You) design guidelines:

- **Niri**: Dynamic scrollable-tiling compositor with an infinite horizontal window strip. Modular configuration in `~/.config/niri/` with DMS includes in `~/.config/niri/dms/` (`binds.kdl`, `colors.kdl`, `layout.kdl`, `alttab.kdl`, `outputs.kdl`).
- **Dank Material Shell (DMS)**:
  - Full desktop interface: Top bar / dock, application launcher (`dms ipc call launcher toggle`), hardware control center & quick settings (`dms ipc call control-center toggle`), clipboard manager with preview, and session lock screen.
  - Dynamic Material You theming via **Matugen**: Automatically synchronizes system and application colors with the active wallpaper.
  - Complementary apps: `dankcalendar` (`dcal`), `danksearch`, and `dms-greeter` for Greetd.
  - Systemd user service: `dms.service`.
- **Xwayland Satellite**: Decoupled, lightweight X11 backward compatibility.
- **Wayland Portals**: `xdg-desktop-portal-gnome` and `xdg-desktop-portal-gtk` for file dialogs and screen sharing.
- **Desktop Tools**: `wl-clipboard`, `grim` and `slurp` (screenshots), `satty` (annotation), `brightnessctl`, `playerctl`.

---

## 3. Terminal Environment & Shells (`shell.sh`, `fastfetch.sh`, `fonts.sh`)

Installs modern command-line tools, programmer fonts, and modular shell configuration for both **Bash** and **Zsh** from `Bash.Setup`, featuring the cross-shell **Starship** prompt.

### Modern Terminal Utilities (`shell.sh`)
- `eza` (modern `ls` alternative with Git integration)
- `bat` (syntax-highlighting `cat` alternative)
- `fzf` (fuzzy finder)
- `zoxide` (smart navigation `z`)
- `ripgrep` (`rg`, fast text search)
- `fd` (fast file search)
- `duf` & `dust` (disk usage visualizers)
- `procs` (modern `ps` replacement)
- `btop` (interactive terminal resource monitor)
- `jq` (command-line JSON parser)
- `zsh`, `zsh-completions`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- `starship` (customizable prompt)

---

## 4. Terminal Emulator: Kitty (`kitty.sh`)

Sets up Kitty with native Wayland GPU acceleration:
- **Opacity & Blur**: Default opacity at 75% (`0.75`) with Wayland background blur (`blur 32`).
- **Dynamic Opacity Keybindings**:
  - `Ctrl+Alt+Up` / `Ctrl+Alt+Down`: Adjust opacity in ±5% steps.
  - `Ctrl+Alt+0`: Reset to default opacity.
  - `Ctrl+Alt+1`: 100% opaque mode.
- **DMS Theming**: Integrates `./dank-theme.conf` and `./dank-tabs.conf` generated dynamically by Matugen / DMS.
- **Typography**: `JetBrainsMono Nerd Font` size `11.5`.

---

## 5. Niri & DMS Backup (`backup-niri-dms.sh`)

Creates timestamped compressed archives of the desktop configuration:
- `~/.config/niri`
- `~/.config/DankMaterialShell`
- `~/.config/danksearch`
- `~/.config/dankcal`
- `~/.config/kitty`

Commands:
```bash
./Setup/backup-niri-dms.sh          # Create backup
./Setup/backup-niri-dms.sh --list   # List backups
./Setup/backup-niri-dms.sh --restore # Restore latest
```

---

## 6. Post-Installation Verification

- **DMS**: Run `dms doctor` to audit all dependencies and services.
- **Niri**: Verify configuration syntax with `niri validate` and reload with `niri msg action reload-config`.
- **Terminal**: Open Kitty and verify that aliases and Starship prompt load cleanly.
