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
   - Salida en color e `ILoveCandy` habilitados
   - Espejos ordenados por velocidad con `cachyos-rate-mirrors`

3. **Software Esencial**:
   - Compilación: `base-devel`, `cmake`
   - Monitorización: `btop`, `htop`, `inxi`
   - Utilidades y compresión: `curl`, `fuse2`, `fuse3`, `exfatprogs`, `7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`, `flatpak`

4. **ZRAM**:
   Configurado con algoritmo ZSTD al 50% de la memoria RAM.

---

## 2. Entorno de Escritorio: Niri Compositor & Noctalia Shell (`niri-setup.sh`)

Despliega y optimiza el entorno gráfico moderno Wayland basado en **Niri** (compositor scrollable-tiling en Rust) y **Noctalia Shell**:

1. **Stack Wayland y Paquetes**:
   ```bash
   ./Setup/niri-setup.sh
   ```
   Instala y configura:
   - **Niri**: Compositor dinámico con cinta infinita horizontal de ventanas.
   - **Noctalia Shell**: Barra superior integrada, lanzador de aplicaciones, centro de control de hardware y bloqueo de sesión.
   - **Xwayland Satellite**: Gestión desacoplada y ligera para aplicaciones X11 heredadas.
   - **Portales Wayland**: `xdg-desktop-portal-gnome` y `xdg-desktop-portal-gtk` para cuadros de diálogo y compartición de pantalla.
   - **Herramientas de Escritorio**: `wl-clipboard`, `grim` y `slurp` (capturas de pantalla), `satty` (anotación), `brightnessctl`, `playerctl`.
   - **Interfaces de Hardware**: `pavucontrol` (audio PipeWire), `blueman` (Bluetooth), `network-manager-applet` (Wi-Fi/Red).
   - **Tematización**: `qt5-wayland`, `qt6-wayland`, `qt6ct`, `kvantum` y `papirus-icon-theme`.

2. **Diagnóstico y Estado**:
   Puedes verificar el estado del stack gráfico en cualquier momento:
   ```bash
   ./Setup/niri-setup.sh --status
   # o vía justfile:
   just niri-status
   ```

---

## 3. Optimizaciones de Rendimiento y Portátil (`cachyos-tuning.sh` y `laptop-setup.sh`)

1. **Ajustes de Rendimiento del Sistema (`cachyos-tuning.sh`)**:
   - Sysctl para optimizar memoria virtual, latencia de red e I/O de disco.
   - Optimización de colas de disco NVMe y planificador del kernel BORE/EEVDF de CachyOS.
   - Diagnóstico: `./Setup/cachyos-tuning.sh --status`.

2. **Optimización de Portátiles (`laptop-setup.sh`)**:
   - Configuración de gestos en el Touchpad para Wayland.
   - Ahorro de energía con `tuned-ppd` / `power-profiles-daemon`.
   - Persistencia de niveles de brillo de pantalla y teclado con `systemd-backlight`.

---

## 4. Entorno de Terminal y Zsh (`shell.sh`, `starship.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo y enlaza de forma modular la configuración de **Zsh** desde `ZSH.Setup`.

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

### Prompt Starship Opcional (`starship.sh`)
CachyOS incluye de serie el prompt **Powerlevel10k (p10k)** en Zsh. Si prefieres usar **Starship**, puedes alternar fácilmente:
```bash
# Instalar y activar Starship
./Setup/starship.sh

# Desactivar y restaurar el prompt nativo p10k de CachyOS
./Setup/starship.sh --disable

# Ver estado actual
./Setup/starship.sh --status
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

Endurecimiento del sistema con Firewalld, DNS-over-TLS y MAC Randomization:
- **Firewalld**: Servicios mdns, ssh y soporte para contenedores Podman.
- **DNS-over-TLS**: Cifrado oportunista con `systemd-resolved`.
- **MAC Randomization**: Generación de MACs aleatorias en escaneo y conexión Wi-Fi.
- **Kernel hardening**: Restricciones de dmesg, punteros de kernel y SYN cookies.

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
