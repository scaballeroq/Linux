---
sidebar_position: 2
---

# System Setup on Soplos Linux Tyson

This guide details KDE Plasma 6 customization, Konsole/Kitty terminals, unified shell (Bash and Zsh with Starship), UFW firewall for Podman development, and web administration on **Soplos Linux Tyson** (Debian Testing derivative with **KDE Plasma 6**, **dracut**, **GRUB**, and **systemd**).

Configurations are automated through scripts in the `Setup/` directory.

---

## 1. KDE Plasma 6 Customization & Widgets (`kde-settings.sh` & `kde-widgets.sh`)

- **Night Color**: Disabled.
- **24-hour clock** and battery percentage display.
- **Window buttons**: Minimize, maximize, close on the right.
- **Touchpad**: Tap-to-click and natural scrolling enabled.
- **Klipper**: Persistent 100-item clipboard manager (`Meta + V`).
- **KWin Effects**: Blur, translucency, overview, and window tiling shortcuts.

```bash
just kde
just widgets
```

---

## 2. Terminal Emulators: Konsole & Kitty (`konsole.sh` & `kitty.sh`)

- **Konsole**: Translucent profile with blur (85%), JetBrainsMono Nerd Font, `Ctrl + Alt + T` global shortcut, Dolphin integration (`F4`).
- **Kitty**: GPU-accelerated terminal with dynamic opacity controls and Dolphin context menu.

```bash
just konsole
just kitty
```

---

## 3. Unified Shell Environment (`shell.sh`, `fastfetch.sh`, `fonts.sh`)

Installs modern CLI tools (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`), developer typography (Nerd Fonts), and unified **Starship** prompt for both **Bash** and **Zsh**.

```bash
just shell
just fonts
just fastfetch
```

---

## 4. Firewall & Hardening for Podman Development (`seguridad.sh`)

Configures UFW and Fail2ban to protect the laptop across Wi-Fi networks without blocking developer workflows:
- `localhost` / `127.0.0.1` traffic allowed.
- Forwarding and virtual network interfaces for **Podman** and **KVM** enabled.
- Native **KDE Connect** and mDNS / CUPS printer discovery allowed.
- Rate-limiting for SSH and Cockpit.

```bash
just security
```

---

## 5. Cockpit Web Admin Console (`cockpit.sh`)

Installs Cockpit for web-based machine management ([https://localhost:9090](https://localhost:9090)):
- `cockpit-podman`: Podman container management.
- `cockpit-machines`: KVM/QEMU VM management.
- `cockpit-storaged`: Storage and SMART metrics.

```bash
just cockpit
```

---

## 6. Desktop Themes & Icons (`apariencia.sh`)

Applies clean styling with Breeze Dark, Papirus-Dark icons, and Qt/GTK integration consistency.

```bash
just apariencia
```
