# 🚀 Bash.Setup

Colección de scripts de configuración y funciones avanzadas para potenciar tu terminal Bash en Linux (optimizado para Fedora y Arch Linux).

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia y gestores de contenedores (Podman).

---

## 📁 Estructura del Proyecto

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`dnf`) e integración con `eza` y `bat`. |
| `functions.sh` | El "navaja suiza": utilidades multimedia (FFMPEG), gestión de discos, extracción de archivos (unificado) y navegación avanzada. |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman** y gestión de Pods. |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descarga optimizada de vídeo (1080p) y audio (MP3) con **yt-dlp**. |
| `history.sh` | Configuración optimizada del historial de Bash (10k/20k líneas, sin duplicados). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`) y personalización visual de `less` y `man`. |
| `options.sh` | Configuración del comportamiento de Bash (`autocd`, `globstar`, corrección de typos). |
| `gnome_settings.sh` | [NUEVO] Optimizaciones del entorno GNOME (luz nocturna, formato 24h, gestión de extensiones). |

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
ln -s ~/Workspace/Repositorios/Debian/Bash.Setup/*.sh ~/.bashrc.d/
```

*Nota: Asegúrate de ajustar la ruta al directorio donde hayas clonado el repositorio.*

---

## ✨ Características Destacadas

### 🐳 Contenedores (Podman)
- `dsh` / `psh`: Entra en una shell interactiva de un contenedor con un solo comando.
- `dlogs` / `plogs`: Sigue los logs en tiempo real.
- `dstats` / `pstats`: Monitoriza recursos de forma limpia.
- `dclean` / `pclean`: Limpieza profunda del sistema de contenedores.

### 🎬 Multimedia (FFMPEG & ImageMagick)
- `webm2mp4`: Convierte grabaciones de GNOME a MP4 compatible.
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
- Configurado con límites de TPS y logs detallados para evitar bloqueos.

### 📥 Descargas (YT-DLP)
- `ytvideo` / `ytaudio`: Descarga directa en MP4 (1080p) o MP3 (alta calidad).
- `ytlista-audio`: Descarga listas completas de reproducción convertidas a audio.
- Incluye parches automáticos para evitar el error de descifrado y n-challenge.

---

## 📦 Herramientas Recomendadas

Para disfrutar de la experiencia completa con los aliases predefinidos, se recomienda instalar:
- **[bat](https://github.com/sharkdp/bat)**: `cat` con resaltado de sintaxis.
- **[eza](https://github.com/eza-community/eza)**: Reemplazo moderno de `ls` con iconos.
- **[ffmpeg](https://ffmpeg.org/)**: Motor de procesamiento multimedia.
- **[rclone](https://rclone.org/)**: El "rsync" para almacenamiento en la nube.
- **[yt-dlp](https://github.com/yt-dlp/yt-dlp)**: Potente extractor de vídeo y audio de YouTube y otros sitios.
- **[ImageMagick](https://imagemagick.org/)**: Manipulación de imágenes por consola.
- **[paru](https://github.com/Morganamilo/paru)**: AUR helper para Arch Linux (opcional, cae a `pacman` si no existe).

---

## 🛡️ Seguridad
El archivo `aliases.sh` incluye medidas de protección como:
- `rm`, `cp`, `mv` interactivos para evitar borrados accidentales.
- Protección del directorio raíz (`--preserve-root`).
- Verificación automática de la tabla de particiones en funciones de disco.
