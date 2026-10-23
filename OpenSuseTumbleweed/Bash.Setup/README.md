# 🐚 Bash.Setup - Configuración Modular de Bash para openSUSE Tumbleweed

Este directorio contiene la configuración modular de Bash para **openSUSE Tumbleweed + KDE Plasma 6 (Wayland)**, optimizada para la estación de trabajo HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U, Vega 7 GPU, Btrfs + Snapper, Firewalld y Podman rootless).

---

## 📁 Estructura de Módulos

- **`aliases.sh`**:
  - Navegación rápida por el monorepo y proyectos (`opensuse`, `tumbleweed`, `linux`, `repo`).
  - Gestión nativa de paquetes con **Zypper** (`dup`, `update`, `install`, `remove`, `search`, `clean`).
  - Control de instantáneas Btrfs con **Snapper** (`snapshots`, `snap-status`, `snap-diff`, `snap-create`, `snap-rollback`).
  - Herramientas modernas en Rust (`eza`, `bat`, `duf`, `dust`, `procs`, `btm`).
  - Control de cortafuegos exclusivo con **Firewalld** (`fw`, `fw-status`, `fw-active`, `fw-ports`, `fw-services`, `fw-all`, `fw-reload`).
  - Monitorización de hipervisor KVM/Libvirt (`vms`, `vmstart`, `vmstop`, `vminfo`).
  - Verificación de kernel activo contra kernel.org (`check-kernel`).
  - Actualizadores de Antigravity (`update-antigravity`, `update-antigravity-ide`).

- **`environment.sh`**:
  - Variables de entorno globales (`EDITOR=nvim/nano`, `PAGER=less` coloreado).
  - Integración nativa Wayland y Qt 6 (`QT_QPA_PLATFORM="wayland;xcb"`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`, `MOZ_ENABLE_WAYLAND=1`).
  - Rutas de usuario (`~/bin`, `~/.local/bin`, `~/.cargo/bin`, `~/go/bin`, `~/.local/share/mise/shims`).
  - Socket rootless de Podman compatible con Docker CLI (`DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"`).
  - Optimización de **uv** para Btrfs con reflinks Copy-on-Write (`UV_LINK_MODE="clone"`).
  - Conexión por defecto a Libvirt KVM (`LIBVIRT_DEFAULT_URI="qemu:///system"`).
  - Activación automática de Mise para shims de versiones.

- **`functions.sh`**:
  - Navegación y utilidades de archivos (`mkcd`, `up`, `extract`, `backup`, `compress`).
  - Búsqueda de procesos y análisis de disco (`psgrep`, `duh`, `hg`).
  - Gestión de discos e imágenes (`iso2sd`, `format-drive` exFAT GPT).
  - Transcodificación multimedia con FFmpeg (H.264, HEVC 4K, WebM a MP4).
  - Optimización de imágenes por lotes con ImageMagick (`img2jpg`, `img2jpg-small`, `img2png`).

- **`kde_settings.sh`**:
  - Reinicio seguro de sesión KDE Plasma 6 y KWin Wayland (`plasma-restart`, `kwin-restart` vía `qdbus6`).
  - Alternador de temas claro/oscuro Breeze (`kde-theme-dark`, `kde-theme-light`).
  - Luz nocturna por software (`kde-night-light-on`, `kde-night-light-off` vía `kwriteconfig6` y `qdbus6`).
  - Accesos rápidos a módulos KCM de `systemsettings` (`kcmshell6`).
  - Portapapeles Wayland (`wl-copy`, `wl-paste`) y utilidades gráficas (`spectacle`, `dolphin`).

- **`history.sh`**:
  - Historial persistente optimizado (10.000 comandos en memoria, 20.000 en disco).
  - Control estricto de duplicados y comandos vacíos (`ignoreboth:erasedups`).
  - Marcado temporal ISO (`%F %T `).
  - Filtro de comandos triviales de navegación en `HISTIGNORE`.

- **`options.sh`**:
  - Opciones de navegación (`cdspell`, `autocd`, `globstar`, `checkwinsize`).
  - Readline interactivo (autocompletado insensible a mayúsculas, estadísticas coloreadas).

- **`podman-functions.sh`**:
  - Gestión de contenedores rootless (`pps`, `pexec`, `plogs`, `pinfo`, `pcp`).
  - Limpieza de imágenes huérfanas y contenedores detenidos (`prm-stopped`, `prmi-dangling`, `pclean-total`).
  - Orquestación y estado de Quadlets Systemd de usuario (`quadlet-status`, `quadlet-reload`, `quadlet-logs`).

- **`rclone_aliases.sh`**:
  - Sincronización y copias de seguridad en Google Drive y OneDrive con control de tasa (`--tpslimit 10`, `--fast-list`).
  - Modos normales y simulaciones seguras (`--dry-run`).

- **`yt-dlp_aliases.sh`**:
  - Descargas de vídeo hasta 1080p y extracción de audio MP3 (320 kbps).
  - Listas de reproducción y subtítulos bilingües (ES/EN) con cookies de sesión de Chrome/Firefox.
  - Limpieza de caché (`ytclean`).

---

## 🛠️ Instalación y Carga en openSUSE

Para activar la carga modular en openSUSE Tumbleweed, añade el siguiente bloque a tu `~/.bashrc`:

```bash
# Carga modular de Bash.Setup de openSUSE Tumbleweed
BASH_SETUP_DIR="$HOME/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Bash.Setup"
if [ -d "$BASH_SETUP_DIR" ]; then
    for script in "$BASH_SETUP_DIR"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script BASH_SETUP_DIR
fi
```

O alternativamente, vincula los scripts al directorio estándar `~/.bashrc.d/`:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Bash.Setup/*.sh ~/.bashrc.d/
```
