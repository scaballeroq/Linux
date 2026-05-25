---
sidebar_position: 2
---

# Configuración del Sistema en Kubuntu 26.04 LTS

Esta guía detalla el proceso de configuración base, optimización de la terminal, instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema Kubuntu 26.04 LTS.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base configurando repositorios oficiales adicionales, instalando software esencial y configurando la aceleración por hardware.

1. **Actualización base del sistema**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Habilitación de repositorios Extra** (Universe, Multiverse y Restricted):
   ```bash
   sudo add-apt-repository -y universe
   sudo add-apt-repository -y multiverse
   sudo add-apt-repository -y restricted
   sudo apt update
   ```

3. **Software Esencial**:
   Instala utilidades de compilación, monitorización de sistema y compatibilidad:
   - Compilación: `build-essential`, `cmake`
   - Monitorización: `btop`, `htop`, `inxi`
   - Utilidades: `curl`, `fuse3`, `libfuse2t64`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`
   - Paquetes universales: `flatpak`, `gnome-software-plugin-flatpak`

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   sudo apt install -y libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers
   ```

---

## 2. Entorno de Terminal y Shell (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo y el prompt interactivo Starship.

### Utilidades Modernas de Terminal
Se instalan alternativas modernas a comandos clásicos:
- `eza` (reemplazo de `ls`)
- `bat` (reemplazo de `cat` con sintaxis coloreada)
- `fzf` (buscador difuso)
- `zoxide` (reemplazo inteligente de `cd`)
- `ripgrep` (`rg`, búsqueda rápida de texto)
- `fd-find` (`fd`, reemplazo simple de `find`)
- `tealdeer` (`tldr`, hojas de trucos simplificadas de man)
- `duf` (reemplazo visual de `df`)
- `du-dust` (`dust`, visualizador de espacio en disco)
- `procs` (reemplazo moderno de `ps`)

En Kubuntu/Ubuntu, para evitar conflictos de nombres, se configuran enlaces simbólicos:
```bash
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat
ln -sf /usr/bin/fdfind ~/.local/bin/fd
```

### Prompt Starship
Se descarga y configura la versión más reciente del prompt de Starship:
```bash
curl -sS https://starship.rs/install.sh | sh -s -- -y
```
La configuración es modular. Si el sistema soporta `.bashrc.d`, se crea el archivo `~/.bashrc.d/starship.sh`:
```bash
# Starship Prompt Configuration
eval "$(starship init bash)"
```
Adicionalmente, se copia la configuración de diseño desde `Setup/starship.toml` a `~/.config/starship.toml`.

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

## 3. Panel de Administración Cockpit (`cockpit.sh`)

Instala Cockpit para administrar el servidor o máquina local mediante una cómoda interfaz web.

1. **Instalación de Cockpit y extensiones**:
   Instala soporte para la administración de paquetes, almacenamiento, redes, máquinas virtuales (`cockpit-machines`) y contenedores (`cockpit-podman`):
   ```bash
   sudo apt install -y cockpit cockpit-podman cockpit-machines cockpit-packagekit cockpit-storaged cockpit-networkmanager
   ```

2. **Habilitación de Socket**:
   Para ahorrar recursos, Cockpit arranca únicamente cuando se accede a su puerto:
   ```bash
   sudo systemctl enable --now cockpit.socket
   ```

3. **Apertura en el Firewall**:
   ```bash
   sudo ufw allow 9090/tcp
   ```

---

## 4. Soporte Multimedia y yt-dlp (`yt-dlp-setup.sh`)

Configura las herramientas para descargas de video y procesamiento de audio digital.

1. **Instalación de yt-dlp y FFMPEG**:
   ```bash
   sudo apt install -y yt-dlp ffmpeg
   ```

2. **Motor de descifrado rápido JS**:
   Instala Deno mediante `mise` (o NodeJS a nivel de sistema como alternativa de respaldo) para permitir que `yt-dlp` procese la lógica JavaScript de plataformas de manera ultra-rápida:
   ```bash
   mise use --global deno@latest
   ```

---

## 5. Temas e Iconos de Escritorio (`apariencia.sh`)

Aplica paquetes de diseño para un entorno visual limpio y homogéneo.

1. **Instalación de Temas de Iconos**:
   ```bash
   sudo apt install -y papirus-icon-theme
   ```

---

## Verificación

Para comprobar que los componentes principales se instalaron y configuraron correctamente:

- **Terminal y Utilidades**: Abre una nueva terminal. Deberías ver el prompt de **Starship** cargado y el resumen de **Fastfetch** en pantalla. Prueba utilidades ejecutando `eza` o `bat --version`.
- **Cockpit**: Abre tu navegador e ingresa a [https://localhost:9090](https://localhost:9090). Inicia sesión con tus credenciales de usuario del sistema Kubuntu.
