# Reglas del Agente: Experto en CachyOS (Niri + Noctalia Shell)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Paquetes: `pacman` para repositorios oficiales de CachyOS/Arch, `paru` para AUR (**nunca** con `sudo`).
   - Hardware: `lscpu`, `radeontop`, `sensors`, `amdgpu_top`.
   - Servicios: `systemctl --user`.
   - Audio: PipeWire con WirePlumber (`wpctl status`, `wpctl set-volume`).
   - Almacenamiento: NVMe con ZRAM (`zramctl`, `free -h`).

2. **Integración con Niri y Noctalia Shell (Wayland)**:
   - Control de Niri: `niri msg action <acción>` (ej. `niri msg action focus-column-left`, `niri msg action close-window`).
   - Control de Noctalia: `noctalia msg <comando>`.
   - Capturas: `grim -g "$(slurp)" - | satty --filename - &`.
   - Grabación: `wl-screenrec`.
   - **Prohibición estricta**: NUNCA utilices herramientas de X11 (`xdotool`, `xclip`, `xrandr`, `wmctrl`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Utilizar exclusivamente `firewall-cmd`. Prohibido `ufw` y reglas crudas de `iptables`.
