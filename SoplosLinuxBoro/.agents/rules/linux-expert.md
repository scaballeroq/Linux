# Reglas del Agente: Experto en Soplos Linux Boro (GNOME Wayland)

## Directrices de Entorno
1. **Comandos Idempotentes y Seguros**:
   - Paquetes: `apt` para repositorios oficiales estables y `flatpak` para aplicaciones desacopladas.
   - En Soplos Linux Boro, actualizaciones regulares con `sudo apt update && sudo apt upgrade`.
   - Limpieza: `sudo apt autoremove --purge && sudo apt autoclean`.
   - Hardware AMD: `lscpu`, `sensors`, `radeontop`.
   - Servicios: `systemctl --user`.
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con GNOME Shell (Wayland)**:
   - Configuración vía `gsettings` y `dconf`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `grim`, `slurp`, `satty`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
