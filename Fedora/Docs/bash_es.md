---
sidebar_position: 3
---

# Configuración Modular de Bash en Fedora 44 (KDE Plasma 6)

Esta guía detalla la configuración del entorno de terminal (Bash) y las utilidades integradas en la carpeta `Bash.Setup`, optimizadas al 100% para **Fedora 44** con **KDE Plasma 6** y **Wayland**.

---

## 1. Carga Modular del Entorno (`~/.bashrc.d`)

Fedora soporta de manera nativa la carga modular de scripts en `~/.bashrc.d`. Para vincular todos los módulos:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Fedora/Bash.Setup/*.sh ~/.bashrc.d/
```

Cada script se ejecutará de forma ordenada al abrir una terminal o sesión interactiva.

---

## 2. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas, seguras y de monitorización:

### 📦 Atajos de Paquetes con DNF5
- `update` -> `sudo dnf5 update` (comprueba e instala actualizaciones).
- `upgrade` -> `sudo dnf5 upgrade -y` (actualización desatendida).
- `install` -> `sudo dnf5 install`
- `remove` -> `sudo dnf5 remove`
- `search` -> `dnf5 search`
- `clean` -> `sudo dnf5 autoremove -y && sudo dnf5 clean all`
- `list` -> `dnf5 list --upgradable`
- `pkg-info` -> `dnf5 info`
- `pkg-history` -> `dnf5 history`

### 🎨 Integración con KDE Plasma 6 y Wayland
- `dolphin`: Abre el explorador Dolphin en el directorio actual en segundo plano.
- `open` / `o`: Abre cualquier archivo con la aplicación predeterminada (`xdg-open`).
- `trash`: Envía archivos a la papelera de forma segura (`gio trash`).
- `clipcopy` / `clippaste`: Portapapeles integrado con Wayland (`wl-copy` / `wl-paste`).
- `plasma-restart`: Reinicia el shell de Plasma de forma limpia bajo systemd.
- `kwin-reload`: Recarga la configuración del compositor KWin al vuelo.

### 🦀 Herramientas Modernas en Rust
- `ls` / `ll` / `la` / `lt` -> `eza` (con iconos, estado de Git y colores semánticos).
- `cat` -> `bat` (con resaltado de sintaxis y paginación).
- `grep` -> `ripgrep` (`rg`).
- `df` -> `duf` (visualización limpia de particiones y puntos de montaje).
- `du` -> `dust` (análisis visual de uso de disco).
- `ps` -> `procs` (árbol y monitor de procesos).
- `top` / `htop` -> `btop` (monitor de recursos por GPU/CPU/RAM).
- `cd` -> `zoxide` (`z` / `zi`).

### 🛡️ Seguridad
- `rm -i`, `cp -i`, `mv -i` (confirmación interactiva para evitar pérdidas de datos).
- Flag `--preserve-root` activada en comandos destructivos.

---

## 3. Gestor de Entorno KDE Plasma 6 (`kde_settings.sh`)

CLI interactivo para administrar configuraciones del escritorio y accesos directos a módulos de Preferencias del Sistema (`kcmshell6`):

```bash
# Ver estado actual del entorno KDE:
./Bash.Setup/kde_settings.sh status

# Aplicar optimizaciones recomendadas de KWin, Dolphin y atajos:
./Bash.Setup/kde_settings.sh apply

# Crear copia de seguridad de la configuración de KDE:
./Bash.Setup/kde_settings.sh backup

# Restaurar configuración desde copia de seguridad:
./Bash.Setup/kde_settings.sh restore
```

Atajos directos de consola incluidos:
- `kde-pantallas`, `kde-audio`, `kde-wifi`, `kde-bluetooth`, `kde-touchpad`, `kde-energia`, `kde-atajos`.
- `captura` / `grabacion`: Captura y grabación de pantalla instantánea vía Spectacle.
- `kde-theme-dark` / `kde-theme-light`: Cambio rápido de tema visual.

---

## 4. Variables de Entorno y Sesión (`environment.sh`)

Define las variables globales del sistema:
- `EDITOR="nvim"` y `VISUAL="nvim"`.
- Integración nativa de Wayland para Qt y Electron: `QT_QPA_PLATFORM="wayland;xcb"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- `PATH`: Incluye `~/.local/bin`, `~/.cargo/bin`, `~/.local/share/mise/shims` y Go binaries.
- `DOCKER_HOST`: Socket de usuario rootless de Podman (`/run/user/$UID/podman/podman.sock`).
- `GPG_TTY`: Integración para firmas Git con llaves GPG.

---

## 5. Utilidades y Funciones Avanzadas (`functions.sh`)

- `extract <archivo>`: Extracción universal inteligente (`.tar.gz`, `.tar.xz`, `.zip`, `.7z`, `.tar.zst`, `.rar`, `.bz2`, `.tar.bz2`).
- `mkcd <dir>`: Crea un directorio y accede automáticamente a él.
- `myip`: Muestra la IP pública e interfaz local activa.
- `ports`: Lista los puertos TCP/UDP abiertos y sus procesos asociados (`ss -tulpn`).
- `webm2mp4`: Convierte grabaciones de pantalla WebM a MP4 compatible con H.264.
- `img2jpg` / `img2png`: Conversión y optimización de imágenes en lote.
- `transcode-video-1080p` / `transcode-video-4K`: Recodificación de alta eficiencia con FFmpeg.

---

## 6. Contenedores Podman y Quadlets (`podman-functions.sh`)

- `pps`: Lista de contenedores formateada limpiamente en tabla.
- `pexec <contenedor> [cmd]`: Ejecuta comandos o abre una shell interactiva dentro del contenedor.
- `plogs <contenedor> [lineas]`: Visualiza logs en tiempo real.
- `pclean-total`: Limpieza profunda de contenedores detenidos, imágenes huérfanas y redes no utilizadas.
- `quadlet-reload` / `quadlet-status` / `quadlet-logs`: Control directo de contenedores Systemd Quadlets del usuario.

---

## 7. Sincronización en la Nube (`rclone_aliases.sh`)

- `gdrive-software`: Respaldo bidireccional de instaladores y herramientas.
- `gdrive-kdenlive`: Sincronización de proyectos y recursos de vídeo.
- `gdrive-images`: Respaldo de imágenes y capturas.
- `gdrive-repos`: Respaldo y sincronización de repositorios de código.
- `gdrive-check-all`: Comprobación de integridad de remotos de Google Drive.
- `onedrive-get`: Descarga de carpetas sincronizadas en OneDrive.

---

## 8. Descargas Multimedia con YT-DLP (`yt-dlp_aliases.sh`)

- `ytdl <url>`: Descarga el mejor vídeo disponible en formato MP4 (hasta 1080p).
- `ytdl-audio <url>`: Extrae audio y lo convierte a MP3 de máxima calidad (320k) con metadatos y carátula.
- `ytdl-best <url>`: Descarga en resolución máxima disponible (4K/2K/1080p).
- `ytdl-playlist <url>`: Descarga listas completas organizadas por índice y título.
- `ytdl-update`: Actualiza automáticamente el binario yt-dlp.
