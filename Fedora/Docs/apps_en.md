---
sidebar_position: 9
---

# Desktop Applications & User Tools on Fedora 44 (KDE Plasma 6)

This guide details the primary desktop applications, multimedia tools, and package formats integrated into the **Fedora 44 Workstation** environment with **KDE Plasma 6**.

---

## 1. KDE Plasma Native Suite

The system includes native, optimized KDE tools:
- **Dolphin**: High-performance file manager with Kitty terminal integration (*Open in Kitty*), media previews, and Git integration.
- **Kate / KWrite**: Advanced text editors with syntax highlighting and project support.
- **Spectacle**: Wayland screenshot and screen recording tool linked to console shortcuts `captura` and `grabacion`.
- **Ark**: Archiver for compressing and extracting 7z, tar, zip, rar, and zstd formats.
- **Plasma System Monitor**: Resource monitor tracking GPU, CPU, and RAM metrics.
- **KCalc**: Scientific and developer calculator.

---

## 2. Media Center & Streaming (`kodi`)

For desktop workstations dedicated to home theater and multimedia streaming:
- **Kodi**: Media player platform with VA-API hardware acceleration.
- **Plugins**: `kodi-inputstream-adaptive` (streaming playback), `kodi-inputstream-rtmp`, and `kodi-pvr-iptvsimple`.

Quick installation:
```bash
just kodi
# or sudo dnf5 install -y kodi kodi-inputstream-adaptive kodi-inputstream-rtmp kodi-pvr-iptvsimple
```

---

## 3. Visual Diff & Merge Tool (`meld`)

Meld is a visual diff tool for comparing files, directories, and Git version control branches:

```bash
sudo dnf5 install -y meld
```

---

## 4. Universal Packages (Flatpak & Flathub)

The system comes preconfigured with the global **Flathub** remote repository to deploy sandboxed third-party applications and gaming tools:

```bash
# Search apps on Flathub:
flatpak search <name>

# Install application:
flatpak install flathub <app_id>
```
