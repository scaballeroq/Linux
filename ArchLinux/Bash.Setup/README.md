# Bash Setup Module

Configuración modular de Bash para Arch Linux con GNOME.

## Estructura

| Archivo | Propósito |
|---------|-----------|
| `aliases.sh` | Atajos de teclado (Pacman, Git, Rust tools, navegación) |
| `environment.sh` | Variables de entorno (PATH, EDITOR, LESS) |
| `functions.sh` | Funciones utils (mkcd, extract, multimedia, disco) |
| `history.sh` | Configuración del historial de comandos |
| `options.sh` | Opciones de shell (autocd, globstar, autocompletado) |
| `podman-functions.sh` | Funciones y aliases para Podman |
| `gnome_settings.sh` | Optimizaciones de GNOME y aliases |
| `rclone_aliases.sh` | Sincronización con Google Drive / OneDrive |
| `yt-dlp_aliases.sh` | Descarga de vídeos y audio con yt-dlp |

## Instalación

Crear enlaces simbólicos en `~/.bashrc.d/`:

```bash
mkdir -p ~/.bashrc.d
ln -s /home/caballero/Workspace/Repositorios/ArchLinux/Bash.Setup/*.sh ~/.bashrc.d/
```

Añadir en `~/.bashrc`:

```bash
if [ -d ~/.bashrc.d ]; then
    for f in ~/.bashrc.d/*.sh; do
        [ -r "$f" ] && source "$f"
    done
    unset f
fi
```

## Características destacadas

- **Aliases de Pacman + Yay**: `update`, `upgrade`, `install`, `remove`, `aur-install`
- **Funciones Podman**: `psh`, `plogs`, `prmf`, `pstats`, `pclean-total`
- **Multimedia**: `webm2mp4`, `transcode-video-1080p`, `img2jpg` (FFMPEG + ImageMagick)
- **Rclone sync**: Upload/download con Google Drive y OneDrive
- **yt-dlp**: Descarga de vídeos, audio, playlists y subtítulos
