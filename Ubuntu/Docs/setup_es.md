---
sidebar_position: 2
---

# Configuración del Sistema en Debian 13

Esta guía detalla el proceso de configuración base, optimización de la terminal, instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema Debian 13 (Trixie).

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base configurando repositorios oficiales adicionales, instalando software esencial y configurando la aceleración por hardware.

1. **Actualización base del sistema**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Habilitación de repositorios Extra** (Contrib, Non-Free, Non-Free-Firmware y Backports):
   ```bash
   sudo apt-add-repository -y contrib non-free non-free-firmware
   # Añadir repositorio de Backports
   CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)
   echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list
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

En Debian, para evitar conflictos de nombres, se configuran enlaces simbólicos:
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

## 3. Terminal Moderno Ptyxis (`ptyxis.sh`)

Instala y optimiza **Ptyxis**, un emulador de terminal moderno diseñado para GNOME, junto con integración en el gestor de archivos Nautilus.

1. **Instalación**:
   ```bash
   sudo apt install -y ptyxis python3-nautilus gir1.2-gtk-4.0 gettext build-essential git make
   ```

2. **Extensión "Nautilus Open Any Terminal"**:
   Permite abrir terminales en el directorio actual directamente desde Nautilus. Se clona y compila desde su repositorio oficial:
   ```bash
   git clone https://github.com/Stunkymonkey/nautilus-open-any-terminal.git
   cd nautilus-open-any-terminal
   make && sudo make install schema
   sudo glib-compile-schemas /usr/share/glib-2.0/schemas
   # Configurar ptyxis como la terminal por defecto de la extensión
   gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ptyxis
   gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true
   ```

3. **Atajo de Teclado Global (Ctrl + Alt + T)**:
   Registra un atajo de teclado en GNOME para abrir Ptyxis automáticamente.

4. **Estilo Estético**:
   Configura opacidad al 85% para un efecto de transparencia moderno, activa la interfaz oscura por defecto y oculta la barra de desplazamiento lateral:
   ```bash
   PROFILE_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")
   gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PROFILE_UUID}/" opacity 0.85
   gsettings set org.gnome.Ptyxis interface-style 'dark'
   gsettings set org.gnome.Ptyxis scrollbar-policy 'never'
   ```

---

## 4. Instalación de Firefox Oficial (`firefox.sh`)

Reemplaza la versión ESR (Extended Support Release) predeterminada de Debian por las versiones oficiales estables y de desarrollo directamente de Mozilla.

1. **Importación de Clave GPG y Repositorio de Mozilla**:
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
   echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
   ```

2. **Configuración de Preferencia de Paquetes (APT Pinning)**:
   Se crea `/etc/apt/preferences.d/mozilla` para priorizar los paquetes del repositorio de Mozilla sobre los de Debian:
   ```ini
   Package: *
   Pin: origin packages.mozilla.org
   Pin-Priority: 1000
   ```

3. **Purga de Firefox ESR e Instalación de Firefox Oficial**:
   ```bash
   sudo apt purge -y firefox-esr firefox-esr-l10n-*
   sudo apt update
   sudo apt install -y firefox firefox-l10n-es-es firefox-nightly firefox-nightly-l10n-es-es
   ```

---

## 5. Panel de Administración Cockpit (`cockpit.sh`)

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

## 6. Soporte Multimedia y yt-dlp (`yt-dlp-setup.sh`)

Configura las herramientas para descargas de video y procesamiento de audio digital.

1. **Instalación de yt-dlp (Backports) y FFMPEG**:
   Se requiere la versión de Backports para que `yt-dlp` esté al día con los cambios constantes en plataformas de streaming:
   ```bash
   sudo apt install -y -t trixie-backports yt-dlp
   sudo apt install -y ffmpeg
   ```

2. **Motor de descifrado rápido JS**:
   Instala Deno mediante `mise` (o NodeJS a nivel de sistema como alternativa de respaldo) para permitir que `yt-dlp` procese la lógica JavaScript de plataformas de manera ultra-rápida:
   ```bash
   mise use --global deno@latest
   ```

---

## 7. Temas e Iconos de Escritorio (`apariencia.sh`)

Aplica paquetes de diseño para un entorno visual limpio y homogéneo.

1. **Instalación de Temas de Iconos**:
   ```bash
   sudo apt install -y papirus-icon-theme adwaita-icon-theme adwaita-icon-theme-legacy gnome-themes-extra
   ```

---

## Verificación

Para comprobar que los componentes principales se instalaron y configuraron correctamente:

- **Terminal y Utilidades**: Abre una nueva terminal. Deberías ver el prompt de **Starship** cargado y el resumen de **Fastfetch** en pantalla. Prueba utilidades ejecutando `eza` o `bat --version`.
- **Nautilus y Terminal**: Haz clic derecho dentro de cualquier carpeta en Nautilus. Deberías ver la opción "Abrir terminal aquí" y se debe desplegar **Ptyxis** con transparencia.
- **Firefox**: Ejecuta `firefox --version` (debe mostrar el release oficial de Mozilla, no ESR).
- **Cockpit**: Abre tu navegador e ingresa a [https://localhost:9090](https://localhost:9090). Inicia sesión con tus credenciales de usuario del sistema Debian.
