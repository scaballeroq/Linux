# 🐚 Configuración Modular de Bash para Manjaro Linux (Bash.Setup)

Aunque **ZSH** es la shell predeterminada en Manjaro Linux, esta carpeta proporciona la suite equivalente modular de configuración para **Bash**, garantizando una experiencia coherente cuando se use Bash como shell interactiva o de rescate.

---

## 📂 Estructura de Módulos

| Archivo | Descripción |
| :--- | :--- |
| **`aliases.sh`** | Atajos rápidos (`pacman`, `pamac`), herramientas modernas (`eza`, `bat`, `duf`, `dust`, `procs`), monitor de kernel y seguridad. |
| **`environment.sh`** | Variables globales de entorno (`PATH`, `EDITOR`, `PAGER`, directorios locales, Mise, Cargo, Go). |
| **`functions.sh`** | Colección de funciones de utilidad adaptadas a Manjaro: navegación (`mkcd`, `up`), extracción universal (`extract`), discos (`iso2sd`, `format-drive`), multimedia (`ffmpeg`, `ImageMagick`) y gestión de paquetes (`manjaro-mirrors-fast`, `pacman-clean-all`, `aur-search`). |
| **`gnome_settings.sh`** | Atajos y ajustes para interactuar con la configuración de GNOME vía `gsettings`. |
| **`history.sh`** | Configuración de historial enriquecido (20.000 líneas, `histappend`, `cmdhist`, sin duplicados). |
| **`options.sh`** | Parámetros de comportamiento interno de Bash mediante `shopt` y `bind` (`autocd`, `globstar`, autocompletado insensible a mayúsculas). |
| **`podman-functions.sh`** | Funciones y atajos para contenedores Rootless y Quadlets de Podman. |
| **`rclone_aliases.sh`** | Atajos para sincronización en la nube con Google Drive y OneDrive. |
| **`yt-dlp_aliases.sh`** | Descargas multimedia optimizadas con `yt-dlp`. |

---

## 🚀 Carga Modular en `~/.bashrc`

Añade el siguiente bloque al final de tu archivo `~/.bashrc`:

```bash
# Carga Modular de Bash.Setup (~/.bashrc.d)
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```
