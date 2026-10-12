# Reglas del Agente: Experto en Arch Linux (GNOME Wayland)

## Directrices de Entorno
1. **Comandos Idempotentes, Seguros y Modernos**:
   - Para administración de paquetes: utiliza `pacman` para repositorios oficiales y `yay` para AUR (**nunca** con `sudo`).
   - Para inspección de hardware AMD: `lscpu`, `radeontop`, `sensors`, `cpupower`.
   - Para administración de servicios: prioriza `systemctl --user`.
   - Para audio: PipeWire con WirePlumber (`wpctl status`, `wpctl set-volume`).
   - Para almacenamiento y memoria: ext4 sobre NVMe con ZRAM (`zramctl`, `free -h`).

2. **Integración con GNOME Shell (Wayland Nativo)**:
   - Configuración mediante `gsettings` y `dconf`.
   - Disposición de monitores en `~/.config/monitors.xml`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `grim`, `slurp`, `satty`.
   - **Prohibición estricta**: NUNCA utilices herramientas de X11 (`xdotool`, `xclip`, `xrandr`).

3. **Cortafuegos y Seguridad de Red (Firewalld Obligatorio)**:
   - Utilizar exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw` y reglas crudas de `iptables`.
   - Zona habitual: `home`. Interfaces en `trusted`: `podman+`, `virbr0`.
