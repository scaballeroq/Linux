---
sidebar_position: 3
---

# Configuración de Terminal y Shells en Fedora 44 Workstation (Bash & Zsh)

Esta guía detalla la configuración del entorno de terminal (optimizado para **Bash** como shell predeterminada del proyecto y compatible con **Zsh** si existe `~/.zshrc`) junto a las utilidades integradas en los scripts modulares de la carpeta `Bash.Setup`.

La carga modular está estructurada a través de los directorios `~/.bashrc.d/` (predeterminado) y `~/.zshrc.d/` (compatibilidad) para garantizar la limpieza, velocidad y mantenibilidad de tus configuraciones.

---

## 1. Carga Modular del Entorno

### Para Bash (Predeterminado - `~/.bashrc`)
Añade el siguiente bloque a tu archivo `~/.bashrc`:

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
Puedes habilitar todos los módulos ejecutando `./Setup/shell.sh` o manualmente:
```bash
# Para Bash (Predeterminado)
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Fedora 44 Workstation/Bash.Setup/*.sh ~/.bashrc.d/

# Para Zsh (si existe ~/.zshrc)
if [ -f "$HOME/.zshrc" ]; then
    mkdir -p ~/.zshrc.d
    ln -sf ~/Workspace/Repositorios/Linux/Fedora 44 Workstation/Bash.Setup/*.sh ~/.zshrc.d/
fi
```

---

## 2. Variables de Entorno (`environment.sh`)

Define configuraciones globales y optimizaciones para las herramientas del sistema:

- **Editor Predeterminado**: Se establece `nvim` (Neovim) o `nano` como editor global (`EDITOR`, `VISUAL`).
- **Wayland/Qt**: `QT_QPA_PLATFORM="wayland;xcb"`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- **Ruta de Ejecutables (`PATH`)**: Se añaden directorios locales del usuario:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Activación dinámica e inteligente (`mise activate zsh` en Zsh / `mise activate bash` en Bash).
- **Podman**: `DOCKER_HOST` automático si el socket existe.
- **Paginación Estética (`less` y `man`)**: Colores y flags modernos para páginas man.

---

## 3. Comportamiento de Shell (`options.sh` e `history.sh`)

Optimiza la interacción de la shell mediante ajustes internos adaptados a Zsh y Bash.

### Comportamiento Avanzado (`options.sh`)
* **`autocd` / `AUTO_CD`**: Permite cambiar de directorio escribiendo solo la ruta (sin `cd`).
* **`globstar` / `EXTENDED_GLOB`**: Habilita la expansión recursiva de patrones (ej. `ls **/*.js`).
* **Corrección de Directorios**: `setopt CORRECT` en Zsh y `cdspell` en Bash para corregir errores tipográficos.
* **Autocompletado Inteligente en Zsh**: `zstyle` con distinción insensible a mayúsculas, navegación con flechas (`menu select`) y colores con `LS_COLORS`.

### Historial de Comandos (`history.sh`)
* Capacidad expandida: **10,000 comandos** en memoria (`HISTSIZE`), **20,000 en archivo** (`SAVEHIST` / `HISTFILESIZE`).
* Omisión de duplicados (`HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`, `erasedups`) y comandos comunes (`HISTORY_IGNORE` / `HISTIGNORE`).
* Escritura inmediata tras cada ejecución (`INC_APPEND_HISTORY` / `histappend`) y sincronización entre terminales (`SHARE_HISTORY`).


---

## 4. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas y seguras:

- **Seguridad**:
  - `rm -i`, `cp -i`, `mv -i` (confirmación interactiva)
  - `--preserve-root` en `chown`, `chmod`, `chgrp`
- **Visualización** (si están instalados `eza` y `bat`):
  - `ls` → `eza --icons --git --group-directories-first`
  - `cat` → `bat --paging=never`
- **Gestión de Paquetes (DNF5)**:
  - `update` → `sudo dnf5 check-update --refresh`
  - `upgrade` → `sudo dnf5 upgrade --refresh -y`
  - `install` → `sudo dnf5 install`
  - `remove` → `sudo dnf5 remove`
  - `search` → `dnf5 search`
  - `clean` → `sudo dnf5 autoremove -y && sudo dnf5 clean all`
- **GNOME y Escritorio**:
  - `open` / `o` → `xdg-open`
  - `nautilus` / `files` → Abre Nautilus en directorio actual
  - `clipcopy` / `clippaste` → Portapapeles Wayland nativo (`wl-clipboard`)
- **Kernel Check**: `check-kernel` compara kernel activo vs kernel.org

---

## 5. Funciones y Utilidades del Sistema (`functions.sh`)

Incluye funciones en bash para simplificar tareas recurrentes:

* **`extract`**: Extrae automáticamente casi cualquier archivo comprimido.
* **`mkcd`**: Crea una carpeta y entra en ella.
* **`up <N>`**: Sube `N` niveles en el árbol de directorios.
* **`duh`**: Muestra tamaño de carpetas ordenadas por peso.
* **Procesamiento Multimedia**:
  - `webm2mp4`: Convierte WebM a MP4.
  - `transcode-video-1080p` / `transcode-video-4k`: Transcodifica video.
  - `img2jpg` / `img2png`: Convierte y optimiza imágenes.

---

## 6. Configuración de GNOME (`gnome_settings.sh`)

Aplica configuraciones automáticas y atajos para el entorno de escritorio GNOME:

- **Tema Oscuro**: `gnome-theme-dark`, `gnome-theme-light`
- **GNOME Control Center**: Accesos directos a módulos de configuración (`gnome-settings`, `gnome-pantallas`, `gnome-wifi`, `gnome-audio`, `gnome-bluetooth`, `gnome-teclado`, `gnome-energia`, `gnome-red`, `gnome-info`)
- **Luz Nocturna**: `gnome-night-light-on`, `gnome-night-light-off`
- **Herramientas Wayland**: `captura` (grim + slurp + satty/wl-copy), `grabacion` (wl-screenrec)
- **Explorador de Archivos**: `nautilus`, `files`

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

Aliases y funciones que simplifican el control de contenedores con Podman y Quadlets:

- `p` → `podman`
- `pps` → `podman ps` con formato de tabla
- `pexec <contenedor>`: Ejecutar comandos en contenedor
- `plogs <contenedor>`: Ver logs en tiempo real
- `pinfo <contenedor>`: Inspeccionar contenedor
- `pclean-total`: Limpieza completa del sistema
- **Quadlets**:
  - `quadlet-reload`: `systemctl --user daemon-reload`
  - `quadlet-status`: Estado de servicios container-*
  - `quadlet-logs <servicio>`: Logs de servicio Quadlet
