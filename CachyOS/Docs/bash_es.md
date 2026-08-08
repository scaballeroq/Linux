---
sidebar_position: 3
---

# Configuración de Bash en Debian 13

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
ln -s /home/caballero/Workspace/Repositorios/Debian/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Variables de Entorno (`environment.sh`)

Define configuraciones globales y optimizaciones para las herramientas del sistema:

- **Editor Predeterminado**: Se establece `nvim` (Neovim) como editor global.
- **Ruta de Ejecutables (`PATH`)**: Se añaden directorios locales del usuario a la variable de entorno:
  - `~/.local/bin`
  - `~/bin`
  - Carpeta de binarios de Cargo/Rust (`~/.cargo/bin`)
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
* Escritura inmediata de comandos al archivo de historial tras cada ejecución.

---

## 4. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas y seguras:

- **Seguridad**:
  - `rm -i` (confirmar borrado de archivos)
  - `cp -i` (confirmar sobreescritura al copiar)
  - `mv -i` (confirmar sobreescritura al mover)
  - Medida preventiva `--preserve-root` habilitada por defecto.
- **Visualización de Archivos** (si están instalados `eza` y `bat`):
  - `ls` mapeado a `eza` con iconos y estructura limpia.
  - `cat` mapeado a `bat` con resaltado de sintaxis.
- **Accesos Rápidos**:
  - `..`, `...`, `....` para subir directorios rápidamente.
  - `c` para limpiar pantalla (`clear`).
  - `path` para listar las rutas de la variable PATH formateadas en líneas individuales.

---

## 5. Funciones y Utilidades del Sistema (`functions.sh`)

Incluye funciones en bash para simplificar tareas recurrentes:

* **`extract`**: Extrae automáticamente casi cualquier archivo comprimido (`.zip`, `.tar.gz`, `.bz2`, `.rar`, etc.) sin tener que recordar las flags específicas del descompresor.
* **`mkcd`**: Crea una nueva carpeta y entra automáticamente en ella con un solo comando.
* **`up <N>`**: Sube `N` niveles en el árbol de directorios de manera sencilla (ej. `up 3`).
* **`duh`**: Muestra el tamaño de las carpetas en el directorio actual, ordenadas por su peso en disco.
* **Procesamiento Multimedia**:
  - `webm2mp4`: Convierte grabaciones en formato WebM (comunes en el escritorio de GNOME) a MP4 estándar.
  - `img2jpg` / `img2png`: Convierte y optimiza imágenes rápidamente vía consola.

---

## 6. Sincronización en la Nube (`rclone_aliases.sh` e `yt-dlp_aliases.sh`)

Automatiza la gestión de almacenamiento y descargas externas.

### Sincronización Rclone
Facilita la sincronización y copia bidireccional con servicios como Google Drive mediante límites controlados de transacciones para evitar bloqueos del servicio:
- `rclone-documentos`: Sincroniza local -> nube.
- `rclone-videos-down`: Descarga archivos multimedia de la nube al equipo local.

### Descargas yt-dlp
Utilidades para automatizar la extracción multimedia:
- `ytvideo <URL>`: Descarga video en calidad óptima (1080p).
- `ytaudio <URL>`: Descarga y convierte a formato MP3 de alta fidelidad.
- `ytlista-audio <URL>`: Descarga listas de reproducción completas convertidas a MP3.

---

## 7. Entorno GNOME (`gnome_settings.sh`)

Aplica configuraciones automáticas para el entorno de escritorio GNOME:
- Habilitación de la luz nocturna nocturna (filtro de luz azul).
- Configuración del formato horario de 24 horas y fecha completa en la barra superior.
- Optimización de velocidad de animaciones e instalación rápida de extensiones.

---

## 8. Funciones para Contenedores (`podman-functions.sh`)

Aliases y funciones que simplifican el control de contenedores y Pods de Podman:
- `psh <contenedor>`: Abre una shell interactiva dentro del contenedor indicado.
- `plogs <contenedor>`: Muestra e interactúa con los logs en tiempo real.
- `pclean`: Realiza una purga completa de imágenes y contenedores sin uso en el sistema.
