# 🐚 Configuración Modular de ZSH para Manjaro Linux (Zsh.Setup)

Manjaro Linux utiliza **ZSH** como shell predeterminada interactiva junto con herramientas como `manjaro-zsh-config`, `zsh-syntax-highlighting`, `zsh-autosuggestions` y prompts enriquecidos (`powerlevel10k` o `starship`).

Esta carpeta contiene la suite modular de configuración diseñada para estructurar y potenciar tu terminal de forma limpia y mantenible.

---

## 📂 Estructura de Módulos

| Archivo | Descripción |
| :--- | :--- |
| **`aliases.zsh`** | Atajos rápidos de navegación, paquetes (`pacman`, `pamac`), herramientas modernas (`eza`, `bat`, `duf`, `dust`, `procs`), monitor de kernel y seguridad. |
| **`environment.zsh`** | Variables de entorno globales (`PATH`, `EDITOR`, `PAGER`, directorios locales, Mise, Cargo, Go). |
| **`functions.zsh`** | Colección completa de funciones de utilidad: navegación (`mkcd`, `up`), extracción universal (`extract`), compresión, discos (`iso2sd`, `format-drive`), multimedia (`ffmpeg`, `ImageMagick`) y gestión de Manjaro (`manjaro-mirrors-fast`, `pacman-clean-all`, `aur-search`). |
| **`gnome_settings.zsh`** | Atajos y funciones para interactuar con la configuración de GNOME vía `gsettings`. |
| **`history.zsh`** | Gestión avanzada del historial en ZSH (50.000 líneas, sin duplicados, compartido en tiempo real entre terminales). |
| **`options.zsh`** | Parámetros de comportamiento de ZSH (`autocd`, corrección de comandos, autocompletado inteligente). |
| **`podman-functions.zsh`** | Funciones y atajos para contenedores Rootless y Quadlets de Podman. |
| **`rclone_aliases.zsh`** | Atajos para sincronización y montaje en la nube con Rclone. |
| **`yt-dlp_aliases.zsh`** | Descargas multimedia de audio y vídeo de alta calidad con `yt-dlp`. |

---

## 🚀 Cómo Cargar estos Módulos en tu `~/.zshrc`

Para que todos los módulos se carguen automáticamente al abrir cualquier terminal ZSH, añade el siguiente bloque al final de tu archivo `~/.zshrc`:

```zsh
# Carga Modular de Zsh.Setup (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.zsh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

También puedes enlazar simbólicamente toda la carpeta para sincronizarla en tiempo real:

```bash
mkdir -p ~/.zshrc.d
ln -sf ~/Workspace/Repositorios/Linux/Manjaro/Zsh.Setup/*.zsh ~/.zshrc.d/
```
