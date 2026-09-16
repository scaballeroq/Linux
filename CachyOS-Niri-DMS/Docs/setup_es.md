---
sidebar_position: 2
---

# Configuración del Sistema en CachyOS (Niri + Dank Material Shell)

Esta guía detalla el proceso de configuración base, despliegue del compositor **Niri**, la barra y entorno **Dank Material Shell (DMS)**, optimización de la terminal (**Zsh** y **Bash**), instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema **CachyOS**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base optimizando descargas en Pacman, instalando software esencial y configurando la aceleración por hardware. El script detecta automáticamente el procesador (AMD Ryzen vs Intel Core) y ejecuta la configuración correspondiente:

1. **Auto-detección de CPU**:
   - `AuthenticAMD` → Ejecuta `post-install-amd.sh` (microcódigo AMD, RADV, Mesa, PipeWire)
   - `GenuineIntel` → Ejecuta `post-install-intel.sh` (microcódigo Intel, VA-API Intel, PipeWire)

2. **Optimización de Pacman**:
   - `ParallelDownloads = 10`
   - Salida en color y efecto visual `ILoveCandy` habilitados
   - Actualización completa de la base del sistema (`pacman -Syu`)

3. **Software Esencial**:
   - Compilación: `base-devel`, `cmake`, `git`
   - Monitorización y diagnóstico: `btop`, `htop`, `inxi`
   - Utilidades y compresión: `curl`, `wget`, `fuse2`, `fuse3`, `sshfs`, `dosfstools`, `mtools`, `exfatprogs`, `ntfs-3g`, `7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`, `ca-certificates`, `gnupg`
   - Gráficos y Multimedia: `vlc`, `mpv`, `gimp`, `gparted`
   - Stack Wayland y Niri: `niri`, `xwayland-satellite`, portales GNOME/GTK, `wl-clipboard`, `grim`, `slurp`, `satty`, `pavucontrol`, `qt5-wayland`, `qt6-wayland`, `qt6ct`, `kvantum`

---

## 2. Entorno de Escritorio: Niri Compositor & Dank Material Shell (DMS)

El entorno gráfico Wayland combina el compositor de cinta infinita **Niri** (Rust scrollable-tiling window manager) con **Dank Material Shell (DMS)**, un entorno de escritorio moderno basado en Quickshell y principios de diseño Material 3 (Material You):

- **Niri**: Compositor scrollable-tiling dinámico con cinta infinita horizontal de ventanas. Su configuración modular reside en `~/.config/niri/` e incluye subarchivos en `~/.config/niri/dms/` (`binds.kdl`, `colors.kdl`, `layout.kdl`, `alttab.kdl`, `outputs.kdl`).
- **Dank Material Shell (DMS)**:
  - Interfaz gráfica completa: Barra superior / dock, lanzador de aplicaciones (`dms ipc call launcher toggle`), centro de control de hardware y ajustes rápidos (`dms ipc call control-center toggle`), gestor de portapapeles con vista previa y bloqueo de pantalla.
  - Generación dinámica de colores mediante **Matugen**: Adapta automáticamente los colores del sistema y de aplicaciones compatibles a partir del fondo de pantalla o esquema de color seleccionado.
  - Satélites integrados: `dankcalendar` (`dcal`), `danksearch` y greeter para Greetd (`dms-greeter`).
  - Servicio de usuario en systemd: `dms.service`.
- **Xwayland Satellite**: Gestión desacoplada y ligera para aplicaciones X11 heredadas.
- **Portales Wayland**: `xdg-desktop-portal-gnome` y `xdg-desktop-portal-gtk` para cuadros de diálogo y compartición de pantalla.
- **Herramientas de Escritorio**: `wl-clipboard`, `grim` y `slurp` (capturas de pantalla), `satty` (anotación), `brightnessctl`, `playerctl`.

---

## 3. Entorno de Terminal y Shells (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo y enlaza de forma modular la configuración de **Bash** y **Zsh** desde `Bash.Setup`, utilizando el prompt **Starship** optimizado con Nerd Fonts.

### Utilidades Modernas de Terminal (`shell.sh`)
Se instalan alternativas modernas a herramientas clásicas y se configura la carga modular en `~/.zshrc.d/` y `~/.bashrc.d/`:
- `eza` (reemplazo moderno de `ls` con soporte Git)
- `bat` (reemplazo de `cat` con sintaxis coloreada)
- `fzf` (buscador difuso interactivo)
- `zoxide` (navegación inteligente con `z`)
- `ripgrep` (`rg`, búsqueda de texto ultrarrápida)
- `fd` (búsqueda ágil de archivos)
- `duf` y `dust` (análisis visual del uso del disco)
- `procs` (reemplazo moderno de `ps`)
- `btop` (monitor de recursos por consola con soporte GPU AMD/Intel)
- `jq` (procesador de JSON en línea de comandos)
- `zsh`, `zsh-completions`, `zsh-autosuggestions`, `zsh-syntax-highlighting`
- `starship` (prompt rápido y personalizable)

---

## 4. Emulador de Terminal: Kitty (`kitty.sh`)

Despliega una configuración para Kitty orientada a Wayland nativo con aceleración por GPU:
- **Transparencia y Desenfoque**: Opacidad predeterminada al 75% (`0.75`) con radio de desenfoque Wayland (`blur 32`).
- **Control dinámico de opacidad**:
  - `Ctrl+Alt+Arriba` / `Ctrl+Alt+Abajo`: Aumentar/disminuir opacidad en pasos de ±5%.
  - `Ctrl+Alt+0`: Restaurar opacidad por defecto.
  - `Ctrl+Alt+1`: Modo 100% opaco.
- **Integración con DMS**: Incluye `./dank-theme.conf` y `./dank-tabs.conf` sincronizados dinámicamente con la paleta Material You de DMS.
- **Fuentes**: `JetBrainsMono Nerd Font` con tamaño `11.5` y ligaduras habilitadas.

---

## 5. Copias de Seguridad de Niri y DMS (`backup-niri-dms.sh`)

Permite crear snapshots comprimidos de toda la configuración gráfica:
- `~/.config/niri` (config.kdl y dms/)
- `~/.config/DankMaterialShell` (settings.json, temas, layout)
- `~/.config/danksearch`
- `~/.config/dankcal`
- `~/.config/kitty`

Comandos:
```bash
./Setup/backup-niri-dms.sh          # Crear backup
./Setup/backup-niri-dms.sh --list   # Ver respaldos
./Setup/backup-niri-dms.sh --restore # Restaurar último
```

---

## 6. Verificación Post-Instalación

- **DMS**: Ejecuta `dms doctor` para verificar el estado de salud de todos los subsistemas.
- **Niri**: Comprueba la sesión gráfica y la recarga en caliente con `niri msg action reload-config`.
- **Terminal**: Abre una nueva pestaña de Kitty y verifica que los aliases y Starship cargan instantáneamente.
