---
sidebar_position: 3
---

# Modular Bash Configuration on Fedora 44 (KDE Plasma 6)

This guide details the modular terminal setup and utilities located in `Bash.Setup`, fully optimized for **Fedora 44** with **KDE Plasma 6** and **Wayland**.

---

## 1. Modular Environment Loading (`~/.bashrc.d`)

Fedora natively supports modular script loading from `~/.bashrc.d`. To link all configuration modules:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Fedora/Bash.Setup/*.sh ~/.bashrc.d/
```

Scripts will be automatically sourced in order whenever an interactive terminal is opened.

---

## 2. System Aliases & Modern Tools (`aliases.sh`)

Replaces standard commands with feature-rich, safer alternatives:

### 📦 DNF5 Package Management Aliases
- `update` -> `sudo dnf5 update` (check and apply upgrades).
- `upgrade` -> `sudo dnf5 upgrade -y` (automated non-interactive upgrade).
- `install` -> `sudo dnf5 install`
- `remove` -> `sudo dnf5 remove`
- `search` -> `dnf5 search`
- `clean` -> `sudo dnf5 autoremove -y && sudo dnf5 clean all`
- `list` -> `dnf5 list --upgradable`
- `pkg-info` -> `dnf5 info`
- `pkg-history` -> `dnf5 history`

### 🎨 KDE Plasma 6 & Wayland Integration
- `dolphin`: Opens Dolphin file manager in the background at current directory.
- `open` / `o`: Opens any file using default desktop handler (`xdg-open`).
- `trash`: Safely moves files to trash (`gio trash`).
- `clipcopy` / `clippaste`: Wayland clipboard integration (`wl-copy` / `wl-paste`).
- `plasma-restart`: Restarts KDE Plasma shell under systemd.
- `kwin-reload`: Hot-reloads KWin compositor configuration.

### 🦀 Modern Rust CLI Tools
- `ls` / `ll` / `la` / `lt` -> `eza` (with icons, Git status, and semantic colors).
- `cat` -> `bat` (with syntax highlighting and pagination).
- `grep` -> `ripgrep` (`rg`).
- `df` -> `duf` (clean mount point and disk partition viewer).
- `du` -> `dust` (graphical tree-based disk usage analyzer).
- `ps` -> `procs` (process tree and monitor).
- `top` / `htop` -> `btop` (resource monitor with GPU/CPU/RAM support).
- `cd` -> `zoxide` (`z` / `zi`).

### 🛡️ Safety
- `rm -i`, `cp -i`, `mv -i` (interactive confirmation against accidental data loss).
- `--preserve-root` flag enabled on destructive operations.

---

## 3. KDE Plasma 6 Environment Manager (`kde_settings.sh`)

Interactive CLI tool to manage desktop settings and quick shortcuts to System Settings modules (`kcmshell6`):

```bash
# Check KDE environment status:
./Bash.Setup/kde_settings.sh status

# Apply recommended KWin, Dolphin, and shortcut optimizations:
./Bash.Setup/kde_settings.sh apply

# Backup KDE configuration:
./Bash.Setup/kde_settings.sh backup

# Restore KDE configuration:
./Bash.Setup/kde_settings.sh restore
```

Direct console shortcuts included:
- `kde-pantallas`, `kde-audio`, `kde-wifi`, `kde-bluetooth`, `kde-touchpad`, `kde-energia`, `kde-atajos`.
- `captura` / `grabacion`: Instant screenshots and screen recording via Spectacle.
- `kde-theme-dark` / `kde-theme-light`: Fast visual theme switching.

---

## 4. Environment Variables & Session (`environment.sh`)

Defines system-wide session variables:
- `EDITOR="nvim"` and `VISUAL="nvim"`.
- Native Wayland flags for Qt and Electron: `QT_QPA_PLATFORM="wayland;xcb"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- `PATH`: Includes `~/.local/bin`, `~/.cargo/bin`, `~/.local/share/mise/shims`, and Go binaries.
- `DOCKER_HOST`: Rootless Podman user socket (`/run/user/$UID/podman/podman.sock`).
- `GPG_TTY`: GPG key signing integration for Git commits.

---

## 5. Advanced Functions & Utilities (`functions.sh`)

- `extract <file>`: Universal smart archive extraction (`.tar.gz`, `.tar.xz`, `.zip`, `.7z`, `.tar.zst`, `.rar`, etc.).
- `mkcd <dir>`: Creates directory and switches to it automatically.
- `myip`: Displays public IP and active local network interface.
- `ports`: Lists listening TCP/UDP sockets and associated processes (`ss -tulpn`).
- `webm2mp4`: Converts WebM screen recordings to H.264 MP4 videos.
- `img2jpg` / `img2png`: Batch image conversions and optimization.
- `transcode-video-1080p` / `transcode-video-4K`: High-efficiency video transcoding via FFmpeg.

---

## 6. Podman Containers & Quadlets (`podman-functions.sh`)

- `pps`: Clean tabular container list.
- `pexec <container> [cmd]`: Runs commands or interactive shell inside container.
- `plogs <container> [lines]`: Streams live container logs.
- `pclean-total`: Deep cleanup of stopped containers, dangling images, and unused networks.
- `quadlet-reload` / `quadlet-status` / `quadlet-logs`: Direct management of user Systemd Quadlets.

---

## 7. Cloud Synchronization (`rclone_aliases.sh`)

- `gdrive-software`: Two-way sync for software installers and tools.
- `gdrive-kdenlive`: Video projects and media asset synchronization.
- `gdrive-images`: Picture and screenshot sync.
- `gdrive-repos`: Code repository cloud backup.
- `gdrive-check-all`: Integrity verification for Google Drive remotes.
- `onedrive-get`: Downloads synced OneDrive folders.

---

## 8. YT-DLP Multimedia Downloads (`yt-dlp_aliases.sh`)

- `ytdl <url>`: Downloads best MP4 video (up to 1080p).
- `ytdl-audio <url>`: Extracts and converts to high-quality MP3 (320k) with cover art and tags.
- `ytdl-best <url>`: Downloads highest available resolution (4K/2K/1080p).
- `ytdl-playlist <url>`: Downloads entire playlists indexed by number and title.
- `ytdl-update`: Updates yt-dlp binary to the latest release.
