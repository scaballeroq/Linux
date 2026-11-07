---
name: debian-tv-multimedia
description: >-
  Use this skill when installing, configuring, troubleshooting, or optimizing multimedia applications (Kodi Flatpak, Stremio Flatpak, VLC Flatpak, browser streaming for Netflix/Prime Video/RTVE/Pluto TV/YouTube) or VA-API acceleration on the HP Z230 SFF TV setup.
---

# Debian TV Multimedia Skill (Kodi, Stremio, VLC & Browser Streaming)

Procedimientos para la instalación, permisos, optimización y resolución de problemas en el centro multimedia de salón sobre Debian y GNOME Wayland.

## 1. Aplicaciones Multimedia Flatpak Principales
```bash
# Comprobar estado de instalación de las tres aplicaciones centrales
flatpak list --app | grep -E "tv.kodi.Kodi|com.stremio.Stremio|org.videolan.VLC"

# Permisos recomendados para aceleración por hardware y Wayland en Flatpak
flatpak override --user --device=all tv.kodi.Kodi
flatpak override --user --socket=wayland --socket=pulseaudio tv.kodi.Kodi
flatpak override --user --device=all com.stremio.Stremio
flatpak override --user --socket=wayland --socket=pulseaudio com.stremio.Stremio
flatpak override --user --device=all org.videolan.VLC
flatpak override --user --socket=wayland --socket=pulseaudio org.videolan.VLC

# Lanzar aplicaciones directamente
flatpak run tv.kodi.Kodi &
flatpak run com.stremio.Stremio &
flatpak run org.videolan.VLC &
```

## 2. Aceleración Gráfica VA-API (Intel HD Graphics 4600 / Haswell)
Haswell soporta decodificación por hardware de **H.264 (AVC) a 1080p 60fps**, pero **no** decodifica VP9 ni AV1 por hardware.
```bash
# Verificar driver i965 para Haswell
vainfo 2>&1 | grep -E "Driver version|VAProfileH264"

# Si vainfo da error, asegurar variables de entorno:
export LIBVA_DRIVER_NAME=i965
```

## 3. Optimización para Streaming en Navegador (Netflix, Prime Video, RTVE, YouTube)
- **Widevine DRM**: Necesario para Netflix y Prime Video en 1080p.
- **Forzar H.264 en YouTube y Web**: En navegadores como Chrome y Firefox, usar la extensión `enhanced-h264ify` o banderas de hardware para bloquear VP9/AV1 y forzar H.264. Esto reduce el uso de CPU de 80-100% a 5-15% gracias al silicio Haswell H.264 decodificador.
- **Banderas de Google Chrome para Intel Haswell**:
  ```bash
  google-chrome-stable \
    --ozone-platform-hint=auto \
    --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks \
    --ignore-gpu-blocklist \
    --enable-gpu-rasterization \
    --enable-zero-copy \
    --app=https://www.netflix.com
  ```

## 4. Lanzadores WebApp para Televisión
Los accesos directos de Netflix, Prime Video, RTVE Play, Pluto TV y YouTube se ubican en `~/.local/share/applications/` para integrarse nativamente en el dock y menú de GNOME.
