---
sidebar_position: 3
---

# Modular Bash Configuration (Soplos Linux Tyson)

This guide details the modular terminal environment (Bash) and utilities included in `Bash.Setup` for **Soplos Linux Tyson** (Debian Testing + KDE Plasma 6 + systemd + dracut + Podman).

---

## 1. Modular Loading

Scripts are dynamically loaded by adding this block to `~/.bashrc`:

```bash
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Create the symlinks with:
```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/SoplosLinuxTyson/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Modules Overview

- **`aliases.sh`**: APT package management, `systemd` (`sc`, `scu`), `dracut` (`dracut-rebuild`), kernel checker (`check-kernel`), and modern Rust CLI tools (`eza`, `bat`, `duf`, `dust`, `procs`).
- **`functions.sh`**: Swiss army knife utilities: `mkcd`, `up`, universal extraction (`extract` with `zstd`/`xz`), safe backup, guarded `iso2sd` ISO burning, and FFmpeg/ImageMagick helpers.
- **`podman-functions.sh`**: Podman container shortcuts (`psh`, `plogs`, `pstats`, `pclean`) and Podman Quadlet reload support.
- **`kde_settings.sh`**: KDE Plasma 6 desktop integrations (`plasma-restart`, `kwin-restart`, `kde-night-light-*`, `plasma-info`).
- **`history.sh`**: 10k/20k history with instant multi-terminal synchronization (`history -a`).
- **`environment.sh`**: Global variables, deduplicated `$PATH` additions, GPG support, and `mise` integration.
- **`options.sh`**: Shell options (`autocd`, `globstar`, `cdspell`, `dirspell`, case-insensitive completion).
- **`rclone_aliases.sh`**: Bidirectional sync and dry-runs for Google Drive and OneDrive.
- **`yt-dlp_aliases.sh`**: Optimized video/audio downloads with JS runtime auto-detection and browser cookies extraction.

