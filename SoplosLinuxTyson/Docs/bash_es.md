---
sidebar_position: 3
---

# Configuración Modular de Bash (Soplos Linux Tyson)

Esta guía detalla la configuración del entorno de terminal (Bash) y las utilidades integradas en los scripts modulares de la carpeta `Bash.Setup` para **Soplos Linux Tyson** (Debian Testing + KDE Plasma 6).

---

## 1. Carga Modular del Entorno

Los scripts se cargan de forma dinámica añadiendo el siguiente bloque al archivo `~/.bashrc`:

```bash
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

Para crear los enlaces simbólicos de los scripts:
```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/SoplosLinuxTyson/Bash.Setup/*.sh ~/.bashrc.d/
```

---

## 2. Componentes de `Bash.Setup`

| Módulo | Finalidad |
| :--- | :--- |
| `aliases.sh` | Atajos para APT, `systemd` (`sc`, `scu`), `dracut` (`dracut-rebuild`), monitor `check-kernel` y herramientas Rust (`eza`, `bat`, `duf`, `dust`, `procs`). |
| `functions.sh` | Funciones multipropósito: `mkcd`, `up`, `extract` (soporte `zstd`/`xz`), `backup`, `iso2sd` seguro y conversión con FFmpeg / ImageMagick. |
| `podman-functions.sh` | Control de contenedores Podman (`psh`, `plogs`, `pstats`, `pclean`, `podman-quadlet-reload`). |
| `kde_settings.sh` | Integración y reinicio de KDE Plasma 6 (`plasma-restart`, `kwin-restart`, `kde-night-light-*`, `plasma-info`). |
| `history.sh` | Historial persistente de 10k/20k comandos con sincronización inmediata `history -a` entre terminales. |
| `environment.sh` | Variables globales, adición a `$PATH` sin duplicados, soporte GPG y activador de `mise`. |
| `options.sh` | Opciones de shell (`autocd`, `globstar`, `cdspell`, `dirspell`, completado insensible a mayúsculas). |
| `rclone_aliases.sh` | Sincronizaciones bidireccionales y simulaciones con Google Drive y OneDrive. |
| `yt-dlp_aliases.sh` | Descargas multimedia optimizadas con soporte para runtimes JavaScript y extracción de cookies de navegadores. |

---

## 3. Seguridad Reforzada
- `iso2sd`: Solicita confirmación interactiva en mayúsculas antes de escribir en cualquier disco o USB con `dd`.
- `rm -i`, `cp -i`, `mv -i` y `--preserve-root` activados de forma predeterminada.

