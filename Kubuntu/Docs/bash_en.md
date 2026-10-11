---
sidebar_position: 3
---

# Bash Configuration in Kubuntu (KDE Plasma)

This guide details the terminal environment (Bash) and integrated utilities within the modular scripts located in `Bash.Setup`.

Modular loading is structured through `~/.bashrc.d/` to keep `~/.bashrc` clean and maintainable.

---

## 1. Modular Loading

Scripts are dynamically sourced by adding the following snippet to `~/.bashrc`:

```bash
# Modular bashrc loader
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Enable them by creating symlinks in `~/.bashrc.d/`:
```bash
mkdir -p ~/.bashrc.d
ln -s ~/Workspace/Repositorios/Kubuntu/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Environment Variables (`environment.sh`)

Sets global configurations:
- **Default Editor**: Sets `nvim` (Neovim) or `nano`.
- **Path Extensions**: Adds `~/.local/bin`, `~/bin`, `~/.cargo/bin`, and `~/.local/share/mise/shims`.
- **Terminal Pagination**: Colorizes and styles `less` and `man` pages.

---

## 3. Shell Behavior (`options.sh` & `history.sh`)

- **Options**: `autocd`, `globstar` (recursive `**`), `cdspell`, `dirspell`, `checkwinsize`.
- **History**: 10,000 commands in RAM, 20,000 in file, ignores duplicates and common commands, timestamps formatted.

---

## 4. Aliases (`aliases.sh`)

- **Safety**: `rm -i`, `cp -i`, `mv -i`, `--preserve-root`.
- **Modern Tools**: `eza` for `ls`, `bat` for `cat`/`less`, `duf` for `df`, `dust` for `du`, `procs` for `ps`, `btm` for `top`.
- **Virtualization**: `vms`, `vmstart`, `vmstop`, `vminfo`.
- **Fast Navigation**: `..`, `...`, `....`, `repo`.

---

## 5. Shell Functions (`functions.sh`)

- **`extract`**: Universal archive extraction (`.zip`, `.tar.gz`, `.bz2`, `.rar`, `.7z`, `.tar.zst`).
- **`mkcd`**: Make directory and enter.
- **`up <N>`**: Move up N parent directories.
- **`backup`**: Fast timestamped copy (`.bak_YYYYMMDD_HHMMSS`).
- **`duh`**: Top largest directories.
- **`iso2sd`**: Guided ISO burning tool.
- **`format-drive`**: Guided formatting for FAT32, NTFS, EXT4, EXFAT.
- **Multimedia**: `webm2mp4`, `transcode-video-1080p`, `img2jpg`, `img2png`.

---

## 6. Cloud & Download Aliases (`rclone_aliases.sh` & `yt-dlp_aliases.sh`)

- **Rclone**: `sync`, `copy`, and `--dry-run` modes for Google Drive and OneDrive with `--tpslimit 10` and `--fast-list`.
- **yt-dlp**: `ytvideo`, `ytaudio`, `ytlista`, `ytlista-audio`.

---

## 7. Desktop Settings (`desktop_settings.sh`)

Applies configurations for KDE Plasma 6 / 5 and GNOME:
- **KDE Plasma**: Night Color (`kde-night-light-on/off`), theme switcher (`kde-theme-dark/light`), system settings (`kde-conf`), KWin reconfigure (`kde-restart-kwin`).

---

## 8. Podman Functions (`podman-functions.sh`)

Safe non-colliding Podman management:
- `psh <container>`, `plogs <container>`, `ppsf`, `pstats`, `pclean`, `pclean-all`.
