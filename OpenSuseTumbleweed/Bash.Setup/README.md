# 🐚 Bash.Setup - Configuración Modular de Bash para OpenSUSE Tumbleweed

Este directorio contiene la configuración modular de Bash para **OpenSUSE Tumbleweed + GNOME**, organizada en scripts individuales y cargados de manera estructurada:

- **`aliases.sh`**: Atajos comunes para navegación, utilidades modernas en Rust (`eza`, `bat`, `duf`, `dust`), gestión de paquetes con `zypper` (`update`, `dup`, `install`, `clean`) e instantáneas `snapper`.
- **`environment.sh`**: Variables globales de entorno (`PATH`, `EDITOR`, configuraciones de terminal y paginadores).
- **`functions.sh`**: Colección de funciones avanzadas para desarrollo y multimedia (extracción unificada, FFmpeg, ImageMagick).
- **`gnome_settings.sh`**: Ajustes de escritorio GNOME (luz nocturna, modo oscuro, 24h, batería, reinicio de shell).
- **`history.sh`**: Control y persistencia del historial de Bash.
- **`options.sh`**: Opciones internas de Bash (`shopt`, `bind`).
- **`podman-functions.sh`**: Funciones rápidas para administración de contenedores Podman.
- **`rclone_aliases.sh`**: Atajos de sincronización con la nube (Google Drive).
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas en audio y vídeo.
