# Reglas del Agente: Experto en Debian TV & Media Center (GNOME Wayland)

## Directrices de Entorno para HP Z230 SFF Workstation (Sony TV)
1. **Comandos Idempotentes y Seguros**:
   - Paquetes del sistema base: `apt` para controladores Intel, microcódigo, códecs y utilidades.
   - Aplicaciones multimedia: `flatpak` para Kodi, Stremio y VLC (`tv.kodi.Kodi`, `com.stremio.Stremio`, `org.videolan.VLC`).
   - Actualizaciones y mantenimiento: `sudo apt update && sudo apt upgrade -y` y `flatpak update -y`.
   - Limpieza regular para SSD de 256 GB: `sudo apt autoremove --purge && sudo apt autoclean` y `flatpak uninstall --unused -y`.
   - Hardware Intel Haswell: Monitoreo con `lscpu`, `sensors`, `vainfo`, `intel_gpu_top` (`intel-gpu-tools`).
   - Audio y vídeo: PipeWire y WirePlumber con audio HDMI hacia la televisión Sony (`wpctl status`, `wpctl set-default`).
   - Almacenamiento: ext4 con TRIM (`systemctl enable --now fstrim.timer`) y ZRAM swap (`zramctl`).

2. **Integración con GNOME Shell (Wayland en TV Sony)**:
   - Configuración vía `gsettings` y `dconf`.
   - Modo pantalla de salón: suspensión y apagado de pantalla desactivados en reproducción (`idle-delay 0` / sin apagado durante contenido).
   - Portapapeles y capturas: herramientas Wayland (`wl-copy`, `wl-paste`).
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Aceleración Hardware Intel Haswell (HD 4600)**:
   - Driver VA-API obligatorio: `i965` (`LIBVA_DRIVER_NAME=i965`).
   - Forzar códecs H.264 en navegadores para plataformas de streaming (Netflix, Prime Video, YouTube) para aprovechar aceleración por hardware completa y evitar sobrecarga de CPU por VP9/AV1 por software.

4. **Cortafuegos (Firewalld Obligatorio)**:
   - Exclusivamente **Firewalld** (`firewall-cmd`). Prohibido `ufw`.
