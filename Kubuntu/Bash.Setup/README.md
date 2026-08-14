# 🚀 Kubuntu Bash Setup (.bashrc.d)

Colección modular de scripts de configuración para Bash, diseñados específicamente para optimizar la productividad y experiencia en **Kubuntu (KDE Plasma)** y sistemas derivados.

---

## 📁 Contenido del Módulo

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos para comandos frecuentes, navegación, Git, APT, utilidades modernas de Rust y virtualización. |
| `functions.sh` | Funciones utilitarias para navegación, backups, compresión, búsqueda de procesos y conversión multimedia. |
| `podman-functions.sh` | Funciones avanzadas para gestionar contenedores Podman de forma ágil y segura sin colisiones. |
| `rclone_aliases.sh` | Atajos y funciones de sincronización, copia y dry-run con Google Drive y OneDrive. |
| `yt-dlp_aliases.sh` | Atajos para descarga de video/audio en alta calidad con cookies de navegador y motor JS. |
| `history.sh` | Configuración optimizada del historial de Bash (10k/20k líneas, sin duplicados y con timestamps). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`) y personalización visual de `less` y `man`. |
| `options.sh` | Configuración del comportamiento de Bash (`autocd`, `globstar`, corrección de typos). |
| `desktop_settings.sh` | Optimizaciones de escritorio para KDE Plasma 6/5 (Luz nocturna, energía, temas Breeze, aliases). |

---

## ⚙️ Instalación

Para activar estos módulos de forma automática, crea el directorio `~/.bashrc.d` y enlaza simbólicamente los scripts:

```bash
mkdir -p ~/.bashrc.d
ln -s ~/Workspace/Repositorios/Kubuntu/Bash.Setup/*.sh ~/.bashrc.d/
```

*Nota: Asegúrate de ajustar la ruta al directorio donde hayas clonado el repositorio.*

Luego, agrega el cargador modular a tu `~/.bashrc` si aún no lo tienes:

```bash
# Cargar módulos de ~/.bashrc.d
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*.sh; do
        [ -f "$rc" ] && source "$rc"
    done
fi
```

---

## 🛠️ Comandos Destacados

### 📦 Contenedores (Podman)
- `psh <contenedor>`: Abre una shell interactiva dentro del contenedor.
- `plogs <contenedor>`: Muestra logs en tiempo real con `--tail 100`.
- `ppsf` / `ppsaf`: Listado de contenedores formateado en tabla limpia.
- `pstats`: Monitor en vivo de consumo de CPU, RAM y red.
- `pclean` / `pclean-all`: Limpieza profunda del sistema de contenedores.

### 🎬 Multimedia (FFMPEG & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla a MP4 compatible.
- `img2jpg` / `img2png`: Optimiza imágenes para web o almacenamiento.
- `transcode-video-1080p`: Optimización rápida de video.

### 🖥️ KDE Plasma
- `kde-night-light-on` / `kde-night-light-off`: Control rápido de Luz Nocturna.
- `kde-theme-dark` / `kde-theme-light`: Alterna entre tema Breeze Oscuro y Claro.
- `kde-conf`: Acceso directo a Preferencias del Sistema.

### ☁️ Sincronización (Rclone)
- `gdrive-documentos` / `gdrive-documentos-copy`: Sincroniza o copia tu carpeta de documentos con Google Drive.
- `gdrive-videos-down` / `gdrive-videos-down-copy`: Descarga tus vídeos de la nube al equipo local.
- `gdrive-repos-kubuntu`: Respaldo específico del repositorio de Kubuntu.
- Optimizado para Google Drive con límites de TPS (`--tpslimit 10`), carga rápida (`--fast-list`) y simulaciones `--dry-run`.

### 📥 Descargas (YT-DLP)
- `ytvideo` / `ytaudio`: Descarga directa en MP4 (1080p) o MP3 (alta calidad).
- `ytlista` / `ytlista-audio`: Descarga de listas de reproducción organizadas por índice.
