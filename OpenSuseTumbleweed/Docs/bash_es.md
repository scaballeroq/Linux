---
sidebar_position: 3
---

# Configuración de Terminal y Shells en openSUSE Tumbleweed (Bash & Zsh)

Esta guía detalla la configuración del entorno de terminal (optimizado para **Bash** como shell predeterminada del proyecto y compatible con **Zsh** si existe `~/.zshrc`) junto a las utilidades integradas en los scripts modulares de la carpeta `Bash.Setup`.

La carga modular está estructurada a través de los directorios `~/.bashrc.d/` (predeterminado) y `~/.zshrc.d/` (compatibilidad) para garantizar la limpieza, velocidad y mantenibilidad de tus configuraciones.

---

## 1. Carga Modular del Entorno

### Para Bash (Predeterminado - `~/.bashrc`)
El script `./Setup/shell.sh` añade el cargador modular a tu `~/.bashrc`:

```bash
# Carga modular de scripts de Bash.Setup
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### Para Zsh (Compatibilidad condicional si existe `~/.zshrc`)
Si utilizas Zsh y existe `~/.zshrc` en tu sistema:

```zsh
# Carga modular de configuraciones y aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### Enlaces Simbólicos
Puedes habilitar todos los módulos ejecutando `./Setup/shell.sh` o `just shell`:
```bash
# Para Bash (Predeterminado)
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Bash.Setup/*.sh ~/.bashrc.d/

# Para Zsh (si existe ~/.zshrc)
if [ -f "$HOME/.zshrc" ]; then
    mkdir -p ~/.zshrc.d
    ln -sf ~/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Bash.Setup/*.sh ~/.zshrc.d/
fi
```

---

## 2. Variables de Entorno (`environment.sh`)

Define configuraciones globales y optimizaciones para las herramientas del sistema:

- **Editor Predeterminado**: Se establece `nvim` (Neovim), `kate` o `nano` como editor global (`EDITOR`, `VISUAL`).
- **Wayland/Qt**: `QT_QPA_PLATFORM="wayland;xcb"`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- **Ruta de Ejecutables (`PATH`)**: Se añaden directorios locales del usuario:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Activación dinámica e inteligente (`mise activate bash` en Bash / `mise activate zsh` en Zsh).
- **Podman**: `DOCKER_HOST` automático si el socket rootless existe.
- **Paginación Estética (`less` y `man`)**: Colores y flags modernos para páginas man.

---

## 3. Comportamiento de Shell (`options.sh` e `history.sh`)

Optimiza la interacción de la shell mediante ajustes internos adaptados a Zsh y Bash.

### Comportamiento Avanzado (`options.sh`)
* **`autocd` / `AUTO_CD`**: Permite cambiar de directorio escribiendo solo la ruta (sin `cd`).
* **`globstar` / `EXTENDED_GLOB`**: Habilita la expansión recursiva de patrones (ej. `ls **/*.js`).
* **Corrección de Directorios**: `cdspell` en Bash y `setopt CORRECT` en Zsh para corregir errores tipográficos.

### Historial de Comandos (`history.sh`)
* Capacidad expandida: **10,000 comandos** en memoria (`HISTSIZE`), **20,000 en archivo** (`HISTFILESIZE`).
* Omisión de duplicados (`erasedups`, `ignoreboth`) y comandos comunes (`HISTIGNORE`).
* Escritura inmediata tras cada ejecución (`histappend`) y sincronización entre terminales.

---

## 4. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas y seguras:

- **Seguridad**:
  - `rm -i`, `cp -i`, `mv -i` (confirmación interactiva)
  - `--preserve-root` en `chown`, `chmod`, `chgrp`
- **Visualización** (si están instalados `eza` y `bat`):
  - `ls` → `eza --icons --git --group-directories-first`
  - `cat` → `bat --paging=never`
- **Gestión de Paquetes (Zypper & Snapper)**:
  - `dup` / `upgrade` → `sudo zypper dup`
  - `update` → `sudo zypper refresh && sudo zypper dup`
  - `install` → `sudo zypper install`
  - `remove` → `sudo zypper remove -u`
  - `search` → `zypper search`
  - `clean` → `sudo zypper clean --all`
  - `snapshots` → `snapper list`
- **KDE Plasma y Escritorio**:
  - `open` / `o` → `xdg-open`
  - `dolphin` / `files` → Abre Dolphin en directorio actual
  - `trash` → Papelera vía `kioclient6 move "$@" trash:/`
  - `clipcopy` / `clippaste` → Portapapeles Wayland nativo (`wl-clipboard`)

---

## 5. Funciones y Utilidades del Sistema (`functions.sh`)

Incluye funciones avanzadas para simplificar tareas recurrentes:

* **`extract`**: Extrae automáticamente casi cualquier archivo comprimido (`.tar.gz`, `.tar.bz2`, `.zip`, `.rar`, `.7z`, etc.).
* **`mkcd`**: Crea una carpeta y entra en ella directamente.
* **`up <N>`**: Sube `N` niveles en el árbol de directorios.
* **`duh`**: Muestra tamaño de carpetas ordenadas por espacio utilizado.
* **Procesamiento Multimedia**:
  - `webm2mp4`: Convierte WebM a MP4 manteniendo alta calidad.
  - `transcode-video-1080p` / `transcode-video-4k`: Transcodifica video con FFmpeg.
  - `img2jpg` / `img2png`: Convierte y optimiza imágenes.

---

## 6. Configuración de KDE Plasma 6 (`kde_settings.sh`)

Aplica configuraciones automáticas y atajos para el entorno de escritorio **KDE Plasma 6 (Wayland)**:

- **Reinicio del Entorno**: `plasma-restart`, `kwin-restart`.
- **Tema Oscuro y Claro**: `kde-theme-dark` (Breeze Dark), `kde-theme-light` (Breeze Light).
- **Preferencias del Sistema (KCM)**: Atajos directos a módulos de configuración:
  - `kde-settings` (Preferencias generales)
  - `kde-conf-display` (KScreen)
  - `kde-conf-audio` (Control de volumen y dispositivos)
  - `kde-conf-bluetooth` (Bluetooth)
  - `kde-conf-power` (PowerDevil / Gestión de energía)
  - `kde-conf-shortcuts` (Atajos de teclado KWin)
  - `kde-conf-touchpad` (Touchpad)
  - `kde-conf-appearance` (Aspecto visual)
- **Luz Nocturna (Night Color)**: `kde-night-light-on`, `kde-night-light-off`.
- **Herramientas de KDE**: `dolphin`, `kate`, `kwrite`, `spectacle` (`captura`), `sysmon` (`plasma-systemmonitor`).

---

## 7. Sincronización en la Nube (`rclone_aliases.sh` e `yt-dlp_aliases.sh`)

### Sincronización Rclone
Facilita la sincronización con Google Drive y OneDrive:
- `rclone-documentos`: Sincroniza local → nube
- `rclone-videos-down`: Descarga archivos multimedia de la nube
- `rclone-onedrive-down`: Descarga desde OneDrive

### Descargas yt-dlp
- `ytvideo <URL>`: Descarga video en 1080p
- `ytaudio <URL>`: Descarga y convierte a MP3
- `ytlista <URL>`: Descarga listas de reproducción
- `ytdl-subs <URL>`: Descarga con subtítulos en español

---

## 8. Funciones para Contenedores (`podman-functions.sh`)

Aliases y funciones que simplifican el control de contenedores con Podman y Quadlets rootless:

- `p` → `podman`
- `pps` → `podman ps` con formato de tabla
- `pexec <contenedor>`: Ejecutar comandos en contenedor
- `plogs <contenedor>`: Ver logs en tiempo real
- `pinfo <contenedor>`: Inspeccionar contenedor
- `pclean-total`: Limpieza completa del sistema de contenedores
- **Quadlets**:
  - `quadlet-reload`: `systemctl --user daemon-reload`
  - `quadlet-status`: Estado de servicios container-*
  - `quadlet-logs <servicio>`: Logs de servicio Quadlet
