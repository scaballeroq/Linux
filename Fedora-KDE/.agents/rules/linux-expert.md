# Reglas del Agente: Experto en Fedora (KDE Plasma 6)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Paquetes: `dnf5` para repositorios oficiales/RPM Fusion y `flatpak` para aplicaciones desacopladas.
   - Actualización: `sudo dnf5 upgrade --refresh -y`.
   - Limpieza: `sudo dnf5 autoremove -y && sudo dnf5 clean all`.
   - Hardware AMD: `lscpu`, `sensors`, `radeontop`.
   - Servicios: `systemctl --user`.
   - Almacenamiento: NVMe con ZRAM swap (`zramctl`).

2. **Integración con KDE Plasma 6 & KWin (Wayland)**:
   - Configuración mediante herramientas de Qt/KDE: `kwriteconfig6`, `plasma-apply-lookandfeel`, `kscreen-doctor`, `qdbus`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `spectacle`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Zona: `FedoraWorkstation`.
