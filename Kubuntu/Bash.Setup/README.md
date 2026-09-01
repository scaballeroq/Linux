# 🚀 Kubuntu Bash Setup (.bashrc.d)

Colección modular de scripts de configuración para Bash, diseñados específicamente para optimizar la productividad y experiencia en **Kubuntu (KDE Plasma 6 / Wayland)** y entornos de desarrollo.

---

## 📁 Contenido del Módulo

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos para comandos frecuentes, navegación, Git, APT, utilidades modernas de Rust y virtualización. |
| `functions.sh` | Funciones utilitarias para navegación (`mkcd`, `up`), backups, compresión multiformato (`zstd`, `zip`, `tar`), búsqueda de procesos y conversión multimedia (`ffmpeg`, `ImageMagick`). |
| `podman-functions.sh` | Funciones avanzadas para gestionar contenedores Podman, pods y servicios Quadlet (`systemd --user`). |
| `rclone_aliases.sh` | Atajos y funciones de sincronización, copia y dry-run con Google Drive y OneDrive. |
| `yt-dlp_aliases.sh` | Atajos para descarga de video/audio en alta calidad con cookies de navegador y motor JS. |
| `history.sh` | Configuración optimizada del historial de Bash (sincronización en tiempo real entre pestañas, sin duplicados y con timestamps). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`, `DOCKER_HOST`, `QT_QPA_PLATFORM`) y personalización visual de `less` y `man`. |
| `options.sh` | Configuración del comportamiento de Bash (`autocd`, `globstar`, `cdspell`, `dirspell`). |
| `desktop_settings.sh` | Atajos rápidos de control para KDE Plasma 6 (Luz nocturna, conmutador de tema Kubuntu Dark, recarga de KWin y Plasmashell). |

---

## ⚙️ Instalación

Para activar estos módulos de forma automática, crea el directorio `~/.bashrc.d` y enlaza simbólicamente los scripts:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Kubuntu/Bash.Setup/*.sh ~/.bashrc.d/
```

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

### 📦 Contenedores (Podman & Quadlets)
- `psh <contenedor>`: Abre una shell interactiva dentro del contenedor.
- `plogs <contenedor>`: Muestra logs en tiempo real con `--tail 100`.
- `ppsf` / `ppsaf`: Listado de contenedores formateado en tabla limpia.
- `pstats`: Monitor en vivo de consumo de CPU, RAM y red.
- `pstop-all` / `prm-all` / `pclean-all`: Limpiezas seguras usando `xargs -r`.
- `qstatus` / `qlogs <servicio>` / `qrestart <servicio>` / `qreload`: Gestión de Quadlets de usuario en Systemd.

### 🎬 Multimedia (FFMPEG & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla a MP4 compatible.
- `img2jpg` / `img2png`: Optimiza y convierte imágenes rápidamente.
- `transcode-video-1080p` / `transcode-video-720p`: Recodificación de vídeo optimizada.

### 🖥️ KDE Plasma
- `kde-night-light-on` / `kde-night-light-off`: Control rápido de Luz Nocturna.
- `kde-theme-dark` / `kde-theme-light`: Alterna entre tema Kubuntu Dark y Claro.
- `kde-restart-kwin` / `kde-restart-plasma`: Recarga en caliente del compositor KWin o la interfaz Plasmashell.

### ☁️ Sincronización (Rclone)
- `gdrive-documentos` / `gdrive-documentos-copy`: Sincroniza o copia tu carpeta de documentos con Google Drive.
- `gdrive-repos-kubuntu`: Respaldo específico del repositorio de Kubuntu.
- Optimizado para Google Drive con límites de TPS (`--tpslimit 10`), carga rápida (`--fast-list`) y simulaciones `--dry-run`.

### 📥 Descargas (YT-DLP)
- `ytvideo` / `ytaudio`: Descarga directa en MP4 (1080p) o MP3 (alta calidad).
- `ytlista` / `ytlista-audio`: Descarga de listas de reproducción organizadas por índice.
