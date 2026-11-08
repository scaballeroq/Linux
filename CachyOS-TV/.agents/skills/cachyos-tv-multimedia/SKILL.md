---
name: cachyos-tv-multimedia
description: >-
  Use this skill when installing, configuring, troubleshooting, or optimizing multimedia applications (native Kodi with NAS streaming, Stremio Flatpak, VLC Flatpak, Google Chrome WebApps for YouTube/Netflix/Prime Video/Pluto TV/RTVE Play) or Intel Haswell VA-API and HDMI audio on the HP Z230 SFF CachyOS TV setup.
---

# CachyOS TV Multimedia Skill (Kodi, Stremio, Chrome WebApps & NAS)

Procedimientos para la instalación, permisos, optimización y resolución de problemas en el centro multimedia de salón sobre CachyOS (Arch Linux) y GNOME Wayland.

## 1. Kodi Nativo y Acceso a NAS por Red
Kodi se instala de forma nativa vía Pacman en CachyOS para obtener rendimiento óptimo con el controlador VA-API `i965` de Haswell y soporte de audio PipeWire.
```bash
# Instalación del stack completo de Kodi y red
sudo pacman -S --needed kodi kodi-inputstream-adaptive kodi-inputstream-ffmpegdirect smbclient cifs-utils nfs-utils gvfs-smb avahi

# Habilitar auto-descubrimiento en red (mDNS)
sudo systemctl enable --now avahi-daemon.service

# Lanzar Kodi con aceleración forzada y backend PipeWire
LIBVA_DRIVER_NAME=i965 kodi --audio-backend=pipewire &
```

### Carpetas compartidas del NAS
- Puntos de montaje automáticos en `/mnt/nas/peliculas` y `/mnt/nas/series`.
- En Kodi: `Añadir fuente de vídeo` -> `Explorar` -> `Red Windows (SMB)` o `Sistema de archivos raíz (/mnt/nas)`.

## 2. Stremio (Flatpak) con Overrides para Intel Haswell
Intel HD Graphics 4600 (Haswell) tiene soporte Vulkan incompleto, por lo que Stremio debe configurarse con renderer OpenGL (`GSK_RENDERER=gl`) y driver VA-API `i965`:
```bash
# Permisos y overrides de Flatpak
flatpak override --user \
  --device=dri \
  --socket=wayland \
  --socket=pulseaudio \
  --filesystem=xdg-run/pipewire-0 \
  --talk-name=org.freedesktop.Flatpak \
  --env=VK_DRIVER_FILES=/dev/null \
  --env=VK_ICD_FILENAMES=/dev/null \
  --env=GSK_RENDERER=gl \
  --env=LIBVA_DRIVER_NAME=i965 \
  com.stremio.Stremio

# Perfil MPV en ~/.var/app/com.stremio.Stremio/config/mpv/mpv.conf
ao=pulse
audio-channels=stereo
audio-samplerate=48000
audio-format=s16
audio-buffer=0.2
audio-normalize-downmix=yes
volume-max=100
hwdec=vaapi
```

## 3. Streaming Web con Google Chrome y Widevine DRM
Google Chrome proporciona soporte nativo de Widevine DRM para Netflix y Prime Video en 1080p.
Banderas recomendadas para aceleración por hardware:
```bash
google-chrome-stable \
  --ozone-platform-hint=auto \
  --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks \
  --ignore-gpu-blocklist \
  --enable-gpu-rasterization \
  --enable-zero-copy \
  --app=https://www.netflix.com
```

Lanzadores WebApp preconfigurados en `~/.local/share/applications/`:
- `netflix.desktop`
- `prime-video.desktop`
- `rtve-play.desktop`
- `pluto-tv.desktop`
- `youtube.desktop`
- `orange-tv.desktop`

## 4. Diagnóstico de Aceleración por Hardware VA-API
Haswell (Intel Core i7-4790 / HD Graphics 4600) decodifica por hardware H.264 (AVC) a 1080p 60fps.
```bash
LIBVA_DRIVER_NAME=i965 vainfo
```
Debe mostrar `VAProfileH264Main : VAEntrypointVLD` y `VAProfileH264High : VAEntrypointVLD`.

## 5. Audio TV Sony (HDMI)
PipeWire y WirePlumber aplican un quantum seguro (1024) y normalización de downmix a estéreo para evitar que las explosiones o efectos saturen los altavoces del televisor o que los diálogos se escuchen apagados.
```bash
# Comprobar dispositivos de audio HDMI
wpctl status
```
