---
sidebar_position: 3
---

# Terminal & Shells Configuration on Fedora 44 Workstation (Bash & Zsh)

This guide details the terminal environment (optimized for **Bash** as the project default shell, and compatible with **Zsh** if `~/.zshrc` exists) along with the modular scripts provided under the `Bash.Setup` folder.

The modular configuration is structured through `~/.bashrc.d/` (default) and `~/.zshrc.d/` (compatibility) directories to ensure fast, clean, and maintainable configurations.

---

## 1. Modular Environment Loading

### For Bash (Default - `~/.bashrc`)
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

### For Zsh (Conditional compatibility if `~/.zshrc` exists)
If you use Zsh and `~/.zshrc` exists on your system:

```zsh
# Modular configuration loader (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### Symbolic Links
You can link all modules automatically by running `./Setup/shell.sh` or manually:
```bash
# For Bash (Default)
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Fedora 44 Workstation/Bash.Setup/*.sh ~/.bashrc.d/

# For Zsh (if ~/.zshrc exists)
if [ -f "$HOME/.zshrc" ]; then
    mkdir -p ~/.zshrc.d
    ln -sf ~/Workspace/Repositorios/Linux/Fedora 44 Workstation/Bash.Setup/*.sh ~/.zshrc.d/
fi
```

---

## 2. Environment Variables (`environment.sh`)

Defines global settings and performance optimizations for system tools:

- **Default Editor**: Sets `nvim` (Neovim) or `nano` as the global editor (`EDITOR`, `VISUAL`).
- **Wayland/Qt**: `QT_QPA_PLATFORM="wayland;xcb"`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- **Executable Paths (`PATH`)**: Adds local user directories:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Smart activation (`mise activate zsh` in Zsh / `mise activate bash` in Bash).
- **Podman**: Automatic `DOCKER_HOST` if socket exists.
- **Aesthetic Pager (`less` and `man`)**: Custom colors and modern flags for manual pages.

---

## 3. Shell Behavior (`options.sh` and `history.sh`)

Optimizes shell interaction through internal adjustments tailored for Zsh and Bash.

### Advanced Shell Behavior (`options.sh`)
* **`autocd` / `AUTO_CD`**: Change directories by typing the path directly (no `cd` needed).
* **`globstar` / `EXTENDED_GLOB`**: Recursive globbing patterns (e.g. `ls **/*.js`).
* **Directory Typo Correction**: `setopt CORRECT` in Zsh and `cdspell` in Bash.
* **Smart Completion in Zsh**: `zstyle` with case-insensitive matching, arrow navigation (`menu select`), and `LS_COLORS` support.

### Command History (`history.sh`)
* Expanded capacity: **10,000 commands** in memory (`HISTSIZE`), **20,000 in file** (`SAVEHIST` / `HISTFILESIZE`).
* Ignores duplicates (`HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`, `erasedups`) and common commands (`HISTORY_IGNORE` / `HISTIGNORE`).
* Immediate write after execution (`INC_APPEND_HISTORY` / `histappend`) and session sharing (`SHARE_HISTORY`).


---

## 4. System Shortcuts & Aliases (`aliases.sh`)

Replaces standard commands with enriched and safe alternatives:

- **Security**:
  - `rm -i`, `cp -i`, `mv -i` (interactive confirmation)
  - `--preserve-root` on `chown`, `chmod`, `chgrp`
- **File Visualization** (if `eza` and `bat` installed):
  - `ls` → `eza --icons --git --group-directories-first`
  - `cat` → `bat --paging=never`
- **Package Management (DNF5)**:
  - `update` → `sudo dnf5 check-update --refresh`
  - `upgrade` → `sudo dnf5 upgrade --refresh -y`
  - `install` → `sudo dnf5 install`
  - `remove` → `sudo dnf5 remove`
  - `search` → `dnf5 search`
  - `clean` → `sudo dnf5 autoremove -y && sudo dnf5 clean all`
- **GNOME & Desktop**:
  - `open` / `o` → `xdg-open`
  - `nautilus` / `files` → Opens Nautilus in current directory
  - `clipcopy` / `clippaste` → Native Wayland clipboard (`wl-clipboard`)
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

## 6. GNOME Configuration (`gnome_settings.sh`)

Applies automatic configurations and shortcuts for the GNOME desktop environment:

- **Dark Theme**: `gnome-theme-dark`, `gnome-theme-light`
- **GNOME Control Center**: Direct shortcuts (`gnome-settings`, `gnome-pantallas`, `gnome-wifi`, `gnome-audio`, `gnome-bluetooth`, `gnome-teclado`, `gnome-energia`, `gnome-red`, `gnome-info`)
- **Night Light**: `gnome-night-light-on`, `gnome-night-light-off`
- **Wayland Utilities**: `captura` (grim + slurp + satty/wl-copy), `grabacion` (wl-screenrec)
- **File Manager**: `nautilus`, `files`

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
