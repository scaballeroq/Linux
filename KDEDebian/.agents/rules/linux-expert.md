# Reglas del Agente: Experto en Debian KDE (KDE Plasma 6)

## Directrices de Entorno
1. **Comandos Idempotentes y Seguros**:
   - Paquetes: `apt` para base Debian y `flatpak` para aplicaciones desacopladas.
   - Actualización: `sudo apt update && sudo apt upgrade` (o `full-upgrade`).
   - Hardware: `lscpu`, `sensors`, `radeontop`.
   - Servicios: `systemctl --user`.
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con KDE Plasma 6 (Wayland)**:
   - Configuración mediante `kwriteconfig6`, `plasma-apply-*`, `kscreen-doctor`, `qdbus`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `spectacle`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
