# 🚀 Bash.Setup (KDEDebian)

Colección de scripts de configuración y funciones avanzadas para potenciar tu terminal Bash en Linux (optimizado para Debian Testing con KDE Plasma 6).

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia, accesos directos a KDE Plasma y gestores de contenedores (Podman).

---

## 📁 Estructura del Proyecto

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`apt`) e integración con `eza` y `bat`. |
| `functions.sh` | El "navaja suiza": utilidades multimedia (FFMPEG), gestión de discos, extracción de archivos (unificado) y navegación avanzada. |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman** y gestión de Pods. |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descarga optimizada de vídeo (1080p) y audio (MP3) con **yt-dlp**. |
| `history.sh` | Configuración optimizada del historial de Bash (10k/20k líneas, sin duplicados). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`) y personalización visual de `less` y `man`. |
| `options.sh` | Configuración del comportamiento de Bash (`autocd`, `globstar`, corrección de typos). |
| `kde_settings.sh` | [NUEVO] Optimizaciones y accesos directos del entorno KDE Plasma 6 (luz nocturna, temas, preferencias KCM). |

---

## 🛠️ Instalación

Para activar todas estas funcionalidades, se recomienda crear una carpeta `.bashrc.d` en tu home y añadir el siguiente bloque a tu archivo `~/.bashrc`:

```bash
# Carga modular de scripts
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Luego, puedes crear enlaces simbólicos de los scripts de este repositorio a esa carpeta:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/KDEDebian/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## ✨ Características Destacadas

### 🐳 Contenedores (Podman)
- `dsh` / `psh`: Entra en una shell interactiva de un contenedor con un solo comando.
- `dlogs` / `plogs`: Sigue los logs en tiempo real.
- `dstats` / `pstats`: Monitoriza recursos de forma limpia.
- `dclean` / `pclean`: Limpieza profunda del sistema de contenedores.

### 🎬 Multimedia (FFMPEG & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla (Spectacle/KDE) a MP4 compatible.
- `img2jpg` / `img2png`: Optimiza imágenes para web o almacenamiento.
- `transcode-video-1080p`: Optimización rápida de video.

### 📂 Navegación y Archivos
- `mkcd`: Crea un directorio y entra en él al instante.
- `extract`: Descomprime casi cualquier formato sin recordar las flags de `tar`.
- `up`: Sube varios niveles de directorio fácilmente (`up 3`).
- `duh`: Visualiza el tamaño de carpetas ordenado por peso.

### ☁️ Sincronización (Rclone)
- `rclone-documentos`: Sincroniza tu carpeta de documentos con Google Drive.
- `rclone-videos-down`: Descarga tus vídeos de la nube al equipo local.

### 📥 Descargas (YT-DLP)
- `ytvideo` / `ytaudio`: Descarga directa en MP4 (1080p) o MP3 (alta calidad).
- `ytlista-audio`: Descarga listas completas de reproducción convertidas a audio.

---

## 🛡️ Seguridad
El archivo `aliases.sh` incluye medidas de protección como:
- `rm`, `cp`, `mv` interactivos para evitar borrados accidentales.
- Protección del directorio raíz (`--preserve-root`).
- Verificación automática de la tabla de particiones en funciones de disco.
