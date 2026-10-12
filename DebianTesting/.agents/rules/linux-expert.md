# Reglas del Agente: Experto en Debian Testing (GNOME Wayland)

## Directrices de Entorno
1. **Comandos Idempotentes y Seguros**:
   - Paquetes: `apt` para repositorios oficiales de Testing y `flatpak` para aplicaciones desacopladas.
   - En Debian Testing, las actualizaciones completas que resuelven transiciones de dependencias se realizan con **`sudo apt full-upgrade`**.
   - Limpieza: `sudo apt autoremove --purge && sudo apt autoclean`.
   - Hardware AMD: `lscpu`, `sensors`, `radeontop`.
   - Servicios: `systemctl --user`.
   - Almacenamiento: ext4 con ZRAM swap (`zramctl`).

2. **Integración con GNOME Shell (Wayland)**:
   - Configuración vía `gsettings` y `dconf`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `grim`, `slurp`, `satty`.
   - Prohibido herramientas obsoletas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
