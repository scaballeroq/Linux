---
sidebar_position: 3
---

# Terminal & Shells Setup in openSUSE Tumbleweed (Bash & Zsh)

This guide details the terminal environment configuration (optimized for **Bash** as the project's default shell and compatible with **Zsh** if `~/.zshrc` exists) alongside utilities in the modular scripts within `Bash.Setup/`.

Modular loading is structured through `~/.bashrc.d/` (default) and `~/.zshrc.d/` (compatibility) to ensure clean, fast, and maintainable configurations.

---

## 1. Modular Shell Loading

### For Bash (Default - `~/.bashrc`)
`./Setup/shell.sh` appends the modular loader to your `~/.bashrc`:

```bash
# Modular loading of Bash.Setup scripts
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### For Zsh (Compatibility if `~/.zshrc` exists)
If using Zsh and `~/.zshrc` exists on your system:

```zsh
# Modular loading of configs and aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### Symlinks
Enable all modules by running `./Setup/shell.sh` or `just shell`:
```bash
# For Bash (Default)
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Bash.Setup/*.sh ~/.bashrc.d/

# For Zsh (if ~/.zshrc exists)
if [ -f "$HOME/.zshrc" ]; then
    mkdir -p ~/.zshrc.d
    ln -sf ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Bash.Setup/*.sh ~/.zshrc.d/
fi
```

---

## 2. Environment Variables (`environment.sh`)

Defines global settings and tool optimizations:

- **Default Editor**: Configures `nvim` (Neovim), `kate`, or `nano` as global editor (`EDITOR`, `VISUAL`).
- **Wayland/Qt**: `QT_QPA_PLATFORM="wayland;xcb"`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- **Executable Paths (`PATH`)**: Adds local user directories:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Dynamic shell hook (`mise activate bash` in Bash / `mise activate zsh` in Zsh).
- **Podman**: Sets `DOCKER_HOST` automatically if rootless socket is present.
- **Paging & Man Pages (`less` & `man`)**: Modern colors and formatting.

---

## 3. Shell Behavior (`options.sh` & `history.sh`)

Optimizes terminal interaction with tailored shell options:

### Advanced Shell Behavior (`options.sh`)
* **`autocd` / `AUTO_CD`**: Change directory by typing the directory name without `cd`.
* **`globstar` / `EXTENDED_GLOB`**: Enables recursive pattern expansion (e.g. `ls **/*.js`).
* **Directory Correction**: `cdspell` in Bash and `setopt CORRECT` in Zsh to correct typos.

### Command History (`history.sh`)
* Expanded limits: **10,000 commands** in memory (`HISTSIZE`), **20,000 in file** (`HISTFILESIZE`).
* Deduplication (`erasedups`, `ignoreboth`) and common commands ignored (`HISTIGNORE`).
* Immediate append (`histappend`) and multi-terminal history synchronization.

---

## 4. System Aliases & Shortcuts (`aliases.sh`)

Provides safe and modern replacements for classic commands:

- **Safety**:
  - `rm -i`, `cp -i`, `mv -i` (interactive confirmation)
  - `--preserve-root` on `chown`, `chmod`, `chgrp`
- **Visualization** (when `eza` and `bat` are installed):
  - `ls` → `eza --icons --git --group-directories-first`
  - `cat` → `bat --paging=never`
- **Package Management (Zypper & Snapper)**:
  - `dup` / `upgrade` → `sudo zypper dup`
  - `update` → `sudo zypper refresh && sudo zypper dup`
  - `install` → `sudo zypper install`
  - `remove` → `sudo zypper remove -u`
  - `search` → `zypper search`
  - `clean` → `sudo zypper clean --all`
  - `snapshots` → `snapper list`
- **KDE Plasma & Desktop**:
  - `open` / `o` → `xdg-open`
  - `dolphin` / `files` → Opens Dolphin in current directory
  - `trash` → Trash via `kioclient6 move "$@" trash:/`
  - `clipcopy` / `clippaste` → Native Wayland clipboard (`wl-clipboard`)

---

## 5. System Functions & Utilities (`functions.sh`)

Includes helper functions for recurring tasks:

* **`extract`**: Automatically extracts compressed archives (`.tar.gz`, `.tar.bz2`, `.zip`, `.rar`, `.7z`, etc.).
* **`mkcd`**: Creates a folder and enters it immediately.
* **`up <N>`**: Navigates up `N` directory levels.
* **`duh`**: Displays folder sizes sorted by disk space.
* **Media Processing**:
  - `webm2mp4`: Converts WebM to MP4.
  - `transcode-video-1080p` / `transcode-video-4k`: Video transcoding via FFmpeg.
  - `img2jpg` / `img2png`: Image format conversion and optimization.

---

## 6. KDE Plasma 6 Settings (`kde_settings.sh`)

Provides desktop settings and shortcuts for **KDE Plasma 6 (Wayland)**:

- **Desktop Shell Management**: `plasma-restart`, `kwin-restart`.
- **Dark and Light Themes**: `kde-theme-dark` (Breeze Dark), `kde-theme-light` (Breeze Light).
- **System Settings Modules (KCM)**: Direct shortcuts to configuration panels:
  - `kde-settings` (General settings)
  - `kde-conf-display` (KScreen)
  - `kde-conf-audio` (Audio and volume)
  - `kde-conf-bluetooth` (Bluetooth)
  - `kde-conf-power` (PowerDevil / Energy management)
  - `kde-conf-shortcuts` (KWin keyboard shortcuts)
  - `kde-conf-touchpad` (Touchpad)
  - `kde-conf-appearance` (Look and feel)
- **Night Color**: `kde-night-light-on`, `kde-night-light-off`.
- **KDE Applications**: `dolphin`, `kate`, `kwrite`, `spectacle` (`captura`), `sysmon` (`plasma-systemmonitor`).

---

## 7. Cloud Synchronization (`rclone_aliases.sh` & `yt-dlp_aliases.sh`)

### Rclone Sync
Streamlines Google Drive and OneDrive sync tasks:
- `rclone-documentos`: Sync local → cloud
- `rclone-videos-down`: Download media from cloud
- `rclone-onedrive-down`: Download from OneDrive

### yt-dlp Downloads
- `ytvideo <URL>`: Download 1080p video
- `ytaudio <URL>`: Download and convert to MP3
- `ytlista <URL>`: Download complete playlists
- `ytdl-subs <URL>`: Download with Spanish subtitles

---

## 8. Rootless Container Functions (`podman-functions.sh`)

Aliases and functions for Podman and Quadlets:

- `p` → `podman`
- `pps` → `podman ps` with formatted table
- `pexec <container>`: Execute commands inside a container
- `plogs <container>`: View live logs
- `pinfo <container>`: Inspect container
- `pclean-total`: Deep clean unused container resources
- **Quadlets**:
  - `quadlet-reload`: `systemctl --user daemon-reload`
  - `quadlet-status`: Status of container-* services
  - `quadlet-logs <service>`: Quadlet service logs
