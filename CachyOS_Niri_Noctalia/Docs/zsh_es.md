---
sidebar_position: 3
---

# Configuración de Terminal y Zsh en CachyOS (ZSH.Setup)

Esta guía detalla la configuración del entorno de terminal (optimizado primordialmente para **Zsh**, la shell predeterminada en CachyOS, con compatibilidad para **Bash**) junto a las utilidades modulares organizadas en el directorio `ZSH.Setup`.

La carga modular está estructurada a través de los directorios `~/.zshrc.d/` y `~/.bashrc.d/` para garantizar modularidad, velocidad y mantenibilidad de tus configuraciones.

---

## 1. Carga Modular del Entorno

### Para Zsh (`~/.zshrc`)
Añade el siguiente bloque a tu archivo `~/.zshrc`:

```zsh
# Carga modular de configuraciones y aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### Para Bash (`~/.bashrc`) - Respaldo
Añade el siguiente bloque a tu archivo `~/.bashrc`:

```bash
# Carga modular de scripts de ZSH.Setup
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### Enlaces Simbólicos
Puedes habilitar todos los módulos ejecutando `./Setup/shell.sh` o manualmente:
```bash
mkdir -p ~/.zshrc.d ~/.bashrc.d
ln -sf /home/caballero/Warehouse/Repositorios/Linux/CachyOS_Niri_Noctalia/ZSH.Setup/*.sh ~/.zshrc.d/
ln -sf /home/caballero/Warehouse/Repositorios/Linux/CachyOS_Niri_Noctalia/ZSH.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Variables de Entorno (`environment.sh`)

Define configuraciones globales y optimizaciones para las herramientas del sistema:

- **Deduplicación de PATH (Zsh)**: Se activa `typeset -U path` para prevenir rutas repetidas.
- **Editor Predeterminado**: Se establece `nvim` (Neovim) o `nano` como editor global (`EDITOR`, `VISUAL`).
- **Wayland/Qt (Niri & Noctalia)**: `XDG_CURRENT_DESKTOP="niri"`, `XDG_SESSION_TYPE="wayland"`, `QT_QPA_PLATFORM="wayland;xcb"`, `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`.
- **Ruta de Ejecutables (`PATH`)**: Se añaden directorios locales del usuario:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Activación dinámica (`mise activate zsh` en Zsh / `mise activate bash` en Bash).
- **Podman Rootless**: `DOCKER_HOST` automático si el socket existe en `$XDG_RUNTIME_DIR/podman/podman.sock`.
- **Paginación Estética (`less` y `man`)**: Colores y flags modernos para páginas man.

---

## 3. Comportamiento de Shell (`options.sh` e `history.sh`)

Optimiza la interacción de la shell mediante ajustes internos adaptados a Zsh.

### Comportamiento Avanzado (`options.sh`)
* **`AUTO_CD`**: Permite cambiar de directorio escribiendo solo la ruta (sin `cd`).
* **`EXTENDED_GLOB`**: Habilita la expansión recursiva de patrones avanzados (ej. `ls **/*.js`).
* **Corrección de Directorios**: `setopt CORRECT` en Zsh para sugerir correcciones tipográficas.
* **Sin pitidos**: `setopt NO_BEEP` desactiva sonidos molestos de campana.
* **Autocompletado Inteligente en Zsh**: `zstyle` con distinción insensible a mayúsculas, navegación con flechas (`menu select`) y colores con `LS_COLORS`.

### Historial de Comandos (`history.sh`)
* Capacidad expandida: **50,000 comandos** en memoria (`HISTSIZE`) y en archivo (`SAVEHIST`).
* **`EXTENDED_HISTORY`**: Registra fecha, hora y duración exacta de cada comando ejecutado.
* Omisión de duplicados (`HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`) y comandos comunes (`HISTORY_IGNORE`).
* Escritura inmediata tras cada ejecución (`INC_APPEND_HISTORY`) y sincronización en tiempo real entre terminales (`SHARE_HISTORY`).

---

## 4. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas y seguras:

- **Navegación Rápida**:
  - `cachyos` / `project`: Navega directamente a `/home/caballero/Warehouse/Repositorios/Linux/CachyOS_Niri_Noctalia`
  - `repo` / `repos`: Navega a `/home/caballero/Warehouse/Repositorios`
  - `..`, `...`, `....`: Subir 1, 2 o 3 niveles
- **Pipes Globales de Zsh** (atajos de sufijo):
  - `G` → `| grep -i` (ej. `cat file G error`)
  - `L` → `| less`
  - `H` → `| head -n 20`
  - `T` → `| tail -n 20`
  - `J` → `| jq`
- **Seguridad**:
  - `rm -i`, `cp -i`, `mv -i` (confirmación interactiva)
  - `--preserve-root` en `chown`, `chmod`, `chgrp`
- **Visualización** (si están instalados `eza` y `bat`):
  - `ls` → `eza --icons --git --group-directories-first`
  - `cat` → `bat --paging=never`
- **Gestión de Paquetes (Pacman/Paru)**:
  - `update` → `sudo pacman -Syu`
  - `install` → `sudo pacman -S`
  - `aur` → `paru` o `yay` (según disponible)
  - `rate-mirrors` → `cachyos-rate-mirrors`
- **Escritorio Wayland (Niri / Noctalia)**:
  - `open` / `o` → `xdg-open`
  - `files` → Abre explorador de archivos en directorio actual
  - `clipcopy` / `clippaste` → Portapapeles Wayland (`wl-copy` / `wl-paste`)
- **Kernel Check**: `check-kernel` compara kernel activo vs kernel.org
- **Recarga rápida**: `reload` (`source ~/.zshrc`), `edit-zshrc`, `edit-aliases`

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

## 6. Configuración de Niri y Noctalia Shell (`niri_noctalia.sh`)

Proporciona integración, atajos e IPC directo con el compositor scrollable-tiling **Niri** y la shell **Noctalia**:

- **Niri IPC**:
  - `niri-reload`: Recarga la configuración de Niri en caliente (`~/.config/niri/config.kdl`)
  - `niri-validate`: Valida la sintaxis del archivo de configuración KDL
  - `niri-windows` / `niri-focused` / `niri-outputs`: Consulta el estado de ventanas y monitores
  - `niri-quit`: Cierra la sesión de Niri limpiamente
- **Noctalia Shell IPC**:
  - `noctalia-reload`: Recarga o reinicia la shell Noctalia
  - `noctalia-launcher`: Despliega el lanzador de aplicaciones
  - `noctalia-control`: Abre el Centro de Control (Wi-Fi, Bluetooth, Audio, perfiles)
  - `noctalia-settings`: Abre los ajustes de Noctalia Shell
  - `noctalia-lock`: Bloquea la sesión de usuario
  - `noctalia-set-wallpaper <ruta>`: Aplica fondo de pantalla mediante IPC
- **Capturas y Grabación Wayland**:
  - `captura`: Selección interactiva de región directa al portapapeles con `grim` + `slurp`
  - `captura-pantalla`: Captura pantalla completa al portapapeles
  - `captura-archivo`: Guarda la captura con fecha y hora en `~/Imágenes/Capturas/`
  - `grabacion`: Grabación interactiva de región a video MP4 con `wl-screenrec`
- **Ajustes Rápidos**:
  - `audio-settings`: Abre interfaz de audio `pavucontrol`
  - `bluetooth-settings`: Abre gestor de dispositivos `blueman-manager`
  - `wifi-settings`: Abre editor de conexiones de red `nm-connection-editor`

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
