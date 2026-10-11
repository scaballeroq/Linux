---
sidebar_position: 3
---

# Configuración de Bash en Kubuntu (KDE Plasma)

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
ln -s ~/Workspace/Repositorios/Kubuntu/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Variables de Entorno (`environment.sh`)

Define configuraciones globales y optimizaciones para las herramientas del sistema:

- **Editor Predeterminado**: Se establece `nvim` (Neovim) o `nano` como editor global.
- **Ruta de Ejecutables (`PATH`)**: Se añaden directorios locales del usuario a la variable de entorno:
  - `~/.local/bin`
  - `~/bin`
  - Carpeta de binarios de Cargo/Rust (`~/.cargo/bin`)
  - Shims de Mise (`~/.local/share/mise/shims`)
- **Paginación Estética (`less` y `man`)**: Se configuran colores y flags para hacer las páginas del manual de Linux (`man`) y la visualización de texto con `less` más legibles.

---

## 3. Comportamiento de Bash (`options.sh` e `history.sh`)

Optimiza la interacción de la shell mediante ajustes internos.

### Comportamiento Avanzado (`options.sh`)
* **`autocd`**: Permite cambiar de directorio escribiendo solo la ruta (sin necesidad de anteponer `cd`).
* **`globstar`**: Habilita la expansión recursiva de patrones de búsqueda (ej. `ls **/*.js`).
* **Corrección de Directorios**: Habilita `cdspell` y `dirspell` para corregir automáticamente pequeños errores tipográficos al escribir nombres de carpetas.

### Historial de Comandos (`history.sh`)
* Capacidad expandida de hasta **10,000 comandos** en memoria y **20,000 en archivo**.
* Omisión de duplicados y comandos comunes (`history -a`, `histignore`).
* Formato de fecha y hora para auditoría precisa.

---

## 4. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas y seguras:

- **Seguridad**:
  - `rm -i` (confirmar borrado de archivos)
  - `cp -i` (confirmar sobreescritura al copiar)
  - `mv -i` (confirmar sobreescritura al mover)
  - Medida preventiva `--preserve-root` habilitada por defecto.
- **Visualización de Archivos** (con `eza` y `bat`):
  - `ls`, `ll`, `la`, `lt`, `tree` mapeados a `eza` con iconos y metadatos git.
  - `cat` y `less` mapeados a `bat` con resaltado de sintaxis.
- **Utilidades Modernas de Rust**:
  - `df` -> `duf`, `du` -> `dust`, `ps` -> `procs`, `top` -> `btm`.
- **Virtualización (KVM/Libvirt)**:
  - `vms`, `vmstart`, `vmstop`, `vminfo`.
- **Accesos Rápidos**:
  - `..`, `...`, `....` para subir directorios rápidamente.
  - `c` para limpiar pantalla (`clear`).
  - `ff` / `sysinfo` para Fastfetch.

---

## 5. Funciones y Utilidades del Sistema (`functions.sh`)

Incluye funciones en bash para simplificar tareas recurrentes:

* **`extract`**: Extrae automáticamente cualquier archivo comprimido (`.zip`, `.tar.gz`, `.bz2`, `.rar`, `.7z`, `.tar.zst`).
* **`mkcd`**: Crea una nueva carpeta y entra automáticamente en ella.
* **`up <N>`**: Sube `N` niveles en el árbol de directorios (ej. `up 3`).
* **`backup`**: Crea una copia de seguridad con fecha y hora (`.bak_YYYYMMDD_HHMMSS`).
* **`duh`**: Muestra los directorios más pesados ordenados por peso.
* **`iso2sd`**: Graba una imagen ISO en USB/SD de forma guiada y segura.
* **`format-drive`**: Formatea discos en FAT32, NTFS, EXT4 o EXFAT.
* **Procesamiento Multimedia**:
  - `webm2mp4`: Convierte grabaciones en formato WebM a MP4 estándar.
  - `transcode-video-1080p` / `transcode-video-720p`: Optimización de vídeo.
  - `img2jpg` / `img2png`: Convierte y optimiza imágenes rápidamente vía consola.

---

## 6. Sincronización en la Nube (`rclone_aliases.sh` e `yt-dlp_aliases.sh`)

### Sincronización Rclone
Facilita la sincronización (`sync`), copia (`copy`) y simulaciones (`dry-run`) bidireccionales con Google Drive y OneDrive con límites de tasa (`--tpslimit 10`) y `--fast-list`:
- `gdrive-documentos` / `gdrive-documentos-copy`: Local <-> Nube.
- `gdrive-videos-down` / `gdrive-videos-down-copy`: Descarga multimedia.
- `gdrive-repos-kubuntu`: Respaldo del repositorio Kubuntu.

### Descargas yt-dlp
- `ytvideo <URL>`: Descarga video en calidad óptima (hasta 1080p).
- `ytaudio <URL>`: Descarga y convierte a formato MP3 de alta fidelidad.
- `ytlista` / `ytlista-audio`: Descarga listas de reproducción completas.

---

## 7. Entorno de Escritorio (`desktop_settings.sh`)

Aplica configuraciones y define atajos/aliases automáticos detectando el entorno de escritorio activo (KDE Plasma o GNOME):
- **KDE Plasma**: Configura la luz nocturna y previene la suspensión en corriente alterna mediante `kwriteconfig5`/`kwriteconfig6` y `qdbus6`/`qdbus`, además de añadir aliases (`kde-night-light-on/off`, `kde-theme-dark/light`, `kde-conf`, `kde-restart-kwin`).
- **GNOME**: Configura luz nocturna, formato 24h, porcentaje de batería y botones de ventana mediante `gsettings`.

---

## 8. Funciones para Contenedores (`podman-functions.sh`)

Aliases y funciones no colisionantes que simplifican el control de contenedores y Pods de Podman:
- `psh <contenedor>`: Abre una shell interactiva dentro del contenedor indicado.
- `plogs <contenedor>`: Muestra e interactúa con los logs en tiempo real (`--tail 100`).
- `ppsf` / `ppsaf`: Lista contenedores con formato de tabla limpia.
- `pstats`: Métricas en vivo de CPU, RAM e I/O.
- `pclean` / `pclean-all`: Realiza una purga completa del sistema de contenedores.
