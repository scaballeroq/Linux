# 🐚 Bash.Setup - Configuración Modular de Shell para NixOS

Este directorio contiene la configuración modular de Bash (y compatible con Zsh) para **NixOS + KDE Plasma 6 (Wayland)**, organizada en scripts individuales cargados de manera estructurada:

- **`aliases.sh`**: Atajos comunes para navegación, utilidades modernas en Rust (`eza`, `bat`, `duf`, `dust`), integración con Dolphin / KIO (`kioclient6`), gestión declarativa de NixOS con Flakes (`rebuild`, `switch`, `test-build`, `nix-update`, `nix-clean`, `generations`, `rollback`) y atajos de búsqueda efímera (`nshell`, `nrun`).
- **`environment.sh`**: Variables globales de entorno (`PATH` priorizando `~/.local/bin`, `~/.nix-profile/bin` y `/run/current-system/sw/bin`, `EDITOR`, Wayland flags, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`).
- **`functions.sh`**: Colección de funciones avanzadas para desarrollo y multimedia (extracción unificada, utilidades NixOS `nix-where`, `nix-diff-generations`, FFmpeg, ImageMagick).
- **`kde_settings.sh`**: Ajustes de escritorio KDE Plasma 6 (Night Color, Breeze Dark/Light, reinicio de Plasma/KWin, accesos directos a KCM).
- **`history.sh`**: Control y persistencia del historial de Bash (deduplicación, 20.000 entradas).
- **`options.sh`**: Opciones internas de Bash (`autocd`, `cdspell`, globbing extendido).
- **`podman-functions.sh`**: Funciones rápidas para administración de contenedores Podman rootless y Quadlets.
- **`rclone_aliases.sh`**: Atajos de sincronización con la nube (Google Drive).
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas en audio y vídeo.
