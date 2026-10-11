---
sidebar_position: 3
---

# Terminal and Shell Configuration on Debian Testing (Bash & Zsh)

This guide details the terminal environment configuration (optimized for **Bash** as the default project shell and compatible with **Zsh** when `~/.zshrc` is present) along with utilities integrated into the modular scripts in `Bash.Setup`.

Modular loading is structured through `~/.bashrc.d/` (default) and `~/.zshrc.d/` (compatibility) to guarantee cleanliness, performance, and maintainability.

---

## 1. Modular Environment Loading

### For Bash (Default - `~/.bashrc`)
`./Setup/shell.sh` injects the modular loader into your `~/.bashrc`:

```bash
# Modular scripts loader
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### For Zsh (Compatibility when `~/.zshrc` exists)
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
Enable all modules by running `./Setup/shell.sh` or `just shell`:
```bash
# For Bash (Default)
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/KDEDebianTesting/Bash.Setup/*.sh ~/.bashrc.d/

# For Zsh (if ~/.zshrc exists)
if [ -f "$HOME/.zshrc" ]; then
    mkdir -p ~/.zshrc.d
    ln -sf ~/Workspace/Repositorios/Linux/KDEDebianTesting/Bash.Setup/*.sh ~/.zshrc.d/
fi
```

---

## 2. Environment Variables (`environment.sh`)

- **Default Editor**: Configures `nvim` (Neovim), `kate`, or `nano` (`EDITOR`, `VISUAL`).
- **Wayland/Qt**: `QT_QPA_PLATFORM="wayland;xcb"`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- **Executable PATH**: Adds `~/.local/bin`, `~/bin`, `~/.cargo/bin`, `~/go/bin`, `~/.local/share/mise/shims`.
- **Mise**: Dynamic shell activation (`eval "$(mise activate bash --shims)"`).
- **Podman**: Rootless Docker socket (`unix:///run/user/$UID/podman/podman.sock`).
- **Paging & Colors**: Enhanced colors and flags for `less` and `man`.
- **Virtualization**: `LIBVIRT_DEFAULT_URI="qemu:///system"`.

---

## 3. Shell Behavior (`options.sh` & `history.sh`)

- **Navigation**: `autocd`, `globstar` recursive search, and directory typo correction (`cdspell` in Bash, `setopt CORRECT` in Zsh).
- **History**: Expanded 10,000 commands in memory, 20,000 on disk, deduplication (`ignoreboth`, `erasedups`), instant write (`histappend`), and shared history.

---

## 4. Aliases & Shortcuts (`aliases.sh`)

- **Safe Operations**: `rm -i`, `cp -i`, `mv -i`, `ln -i`, `mkdir -p`, `--preserve-root`.
- **APT Management**: `update`, `upgrade`, `install`, `remove`, `search`, `clean`, `list`, `installed`, `pkg-info`.
- **KDE Plasma & Desktop**: `open` (`xdg-open`), `dolphin`, `trash` (`kioclient6 move ... trash:/`), `clipcopy` / `clippaste` (`wl-clipboard`).
- **Rust Utilities**: `eza`, `bat`, `duf`, `dust`, `procs`, `btm`, `fastfetch` (`ff`).

---

## 5. Shell Functions (`functions.sh`)

- `extract`: Universal archive extractor (`.tar.*`, `.zip`, `.rar`, `.7z`).
- `mkcd`: Create directory and enter immediately.
- `up <N>`: Navigate up `N` directory levels.
- `backup`: Create quick timestamped backup (`.bak-YYYYMMDD-HHMMSS`).
- `duh`: Sort directory sizes.
- Multimedia functions: `webm2mp4`, `transcode-video-1080p`, `img2jpg`, `img2png`.

---

## 6. KDE Plasma 6 Settings (`kde_settings.sh`)

- Desktop restart: `plasma-restart`, `kwin-restart`.
- Themes: `kde-theme-dark`, `kde-theme-light`.
- KCM Settings shortcuts: `kde-settings`, `kde-conf-display`, `kde-conf-audio`, `kde-conf-power`, etc.
- Night Color: `kde-night-light-on`, `kde-night-light-off`.

---

## 7. Cloud Sync & YouTube Downloads (`rclone_aliases.sh` & `yt-dlp_aliases.sh`)

- `rclone-documentos`, `rclone-videos-down`.
- `ytvideo`, `ytaudio`, `ytlista`, `ytdl-subs`.

---

## 8. Container Functions (`podman-functions.sh`)

- `p` (`podman`), `pps` (`podman ps` formatted), `pexec`, `plogs`, `pclean-total`.
- Quadlet helpers: `quadlet-reload`, `quadlet-status`, `quadlet-logs`.
