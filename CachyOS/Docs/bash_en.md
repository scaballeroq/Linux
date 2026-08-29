---
sidebar_position: 3
---

# Bash Configuration on CachyOS

This guide details the terminal environment (Bash) setup and built-in utilities provided in the modular scripts under the `Bash.Setup` folder.

The modular configuration is structured through the `~/.bashrc.d/` directory to ensure the `~/.bashrc` file remains clean and maintainable.

---

## 1. Modular Environment Loading

The scripts are loaded dynamically by adding the following block to your `~/.bashrc` file:

```bash
# Modular loading of Bash.Setup scripts
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

You can enable them by creating symbolic links in `~/.bashrc.d/`:
```bash
mkdir -p ~/.bashrc.d
ln -s ~/Workspace/Repositorios/Linux/CachyOS/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Environment Variables (`environment.sh`)

Defines global settings and performance optimizations for system tools:

- **Default Editor**: Sets `nvim` (Neovim) as the global editor.
- **Wayland/Qt**: `QT_QPA_PLATFORM="wayland;xcb"`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`
- **Executable Paths (`PATH`)**: Adds local user directories:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Polyglot version manager activation
- **Podman**: Automatic `DOCKER_HOST` if socket exists
- **Aesthetic Pager (`less` and `man`)**: Custom colors and flags for readable manual pages.

---

## 3. Bash Behavior (`options.sh` and `history.sh`)

Optimizes shell interaction through internal adjustments.

### Advanced Shell Behavior (`options.sh`)
* **`autocd`**: Change directories by typing the path directly (no `cd` needed).
* **`globstar`**: Recursive globbing patterns (e.g. `ls **/*.js`).
* **Directory Typo Correction**: `cdspell` and `dirspell` for automatic typo fixes.
* **Case-insensitive completion**: `bind 'set completion-ignore-case on'`.

### Command History (`history.sh`)
* Expanded capacity: **10,000 commands** in memory, **20,000 in file**.
* Ignores duplicates (`erasedups`) and common commands (`HISTIGNORE`).
* Immediate write after each execution.

---

## 4. System Shortcuts & Aliases (`aliases.sh`)

Replaces standard commands with enriched and safe alternatives:

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
- **KDE Plasma**:
  - `open` / `o` → `xdg-open`
  - `dolphin` → Opens Dolphin in current directory
  - `clipcopy` / `clippaste` → Wayland/X11 clipboard
- **Kernel Check**: `check-kernel` compares active kernel vs kernel.org

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

## 6. KDE Plasma 6 Configuration (`kde_settings.sh`)

Applies automatic configurations for the KDE Plasma 6 desktop environment:

- **Touchpad**: Tap-to-click, natural scrolling
- **Window Buttons**: Minimize, Maximize, Close on the right
- **Clock**: 24-hour format, ISO date
- **KWin**: Reload configuration without restarting session
- **KCM Shell**: Shortcuts to configuration modules (displays, wifi, audio, bluetooth, etc.)
- **Themes**: `kde-theme-dark`, `kde-theme-light`, `kde-set-wallpaper`
- **Spectacle**: `captura` (region capture), `grabacion` (screen recording)
- **Plasmoids**: `plasmoids-list`, `kwin-scripts-list`

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
