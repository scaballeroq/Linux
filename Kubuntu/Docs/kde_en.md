---
sidebar_position: 8
---

# KDE Plasma Customization and Optimization in Kubuntu

This guide documents the configuration, shortcuts, and optimizations for **KDE Plasma 6 / 5** on Kubuntu.

---

## 1. System Settings and Appearance (`kde-settings.sh`, `apariencia.sh`)

Kubuntu utilizes KDE Plasma as its primary desktop environment. The customization scripts automate:

1. **Global Theme and Styling**:
   - Installation of **Papirus** and **Breeze** icon themes.
   - Automatic activation of the official **Breeze Dark** theme via `lookandfeeltool`.

2. **Night Color**:
   - Fixed warm temperature at `3500K` to reduce eye strain.
   - Dynamic CLI shortcuts: `kde-night-light-on` / `kde-night-light-off`.

3. **Power Profiles (Powerdevil)**:
   - Disables automatic sleep while plugged into AC power.
   - Optimizes dimming and sleep timeouts when on battery.

4. **Keyboard Shortcuts**:
   - **Meta + T**: Launch terminal (Konsole).

---

## 2. CLI Tools for KDE Plasma

KDE Plasma configuration can be managed via command-line utilities:

```bash
# Read/Write configuration in KDE Plasma 6
kwriteconfig6 --file kwinrc --group NightColor --key Active true

# Reload KWin compositor without restarting session
qdbus6 org.kde.KWin /KWin reconfigure

# Switch Breeze themes from the terminal
lookandfeeltool -a org.kde.breezedark.desktop   # Dark
lookandfeeltool -a org.kde.breeze.desktop       # Light
```

---

## 3. Integrated Shell Shortcuts (`desktop_settings.sh`)

When sourcing `~/.bashrc.d/desktop_settings.sh`, the following shortcuts become available:

| Alias | Description |
| :--- | :--- |
| `kde-night-light-on` | Turns on Night Color in KDE Plasma. |
| `kde-night-light-off` | Turns off Night Color in KDE Plasma. |
| `kde-theme-dark` | Applies the Breeze Dark theme. |
| `kde-theme-light` | Applies the Breeze Light theme. |
| `kde-conf` | Opens KDE System Settings (`systemsettings`). |
| `kde-restart-kwin` | Reloads the KWin window manager/compositor. |
