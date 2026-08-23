---

# GNOME Shell Extensions Guide

This guide details the set of **10 GNOME Shell extensions** and auxiliary tools automatically installed and configured via the [`Setup/gnome-extensions.sh`](file:///home/caballero/Workspace/Repositorios/Linux/DebianTesting/Setup/gnome-extensions.sh) script and the `just extensions` command.

The objective is to optimize the GNOME desktop environment on Debian Testing by combining **window management**, **productivity**, **system tray support**, and a **modern aesthetic** (glassmorphism/blur, daily dynamic wallpapers, and an integrated audio mixer), with **Dash to Dock** acting as the primary dock.

---

## 🛠️ Management & Infrastructure Tools

Before installing extensions, the script sets up base support tools to ensure seamless installation and avoid compilation or compatibility issues:

| Tool | Type | Description |
| :--- | :--- | :--- |
| **`gnome-browser-connector`** | APT Package | Native connector enabling extension installation directly from [extensions.gnome.org](https://extensions.gnome.org/). |
| **`extension-manager`** | GTK4/Adwaita App | Native application to search, install, update, and configure GNOME extensions without a browser. |
| **`gnome-extensions-cli` (`gext`)** | CLI Tool (Python/pipx) | Command-line utility used to install and update extensions via the official API. |
| **`glib-compile-schemas`** | GSettings Compiler | Automatically compiles GSettings schemas in `~/.local/share/gnome-shell/extensions/<UUID>/schemas`, avoiding `Disabled` or `Error` states. |

---

## 🧩 Extensions Catalog (10 Extensions)

Extensions are installed using optimal sources, combining native **Debian Testing (APT)** packages and the official **extensions.gnome.org (EGO)** repository.

| Extension | Method | Package / ID | UUID |
| :--- | :--- | :--- | :--- |
| **Dash to Dock** | 📦 Debian APT | `gnome-shell-extension-dashtodock` | `dash-to-dock@micxgx.gmail.com` |
| **Blur my Shell** | 📦 Debian APT | `gnome-shell-extension-blur-my-shell` | `blur-my-shell@aunetx` |
| **Caffeine** | 📦 Debian APT | `gnome-shell-extension-caffeine` | `caffeine@patapon.info` |
| **AppIndicator Support** | 📦 Debian APT | `gnome-shell-extension-appindicator` | `appindicatorsupport@rgcjonas.gmail.com` |
| **Bing Wallpaper** | 🌐 GNOME Extensions | ID `1262` | `BingWallpaper@ineffable-gmail.com` |
| **Lock Keys** | 🌐 GNOME Extensions | ID `36` | `lockkeys@vaina.lt` |
| **Status Area Horizontal Spacing** | 🌐 GNOME Extensions | ID `355` | `status-area-horizontal-spacing@mathematical.coffee.gmail.com` |
| **Quick Settings Audio Panel** | 🌐 GNOME Extensions | ID `5940` | `quick-settings-audio-panel@rayzeq.github.io` |
| **Clipboard Indicator** | 🌐 GNOME Extensions | ID `779` | `clipboard-indicator@tudmotu.com` |
| **Tiling Shell** | 🌐 GNOME Extensions | ID `7065` | `tilingshell@ferrarodomenico.com` |

---

### 1. Window & Workspace Management

#### 🪟 Tiling Shell
* **Source**: [extensions.gnome.org (ID: 7065)](https://extensions.gnome.org/extension/7065/tiling-shell/)
* **UUID**: `tilingshell@ferrarodomenico.com`
* **Description**: Advanced window tiling inspired by Windows 11's FancyZones. Split screen into custom layouts and snap windows with modifier keys or shortcuts.

#### ⚓ Dash to Dock (Main Dock)
* **Source**: Debian Package `gnome-shell-extension-dashtodock` / [EGO ID: 307](https://extensions.gnome.org/extension/307/dash-to-dock/)
* **UUID**: `dash-to-dock@micxgx.gmail.com`
* **Description**: Transforms the GNOME dash into an intelligent, customizable dock accessible from the desktop.

---

### 2. Productivity & Workflow

#### 📋 Clipboard Indicator
* **Source**: [extensions.gnome.org (ID: 779)](https://extensions.gnome.org/extension/779/clipboard-indicator/)
* **UUID**: `clipboard-indicator@tudmotu.com`
* **Description**: Clipboard manager with searchable history and pinning directly from the top panel.

#### ☕ Caffeine
* **Source**: Debian Package `gnome-shell-extension-caffeine` / [EGO ID: 517](https://extensions.gnome.org/extension/517/caffeine/)
* **UUID**: `caffeine@patapon.info`
* **Description**: Toggle to prevent screen blanking, screensaver, and auto-suspend.

#### 🔒 Lock Keys
* **Source**: [extensions.gnome.org (ID: 36)](https://extensions.gnome.org/extension/36/lock-keys/)
* **UUID**: `lockkeys@vaina.lt`
* **Description**: Real-time status indicators and OSD notifications for Num Lock and Caps Lock.

---

### 3. System & Audio Integration

#### 🔔 AppIndicator and KStatusNotifierItem Support
* **Source**: Debian Package `gnome-shell-extension-appindicator` / [EGO ID: 615](https://extensions.gnome.org/extension/615/appindicator-support/)
* **UUID**: `appindicatorsupport@rgcjonas.gmail.com`
* **Description**: Tray icon support for background applications (Steam, Telegram, Discord, VS Code, etc.).

#### 🔊 Quick Settings Audio Panel
* **Source**: [extensions.gnome.org (ID: 5940)](https://extensions.gnome.org/extension/5940/quick-settings-audio-panel/)
* **UUID**: `quick-settings-audio-panel@rayzeq.github.io`
* **Description**: Per-application volume control and stream mixer inside Quick Settings.

---

### 4. Aesthetics & Customization

#### 🧊 Blur my Shell
* **Source**: Debian Package `gnome-shell-extension-blur-my-shell` / [EGO ID: 3193](https://extensions.gnome.org/extension/3193/blur-my-shell/)
* **UUID**: `blur-my-shell@aunetx`
* **Description**: Glassmorphic blur effect for the top bar, overview, and dash.

#### 🖼️ Bing Wallpaper
* **Source**: [extensions.gnome.org (ID: 1262)](https://extensions.gnome.org/extension/1262/bing-wallpaper-changer/)
* **UUID**: `BingWallpaper@ineffable-gmail.com`
* **Description**: Daily Bing UHD/4K wallpaper synchronization.

#### 📐 Status Area Horizontal Spacing
* **Source**: [extensions.gnome.org (ID: 355)](https://extensions.gnome.org/extension/355/status-area-horizontal-spacing/)
* **UUID**: `status-area-horizontal-spacing@mathematical.coffee.gmail.com`
* **Description**: Compact padding between top panel indicator icons.

---

## 🚀 Execution

Run:

```bash
just extensions
# Or directly:
./Setup/gnome-extensions.sh
```
