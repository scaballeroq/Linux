---
sidebar_position: 2
---

# Configuración del Sistema en CachyOS

Esta guía detalla el proceso de configuración base, optimización de la terminal, instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema **CachyOS** (Arch Linux, optimizado para x86-64-v3/v4) con **KDE Plasma 6**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base optimizando espejos, instalando software esencial y configurando la aceleración por hardware. El script detecta automáticamente el procesador (AMD Ryzen vs Intel Core) y ejecuta la configuración correspondiente.

1. **Auto-detección de CPU**:
   ```bash
   CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')
   ```
   - `AuthenticAMD` → Ejecuta `post-install-amd.sh`
   - `GenuineIntel` → Ejecuta `post-install-intel.sh`

2. **Optimización de Pacman**:
   - ParallelDownloads = 10
   - Color habilitado
   - Espejos optimizados con `cachyos-rate-mirrors`

3. **Software Esencial**:
   Instala utilidades de compilación, monitorización de sistema y compatibilidad:
   - Compilación: `base-devel`, `cmake`
   - Monitorización: `btop`, `htop`, `inxi`
   - Utilidades: `curl`, `fuse2`, `fuse3`, `exfatprogs`, `7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`
   - Paquetes universales: `flatpak`

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   # AMD
   sudo pacman -S --needed --noconfirm mesa libva-mesa-driver vulkan-radeon
   # Intel
   sudo pacman -S --needed --noconfirm mesa libva-intel-driver intel-media-driver vulkan-intel
   ```

5. **ZRAM**: Configurado con algoritmo ZSTD al 50% de RAM.

---

## 2. Entorno de Terminal y Shell (`shell.sh`, `starship.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo y permite gestionar de forma opcional el prompt interactivo Starship.

### Utilidades Modernas de Terminal (`shell.sh`)
Se instalan alternativas modernas a comandos clásicos y se activa la integración de `zoxide` respetando la configuración nativa de Zsh y Powerlevel10k en CachyOS:
- `eza` (reemplazo de `ls`)
- `bat` (reemplazo de `cat` con sintaxis coloreada)
- `fzf` (buscador difuso)
- `zoxide` (reemplazo inteligente de `cd`)
- `ripgrep` (`rg`, búsqueda rápida de texto)
- `fd` (reemplazo simple de `find`)
- `duf` (reemplazo visual de `df`)
- `dust` (visualizador de espacio en disco)
- `procs` (reemplazo moderno de `ps`)
- `btop` (monitor de recursos)

### Prompt Starship Opcional (`starship.sh`)
CachyOS incluye de serie el prompt **Powerlevel10k (p10k)** en Zsh. Si prefieres usar **Starship**, puedes activarlo o desactivarlo fácilmente:
```bash
# Instalar y activar Starship
./Setup/starship.sh

# Desactivar y restaurar el prompt nativo p10k de CachyOS
./Setup/starship.sh --disable

# Ver estado actual
./Setup/starship.sh --status
```
La configuración de Starship se gestiona mediante `Setup/starship.toml` en `~/.config/starship.toml`.

### Fuentes de Desarrollo (Nerd Fonts)
Descarga e instala fuentes optimizadas para programación y símbolos de terminal (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo` y `Hack`):
```bash
# Descarga y extracción automatizada en ~/.local/share/fonts
# Actualización de la caché de fuentes:
fc-cache -f
```

### Fastfetch
Muestra información del sistema de manera visual y estética al abrir la terminal. Instala `fastfetch` y copia la plantilla de configuración `config.jsonc` a `~/.config/fastfetch/config.jsonc`.

---

## 3. Terminal Kitty (`kitty.sh`)

Instala y optimiza **Kitty**, un emulador de terminal moderno acelerado por GPU, con integración en KDE Plasma y Dolphin.

1. **Instalación**:
   ```bash
   sudo pacman -S --needed --noconfirm kitty
   ```

2. **Configuración Estética**:
   - Opacidad al 75% con desenfoque (blur 32)
   - Tema de colores Catppuccin Mocha
   - Fuente JetBrainsMono Nerd Font
   - Tab bar con estilo powerline

3. **Integración con KDE Plasma**:
   - Terminal predeterminado de KDE
   - Atajo global Ctrl+Alt+T
   - Menú contextual en Dolphin: "Abrir en Kitty"

4. **Atajos de teclado**:
   - `Ctrl+Alt+Arriba/Abajo`: Ajustar opacidad
   - `Ctrl+Shift+F5`: Recargar configuración
   - `Ctrl+Shift+T`: Nueva pestaña en mismo directorio

---

## 4. Seguridad (`seguridad.sh`)

Endurecimiento del sistema con Firewalld, DNS-over-TLS y MAC Randomization.

- **Firewalld**: Zona FedoraWorkstation con kdeconnect, mdns, ssh
- **DNS-over-TLS**: Opportunistic con systemd-resolved
- **MAC Randomization**: Wi-Fi scan y connection
- **Kernel hardening**: dmesg_restrict, kptr_restrict, syncookies
- **Podman rootless**: user namespaces habilitados

---

## 5. Panel de Administración Cockpit (`cockpit.sh`)

Instala Cockpit para administrar el sistema mediante una interfaz web.

```bash
sudo pacman -S --needed --noconfirm cockpit cockpit-podman cockpit-machines
sudo systemctl enable --now cockpit.socket
```

Acceso: [https://localhost:9090](https://localhost:9090)

---

## 6. Soporte Multimedia y yt-dlp (`yt-dlp-setup.sh`)

Configura las herramientas para descargas de video y procesamiento de audio digital.

1. **Instalación de yt-dlp y FFMPEG**:
   ```bash
   sudo pacman -S --needed --noconfirm yt-dlp ffmpeg
   ```

2. **Motor de descifrado rápido JS**:
   Instala Deno mediante `mise` para permitir que `yt-dlp` procese la lógica JavaScript de plataformas de streaming.

---

## Verificación

Para comprobar que los componentes principales se instalaron y configuraron correctamente:

- **Terminal y Utilidades**: Abre una nueva terminal. Deberías ver el prompt de **Starship** cargado y el resumen de **Fastfetch** en pantalla. Prueba utilidades ejecutando `eza` o `bat --version`.
- **Kitty**: Ejecuta `kitty --version`. Debería abrirse con opacidad y tema Catppuccin.
- **Cockpit**: Abre tu navegador e ingresa a [https://localhost:9090](https://localhost:9090). Inicia sesión con tus credenciales de usuario del sistema.
- **Firewalld**: Verifica con `sudo firewall-cmd --state`.
