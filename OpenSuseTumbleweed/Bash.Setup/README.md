# 🐚 Bash.Setup - Configuración Modular de Bash para openSUSE Tumbleweed

Este directorio contiene la configuración modular de Bash para **openSUSE Tumbleweed + KDE Plasma 6 (Wayland)**, organizada en scripts individuales cargados de manera estructurada:

- **`aliases.sh`**: Atajos comunes para navegación, utilidades modernas en Rust (`eza`, `bat`, `duf`, `dust`), integración con Dolphin / KIO (`kioclient6`), gestión de paquetes con `zypper` (`update`, `dup`, `install`, `clean`) e instantáneas `snapper`.
- **`environment.sh`**: Variables globales de entorno (`PATH`, `EDITOR`, configuraciones de terminal y paginadores).
- **`functions.sh`**: Colección de funciones avanzadas para desarrollo y multimedia (extracción unificada, FFmpeg, ImageMagick).
- **`kde_settings.sh`**: Ajustes de escritorio KDE Plasma 6 (Night Color, Breeze Dark/Light, reinicio de Plasma/KWin, accesos directos a KCM).
- **`history.sh`**: Control y persistencia del historial de Bash.
- **`options.sh`**: Opciones internas de Bash (`shopt`, `bind`).
- **`podman-functions.sh`**: Funciones rápidas para administración de contenedores Podman rootless.
- **`rclone_aliases.sh`**: Atajos de sincronización con la nube (Google Drive).
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas en audio y vídeo.
