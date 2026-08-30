# 🚀 Bash.Setup (CachyOS / Arch Linux + KDE Plasma 6)

Colección de scripts modulares de configuración, aliases y funciones avanzadas para potenciar tu terminal en **Zsh** (la shell predeterminada en CachyOS) y **Bash**.

Este repositorio organiza de forma limpia tus alias, variables de entorno, utilidades multimedia, gestores de contenedores (Podman) y opciones de shell.

---

## 📁 Estructura del Proyecto

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`pacman` / `paru`), recarga dinámica y utilidades Rust (`eza`, `bat`). |
| `functions.sh` | "Navaja suiza": utilidades multimedia (FFmpeg / ImageMagick), gestión de discos, extracción universal y navegación (`mkcd`, `up`, `hg`). |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman** y gestión de Pods / Quadlets (compatible con arrays de Zsh y Bash). |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive / OneDrive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descarga optimizada de vídeo (1080p), audio (MP3) y listas con **yt-dlp**. |
| `history.sh` | Configuración optimizada del historial (10k/20k líneas, deduplicación, escritura inmediata en `~/.zsh_history` o `~/.bash_history`). |
| `environment.sh` | Variables globales (`EDITOR`, `PATH`, Wayland/Qt, Docker host) y activación inteligente de **Mise** en Zsh y Bash. |
| `options.sh` | Comportamiento interno de la shell (`autocd`, corrección de typos, `globstar`/`extended_glob`, menús y colores de autocompletado en Zsh y Readline). |
| `kde_settings.sh` | Optimizaciones para KDE Plasma 6 Wayland (touchpad, KWin, KCM Shell, Spectacle y temas). |

---

## 🛠️ Instalación y Activación

### Para Zsh (Recomendado en CachyOS)

Crea el directorio `~/.zshrc.d/` y enlaza los scripts:

```bash
mkdir -p ~/.zshrc.d
ln -sf ~/Workspace/Repositorios/Linux/CachyOS/Bash.Setup/*.sh ~/.zshrc.d/
```

Asegúrate de que tu `~/.zshrc` contenga el bloque de carga modular:

```zsh
# Carga modular de configuraciones (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

### Para Bash

Si utilizas Bash o una sesión de respaldo en Bash:

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/CachyOS/Bash.Setup/*.sh ~/.bashrc.d/
```

Y añade a tu `~/.bashrc`:

```bash
# Carga modular de scripts de Bash.Setup
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

> 💡 **Tip automático**: Ejecutando `just shell` o `./Setup/shell.sh` se realiza automáticamente la configuración de utilidades y la integración en `~/.zshrc` y `~/.bashrc`.

---

## 🛡️ Seguridad y Robustez
- `rm`, `cp`, `mv` interactivos para prevenir borrados accidentales.
- Protección del directorio raíz (`--preserve-root`).
- Funciones de Podman diseñadas con arrays para evitar fallos de separación de palabras en Zsh.
- Verificación automática de la tabla de particiones en funciones de disco.

