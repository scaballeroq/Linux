---
sidebar_position: 3
---

# Configuración de Bash en CachyOS

Esta guía detalla la configuración del entorno de terminal (Bash) y las utilidades integradas en los scripts modulares de la carpeta `Bash.Setup`.

La carga modular está estructurada a través del directorio `~/.bashrc.d/` para garantizar la limpieza y mantenibilidad del archivo `~/.bashrc`.

---

## 1. Carga Modular del Entorno

Los scripts se cargan de forma dinámica añadiendo el siguiente bloque al archivo `~/.bashrc`:

```bash
# Carga modular de scripts de Bash.Setup
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Puedes habilitarlos creando enlaces simbólicos en `~/.bashrc.d/`:
```bash
mkdir -p ~/.bashrc.d
ln -s ~/Workspace/Repositorios/Linux/CachyOS/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Variables de Entorno (`environment.sh`)

Define configuraciones globales y optimizaciones para las herramientas del sistema:

- **Editor Predeterminado**: Se establece `nvim` (Neovim) como editor global.
- **Wayland/Qt**: `QT_QPA_PLATFORM="wayland;xcb"`, `MOZ_ENABLE_WAYLAND=1`, `ELECTRON_OZONE_PLATFORM_HINT="auto"`
- **Ruta de Ejecutables (`PATH`)**: Se añaden directorios locales del usuario:
  - `~/.local/bin`
  - `~/bin`
  - `~/.cargo/bin` (Rust/Cargo)
  - `~/go/bin` (Go)
- **MISE**: Activación del gestor de versiones polyglot
- **Podman**: `DOCKER_HOST` automático si el socket existe
- **Paginación Estética (`less` y `man`)**: Colores y flags para hacer las páginas del manual más legibles.

---

## 3. Comportamiento de Bash (`options.sh` e `history.sh`)

Optimiza la interacción de la shell mediante ajustes internos.

### Comportamiento Avanzado (`options.sh`)
* **`autocd`**: Permite cambiar de directorio escribiendo solo la ruta (sin `cd`).
* **`globstar`**: Habilita la expansión recursiva de patrones (ej. `ls **/*.js`).
* **Corrección de Directorios**: `cdspell` y `dirspell` para corregir errores tipográficos.
* **Completado insensible a mayúsculas**: `bind 'set completion-ignore-case on'`.

### Historial de Comandos (`history.sh`)
* Capacidad expandida: **10,000 comandos** en memoria, **20,000 en archivo**.
* Omisión de duplicados (`erasedups`) y comandos comunes (`HISTIGNORE`).
* Escritura inmediata tras cada ejecución.

---

## 4. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas y seguras:

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
- **KDE Plasma**:
  - `open` / `o` → `xdg-open`
  - `dolphin` → Abre Dolphin en directorio actual
  - `clipcopy` / `clippaste` → Portapapeles Wayland/X11
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

## 6. Configuración de KDE Plasma 6 (`kde_settings.sh`)

Aplica configuraciones automáticas para el entorno de escritorio KDE Plasma 6:

- **Touchpad**: Tap-to-click, desplazamiento natural
- **Botones de ventana**: Minimizar, Maximizar, Cerrar a la derecha
- **Reloj**: Formato 24 horas, fecha ISO
- **KWin**: Recargar configuración sin reiniciar sesión
- **KCM Shell**: Accesos directos a módulos de configuración (pantallas, wifi, audio, bluetooth, etc.)
- **Temas**: `kde-theme-dark`, `kde-theme-light`, `kde-set-wallpaper`
- **Spectacle**: `captura` (captura de región), `grabacion` (grabación de pantalla)
- **Plasmoids**: `plasmoids-list`, `kwin-scripts-list`

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
