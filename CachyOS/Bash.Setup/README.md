# 🚀 Bash.Setup (CachyOS / Arch Linux + KDE Plasma 6)

Colección de scripts de configuración y funciones avanzadas para potenciar tu terminal Bash en CachyOS.

Este repositorio organiza de forma modular tus alias, variables de entorno, utilidades multimedia y gestores de contenedores (Podman).

---

## 📁 Estructura del Proyecto

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos generales de navegación, seguridad (`rm -i`), gestión de paquetes (`pacman` / `paru`) e integración con `eza`, `bat` y utilidades de escritorio. |
| `functions.sh` | El "navaja suiza": utilidades multimedia (FFMPEG), gestión de discos, extracción de archivos (unificado) y navegación avanzada. |
| `podman-functions.sh` | Funciones y aliases específicos para **Podman** y gestión de Pods / Quadlets. |
| `rclone_aliases.sh` | Sincronización avanzada con la nube (Google Drive / OneDrive) mediante **Rclone**. |
| `yt-dlp_aliases.sh` | Atajos para descarga optimizada de vídeo (1080p) y audio (MP3) con **yt-dlp**. |
| `history.sh` | Configuración optimizada del historial de Bash (10k/20k líneas, sin duplicados). |
| `environment.sh` | Definición de variables globales (`EDITOR`, `PATH`, Wayland/Qt) y personalización visual de `less` y `man`. |
| `options.sh` | Configuración del comportamiento de Bash (`autocd`, `globstar`, corrección de typos). |
| `kde_settings.sh` | Optimizaciones del entorno KDE Plasma 6 (touchpad, KWin, KCM Shell, gestión de temas y fondos). |

---

## 🛠️ Instalación

Para activar todas estas funcionalidades, se recomienda crear una carpeta `.bashrc.d` en tu home y añadir el siguiente bloque a tu archivo `~/.bashrc`:

```bash
# Carga modular de scripts
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Luego, puedes crear enlaces simbólicos de los scripts de este repositorio a esa carpeta:

```bash
mkdir -p ~/.bashrc.d
ln -s ~/Workspace/Repositorios/Linux/CachyOS/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 🛡️ Seguridad
El archivo `aliases.sh` incluye medidas de protección como:
- `rm`, `cp`, `mv` interactivos para evitar borrados accidentales.
- Protección del directorio raíz (`--preserve-root`).
- Verificación automática de la tabla de particiones en funciones de disco.
