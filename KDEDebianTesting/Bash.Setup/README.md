# 🐚 Bash.Setup - Configuración Modular de Bash para Debian Testing

Este directorio contiene la configuración modular de Bash para **Debian Testing + KDE Plasma 6 (Wayland)**, organizada en scripts individuales cargados de manera estructurada:

- **`aliases.sh`**: Atajos comunes para navegación, utilidades modernas en Rust (`eza`, `bat`, `duf`, `dust`, `procs`, `btop`), integración con Dolphin / KIO (`kioclient6`), gestión de paquetes con `apt` (`update`, `upgrade`, `install`, `remove`, `clean`) y comprobador de kernel.
- **`environment.sh`**: Variables globales de entorno (`PATH`, `EDITOR`, configuraciones de terminal, paginadores, Wayland / Ozone hints y sockets de Podman).
- **`functions.sh`**: Colección de funciones avanzadas para desarrollo, navegación y multimedia (extracción unificada, FFmpeg, ImageMagick).
- **`kde_settings.sh`**: Ajustes de escritorio KDE Plasma 6 (Night Color, Breeze Dark/Light, reinicio de Plasma/KWin, accesos directos a KCM).
- **`history.sh`**: Control y persistencia del historial de Bash y Zsh (10k/20k entradas, sin duplicados).
- **`options.sh`**: Opciones internas de Bash y Zsh (`shopt`, `bind`, autocompletado y autocd).
- **`podman-functions.sh`**: Funciones rápidas y utilidades para administración de contenedores Podman rootless y Quadlets (`systemd`).
- **`rclone_aliases.sh`**: Atajos de sincronización con la nube (Google Drive).
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas en audio y vídeo con detección de motor JavaScript (Deno / Mise).

---

## 🛠️ Instalación y Carga

Los scripts son cargados automáticamente si incluyes la carga modular en tu `~/.bashrc`:

```bash
# Carga modular de scripts en ~/.bashrc.d
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Para vincular estos archivos a `~/.bashrc.d/`:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/KDEDebianTesting/Bash.Setup/*.sh ~/.bashrc.d/
```
