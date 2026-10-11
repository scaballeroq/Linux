---

# Complete Guide to GNOME Shell Extensions

This guide details the set of **12 GNOME Shell extensions** and auxiliary tools automatically installed and configured via the [`Setup/gnome-extensions.sh`](file:///home/caballero/Workspace/Repositorios/Linux/ManjaroTesting/Setup/gnome-extensions.sh) script and the `just extensions` command.

The goal of this selection is to optimize the GNOME desktop environment in Manjaro Linux (Trixie), combining **advanced window management**, **productivity enhancements**, **system tray support**, and **modern visual aesthetics** (glassmorphism/blur, dynamic wallpapers, and audio panel), with **Dash to Dock** as the primary native dock.

---

## 🛠️ Management Tools & Infrastructure

Before installing extensions, the setup script deploys baseline support to ensure clean integration without schema compilation errors or compatibility glitches:

| Tool | Type | Description |
| :--- | :--- | :--- |
| **`gnome-browser-connector`** | APT Package | Native connector enabling extension installation and management directly from [extensions.gnome.org](https://extensions.gnome.org/). |
| **`extension-manager`** | GTK4/Adwaita App | Native graphical application to search, install, update, and configure GNOME extensions without requiring a web browser. |
| **`gnome-extensions-cli` (`gext`)** | CLI Tool (Python/pipx) | Command-line utility used by setup scripts for automated batch installation via official APIs. |
| **`glib-compile-schemas`** | GSettings Compiler | Automatically compiles GSettings schemas into `~/.local/share/gnome-shell/extensions/<UUID>/schemas`, preventing `Disabled` or `Error` states. |

---

## 🧩 Extension Catalog (12 Extensions)

---

### 1. Window & Workspace Management

#### 🪟 Tiling Shell
* **ID / UUID**: `7065` | `tilingshell@ferrarodomenico.com`
* **Link**: [extensions.gnome.org/extension/7065/tiling-shell](https://extensions.gnome.org/extension/7065/tiling-shell/)
* **Description**: Advanced window tiling manager inspired by Windows 11 **FancyZones**. Allows custom screen grids and snapping windows using hotkeys or mouse dragging.
* **Key Features**:
  - Automatic and assisted window snapping (Snap Assistant).
  - Custom user-defined grid layouts.
  - Independent multi-monitor support.
  - Keyboard shortcuts to swap and move windows across zones.

#### ⚓ Dash to Dock (Primary Dock)
* **ID / UUID**: `307` | `dash-to-dock@micxgx.gmail.com`
* **Link**: [extensions.gnome.org/extension/307/dash-to-dock](https://extensions.gnome.org/extension/307/dash-to-dock/)
* **Description**: Transforms the GNOME Overview dash into a persistent dock placed on the desktop as the primary launcher.
* **Key Features**:
  - Flexible positioning on any screen edge (bottom, left, right, top).
  - Intelligent autohide capabilities.
  - Window counter badges and notification indicators.
  - Customizable icon sizing, opacity, and color themes.

#### 🖥️ Desktop Icons NG (DING)
* **ID / UUID**: `2087` | `ding@rastersoft.com`
* **Link**: [extensions.gnome.org/extension/2087/desktop-icons-ng-ding](https://extensions.gnome.org/extension/2087/desktop-icons-ng-ding/)
* **Description**: Enhanced desktop icons extension providing native file, folder, and launcher management on the GNOME desktop.
* **Key Features**:
  - Native drag-and-drop support with Nautilus file manager.
  - Desktop right-click context menu.
  - Thumbnail previews for images, PDFs, and media files.

#### 🔄 Coverflow Alt-Tab
* **ID / UUID**: `97` | `CoverflowAltTab@palatis.blogspot.com`
* **Link**: [extensions.gnome.org/extension/97/coverflow-alt-tab](https://extensions.gnome.org/extension/97/coverflow-alt-tab/)
* **Description**: Replaces standard `Alt + Tab` switcher with a 3D **Cover Flow** animation displaying live window previews.
* **Key Features**:
  - Smooth application switching with full window previews.
  - Customizable switcher animations (Cover Flow or Timeline).
  - Window filtering by workspace or display.

---

### 2. Productivity & Workflow

#### 📋 Clipboard Indicator
* **ID / UUID**: `779` | `clipboard-indicator@tudmotu.com`
* **Link**: [extensions.gnome.org/extension/779/clipboard-indicator](https://extensions.gnome.org/extension/779/clipboard-indicator/)
* **Description**: The most popular clipboard manager for GNOME, accessible via top bar icon.
* **Key Features**:
  - Configurable copy history size (up to hundreds of entries).
  - Instant text search across saved clips.
  - Pinning favorite snippets for quick access.
  - Privacy mode and customizable shortcuts.

#### ☕ Caffeine
* **ID / UUID**: `517` | `caffeine@patapon.info`
* **Link**: [extensions.gnome.org/extension/517/caffeine](https://extensions.gnome.org/extension/517/caffeine/)
* **Description**: Top bar toggle preventing screensaver activation and auto-suspend during tasks.
* **Key Features**:
  - One-click manual activation toggle.
  - Automatic activation when fullscreen applications (videos, games, slides) are detected.

#### 🔒 Lock Keys
* **ID / UUID**: `36` | `lockkeys@vaina.lt`
* **Link**: [extensions.gnome.org/extension/36/lock-keys](https://extensions.gnome.org/extension/36/lock-keys/)
* **Description**: Status panel indicator displaying **Num Lock** and **Caps Lock** states.
* **Key Features**:
  - Real-time status icons in the top bar.
  - On-Screen Display (OSD) notifications upon key toggle.

---

### 3. System Integration & Audio

#### 🔔 AppIndicator and KStatusNotifierItem Support
* **ID / UUID**: `615` | `appindicatorsupport@rgcjonas.gmail.com`
* **Link**: [extensions.gnome.org/extension/615/appindicator-support](https://extensions.gnome.org/extension/615/appindicator-support/)
* **Description**: Adds tray icon support for applications using AppIndicator or KStatusNotifierItem standards.
* **Key Features**:
  - View and interact with background apps like Telegram, Steam, Discord, Dropbox, VS Code, and Spotify.
  - Full right-click context menu support for tray icons.

#### 🔊 Quick Settings Audio Panel
* **ID / UUID**: `5940` | `quick-settings-audio-panel@rayzeq.github.io`
* **Link**: [extensions.gnome.org/extension/5940/quick-settings-audio-panel](https://extensions.gnome.org/extension/5940/quick-settings-audio-panel/)
* **Description**: Extends GNOME Quick Settings with per-app audio controls and media players.
* **Key Features**:
  - Per-application volume control mixer (Stream Mixer).
  - Quick output/input device selector (speakers, headsets, microphones).
  - Integrated media playback controls.

---

### 4. Aesthetics & Visual Customization

#### 🧊 Blur my Shell
* **ID / UUID**: `3193` | `blur-my-shell@aunetx`
* **Link**: [extensions.gnome.org/extension/3193/blur-my-shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)
* **Description**: Adds glassmorphism blur effects to GNOME Shell UI elements.
* **Key Features**:
  - Blurs top panel, Overview background, Dash, app windows, and terminal background.
  - Optimized for smooth 60 FPS / 120 FPS performance.
  - Fine-grained control over blur radius, brightness, and noise.

#### 🖼️ Bing Wallpaper
* **ID / UUID**: `1262` | `BingWallpaper@ineffable-gmail.com`
* **Link**: [extensions.gnome.org/extension/1262/bing-wallpaper-changer](https://extensions.gnome.org/extension/1262/bing-wallpaper-changer/)
* **Description**: Automatically synchronizes desktop wallpaper and lock screen with Microsoft Bing's daily UHD image.
* **Key Features**:
  - Daily automatic fetch with zero background overhead.
  - Displays image title, story, and location info.
  - Allows cycling or browsing previously downloaded wallpapers.

#### 📐 Status Area Horizontal Spacing
* **ID / UUID**: `355` | `status-area-horizontal-spacing@mathematical.coffee.gmail.com`
* **Link**: [extensions.gnome.org/extension/355/status-area-horizontal-spacing](https://extensions.gnome.org/extension/355/status-area-horizontal-spacing/)
* **Description**: Adjusts horizontal padding between top bar status icons.
* **Key Features**:
  - Compact spacing allows more system monitors and status indicators to fit comfortably in the panel.

---

## 🚀 Quick Management Commands

Install all extensions automatically:

```bash
just extensions
# Or execute script:
./Setup/gnome-extensions.sh
```

### Useful CLI Commands

- **List installed extensions**:
  ```bash
  gnome-extensions list
  ```
- **Enable / Disable extension**:
  ```bash
  gnome-extensions enable <UUID>
  gnome-extensions disable <UUID>
  ```
- **Open extension preferences**:
  ```bash
  gnome-extensions prefs <UUID>
  ```
- **Open GUI Extension Manager**:
  ```bash
  extension-manager
  ```
