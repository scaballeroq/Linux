---
sidebar_position: 8
---

# Configuración de Terminal Bash en OpenSUSE Tumbleweed

La configuración de la shell Bash está modularizada en `Bash.Setup/`:

- `aliases.sh`: Atajos para `zypper` (`update`, `dup`, `install`, `remove`, `clean`), `snapper` y utilidades Rust (`eza`, `bat`, `duf`, `dust`).
- `environment.sh`: Configuración global de `PATH`, `EDITOR` y paginadores.
- `functions.sh`: Funciones avanzadas y utilidades multimedia.
- `gnome_settings.sh`: Accesos rápidos a configuración y control de GNOME Shell.
- `history.sh`: Persistencia de historial.
- `options.sh`: Opciones de Bash (`shopt`).
- `podman-functions.sh`: Gestión de contenedores Podman.
- `rclone_aliases.sh`: Sincronización Google Drive.
- `yt-dlp_aliases.sh`: Descargas multimedia.
