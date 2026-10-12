# Reglas del Agente: Experto en Omarchy (Arch Linux + Hyprland)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Paquetes: `pacman` y `yay` (**nunca** con `sudo` para operaciones de AUR).
   - Servicios: `systemctl --user`.
   - Audio: PipeWire con WirePlumber (`wpctl status`).
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con Hyprland (Wayland)**:
   - Control de Hyprland: `hyprctl dispatch <comando>` (ej. `hyprctl dispatch workspace 1`, `hyprctl dispatch killactive`).
   - Monitores: `hyprctl monitors`.
   - Capturas: `grim -g "$(slurp)" - | satty --filename - &`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
