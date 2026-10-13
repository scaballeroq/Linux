# 🚀 Bash.Setup (Fedora 44 + KDE Plasma 6)

Colección modular de scripts de configuración y utilidades avanzadas para potenciar tu terminal Bash y Zsh en Linux, optimizado al 100% para **Fedora 44 Workstation** con **KDE Plasma 6** y **Wayland**.

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia, control de escritorio KDE Plasma 6, gestor de contenedores Podman (rootless y Quadlets) y sincronización con la nube.

---

## 📁 Estructura Modular

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación (`..`, `repo`, `fedora`, `debian`), seguridad (`rm -i`), gestión de paquetes DNF5 (`update`, `upgrade`, `installed`), integración con Dolphin (`kioclient6`), portapapeles Wayland (`wl-copy`/`wl-paste`), utilidades Rust (`eza`, `bat`, `duf`, `dust`, `procs`, `btom`), virtualización KVM (`vms`) y comprobación de kernel. |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PAGER`, `LESS`), soporte nativo Wayland/Qt/Electron (`GDK_BACKEND`, `QT_QPA_PLATFORM`, `ELECTRON_OZONE_PLATFORM_HINT`), activación rápida de `mise` con shims y compatibilidad con Docker host de Podman rootless. |
| `functions.sh` | Utilidades multipropósito: extracción universal (`extract`), copias de seguridad con timestamp (`backup`), búsqueda rápida en historial (`hg` para Bash y Zsh), multimedia (`ffmpeg`, `imagemagick`, `webm2mp4`, `transcode-video-1080p`, `img2jpg`) y gestión de discos (`iso2sd`, `format-drive`). |
| `kde_settings.sh` | Control de KDE Plasma 6: reinicio de entorno (`plasma-restart`, `kwin-restart`), accesos directos KCM (`kde-conf-*` y equivalentes en español), alternancia de tema claro/oscuro (`kde-theme-dark`/`kde-theme-light`), control de luz nocturna (`kde-night-light-on`/`kde-night-light-off`) y atajos Spectacle. |
| `history.sh` | Configuración unificada para Bash y Zsh (10k memoria / 20k disco, deduplicación `erasedups`, `histappend`, sincronización entre terminales y exclusión de comandos efímeros). |
| `options.sh` | Opciones internas de shell (`shopt` y `bind` para Bash; `setopt` y `zstyle` para Zsh): autocd, globbing recursivo (`globstar`), corrección tipográfica (`cdspell`) y autocompletado insensible a mayúsculas. |
| `podman-functions.sh` | Administración de Podman rootless (`pps`, `pexec`, `plogs`), limpieza profunda (`pclean-total`, `pstop-all`, `prm-all`) y gestión de servicios Quadlets de usuario en systemd (`quadlet-status`, `quadlet-reload`, `quadlet-logs`). |
| `rclone_aliases.sh` | Sincronización y respaldos con Google Drive y OneDrive con protección de tasa de peticiones (`--fast-list`, `--tpslimit 10`), detección dinámica de almacenamiento externo y logs dedicados. |
| `yt-dlp_aliases.sh` | Descargas multimedia optimizadas en audio y vídeo Full HD (1080p) con cookies automáticas de navegador (`chrome`/`firefox`), formato de lista ordenado (`%(playlist_index)02d`) y limpieza de caché (`ytclean`). |

---

## ⚙️ Instalación y Activación

Para vincular estos scripts automáticamente a tu entorno de terminal:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Fedora-KDE/Bash.Setup/*.sh ~/.bashrc.d/
```

Si incluyes la carga modular en tu `~/.bashrc`:

```bash
# Carga modular de scripts en ~/.bashrc.d
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Fedora cargará automáticamente todos los scripts al abrir cualquier terminal interactiva sin penalización en sesiones no interactivas (`scp`, `rsync`, subshells).

---

## ✨ Características Destacadas

### 📦 Gestión de Paquetes (DNF5)
- `update`: Comprueba actualizaciones con refresco de metadatos (`sudo dnf5 check-update --refresh`).
- `upgrade`: Actualiza todo el sistema automáticamente (`sudo dnf5 upgrade --refresh -y`).
- `install` / `remove` / `search` / `clean`: Atajos rápidos para administración de paquetes.
- `list`: Lista paquetes actualizables (`dnf5 list --upgrades`).
- `installed`: Muestra los paquetes instalados en el sistema (`dnf5 list --installed`).
- `pkg-info` / `pkg-history`: Inspección de metadatos e historial de transacciones.

### 🎨 Integración con KDE Plasma 6 & Wayland
- `plasma-restart`: Reinicia el shell de Plasma limpiamente bajo systemd.
- `kwin-restart` / `kwin-reload`: Recarga o reinicia el compositor KWin al vuelo vía D-Bus o systemd.
- `kde-night-light-on` / `kde-night-light-off`: Activa o desactiva la Luz Nocturna desde la terminal.
- `kde-conf-display`, `kde-conf-audio`, `kde-conf-bluetooth`, `kde-conf-network`, `kde-conf-power`, etc.: Acceso directo a las páginas de Preferencias del Sistema (`kcmshell6` con fallback a `systemsettings`).
- `captura` / `grabacion`: Atajos de captura y grabación de pantalla con Spectacle.
- `kde-theme-dark` / `kde-theme-light`: Alterna entre Breeze Dark y Breeze Light al instante.
- `clipcopy` / `clippaste`: Integración nativa con el portapapeles de Wayland (`wl-copy` / `wl-paste`).

### 🐳 Contenedores (Podman & Quadlets)
- `pps`: Lista de contenedores formateada limpiamente en tabla.
- `pexec`: Ejecuta comandos o abre una shell en el contenedor.
- `plogs`: Sigue los logs en tiempo real (`-f --tail`).
- `pstop-all` / `prm-all` / `prmi-all`: Operaciones masivas seguras con arrays de Bash.
- `quadlet-reload` / `quadlet-status` / `quadlet-logs`: Detección automática y control de contenedores Quadlet (`~/.config/containers/systemd/`) en systemd del usuario.

### 🎬 Multimedia (FFmpeg & ImageMagick)
- `webm2mp4`: Convierte grabaciones de pantalla WebM a MP4 compatible con H.264/AAC.
- `transcode-video-1080p` / `transcode-video-4K`: Transcodificación rápida y optimizada.
- `img2jpg` / `img2jpg-small` / `img2png`: Optimización y compresión sin pérdidas de imágenes.

### ☁️ Sincronización (Rclone)
- `gdrive-*`: Respaldos y sincronización de directorios locales con Google Drive.
- `gdrive-repos-fedora` / `gdrive-repos-debian`: Sincronización granular de repositorios del monorepo.
- `lola-onedrive-*`: Descargas seguras desde OneDrive.
