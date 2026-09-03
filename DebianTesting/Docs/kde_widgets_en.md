---
sidebar_position: 10
---

# Complete Guide to Widgets, Klipper, and KDE Plasma 6 Customization

This guide details the ecosystem of **Widgets (Plasmoids)**, **KWin Scripts**, **Klipper**, and auxiliary tools automatically configured in **KDEDebian** via the [`Setup/kde-widgets.sh`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebian/Setup/kde-widgets.sh) script and the `just widgets` command.

KDE Plasma 6 on Debian Testing (Trixie) provides a high-performance modular architecture where advanced capabilities (clipboard manager, system resource monitors, dynamic daily wallpapers, per-application audio stream mixer, and window tiling) are natively integrated.

---

## 🛠️ Management & Infrastructure Tools

| Tool / Module | Type | Description |
| :--- | :--- | :--- |
| **`kdeplasma-addons`** | APT Package | Official collection of plasmoids, applets, and UI components for KDE Plasma. |
| **`plasma-systemmonitor`** | Qt6 Application | Modern real-time monitoring suite for CPU, RAM, disks, network, and thermal sensors. |
| **`kwriteconfig6` / `kwriteconfig5`** | CLI Tool | Official KDE utility to modify configuration parameters atomically in `~/.config/`. |
| **`plasma-apply-colorscheme`** | CLI Tool | Instantly applies color schemes (e.g. BreezeDark) across all Qt applications. |

---

## 🧩 Key Features & Plasmoids in KDE Plasma 6

---

### 1. Window & Workspace Management

#### 🪟 Quick Tile & Native KWin Tiling
* **Shortcuts**: `Meta + Arrow keys` (Halves and quadrants) | `Meta + T` (Visual Tile Layout Editor in Plasma 6)
* **Description**: Snap windows into configurable grids and zones without relying on fragile third-party extensions.
* **Key Features**:
  - Interactive grid editor opened with `Meta + T`.
  - Independent multi-monitor and native Wayland support.
  - Compatible with advanced KWin tiling scripts (Polonium / Bismuth / Krohnkite).

#### ⚓ Floating Panel & Icons-Only Task Manager
* **Component**: `org.kde.plasma.icontasks`
* **Description**: Modern floating taskbar with hover thumbnail previews, badge counts, and pin functionality.
* **Key Features**:
  - Smart autohide (Dodge Windows / Always Visible).
  - Clean application grouping with right-click jump lists.

#### 🔄 Window Switcher & Overview
* **Shortcuts**: `Meta + W` (Overview) | `Meta + G` (Grid View) | `Alt + Tab` (Task Switcher)
* **Description**: Panoramic views of all virtual desktops and active windows rendered at 60/120 FPS.

---

### 2. Productivity & Workflow

#### 📋 Klipper: Advanced Clipboard Manager
* **Shortcut**: `Meta + V` or `Ctrl + Alt + V`
* **Description**: Native Linux clipboard manager integrated into the system tray.
* **Key Features**:
  - Persistent history (up to 100+ items, text, URLs, code snippets).
  - Real-time instant search in clipboard entries.
  - Automatic regex actions (generate QR codes, open URLs).

#### ☕ Inhibit Sleep (Native Caffeine)
* **Component**: Battery & Brightness Applet (`org.kde.plasma.battery`)
* **Description**: Manually block screen dimming and sleep with a single click in the system tray.

#### 🔒 Lock Keys Indicator
* **Component**: `org.kde.plasma.lockkeys`
* **Description**: OSD notifications and tray indicators when Caps Lock or Num Lock is active.

---

### 3. Monitoring & System

#### 📊 Plasma System Monitor Applets
* **Components**: `org.kde.plasma.systemmonitor.*`
* **Description**: Tray and desktop widgets displaying CPU, RAM, NVMe I/O, and network transfer speeds.

#### 🔔 Native SNI / AppIndicator Support
* **Component**: `org.kde.plasma.systemtray`
* **Description**: First-class support for background applications like Telegram, Steam, Discord, VS Code, and Spotify.

#### 🔊 Per-App Audio Mixer (Plasma-PA)
* **Component**: `org.kde.plasma.volume`
* **Description**: Per-stream volume control, audio device switching, and PipeWire integration.

---

### 4. Visual Aesthetics & Dynamic Wallpapers

#### 🖼️ Picture of the Day (Bing / NASA APOD / Unsplash)
* **Component**: Native KDE Wallpaper Plugin
* **Description**: Automatically updates desktop and lock screen backgrounds with daily 4K/UHD photography.

#### 🧊 KWin Effects (Blur & Translucency)
* **Component**: KWin Compositor
* **Description**: Frosted glass effects applied across Konsole, panels, contextual menus, and window frames.

---

## 🚀 Commands Summary

```bash
just widgets
# Or directly:
./Setup/kde-widgets.sh
```
