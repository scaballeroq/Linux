---
sidebar_position: 2
---

# Configuración del Sistema en CachyOS (Niri + Noctalia Shell)

Esta guía detalla el proceso de configuración base, despliegue del compositor **Niri**, la barra y entorno **Noctalia Shell**, optimización de la terminal **Zsh**, instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema **CachyOS** (Arch Linux, optimizado para x86-64-v3/v4).

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base optimizando espejos, instalando software esencial y configurando la aceleración por hardware. El script detecta automáticamente el procesador (AMD Ryzen vs Intel Core) y ejecuta la configuración correspondiente:

1. **Auto-detección de CPU**:
   - `AuthenticAMD` → Ejecuta `post-install-amd.sh` (microcódigo AMD, RADV, Mesa, PipeWire)
   - `GenuineIntel` → Ejecuta `post-install-intel.sh` (microcódigo Intel, VA-API Intel, PipeWire)

2. **Optimización de Pacman**:
   - `ParallelDownloads = 10`
   - Salida en color habilitada
   - Actualización completa de la base del sistema

3. **Software Esencial**:
   - Compilación: `base-devel`, `cmake`
   - Monitorización y diagnóstico: `btop`, `htop`, `inxi`
   - Utilidades y compresión: `curl`, `fuse2`, `fuse3`, `exfatprogs`, `7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`, `ca-certificates`, `gnupg`
   - Gráficos y Multimedia: `vlc`, `mpv`, `gimp`, `gparted`
   - Stack Wayland y Niri: `niri`, `xwayland-satellite`, portales GNOME/GTK, `wl-clipboard`, `grim`, `slurp`, `satty`, `pavucontrol`, `qt6ct`, `kvantum`

---

## 2. Entorno de Escritorio: Niri Compositor & Noctalia Shell

El entorno gráfico Wayland basado en **Niri** (compositor scrollable-tiling en Rust) y **Noctalia Shell** viene preinstalado y configurado de forma nativa por el paquete oficial `cachyos-niri-noctalia` con arquitectura modular en `~/.config/niri/`:

- **Niri**: Compositor dinámico con cinta infinita horizontal de ventanas.
- **Noctalia Shell**: Barra superior integrada, lanzador de aplicaciones, centro de control de hardware (Wi-Fi y Bluetooth nativos) y bloqueo de sesión.
- **Xwayland Satellite**: Gestión desacoplada y ligera para aplicaciones X11 heredadas.
- **Portales Wayland**: `xdg-desktop-portal-gnome` y `xdg-desktop-portal-gtk` para cuadros de diálogo y compartición de pantalla.
- **Herramientas de Escritorio**: `wl-clipboard`, `grim` y `slurp` (capturas de pantalla), `satty` (anotación), `brightnessctl`, `playerctl`.
- **Interfaces de Hardware**: `pavucontrol` (audio PipeWire). Wi-Fi y Bluetooth son gestionados e integrados de forma nativa por Noctalia Shell.
- **Tematización**: `qt5-wayland`, `qt6-wayland`, `qt6ct`, `kvantum` y `papirus-icon-theme`.

---

## 3. Optimizaciones de Rendimiento del Sistema (`cachyos-tuning.sh`)

Ajustes profundos de kernel, memoria y timeouts de sistema:
- **Sysctl Kernel**: Optimización de memoria virtual (ZRAM `swappiness=180`), inotify ampliado para IDEs y control de congestión TCP BBR.
- **Servicios de Rendimiento**: Auto-nice con `ananicy-cpp`, deduplicación de RAM con `uksmd`, balanceo de interrupciones con `irqbalance` y mantenimiento SSD con `fstrim.timer`.
- **Systemd & Energía**: Reducción de timeouts de apagado a 10s y comportamiento de tapa de portátil con cargador/docking (`logind.conf.d`).
- **Diagnóstico y Estado**: `./Setup/cachyos-tuning.sh --status` (o vía `just tuning-status`).

---

## 4. Entorno de Terminal y Zsh (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo y enlaza de forma modular la configuración de **Zsh** desde `ZSH.Setup`, manteniendo **Powerlevel10k** como prompt nativo de CachyOS.

### Utilidades Modernas de Terminal (`shell.sh`)
Se instalan alternativas modernas a herramientas clásicas y se configura la carga modular en `~/.zshrc.d/`:
- `eza` (reemplazo moderno de `ls` con soporte Git)
- `bat` (reemplazo de `cat` con sintaxis coloreada)
- `fzf` (buscador difuso interactivo)
- `zoxide` (navegación inteligente con `z`)
- `ripgrep` (`rg`, búsqueda de texto ultrarrápida)
- `fd` (búsqueda ágil de archivos)
- `duf` (visualizador de espacio de disco)
- `dust` (análisis interactivo de peso de directorios)
- `procs` (reemplazo de `ps`)
- `btop` (monitor de recursos por consola)

Además, enlaza automáticamente todos los scripts de `ZSH.Setup/` a `~/.zshrc.d/`:
```bash
./Setup/shell.sh
# o vía justfile:
just shell
```

### Fuentes de Desarrollo (Nerd Fonts)
Descarga e instala fuentes optimizadas para programación y símbolos de terminal (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo` y `Hack`):
```bash
./Setup/fonts.sh
```

### Fastfetch
Muestra un resumen estético del sistema al abrir nuevas instancias de terminal:
```bash
./Setup/fastfetch.sh
```

---

## 5. Terminal Kitty (`kitty.sh`)

Instala y optimiza **Kitty**, un emulador de terminal moderno acelerado por GPU, con integración en Niri y Wayland:

1. **Configuración Estética**:
   - Opacidad al 75% con desenfoque (`blur 32`)
   - Tema de colores Catppuccin Mocha
   - Fuente JetBrainsMono Nerd Font
   - Barra de pestañas estilo powerline

2. **Integración con Niri Wayland**:
   - Terminal predeterminado del sistema (`TERMINAL=kitty` en `environment.d`)
   - Atajo global en Niri: `Mod+Return` (o `Super+Enter`)

3. **Atajos de teclado en Kitty**:
   - `Ctrl+Alt+Arriba/Abajo`: Ajustar nivel de opacidad
   - `Ctrl+Shift+F5`: Recargar configuración en caliente
   - `Ctrl+Shift+T`: Abrir nueva pestaña en el mismo directorio

---

## 6. Seguridad y Red (`seguridad.sh`)

Configuración de Firewalld, DNS seguro y optimizaciones de red para desarrollo doméstico:
- **Firewalld**: Zona predeterminada `home` con SSH, mDNS, Cockpit, servidores de desarrollo (3000-3010, 5173, 8000-8080, 8501) y LocalSend/KDE Connect.
- **Virtualización (QEMU/KVM)**: Integración de `virbr0` en la zona `libvirt` con reenvío NAT automático (`--add-forward`).
- **Contenedores (Podman Rootless)**: Redes puente (`podman+`) en zona `trusted` y soporte para puertos sin privilegios (`ip_unprivileged_port_start=80`).
- **Sysctl de Kernel**: `rp_filter=2` (Loose mode para puentes virtuales), `ip_forward=1`, `somaxconn=4096` y `dmesg` sin fricción.
- **DNS Local y Privacidad**: `systemd-resolved` con soporte mDNS (`.local`) y DoT oportunista respetando el router doméstico.

---

## 7. Panel de Administración Web Cockpit (`cockpit.sh`)

Instala Cockpit para monitorizar y administrar el sistema, máquinas virtuales y almacenamiento desde el navegador:

```bash
sudo pacman -S --needed --noconfirm cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```
Acceso web: [https://localhost:9090](https://localhost:9090)

---

## 8. Soporte Multimedia y yt-dlp (`yt-dlp-setup.sh`)

Configura el stack de extracción y procesamiento multimedia:
- `yt-dlp` y `ffmpeg` actualizados.
- Deno configurado mediante `mise` como motor de JavaScript para resolver tokens de streaming.
- Atajos y funciones de audio/vídeo integrados en `ZSH.Setup/yt-dlp_aliases.sh`.

---

## Verificación General

Para verificar la correcta instalación de todo el stack:
- **Niri y Noctalia**: Comprueba `just niri-status`.
- **Terminal Zsh**: Abre una nueva terminal Kitty y confirma que se cargan los módulos desde `~/.zshrc.d/`.
- **Cockpit**: Visita [https://localhost:9090](https://localhost:9090).
- **Firewall**: Comprueba `sudo firewall-cmd --state`.
