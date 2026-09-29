---
sidebar_position: 9
---

# Applications and Gaming on Debian Testing (KDE Plasma 6)

This guide details the desktop application suite, visual utilities, and gaming platforms configured in the `Setup` and `Juegos` directories.

---

## 1. KDE Plasma 6 Native Suite

Debian Testing (Trixie/Sid) incorporates the full KDE Gear suite and KDE Plasma 6 applications:

- **Dolphin**: Fast file manager with details view by default and KIO contextual actions for Kitty and Google Antigravity.
- **Kate & KWrite**: Advanced text editors with syntax highlighting and embedded terminal.
- **Spectacle**: Screenshot and region screen recorder for Wayland (shortcut `Print Screen` or command `captura`).
- **Okular**: Universal document viewer (PDF, ePub, Markdown).
- **Gwenview**: Optimized image viewer.
- **Ark**: Archive manager supporting multiple formats (`tar`, `zip`, `7z`, `rar`).
- **KCalc**: Scientific precision calculator.
- **Discover**: Integrated software center with Flathub backend enabled (`plasma-discover-backend-flatpak`).

---

## 2. Google Chrome Browser (`chrome.sh`)

Installs the official stable release of Google Chrome with an official Google signed repository (dearmored key in `/etc/apt/keyrings/google-chrome.gpg` and `/etc/apt/sources.list.d/google-chrome.list`):

```bash
just chrome
# or ./Setup/chrome.sh
```

Repository and binary diagnostics:
```bash
./Setup/chrome.sh --status
```

---

## 3. Steam, Gaming Performance and Proton (`steam.sh`)

Configures native gaming workstation with hardware acceleration:

- **Native Steam**: Official package via multiarch (`dpkg --add-architecture i386`), 32-bit Vulkan drivers (`mesa-vulkan-drivers:i386`, `libgl1-mesa-dri:i386`).
- **Performance Optimizers**: GameMode (`gamemoderun`) and MangoHud for real-time overlay metrics of FPS, temperatures, and GPU usage.
- **Proton-GE**: GloriousEggroll compatibility layer for maximum Windows game compatibility (`com.valvesoftware.Steam.CompatibilityTool.Proton-GE`).

```bash
just steam
# or ./Setup/steam.sh
```

---

## 4. Kodi Media Center (`kodi`)

Transforms your desktop into a high-fidelity Media Center:

- Official `kodi` package with VA-API hardware acceleration.
- Streaming plugins: `kodi-inputstream-adaptive`, `kodi-inputstream-rtmp`, `kodi-pvr-iptvsimple`.

```bash
just kodi
```

---

## 5. Meld: Visual Diff and Merge Tool

Graphical tool for Git merge conflict resolution and directory comparisons:

```bash
sudo apt update && sudo apt install -y meld
```

---

## 6. Decoupled Desktop Applications via Flatpak (`flatpak.sh`)

To keep the Debian Testing base system 100% clean and avoid third-party repository breakages (such as deb-multimedia), multimedia applications and productivity tools run isolated on standardized **Flathub** runtimes:

- **Management & Containers**:
  - `Flatseal` (`com.github.tchx84.Flatseal`): Granular GUI permissions manager for sandboxes.
  - `Podman Desktop` (`io.podman_desktop.PodmanDesktop`): Visual GUI for containers, pods, and rootless Quadlet services.
  - `Warehouse` (`io.github.flattool.Warehouse`): Flatpak manager, properties inspector, and orphan data cleaner.
- **Multimedia & Creation**:
  - `VLC Media Player` (`org.videolan.VLC`): Universal player.
  - `Celluloid` (`io.github.celluloid_player.Celluloid`): MPV-based hardware accelerated player.
  - `OBS Studio` (`com.obsproject.Studio`): Recording and streaming with native Wayland/PipeWire support.
  - `Kdenlive` (`org.kde.kdenlive`): Non-linear video editor.
  - `Kodi` (`tv.kodi.Kodi`): Media center.
  - `Stremio` (`com.stremio.Stremio`): Streaming content aggregator.
  - `Spotify` (`com.spotify.Client`): Music streaming client.
  - `Audacity` (`org.audacityteam.Audacity`): Multi-track audio recorder and editor.
- **Development & Database**:
  - `Bruno` (`com.usebruno.Bruno`): Lightweight, offline Git-versionable REST & GraphQL API client.
  - `DBeaver Community` (`io.dbeaver.DBeaverCommunity`): Universal database tool.
- **Productivity & Backup**:
  - `LibreOffice` (`org.libreoffice.LibreOffice`): Full office suite.
  - `Obsidian` (`md.obsidian.Obsidian`): Knowledge base and Markdown note vault.
  - `LocalSend` (`org.localsend.localsend_app`): Fast and secure local network file sharing.
  - `Pika Backup` (`org.gnome.World.PikaBackup`): Encrypted deduplicated backups via BorgBackup.
- **Browsers & Privacy**:
  - `Mozilla Firefox` (`org.mozilla.firefox`): Isolated browser with full codecs.
- **Graphics**:
  - `GIMP` (`org.gimp.GIMP`), `Inkscape` (`org.inkscape.Inkscape`).
- **Communication & Gaming**:
  - `Vesktop` (`dev.vencord.Vesktop`): Wayland-optimized Discord with PipeWire screensharing.
  - `Telegram Desktop` (`org.telegram.desktop`).
  - `Proton-GE` (`com.valvesoftware.Steam.CompatibilityTool.Proton-GE`).

### Usage and Commands:

```bash
# Status and diagnostics
just flatpak-status

# Modular installation by profile
./flatpak --essential
./flatpak --multimedia
./flatpak --dev
./flatpak --productivity
./flatpak --graphics
./flatpak --comms
./flatpak --all

# Single app installation
./flatpak install bruno
./flatpak install dbeaver
./flatpak install obsidian

# Maintenance
just flatpak-update
just flatpak-clean
```

---

## Verification

- **KDE Plasma**: Launch applications from Kickoff or KRunner (`Alt+Space`).
- **Chrome**: Run `google-chrome` or verify with `./Setup/chrome.sh --status`.
- **Flatpak**: Check status with `just flatpak-status`.
- **Steam**: Open Steam and verify Steam Play / Proton in Settings.
