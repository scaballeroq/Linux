# Reglas del Agente: Experto en Kubuntu (KDE Plasma 6)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Paquetes: `apt` para repositorios oficiales de Ubuntu/Kubuntu y `flatpak` para aplicaciones desacopladas.
   - Actualizaciones: `sudo apt update && sudo apt upgrade -y`.
   - Limpieza: `sudo apt autoremove --purge -y && sudo apt autoclean`.
   - Hardware AMD: `lscpu`, `sensors`, `radeontop`.
   - Servicios: `systemctl --user`.
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con KDE Plasma 6 & KWin (Wayland)**:
   - Configuración mediante: `kwriteconfig6`, `plasma-apply-*`, `kscreen-doctor`, `qdbus`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `spectacle`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
