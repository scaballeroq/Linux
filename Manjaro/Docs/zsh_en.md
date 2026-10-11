---
sidebar_position: 3
---

# ZSH Configuration and Functions in Manjaro Linux (Zsh.Setup)

Manjaro Linux ships with **ZSH** as its default interactive shell. This guide provides comprehensive documentation of the modular `Zsh.Setup` architecture, all custom functions, aliases, Manjaro/Arch-specific utilities, and shell optimizations.

---

## 1. Modular Environment Loading

The configuration modules in `Zsh.Setup/` are decoupled and loaded automatically by adding the following snippet to your `~/.zshrc`:

```zsh
# Modular Loading of Zsh.Setup (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.zsh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

## 2. Catalog of Custom Functions Adapted to Manjaro

All functions are optimized for native ZSH syntax and the Arch/Manjaro package management ecosystem (`pacman`, `pamac`, `mhwd`).

### 🐧 Manjaro System and Package Management (`functions.zsh`)

| Function | Arguments | Description & Usage |
| :--- | :--- | :--- |
| `manjaro-mirrors-fast` | None | Tests latency across all Manjaro mirrors, selects the 5 fastest, and synchronizes package databases.<br/>`manjaro-mirrors-fast` |
| `pacman-clean-all` | None | Cleans cached package files (`pacman`), cleans AUR build cache (`pamac`), and removes orphaned packages.<br/>`pacman-clean-all` |
| `aur-search` | `<term>` | Searches the Arch User Repository (AUR) via Pamac or direct RPC API lookup.<br/>`aur-search visual-studio-code-bin` |
| `pamac-build-aur` | `<package>` | Builds and installs an AUR package using Pamac.<br/>`pamac-build-aur spotify` |
| `check-kernel` | None | Queries the `kernel.org` API, checks your running kernel version (`uname -r`), and alerts you if a newer version is available to compile with `just build-kernel`.<br/>`check-kernel` |

---

### 📂 Navigation and File Management

| Function | Arguments | Description & Usage |
| :--- | :--- | :--- |
| `mkcd` | `<directory>` | Creates a directory tree (`mkdir -p`) and immediately enters it.<br/>`mkcd projects/backend/api` |
| `up` | `[levels]` | Navigates up `n` directory levels (defaults to 1 level).<br/>`up 3` (equivalent to `cd ../../..`) |
| `backup` | `<file>` | Creates an immediate timestamped backup copy (`.bak-YYYYMMDD-HHMMSS`).<br/>`backup /etc/pacman.conf` |
| `extract` | `<file>` | Universal archive extractor supporting `.tar.gz`, `.tar.bz2`, `.tar.xz`, `.tar.zst`, `.pkg.tar.zst`, `.zip`, `.rar`, `.7z`, etc.<br/>`extract package.tar.zst` |
| `compress` | `<directory>` | Compresses an entire folder into a high-compression `.tar.gz` archive.<br/>`compress my-project` |

---

### 💻 System Monitoring and Diagnostics

| Function | Arguments | Description & Usage |
| :--- | :--- | :--- |
| `psgrep` | `<name>` | Finds active processes while displaying full column headers (`USER`, `PID`, `%CPU`, `%MEM`, `VSZ`, `COMMAND`) and filtering out grep itself.<br/>`psgrep podman` |
| `duh` | `[directory]` | Displays disk usage of the current or specified path sorted from highest to lowest in human-readable format.<br/>`duh /var/log` |
| `hg` | `<query>` | Fast interactive search through ZSH command history using `fc -l 1`.<br/>`hg git commit` |

---

### 💾 Disks and Storage Media

| Function | Arguments | Description & Usage |
| :--- | :--- | :--- |
| `iso2sd` | `<iso> <device>` | Writes an ISO file to a USB/SD device using `dd` (4M buffer, `oflag=sync`) and unmounts safely.<br/>`iso2sd ~/Downloads/manjaro.iso /dev/sda` |
| `format-drive` | `<device> <label>` | Clears the drive, creates a GPT partition table, and formats the primary partition as `exFAT` (universal compatibility).<br/>`format-drive /dev/sdb 'FlashDrive'` |

---

### 🎬 Multimedia Processing

| Function | Arguments | Description & Usage |
| :--- | :--- | :--- |
| `webm2mp4` | `<file.webm>` | Converts GNOME screen recordings from WebM to MP4 using H.264 video and AAC audio.<br/>`webm2mp4 screen-recording.webm` |
| `transcode-video-1080p` | `<video>` | Re-encodes video to 1080p Full HD while maintaining original audio quality.<br/>`transcode-video-1080p video.mkv` |
| `transcode-video-4K` | `<video>` | Optimizes 4K video using the H.265 (HEVC) high-efficiency codec.<br/>`transcode-video-4K movie.mp4` |
| `img2jpg` | `<image>` | Optimizes images to high-quality JPG (95% quality) and removes unnecessary EXIF metadata.<br/>`img2jpg picture.png` |
| `img2jpg-small` | `<image>` | Resizes to 1080px max width and compresses for web sharing.<br/>`img2jpg-small banner.png` |
| `img2png` | `<image>` | Lossless maximum compression (`level 9`, `strategy 1`) for PNG assets.<br/>`img2png logo.png` |

---

### 🐳 Podman Quadlets Management (`podman-functions.zsh`)

| Function / Alias | Description |
| :--- | :--- |
| `pexec <container> [cmd]` | Spawns an interactive shell (default `bash`) in the target container. |
| `plogs <container> [n]` | Streams real-time container logs with `--tail` (default 100 lines). |
| `pinfo <container>` | Inspects complete JSON configuration via `less`. |
| `pcp <src> <dest>` | Copies files bidirectionally between host and container. |
| `pclean-total` | Full Podman system purge (`system prune -af --volumes`). |
| `prm-stopped` | Removes all stopped containers. |
| `prmi-dangling` | Removes dangling/untagged images. |
| `pstop-all` | Gracefully stops all active containers. |
