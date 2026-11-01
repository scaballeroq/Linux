# 🚀 Bash.Setup - Soplos Linux Boro Workstation (GNOME Shell Wayland)

Colección de scripts de configuración modular y funciones avanzadas para potenciar la terminal Bash y Zsh en **Soplos Linux Boro** bajo **GNOME Shell** sobre **Wayland nativo (Mutter)** y hardware **HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)**.

Este directorio organiza de forma modular los alias, variables de entorno, utilidades multimedia aceleradas por hardware, gestores de contenedores (Podman Rootless & Quadlets), cortafuegos exclusivo (**Firewalld**), integración con PipeWire/WirePlumber y atajos de escritorio propios de Soplos Linux Boro.

---

## 📁 Estructura del Módulo

| Archivo | Descripción y Optimizaciones Soplos Linux |
| :--- | :--- |
| `aliases.sh` | Atajos de navegación, seguridad (`rm -i`), gestión de paquetes unificada (`apt` + `flatpak`), atajos de Soplos (`soplos-update`, `soplos-clean`), cortafuegos con UFW (`ufw-open`, `ufw-close`, `ufw-status`, `ufw-dev-ports`, `fw`), audio PipeWire (`wpctl`), telemetría de hardware AMD y soporte `justfile`. |
| `environment.sh` | Variables globales (`EDITOR`, `TERMINAL=ghostty`, Wayland nativo, flags de compilación para AMD Ryzen 7 7730U `MAKEFLAGS="-j8"`, `CMAKE_BUILD_PARALLEL_LEVEL=8`, `UV_LINK_MODE="copy"`, socket Podman rootless, `LIBVIRT_DEFAULT_URI` y Mise). |
| `functions.sh` | Telemetría completa del sistema (`soplos-telemetry`, `soplos-monitors`), multimedia multihilo y aceleración por GPU AMD Radeon VA-API (`transcode-video-vaapi`, `transcode-video-1080p`), compresión multinúcleo con Zstandard (`compress tar.zst`), discos seguros (`format-drive`, `iso2sd`) y descompresión universal (`extract`). |
| `gnome_settings.sh` | Configuración e integración con el branding oficial de Soplos Linux (temas `Orchis-Orange`, iconos `kora-soplos`, cursores `Future-cursors`), atajos al Centro de Control de GNOME, luz nocturna y ejecución idempotente en caché para acelerar la apertura de la terminal. |
| `history.sh` | Historial persistente en tiempo real (`PROMPT_COMMAND` con volcado inmediato `history -a`), 10k/20k comandos, deduplicación e ignorado de comandos triviales (soporte dual Bash/Zsh). |
| `options.sh` | Comportamiento avanzado de la shell (`autocd`, corrección de errores tipográficos en comandos y carpetas con `cdspell` y `dirspell`, `globstar`, y completado optimizado). |
| `podman-functions.sh` | Funciones y atajos seguros para contenedores Podman rootless y unidades Quadlets de systemd (`quadlet-list`, `quadlet-restart`, `quadlet-status`, `quadlet-logs`). |
| `rclone_aliases.sh` | Suite integral de sincronización, respaldo y descarga para Google Drive y OneDrive con Rclone optimizado. |
| `yt-dlp_aliases.sh` | Descargas multimedia de alto rendimiento con yt-dlp, runtime JS Deno/Node via Mise y concurrencia multihilo (`--concurrent-fragments 4`). |

---

## 🛠️ Instalación e Integración

Para activar todas estas funcionalidades de forma modular, ejecuta `./Setup/shell.sh`, el cual enlazará automáticamente estos scripts en `~/.bashrc.d/` (y en `~/.zshrc.d/` si existe Zsh):

```bash
mkdir -p ~/.bashrc.d
ln -sf ~/Workspace/Repositorios/Linux/SoplosLinuxBoro/Bash.Setup/*.sh ~/.bashrc.d/
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

## 🛡️ Seguridad, Cortafuegos y Hardware
- **Cortafuegos Predeterminado (UFW):** Atajos nativos para UFW (`fw`, `ufw-status`, `ufw-open`, `ufw-close`, `ufw-dev-ports`, `ufw-reload`) integrados con la configuración de red y desarrollo de Soplos Linux Boro (`Setup/seguridad.sh`). Incluye fallback para entornos con Firewalld.
- **Hardware AMD Ryzen 7 7730U:** Paralelismo automático configurado a 8 hilos para Make, CMake y Ninja; transcodificación por hardware VA-API mediante `/dev/dri/renderD128` (driver AMDGPU/Mesa).
- **Protección de Archivos:** Operaciones interactivas por defecto (`rm -i`, `cp -i`, `mv -i`, `chown --preserve-root`).
- **Ecosistema Wayland Puro:** Herramientas nativas de portapapeles (`wl-copy`, `wl-paste`), PipeWire / WirePlumber (`wpctl`) y Mutter sin utilidades obsoletas de X11.
