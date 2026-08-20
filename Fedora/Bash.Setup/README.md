# 🚀 Bash.Setup (Fedora 44 Workstation + GNOME)

Colección de scripts de configuración y funciones avanzadas para potenciar tu terminal Bash en Linux (optimizado para Fedora 44 con GNOME).

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia, accesos directos a GNOME y gestores de contenedores (Podman).

---

## 📁 Estructura Modular

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`dnf5`) e integración con `eza` y `bat`. |
| `functions.sh` | El "navaja suiza": utilidades multimedia (FFMPEG), gestión de discos, extracción de archivos (unificado) y navegación avanzada. |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman** y gestión de Quadlets/Pods. |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive y OneDrive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descargas de vídeo (1080p), audio (MP3) y listas con **yt-dlp**. |
| `history.sh` | Configuración optimizada del historial de Bash (10k/20k líneas, sin duplicados). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`), `mise`, `GPG_TTY` y personalización visual de `less` y `man`. |
| `options.sh` | Configuración del comportamiento de Bash (`autocd`, `globstar`, corrección de typos). |
| `gnome_settings.sh` | Optimizaciones del entorno GNOME (luz nocturna, formato 24h, gestión de extensiones, temas y accesos de configuración). |

---

## ⚙️ Instalación Rápida

Para vincular estos scripts automáticamente a tu entorno de terminal:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Fedora/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## ✨ Características Destacadas

### 📦 Gestión de Paquetes (DNF5)
- `update`: Comprueba actualizaciones con actualización de metadatos (`dnf5 check-update --refresh`).
- `upgrade`: Actualiza todo el sistema automáticamente (`dnf5 upgrade --refresh -y`).
- `install` / `remove` / `search` / `clean`: Atajos rápidos y limpios para DNF5.

### 🐳 Contenedores (Podman)
- `pexec`: Ejecuta comandos o abre shells interactivas en contenedores.
- `plogs`: Ver logs en tiempo real con parámetro opcional de líneas.
- `dclean` / `pclean`: Limpieza profunda del sistema de contenedores.

### 🎬 Multimedia (FFMPEG & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla de GNOME a MP4 compatible.
- `img2jpg` / `img2png`: Optimiza imágenes para web o almacenamiento.
- `transcode-video-1080p`: Optimización rápida de video.

### ☁️ Sincronización (Rclone)
- `gdrive-documentos` / `gdrive-videos-down`: Sincronización y descarga con Google Drive.
- Variantes de simulación `--dry-run` y copias directas `--copy`.

### 📥 Descargas (YT-DLP)
- `ytvideo` / `ytaudio`: Descarga directa en MP4 (1080p) o MP3 (alta calidad).
- `ytlista-audio`: Descarga listas completas convertidas a audio.
- Detección automática del runtime JavaScript (Deno vía Mise).
