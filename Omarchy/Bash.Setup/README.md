# Bash Setup Module (Omarchy)

Configuración modular de Bash adaptada y optimizada para **Omarchy (Arch Linux + Hyprland)**.

---

## 📁 Estructura de Módulos

| Módulo | Propósito y Contenido |
| :--- | :--- |
| **`aliases.sh`** | Atajos de teclado rápidos (Pacman, Yay, Git, Rust tools, navegación, virtualización, check de kernel). |
| **`environment.sh`** | Rutas dinámicas al `$PATH` (`~/.local/bin`, `~/.cargo/bin`, `~/go/bin`, `~/bin`) y respeto a variables de Omarchy. |
| **`functions.sh`** | Funciones utilitarias (`mkcd`, `extract`, `backup`, conversiones multimedia FFMPEG + ImageMagick). |
| **`options.sh`** | Opciones de Shell interactivas (`autocd`, `globstar`, `cdspell`, completado insensible a mayúsculas). |
| **`docker-functions.sh`** | Funciones y atajos para Docker, Docker Compose y Lazydocker (`dsh`, `dlogs`, `drmf`, `dstats`, `dclean-total`, `lzd`, `dutils`). |
| **`rclone_aliases.sh`** | Sincronización personalizada con Google Drive y OneDrive. |
| **`yt-dlp_aliases.sh`** | Atajos de descarga con `yt-dlp` (`ytvideo`, `ytaudio`, `ytlista`, `ytdl-subs`). |

---

## ⚙️ Instalación y Configuración

### Método 1: Automático (Recomendado)

Desde la raíz del repositorio, ejecuta:

```bash
just bash-setup
# o directamente:
./Bash.Setup/setup.sh
```

### Método 2: Manual

Añade el siguiente bloque al final de tu archivo `~/.bashrc`:

```bash
# =============================================================================
# Cargar módulos personalizados de Bash.Setup
# =============================================================================
BASH_SETUP_DIR="$HOME/Workspace/Repositorios/Linux/Omarchy/Bash.Setup"
if [ -d "$BASH_SETUP_DIR" ]; then
    for f in "$BASH_SETUP_DIR"/*.sh; do
        [ "$f" != "$BASH_SETUP_DIR/setup.sh" ] && [ -r "$f" ] && source "$f"
    done
    unset f
fi
```

---

## 🔄 Aplicar Cambios

Para activar la configuración en la terminal actual sin reiniciar:

```bash
source ~/.bashrc
# o utilizando el atajo incluido:
reload
```

---

## 🚀 Atajos y Comandos Destacados

* **Gestión de paquetes:**
  * `update` (`sudo pacman -Sy`)
  * `upgrade` (`sudo pacman -Syu`)
  * `install <paquete>` (`sudo pacman -S --needed`)
  * `aur-install <paquete>` (`yay -S --needed`)
  * `clean` (limpia huérfanos y caché)
* **Utilidades del sistema:**
  * `cls` (limpia pantalla, preservando `c` para OpenCode)
  * `fetch` o `sysinfo` (ejecuta Fastfetch, preservando `ff` para FZF)
  * `check-kernel` (compara kernel local con el último de kernel.org)
  * `ports` (muestra puertos y servicios abiertos con `ss`)
* **Navegación y archivos:**
  * `mkcd <directorio>` (crea la carpeta y entra en ella)
  * `extract <archivo>` (descomprime automáticamente según la extensión: zip, tar, 7z, rar, etc.)
  * `backup <archivo>` (crea copia con timestamp `.bak-YYYYMMDD-HHMMSS`)
  * `repos`, `omarchy`, `arch` (acceso directo a tus workspaces)
* **Multimedia:**
  * `webm2mp4 <video.webm>`
  * `transcode-video-1080p <video>`
  * `img2jpg <imagen>`


