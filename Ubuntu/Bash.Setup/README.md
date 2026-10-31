# 🚀 Bash.Setup - Ubuntu Workstation (GNOME Shell Wayland)

Colección de scripts de configuración modular y funciones avanzadas para potenciar la terminal Bash y Zsh en **Ubuntu Linux** bajo **GNOME Shell** sobre **Wayland**.

Este directorio organiza de forma modular los alias, variables de entorno, utilidades multimedia, gestores de contenedores (Podman) y atajos de escritorio sin dependencias de entornos heredados.

---

## 📁 Estructura del Módulo

| Archivo | Descripción |
| :--- | :--- |
| `aliases.sh` | Atajos de navegación, seguridad (`rm -i`), gestión de paquetes (`apt`), cortafuegos (`firewall-cmd`), hardware e integración con herramientas Rust (`eza`, `bat`, `duf`, `dust`). |
| `environment.sh` | Variables globales (`EDITOR`, `PATH`, Wayland, integración Qt/GNOME, `DOCKER_HOST`, `LIBVIRT_DEFAULT_URI`) y activación automática de Mise. |
| `functions.sh` | Utilidades multimedia (FFmpeg / ImageMagick), gestión de discos (`format-drive`, `iso2sd`), descompresión universal (`extract`) y navegación avanzada. |
| `gnome_settings.sh` | Configuración nativa del entorno GNOME (modo oscuro, luz nocturna, botones completos de ventana, reloj 24h, Nautilus y atajos a `gnome-control-center`). |
| `history.sh` | Configuración optimizada del historial (10k/20k comandos, deduplicación inmediata y soporte dual Bash/Zsh). |
| `options.sh` | Comportamiento avanzado de shell (`autocd`, corrección de typos con `cdspell`, globbing extendido y completado insensible a mayúsculas). |
| `podman-functions.sh` | Funciones y atajos para contenedores Podman y unidades Quadlets rootless de systemd. |
| `rclone_aliases.sh` | Suite integral de sincronización, respaldo y descarga para Google Drive y OneDrive con Rclone. |
| `yt-dlp_aliases.sh` | Descargas multimedia de alto rendimiento con yt-dlp y FFmpeg. |

---

## 🛠️ Instalación e Integración

Para activar todas estas funcionalidades de forma modular, ejecuta `./Setup/shell.sh`, el cual enlazará automáticamente estos scripts en `~/.bashrc.d/` (y en `~/.zshrc.d/` si existe Zsh):

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/Ubuntu/Bash.Setup/*.sh ~/.bashrc.d/
```

Y añade el cargador modular a tu `~/.bashrc`:

```bash
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

## 🛡️ Seguridad y Cortafuegos
- **Firewalld Obligatorio:** Todos los atajos de firewall (`fw`, `fw-status`, `fw-ports`, `fw-reload`) operan exclusivamente con `firewall-cmd`.
- **Protección de Archivos:** Operaciones interactivas por defecto (`rm -i`, `cp -i`, `mv -i`, `chown --preserve-root`).
