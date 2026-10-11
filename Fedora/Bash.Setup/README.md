# 🚀 Bash.Setup (Fedora 44 + KDE Plasma 6)

Colección modular de scripts de configuración y utilidades avanzadas para potenciar tu terminal Bash en Linux (optimizado al 100% para **Fedora 44** con **KDE Plasma 6** y **Wayland**).

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia, gestión de KDE Plasma, gestor de contenedores (Podman) y sincronización en la nube.

---

## 📁 Estructura Modular

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`dnf5`), integración con Dolphin, portapapeles Wayland y herramientas Rust (`eza`, `bat`, `duf`, `dust`, `procs`, `btop`, `zoxide`). |
| `kde_settings.sh` | Optimizaciones para KDE Plasma 6 (`kwriteconfig6`), accesos directos a módulos de configuración (`kcmshell6`), reinicio de Plasma/KWin, gestión de widgets y atajos Spectacle. |
| `functions.sh` | El "navaja suiza": utilidades multimedia (FFmpeg, ImageMagick), extracción universal (`tar.xz`, `zstd`, `zip`, etc.) y herramientas de red (`myip`, `ports`). |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman** (`pps`, `pexec`, `plogs`), limpieza profunda (`pclean-total`) y gestión de servicios **Quadlets** en systemd. |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive y OneDrive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descargas de vídeo (1080p), audio (MP3) y listas con **yt-dlp** y detección automática de runtime JS (Deno). |
| `history.sh` | Configuración optimizada del historial de Bash (hasta 20k líneas, sin duplicados, sincronización inmediata). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`), soporte nativo Wayland/Qt/Electron (`QT_QPA_PLATFORM`, `ELECTRON_OZONE_PLATFORM_HINT`), `mise` y `DOCKER_HOST`. |
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
- `update`: Comprueba actualizaciones con actualización de metadatos (`sudo dnf5 update`).
- `upgrade`: Actualiza todo el sistema automáticamente (`sudo dnf5 upgrade -y`).
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
- `pps`: Lista de contenedores formateada limpiamente en tabla.
- `pexec`: Ejecuta comandos o abre shells interactivas en contenedores.
- `plogs`: Ver logs en tiempo real con parámetro opcional de líneas.
- `pclean-total`: Limpieza profunda del sistema de contenedores.
- `quadlet-reload` / `quadlet-status` / `quadlet-logs`: Control de contenedores Quadlet en systemd del usuario.

### 🎬 Multimedia (FFmpeg & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla WebM a MP4 compatible con H.264.
- `img2jpg` / `img2png`: Optimiza y convierte imágenes en lote.
- `transcode-video-1080p` / `transcode-video-4K`: Optimización rápida de video con H.264 o H.265.

### ☁️ Sincronización (Rclone)
- `gdrive-software` / `gdrive-kdenlive` / `gdrive-images` / `gdrive-repos`: Sincronización y respaldo en Google Drive.
- `gdrive-check-all`: Comprobación de integridad de remotos de Google Drive.
- `onedrive-get`: Descarga de carpetas sincronizadas en OneDrive.

### 📥 Descargas (YT-DLP)
- `ytdl`: Descarga directa en MP4 (1080p).
- `ytdl-audio`: Descarga y convierte a MP3 (320k) con carátula y metadatos.
- `ytdl-best`: Descarga en resolución máxima disponible (4K/2K/1080p).
- `ytdl-playlist`: Descarga listas completas organizadas.
- `ytdl-update`: Actualiza el binario de yt-dlp.
