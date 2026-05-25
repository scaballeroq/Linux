---
sidebar_position: 3
---

# Bash Configuration on Kubuntu

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
ln -s /home/caballero/Workspace/Repositorios/Kubuntu/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Environment Variables (`environment.sh`)

Defines global settings and performance optimizations for system tools:

- **Default Editor**: Sets `nvim` (Neovim) as the global editor.
- **Executable Paths (`PATH`)**: Adds local user directories to the environment path:
  - `~/.local/bin`
  - `~/bin`
  - Cargo/Rust bin directory (`~/.cargo/bin`)
- **Aesthetic Pager (`less` and `man`)**: Configures custom colors and flags to make Linux manual pages (`man`) and text viewing with `less` more readable.

---

## 3. Bash Behavior (`options.sh` and `history.sh`)

Optimizes shell interaction through internal adjustments.

### Advanced Shell Behavior (`options.sh`)
* **`autocd`**: Allows changing directories by typing the path directly (without prefixing `cd`).
* **`globstar`**: Enables recursive globbing pattern expansions (e.g. `ls **/*.js`).
* **Directory Typo Correction**: Enables `cdspell` and `dirspell` to automatically fix minor typos when entering folder names.

### Command History (`history.sh`)
* Expanded capacity of up to **10,000 commands** in memory and **20,000 in history file**.
* Ignores duplicates and common commands (`history -a`, `histignore`).
* Writes commands to the history file immediately after execution.

---

## 4. System Shortcuts & Aliases (`aliases.sh`)

Replaces standard commands with enriched and safe alternatives:

- **Security**:
  - `rm -i` (prompt before deletion)
  - `cp -i` (prompt before overwrite when copying)
  - `mv -i` (prompt before overwrite when moving)
  - Defensive `--preserve-root` flag enabled by default.
- **File Visualization** (if `eza` and `bat` are installed):
  - `ls` mapped to `eza` with icons and a clean structure.
  - `cat` mapped to `bat` with syntax highlighting.
- **Quick Navigation**:
  - `..`, `...`, `....` to step up directories quickly.
  - `c` to clear the screen (`clear`).
  - `path` to list PATH directories on individual lines.

---

## 5. System Functions & Utilities (`functions.sh`)

Includes helper shell functions to simplify recurring tasks:

* **`extract`**: Automatically extracts almost any compressed file format (`.zip`, `.tar.gz`, `.bz2`, `.rar`, etc.) without needing to recall specific decompression flags.
* **`mkcd`**: Creates a folder and immediately changes into it with a single command.
* **`up <N>`**: Steps up `N` directory levels easily (e.g. `up 3`).
* **`duh`**: Displays folder sizes in the current directory, sorted by weight on disk.
* **Multimedia Processing**:
  - `webm2mp4`: Converts WebM screen recordings (common in GNOME) to standard MP4 files.
  - `img2jpg` / `img2png`: Rapidly converts and optimizes image formats via console.

---

## 6. Cloud Sync and Downloads (`rclone_aliases.sh` and `yt-dlp_aliases.sh`)

Automates remote storage synchronization and media downloads.

### Rclone Synchronization
Facilita cloud syncing (bidirectional or copy) with services like Google Drive using controlled transaction limits to avoid API throttling:
- `rclone-documentos`: Synchronizes local -> cloud.
- `rclone-videos-down`: Downloads media files from the cloud to the local machine.

### yt-dlp Downloads
Utilities to automate media extraction:
- `ytvideo <URL>`: Downloads video in optimal quality (1080p).
- `ytaudio <URL>`: Downloads and converts stream to high-fidelity MP3.
- `ytlista-audio <URL>`: Downloads complete playlists converted to MP3.

## 7. Desktop Environment (`desktop_settings.sh`)

Applies settings and defines automated shortcuts/aliases detecting the active desktop environment (KDE Plasma or GNOME):
- **KDE Plasma**: Configures Night Color and prevents system suspend on AC power using `kwriteconfig5`/`kwriteconfig6`, and adds aliases for Night Color toggles and theme switches.
- **GNOME**: Configures Night Light, 24h clock format, battery percentage visibility, and window control buttons using `gsettings`.

---

## 8. Container Functions (`podman-functions.sh`)

Aliases and helper functions that simplify container and Podman Pod operations:
- `psh <container>`: Opens an interactive shell inside the specified container.
- `plogs <container>`: Follows container logs in real time.
- `pclean`: Performs a complete system purge of unused containers and images.
