---
sidebar_position: 3
---

# Terminal & Zsh Configuration on CachyOS (ZSH.Setup)

This guide details the terminal environment (optimized primarily for **Zsh**, the default shell in CachyOS, with fallback compatibility for **Bash**) along with the modular scripts provided under the `ZSH.Setup` folder.

The modular configuration is structured through `~/.zshrc.d/` and `~/.bashrc.d/` directories to ensure fast, clean, and maintainable configurations.

---

## 1. Modular Environment Loading

### For Zsh (`~/.zshrc`) - Recommended and Default
Add the following block to your `~/.zshrc`:

```zsh
# Modular configuration loader (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### For Bash (`~/.bashrc`) - Fallback
Add the following block to your `~/.bashrc`:

```bash
# Modular configuration loader (~/.bashrc.d)
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### Symbolic Links
You can link all modules automatically by running `./Setup/shell.sh` or manually:
```bash
mkdir -p ~/.zshrc.d ~/.bashrc.d
ln -sf /home/caballero/Warehouse/Repositorios/Linux/CachyOS_Niri_Noctalia/ZSH.Setup/*.sh ~/.zshrc.d/
ln -sf /home/caballero/Warehouse/Repositorios/Linux/CachyOS_Niri_Noctalia/ZSH.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Environment Variables (`environment.sh`)

Defines global settings and performance optimizations for system tools:

- **PATH Deduplication (Zsh)**: Enables `typeset -U path` to automatically eliminate duplicate PATH entries.
- **Default Editor**: Sets `nvim` (Neovim) or `nano` as the global editor (`EDITOR`, `VISUAL`).
- **Wayland/Qt (Niri & Noctalia)**: `XDG_CURRENT_DESKTOP="niri"`, `XDG_SESSION_TYPE="wayland"`, `QT_QPA_PLATFORM="wayland;xcb"`, `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- **Executable Paths (`PATH`)**: Adds local user directories:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Smart activation (`mise activate zsh` in Zsh / `mise activate bash` in Bash).
- **Podman Rootless**: Automatic `DOCKER_HOST` if socket exists at `$XDG_RUNTIME_DIR/podman/podman.sock`.
- **Aesthetic Pager (`less` and `man`)**: Custom colors and modern flags for manual pages.

---

## 3. Shell Behavior (`options.sh` and `history.sh`)

Optimizes shell interaction through internal adjustments tailored for Zsh.

### Advanced Shell Behavior (`options.sh`)
* **`AUTO_CD`**: Change directories by typing the path directly (no `cd` needed).
* **`EXTENDED_GLOB`**: Recursive globbing patterns (e.g. `ls **/*.js`).
* **Directory Typo Correction**: `setopt CORRECT` in Zsh.
* **No Beep**: `setopt NO_BEEP` disables bell notifications.
* **Smart Completion in Zsh**: `zstyle` with case-insensitive matching, arrow navigation (`menu select`), and `LS_COLORS` support.

### Command History (`history.sh`)
* Expanded capacity: **50,000 commands** in memory (`HISTSIZE`) and in file (`SAVEHIST`).
* **`EXTENDED_HISTORY`**: Records timestamp and elapsed runtime for every command.
* Ignores duplicates (`HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`) and common commands (`HISTORY_IGNORE`).
* Immediate write after execution (`INC_APPEND_HISTORY`) and real-time session sharing (`SHARE_HISTORY`).

---

## 4. System Shortcuts & Aliases (`aliases.sh`)

Replaces standard commands with enriched and safe alternatives:

- **Quick Navigation**:
  - `cachyos` / `project`: Go to `/home/caballero/Warehouse/Repositorios/Linux/CachyOS_Niri_Noctalia`
  - `repo` / `repos`: Go to `/home/caballero/Warehouse/Repositorios`
  - `..`, `...`, `....`: Go up 1, 2, or 3 directories
- **Zsh Global Pipes** (smart suffix aliases):
  - `G` → `| grep -i` (e.g. `cat file G error`)
  - `L` → `| less`
  - `H` → `| head -n 20`
  - `T` → `| tail -n 20`
  - `J` → `| jq`
- **Security**:
  - `rm -i`, `cp -i`, `mv -i` (interactive confirmation)
  - `--preserve-root` on `chown`, `chmod`, `chgrp`
- **File Visualization** (if `eza` and `bat` installed):
  - `ls` → `eza --icons --git --group-directories-first`
  - `cat` → `bat --paging=never`
- **Package Management (Pacman/Paru)**:
  - `update` → `sudo pacman -Syu`
  - `install` → `sudo pacman -S`
  - `aur` → `paru` or `yay` (whichever is available)
  - `rate-mirrors` → `cachyos-rate-mirrors`
- **Wayland Desktop (Niri / Noctalia)**:
  - `open` / `o` → `xdg-open`
  - `files` → Open file manager in current directory
  - `clipcopy` / `clippaste` → Wayland clipboard (`wl-copy` / `wl-paste`)
- **Kernel Check**: `check-kernel` compares running kernel with kernel.org
- **Quick Reload**: `reload` (`source ~/.zshrc`), `edit-zshrc`, `edit-aliases`

---

## 5. System Functions & Utilities (`functions.sh`)

Helper shell functions to simplify recurring tasks:

* **`extract`**: Automatically extracts any compressed file format.
* **`mkcd`**: Creates a folder and changes into it.
* **`up <N>`**: Steps up `N` directory levels.
* **`duh`**: Displays folder sizes sorted by disk weight.
* **Multimedia Processing**:
  - `webm2mp4`: Converts WebM to MP4.
  - `transcode-video-1080p` / `transcode-video-4k`: Transcodes video.
  - `img2jpg` / `img2png`: Converts and optimizes images.

---

## 6. Niri and Noctalia Shell Configuration (`niri_noctalia.sh`)

Provides integration, shortcuts, and direct IPC with the **Niri** scrollable-tiling compositor and **Noctalia** shell:

- **Niri IPC**:
  - `niri-reload`: Hot reloads Niri configuration (`~/.config/niri/config.kdl`)
  - `niri-validate`: Validates KDL configuration file syntax
  - `niri-windows` / `niri-focused` / `niri-outputs`: Inspects window and display states
  - `niri-quit`: Cleanly exits Niri session
- **Noctalia Shell IPC**:
  - `noctalia-reload`: Reloads or restarts Noctalia shell
  - `noctalia-launcher`: Opens the application launcher
  - `noctalia-control`: Opens the Control Center (Wi-Fi, Bluetooth, Audio, profiles)
  - `noctalia-settings`: Opens Noctalia Shell settings
  - `noctalia-lock`: Locks the user session
  - `noctalia-set-wallpaper <path>`: Applies wallpaper via IPC
- **Wayland Screenshots and Recording**:
  - `captura`: Interactive region screenshot to clipboard with `grim` + `slurp`
  - `captura-pantalla`: Fullscreen screenshot to clipboard
  - `captura-archivo`: Saves screenshot with timestamp to `~/Imágenes/Capturas/`
  - `grabacion`: Interactive region screen recording to MP4 via `wl-screenrec`
- **Quick Settings**:
  - `audio-settings`: Opens `pavucontrol` audio mixer
  - `bluetooth-settings`: Opens `blueman-manager`
  - `wifi-settings`: Opens `nm-connection-editor`

---

## 7. Cloud Sync and Downloads (`rclone_aliases.sh` and `yt-dlp_aliases.sh`)

### Rclone Synchronization
Facilitates cloud syncing with Google Drive and OneDrive:
- `rclone-documentos`: Syncs local → cloud
- `rclone-videos-down`: Downloads media from cloud
- `rclone-onedrive-down`: Downloads from OneDrive

### yt-dlp Downloads
- `ytvideo <URL>`: Downloads video in 1080p
- `ytaudio <URL>`: Downloads and converts to MP3
- `ytlista <URL>`: Downloads playlists
- `ytdl-subs <URL>`: Downloads with Spanish subtitles

---

## 8. Container Functions (`podman-functions.sh`)

Aliases and helper functions for Podman and Quadlets:

- `p` → `podman`
- `pps` → `podman ps` with table format
- `pexec <container>`: Execute commands in container
- `plogs <container>`: View logs in real-time
- `pinfo <container>`: Inspect container
- `pclean-total`: Complete system cleanup
- **Quadlets**:
  - `quadlet-reload`: `systemctl --user daemon-reload`
  - `quadlet-status`: Status of container-* services
  - `quadlet-logs <service>`: Quadlet service logs
