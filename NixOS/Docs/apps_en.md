---
sidebar_position: 9
---

# Applications & Gaming in openSUSE Tumbleweed (KDE Plasma 6)

This guide details desktop applications, system utilities, and gaming platforms configured in `Setup/` and `Juegos/`.

---

## 1. Native KDE Plasma 6 Suite

openSUSE Tumbleweed integrates the complete KDE Gear application suite on Wayland:

- **Dolphin**: File manager configured with details view and KIO servicemenus for Kitty and Google Antigravity.
- **Kate & KWrite**: Text editors with syntax highlighting and embedded terminal.
- **Spectacle**: Screenshot and screen recording utility on Wayland (`Print Screen` or `captura`).
- **Okular**: Universal document viewer (PDF, ePub, Markdown).
- **Gwenview**: Lightweight image viewer.
- **Ark**: Archive manager supporting `tar`, `zip`, `7z`, and `rar`.
- **KCalc**: Scientific calculator.
- **Discover**: Software center integrated with Flathub backend.

---

## 2. Google Chrome Browser (`chrome.sh`)

Installs the official stable Google Chrome release from Google's signed RPM repository:

```bash
just chrome
# or ./Setup/chrome.sh
```

Check repository and binary status:
```bash
./Setup/chrome.sh --status
```

---

## 3. Steam, Performance & Gaming (`steam.sh`)

Configures native gaming capabilities with full hardware acceleration:

- **Native Steam**: Official openSUSE package with 32-bit graphics dependencies (`libvulkan_radeon-32bit`, `Mesa-dri-32bit`).
- **Performance Optimizers**: GameMode (`gamemoderun`) and MangoHud for overlay metrics (FPS, GPU usage, thermals).
- **Proton-GE**: GloriousEggroll compatibility layer for maximum Windows title compatibility.

```bash
just steam
# or ./Setup/steam.sh
```

---

## 4. Kodi Media Center (`kodi`)

Turns the system into a high-fidelity media center:

- Official `kodi` package with hardware VA-API acceleration.
- Streaming addons: `kodi-inputstream-adaptive`, `kodi-inputstream-rtmp`, `kodi-pvr-iptvsimple`.

```bash
just kodi
```

---

## 5. Meld: Visual Diff & Merge Tool

Graphical tool for file comparison and Git merge conflicts:

```bash
sudo zypper --non-interactive install -y meld
```

---

## Verification

- **KDE Plasma**: Launch applications from the application launcher (Kickoff) or via KRunner (`Alt+Space`).
- **Chrome**: Run `google-chrome` or check with `./Setup/chrome.sh --status`.
- **Steam**: Open Steam, go to *Settings > Compatibility*, and verify Steam Play / Proton is enabled.
