# 🚀 Bash.Setup (Soplos Linux Tyson)

Colección modular de scripts de configuración, utilidades avanzadas y funciones para potenciar tu terminal Bash en **Soplos Linux Tyson** (Debian Testing + KDE Plasma 6 + systemd + dracut + Podman).

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia, accesos directos a KDE Plasma, gestión de contenedores y sincronización en la nube.

---

## 📁 Estructura del Proyecto

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`apt`), administración de sistema (`systemd`, `dracut`, `grub`), monitor de kernel y herramientas modernas (`eza`, `bat`, `duf`, `dust`, `procs`). |
| `functions.sh` | Navaja suiza: utilidades multimedia (FFmpeg, ImageMagick), gestión segura de discos (`iso2sd` interactivo, `format-drive`), extracción universal (`extract` con soporte `zstd`/`xz`) y navegación rápida (`mkcd`, `up`, `backup`). |
| `podman-functions.sh` | Funciones y aliases avanzados para **Podman**, Pods, inspección, limpieza y recarga de **Podman Quadlets**. |
| `rclone_aliases.sh` | Sincronización y copias avanzadas con la nube (Google Drive y OneDrive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descarga optimizada de vídeo (1080p), audio (MP3) y listas con detección automática de runtimes JS (`deno`, `node`, `quickjs`) y cookies. |
| `history.sh` | Historial persistente optimizado (10k/20k líneas, sincronización inmediata `history -a`, sin duplicados). |
| `environment.sh` | Variables globales (`EDITOR`, `PATH` sin duplicados), gestión de runtimes (`mise`), GPG y colores de `less`/`man`. |
| `options.sh` | Comportamiento inteligente de Bash (`autocd`, `globstar`, `cdspell`, `dirspell`, autocompletado insensible a mayúsculas). |
| `kde_settings.sh` | Accesos directos y control de **KDE Plasma 6** / Qt 6 (reinicio de Plasma/KWin, luz nocturna, temas, preferencias KCM y diagnóstico). |

---

## 🛠️ Instalación y Activación

Para activar todas estas funcionalidades de forma modular, añade el siguiente bloque a tu archivo `~/.bashrc`:

```bash
# Carga modular de scripts de terminal
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Crea la carpeta `~/.bashrc.d` y enlaza los scripts de este repositorio:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/SoplosLinuxTyson/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## ✨ Características Destacadas

### 🐳 Contenedores (Podman)
- `pexec` / `psh` / `dsh`: Entra en una shell interactiva de un contenedor al instante.
- `plogs` / `dlogs`: Sigue logs en tiempo real (`plogs <contenedor>`).
- `pstats` / `dstats`: Monitoriza consumo de CPU y memoria de contenedores.
- `pclean` / `pclean-total`: Limpieza de contenedores parados, redes huérfanas e imágenes.
- `podman-quadlet-reload`: Recarga servicios Quadlet de usuario en systemd (`systemctl --user daemon-reload`).

### 🎬 Multimedia (FFmpeg & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla de Spectacle (KDE) a MP4 de alta compatibilidad.
- `img2jpg` / `img2jpg-small` / `img2png`: Optimiza imágenes para almacenamiento o web.
- `transcode-video-1080p` / `transcode-video-4K`: Transcodificación optimizada con H.264 o H.265 (HEVC).

### 📂 Navegación y Archivos
- `mkcd`: Crea un directorio y accede inmediatamente a él.
- `up`: Sube varios niveles de directorio (`up 3`).
- `extract`: Descomprime cualquier formato (`.tar.gz`, `.tar.xz`, `.tar.zst`, `.zip`, `.7z`, etc.) sin recordar flags.
- `backup`: Crea un respaldo con marca de tiempo (`archivo.bak-YYYYMMDD-HHMMSS`).
- `duh`: Visualiza el tamaño de carpetas ordenado de mayor a menor.

### 🐧 Sistema y Administración (Soplos Linux Tyson)
- `check-kernel`: Consulta `kernel.org` y compara la versión en línea con `uname -r`.
- `sc` / `scu`: Accesos rápidos para `systemctl` y `systemctl --user`.
- `jc` / `jcu`: Visualización rápida del visor de logs `journalctl`.
- `dracut-rebuild`: Reconstruye el initramfs activo de forma segura con `dracut`.

### 🖥️ KDE Plasma 6
- `plasma-restart` / `kwin-restart`: Reinicio seguro de la shell gráfica o compositor.
- `kde-night-light-on` / `kde-night-light-off`: Control de luz nocturna vía CLI / D-Bus.
- `kde-theme-dark` / `kde-theme-light`: Cambio ágil de temas.
- `plasma-info`: Muestra información de versión de Plasma, Frameworks 6, Qt y sesión Wayland/X11.

### ☁️ Sincronización (Rclone) & Descargas (yt-dlp)
- `gdrive-*` / `lola-onedrive-*`: Sincronización bidireccional y simulaciones (`--dry-run`).
- `ytvideo` / `ytaudio` / `ytlista`: Descarga en MP4 (1080p) o MP3 con resolución automática de JavaScript challenge (`deno`, `node`, `quickjs`).

---

## 🛡️ Seguridad
- `rm`, `cp`, `mv` interactivos con `--preserve-root`.
- `iso2sd`: Solicita confirmación explícita antes de escribir con `dd` y detecta dispositivos `sd*`, `nvme*` y `mmcblk*`.
- `format-drive`: Confirmación interactiva y soporte universal de particiones GPT en exFAT.

