---
sidebar_position: 3
---

# Configuración y Funciones de ZSH en Manjaro Linux (Zsh.Setup)

Manjaro Linux incorpora **ZSH** como su shell por defecto. Esta guía documenta de forma exhaustiva la arquitectura modular de `Zsh.Setup`, todas las funciones integradas, los atajos de teclado, las utilidades específicas para Manjaro/Arch y su interoperabilidad con el sistema.

---

## 1. Carga Modular del Entorno

Los módulos de configuración se estructuran de forma desacoplada dentro de `Zsh.Setup/` y se cargan automáticamente añadiendo el siguiente bloque al archivo `~/.zshrc`:

```zsh
# Carga Modular de Zsh.Setup (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.zsh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

## 2. Catálogo de Funciones Adaptadas a Manjaro

Todas las funciones están optimizadas para la sintaxis nativa de ZSH y los gestores de paquetes del ecosistema Arch/Manjaro (`pacman`, `pamac`, `mhwd`).

### 🐧 Gestión del Sistema Manjaro y Paquetes (`functions.zsh`)

| Función | Parámetros | Descripción y Ejemplo |
| :--- | :--- | :--- |
| `manjaro-mirrors-fast` | Ninguno | Prueba la latencia de todos los servidores espejo y selecciona los 5 más rápidos sincronizando la base de datos.<br/>`manjaro-mirrors-fast` |
| `pacman-clean-all` | Ninguno | Limpia la caché descargada de `pacman`, la caché de compilación de `pamac`/AUR y desinstala automáticamente los paquetes huérfanos sin dependencias.<br/>`pacman-clean-all` |
| `aur-search` | `<termino>` | Busca paquetes en el Arch User Repository (AUR) mediante Pamac o consulta directa a la API de AUR.<br/>`aur-search visual-studio-code-bin` |
| `pamac-build-aur` | `<paquete>` | Descarga, compila e instala un paquete directamente desde AUR.<br/>`pamac-build-aur spotify` |
| `check-kernel` | Ninguno | Consulta la API oficial de `kernel.org`, compara la última versión estable con tu kernel activo (`uname -r`) y te sugiere si es necesario compilar con `just build-kernel`.<br/>`check-kernel` |

---

### 📂 Navegación y Gestión de Archivos

| Función | Parámetros | Descripción y Ejemplo |
| :--- | :--- | :--- |
| `mkcd` | `<directorio>` | Crea un árbol de directorios con `mkdir -p` y se posiciona dentro de él inmediatamente.<br/>`mkcd proyectos/backend/api` |
| `up` | `[niveles]` | Sube `n` niveles en el árbol de carpetas de forma ágil (por defecto 1 nivel).<br/>`up 3` (equivale a `cd ../../..`) |
| `backup` | `<archivo>` | Genera una copia de seguridad inmediata agregando la extensión `.bak-AAAAMMDD-HHMMSS`.<br/>`backup /etc/pacman.conf` |
| `extract` | `<archivo>` | Extractor universal que detecta automáticamente el formato (`.tar.gz`, `.tar.bz2`, `.tar.xz`, `.tar.zst`, `.pkg.tar.zst`, `.zip`, `.rar`, `.7z`, etc.) y aplica la herramienta adecuada.<br/>`extract paquete.tar.zst` |
| `compress` | `<directorio>` | Comprime una carpeta completa en formato `.tar.gz` de alta compresión.<br/>`compress mi-proyecto` |

---

### 💻 Monitorización y Diagnóstico del Sistema

| Función | Parámetros | Descripción y Ejemplo |
| :--- | :--- | :--- |
| `psgrep` | `<nombre>` | Busca procesos activos en memoria mostrando la cabecera completa de columnas (`USER`, `PID`, `%CPU`, `%MEM`, `VSZ`, `COMMAND`) y filtrando el propio comando grep.<br/>`psgrep podman` |
| `duh` | `[directorio]` | Muestra el consumo en disco del directorio actual o indicado, ordenado de mayor a menor en formato legible (GB/MB).<br/>`duh /var/log` |
| `hg` | `<termino>` | Búsqueda rápida e interactiva dentro del historial de comandos ZSH mediante `fc -l 1`.<br/>`hg git commit` |

---

### 💾 Discos y Medios de Almacenamiento

| Función | Parámetros | Descripción y Ejemplo |
| :--- | :--- | :--- |
| `iso2sd` | `<iso> <dispositivo>` | Graba una imagen ISO en una memoria USB o tarjeta SD usando `dd` con buffer de 4M, bandera `oflag=sync` y expulsión segura.<br/>`iso2sd ~/Descargas/manjaro.iso /dev/sda` |
| `format-drive` | `<dispositivo> <nombre>` | Limpia la unidad, recrea una tabla GPT y formatea la primera partición en sistema de archivos `exFAT` (compatible con Windows, macOS y Linux).<br/>`format-drive /dev/sdb 'Pendrive'` |

---

### 🎬 Multimedia y Conversión

| Función | Parámetros | Descripción y Ejemplo |
| :--- | :--- | :--- |
| `webm2mp4` | `<archivo.webm>` | Convierte grabaciones de pantalla de GNOME WebM a MP4 compatible usando H.264 y AAC a 192k.<br/>`webm2mp4 captura.webm` |
| `transcode-video-1080p` | `<video>` | Re-codifica vídeo a resolución 1080p Full HD manteniendo el audio original y optimizando el bitrate.<br/>`transcode-video-1080p video.mkv` |
| `transcode-video-4K` | `<video>` | Convierte y optimiza contenido 4K utilizando el códec de alta eficiencia H.265 (HEVC).<br/>`transcode-video-4K pelicula.mp4` |
| `img2jpg` | `<imagen>` | Optimiza imágenes a JPG de alta fidelidad (calidad 95%) eliminando metadatos EXIF pesados con ImageMagick.<br/>`img2jpg foto.png` |
| `img2jpg-small` | `<imagen>` | Redimensiona a un ancho máximo de 1080px y comprime a JPG para compartir en web o redes.<br/>`img2jpg-small banner.png` |
| `img2png` | `<imagen>` | Aplica compresión sin pérdida máxima (`level 9`, `strategy 1`) para archivos PNG.<br/>`img2png icono.png` |

---

### 🐳 Gestión de Podman Quadlets (`podman-functions.zsh`)

| Función / Alias | Descripción |
| :--- | :--- |
| `pexec <cont> [cmd]` | Abre una sesión interactiva (por defecto `bash`) en el contenedor indicado. |
| `plogs <cont> [n]` | Sigue los logs en tiempo real con `--tail` (por defecto 100 líneas). |
| `pinfo <cont>` | Inspecciona la configuración JSON completa del contenedor a través de `less`. |
| `pcp <origen> <dest>` | Copia archivos bidireccionalmente entre el host y el contenedor. |
| `pclean-total` | Limpieza exhaustiva de Podman (`system prune -af --volumes`). |
| `prm-stopped` | Elimina todos los contenedores en estado detenido (`exited`). |
| `prmi-dangling` | Elimina todas las imágenes huérfanas (`dangling`). |
| `pstop-all` | Detiene todos los contenedores en ejecución. |

---

## 3. Atajos de Paquetes (`aliases.zsh`)

Los comandos principales de `pacman` y `pamac` disponen de aliases inmediatos:

- `update` / `upgrade` -> `sudo pacman -Syu`
- `install <pkg>` -> `sudo pacman -S <pkg>`
- `remove <pkg>` -> `sudo pacman -Rns <pkg>`
- `search <termino>` -> `pacman -Ss <termino>`
- `clean` -> `sudo pacman -Sc --noconfirm`
- `orphans` -> Elimina paquetes huérfanos del sistema.
- `p-update` -> `pamac update --aur`
- `p-install <pkg>` -> `pamac install <pkg>`
- `p-search <termino>` -> `pamac search <termino>`

---

## 4. Opciones Avanzadas de ZSH (`options.zsh` y `history.zsh`)

- **Auto CD**: Escribir la ruta de un directorio cambia a él automáticamente sin escribir `cd`.
- **Extended Globbing**: Búsqueda avanzada con patrones `**/*.ext` y sin distinción de mayúsculas.
- **Historial Compartido**: 50.000 comandos en memoria y disco, sincronizados al instante entre múltiples terminales abiertas (`SHARE_HISTORY`).
- **Autocompletado Flexible**: Navegación por menús interactivos con flechas del teclado y coloreado automático según el tipo de archivo.
