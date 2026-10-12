# Reglas del Agente: Experto en Soplos Linux Tyson (Debian Testing + dracut + KDE Plasma 6)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Paquetes: `apt` (repositorios `testing`/`trixie`).
   - Arranque e Initramfs: usar `dracut` (`sudo dracut --force`). **NUNCA** utilices comandos de `initramfs-tools` (`update-initramfs`).
   - Bootloader: GRUB (`/etc/default/grub`, `sudo update-grub`).
   - Servicios: `systemctl` y `systemctl --user`.
   - Hardware: `lscpu`, `sensors`, `radeontop`.
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con KDE Plasma 6 & KWin (Wayland)**:
   - Configuración mediante `kwriteconfig6`, `plasma-apply-*`, `kscreen-doctor`, `qdbus`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `spectacle`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
