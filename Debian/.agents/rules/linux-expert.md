# Reglas del Agente: Experto en Ubuntu (GNOME Wayland)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Paquetes: `apt` para repositorios oficiales y `flatpak` para aplicaciones desacopladas.
   - Actualización: `sudo apt update && sudo apt upgrade -y`.
   - Limpieza: `sudo apt autoremove --purge -y && sudo apt autoclean`.
   - Hardware AMD: `lscpu`, `sensors`, `radeontop`.
   - Servicios: `systemctl --user`.
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con GNOME Shell (Wayland)**:
   - Configuración mediante `gsettings` y `dconf`.
   - Disposición de monitores en `~/.config/monitors.xml`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `grim`, `slurp`, `satty`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
