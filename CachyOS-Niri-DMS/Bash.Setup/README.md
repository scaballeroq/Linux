# 🚀 Bash.Setup (CachyOS + Niri & Dank Material Shell)

Colección de scripts modulares de configuración, aliases y funciones avanzadas para potenciar tu terminal en **Bash** y **Zsh** en **CachyOS**.

Este directorio organiza de forma limpia tus atajos de terminal, variables de entorno, utilidades multimedia, gestores de contenedores (Podman) e integración completa con **Niri** y **Dank Material Shell (DMS)**.

---

## 📁 Estructura de Scripts

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación (`project`, `cachyos`, `repo`), seguridad (`rm -i`), paquetes (`pacman` / `paru` / `yay`), espejos (`rate-mirrors`), recarga de shell y pipes globales en Zsh (`G`, `L`, `H`, `J`). |
| `niri_dms.sh` | Integración, IPC y atajos para el compositor Niri, Dank Material Shell (`dms ipc`), capturas Wayland (`grim` + `slurp` + `satty`) y grabación (`wl-screenrec`). |
| `functions.sh` | "Navaja suiza": utilidades multimedia (FFmpeg / ImageMagick), gestión de discos, extracción universal y navegación rápida (`mkcd`, `up`). |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman Rootless** y gestión de Pods / Quadlets (compatible con Bash y Zsh). |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive / OneDrive) mediante **Rclone**, con soporte para repositorios y documentos. |
| `yt-dlp_aliases.sh` | Atajos para descarga optimizada de vídeo (1080p), audio (MP3) y listas de reproducción con **yt-dlp**. |
| `history.sh` | Configuración optimizada del historial (Bash: 20k entradas con timestamps y erasedups; Zsh: 50k con deduplicación y EXTENDED_HISTORY). |
| `environment.sh` | Variables globales (`EDITOR`, `PATH`, Wayland/Qt, Docker host, libvirt) y activación de **Mise**. |
| `options.sh` | Comportamiento interno de la shell (`autocd`, corrección de typos, globstar, menú interactivo de autocompletado). |

---

## 🛠️ Instalación y Activación

La instalación se realiza automáticamente al ejecutar `./Setup/shell.sh` o `just shell`. Si prefieres configurarlo manualmente:

### Para Bash

```bash
mkdir -p ~/.bashrc.d
ln -sf /home/caballero/Workspace/Repositorios/Linux/CachyOS-Niri-DMS/Bash.Setup/*.sh ~/.bashrc.d/
```

Y añade a tu `~/.bashrc`:

```bash
# Carga modular de scripts de Bash.Setup
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script" > /dev/null
    done
    unset script
fi
```

---

### Para Zsh

Crea el directorio `~/.zshrc.d/` y enlaza los scripts:

```bash
mkdir -p ~/.zshrc.d
ln -sf /home/caballero/Workspace/Repositorios/Linux/CachyOS-Niri-DMS/Bash.Setup/*.sh ~/.zshrc.d/
```

Asegúrate de que tu `~/.zshrc` contenga el bloque de carga modular:

```zsh
# Carga modular de configuraciones (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script" > /dev/null
    done
    unset script
fi
```
