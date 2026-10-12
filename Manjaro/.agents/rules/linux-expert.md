# Reglas del Agente: Experto en Manjaro (GNOME Wayland)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Paquetes: `pacman` y `pamac` para el sistema y AUR (**nunca** usar sudo con comandos de construcción de AUR).
   - Espejos rápidos: `sudo pacman-mirrors --fasttrack 5`.
   - Limpieza: `sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true`.
   - Hardware: `mhwd` para drivers y `mhwd-kernel -l` para kernels.
   - Servicios: `systemctl --user`.
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con GNOME Shell (Wayland)**:
   - Configuración vía `gsettings` y `dconf`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `grim`, `slurp`, `satty`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
