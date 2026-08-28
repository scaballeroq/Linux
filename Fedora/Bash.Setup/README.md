# 🚀 Bash.Setup (Fedora 44 + KDE Plasma 6)

Colección modular de scripts de configuración y utilidades avanzadas para potenciar tu terminal Bash en Linux (optimizado al 100% para Fedora 44 con KDE Plasma 6 y Wayland).

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia, gestión de KDE Plasma, gestores de contenedores (Podman) y sincronización en la nube.

---

## 📁 Estructura Modular

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`dnf5`), integración con Dolphin, portapapeles Wayland y herramientas Rust (`eza`, `bat`, `duf`, `procs`). |
| `kde_settings.sh` | Optimizaciones para KDE Plasma 6 (`kwriteconfig6`), accesos directos a módulos de configuración (`kcmshell6`), reinicio de Plasma/KWin, gestión de widgets/plasmoids y atajos Spectacle. |
| `functions.sh` | El "navaja suiza": utilidades multimedia (FFmpeg, ImageMagick), gestión de discos/ISO, extracción unificada (`tar.xz`, `zstd`, `zip`, etc.) y copias seguras recursivas. |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman** (`pps`, `pexec`, `plogs`), limpieza segura y gestión de servicios **Quadlets** en systemd. |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive y OneDrive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descargas de vídeo (1080p), audio (MP3) y listas con **yt-dlp** y detección automática de runtime JS (Deno/Node). |
| `history.sh` | Configuración optimizada del historial de Bash (10k/20k líneas, sin duplicados, con exclusión de comandos de navegación). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`), soporte nativo Wayland/Qt/Electron (`QT_QPA_PLATFORM`, `ELECTRON_OZONE_PLATFORM_HINT`), `mise` y `GPG_TTY`. |
| `options.sh` | Configuración del comportamiento de Bash (`autocd`, `globstar`, `dirspell`, corrección de typos y protección de bind). |

---

## ⚙️ Instalación y Activación

Para vincular estos scripts automáticamente a tu entorno de terminal:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Fedora/Bash.Setup/*.sh ~/.bashrc.d/
```

Fedora cargará automáticamente todos los scripts al abrir cualquier terminal Bash.

---

## ✨ Características Destacadas

### 📦 Gestión de Paquetes (DNF5)
- `update`: Comprueba actualizaciones con actualización de metadatos (`dnf5 check-update --refresh`).
- `upgrade`: Actualiza todo el sistema automáticamente (`dnf5 upgrade --refresh -y`).
- `install` / `remove` / `search` / `clean` / `pkg-info` / `pkg-history`: Atajos rápidos para DNF5.

### 🎨 Integración con KDE Plasma 6 & Wayland
- `plasma-restart`: Reinicia el shell de Plasma de forma limpia bajo systemd.
- `kwin-reload`: Recarga la configuración del compositor KWin al vuelo.
- `kde-pantallas` / `kde-audio` / `kde-wifi` / `kde-bluetooth` / `kde-touchpad` / `kde-energia`: Acceso directo a las páginas de Preferencias del Sistema (`kcmshell6`).
- `captura` / `grabacion`: Atajos de captura y grabación de pantalla sin esperas vía Spectacle.
- `kde-theme-dark` / `kde-theme-light`: Alterna entre temas visuales desde la terminal.
- `dolphin`: Abre el explorador de archivos Dolphin en el directorio actual.
- `clipcopy` / `clippaste`: Integración con el portapapeles de Wayland (`wl-copy` / `wl-paste`).

### 🐳 Contenedores (Podman & Quadlets)
- `pps`: Lista de contenedores formateada limpiamente en tabla (sin colisionar con el `ps` de procesos del sistema).
- `pexec`: Ejecuta comandos o abre shells interactivas en contenedores.
- `plogs`: Ver logs en tiempo real con parámetro opcional de líneas.
- `pclean-total`: Limpieza profunda del sistema de contenedores.
- `quadlet-reload` / `quadlet-status` / `quadlet-logs`: Control de contenedores Quadlet en systemd del usuario.

### 🎬 Multimedia (FFMPEG & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla a MP4 compatible.
- `img2jpg` / `img2png`: Optimiza imágenes para web o almacenamiento.
- `transcode-video-1080p` / `transcode-video-4K`: Optimización rápida de video con H.264 o H.265.

### ☁️ Sincronización (Rclone)
- `gdrive-documentos` / `gdrive-videos-down`: Sincronización y descarga con Google Drive.
- Variantes de simulación `--dry-run` y copias directas `--copy`.

### 📥 Descargas (YT-DLP)
- `ytvideo` / `ytaudio`: Descarga directa en MP4 (1080p) o MP3 (alta calidad).
- `ytlista` / `ytlista-audio`: Descarga listas completas convertidas a video o audio con cookies de Firefox.
- Detección automática del runtime JavaScript (Deno / Node).
