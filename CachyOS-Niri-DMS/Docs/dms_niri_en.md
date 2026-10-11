---
sidebar_position: 3
---

# Dank Material Shell (DMS) & Niri Compositor Guide

This guide provides an in-depth reference on the architecture, command-line utilities, IPC interfaces, and keybindings for **Dank Material Shell (DMS)** running alongside the **Niri** scrollable-tiling compositor on **CachyOS**.

---

## 1. Dank Material Shell Architecture

Dank Material Shell is a modern desktop environment built on top of **Quickshell** implementing **Material Design 3 (Material You)** principles.

### Key Components:
- **`dms-shell`**: Core package containing the reactive QML desktop shell.
- **`dms` (CLI & Backend)**: Management executable located at `/usr/bin/dms` providing:
  - Backend daemon and IPC communication bus.
  - Material You theme generator (`dms matugen`).
  - Screenshot utility (`dms screenshot` or `dms ipc call niri screenshot`).
  - Clipboard manager, keybinding cheatsheets, wallpapers, and backup engine (`dms backup`).
- **`dms.service`**: Systemd user service (`systemctl --user status dms.service`).
- **`dankcalendar` (`dcal`)**: Calendar app with local, Google Calendar, and CalDAV sync.
- **`danksearch`**: Fast indexing file and application launcher.

---

## 2. DMS CLI & IPC Commands

You can interact with any DMS panel or action from the terminal or keybindings using `dms ipc call <target> <function>`:

| Target | Function | Description | Shell Alias |
| :--- | :--- | :--- | :--- |
| `launcher` | `toggle` | Open or close the app launcher | `dms-launcher` |
| `control-center` | `toggle` | Open or close the quick settings panel | `dms-control` |
| `clipboard` | `toggle` | Toggle the visual clipboard manager | `dms-clipboard` |
| `settings` | `toggle` | Open DMS settings window | `dms-settings` |
| `theme` | `toggle` | Switch between dark and light theme | `dms-theme-toggle` |
| `powermenu` | `toggle` | Open shutdown / restart menu | `dms-powermenu` |
| `lock` | `lock` | Lock the screen session | `dms-lock` |
| `keybinds` | `toggle` | Show keybinding cheatsheet | `dms-keybinds` |
| `notifications` | `toggle` | Open or close notifications center | `dms-notifications` |
| `audio` | `increment` / `decrement` / `mute` | Adjust PipeWire volume | `dms-volup` / `dms-voldown` / `dms-mute` |
| `wallpaper` | `set <path>` | Set wallpaper & regenerate colors | `dms-set-wallpaper <img.jpg>` |

### System Health Audit
Run `dms doctor` to verify dependencies and health:
```bash
dms doctor
# or using the shell alias:
dms-doc
```

---

## 3. Niri Compositor Integration

Niri organizes windows along an infinite horizontal scrolling ribbon. Modular configuration is stored in `~/.config/niri/`:

- `config.kdl`: Main configuration defining outputs, window rules, keybindings, and animations.
- `dms/`: Subdirectory managed by DMS containing:
  - `binds.kdl`: Keyboard shortcuts invoking `dms ipc`.
  - `colors.kdl`: Focus ring and border colors synced by Matugen.
  - `layout.kdl`: Gaps, margins, and column alignment.
  - `alttab.kdl`: Alt+Tab window switcher.
  - `outputs.kdl`: Display output profiles.

### Niri Control Commands:
```bash
niri-reload       # Live reload configuration
niri-validate     # Validate config.kdl syntax
niri-windows      # List active windows
niri-focused      # Inspect focused window
niri-outputs      # Query connected monitors
```

---

## 4. Dynamic Theming with Matugen

DMS utilizes **Matugen** to extract a harmonic Material You palette from your wallpaper:
- Theme files are generated at `~/.config/kitty/dank-theme.conf` and `~/.config/kitty/dank-tabs.conf`.
- GTK style sheets are updated at `~/.config/gtk-3.0/dank-colors.css` and `~/.config/gtk-4.0/dank-colors.css`.
- Niri window borders update automatically via `dms/colors.kdl`.

To force manual theme regeneration:
```bash
dms matugen generate
```
