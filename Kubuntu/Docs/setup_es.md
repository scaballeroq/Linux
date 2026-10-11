---
sidebar_position: 2
---

# Configuración del Sistema en Kubuntu (KDE Plasma)

Esta guía detalla el proceso de configuración base, optimización de la terminal, instalación de herramientas esenciales, soporte multimedia, hardware y personalización del entorno de usuario aplicados a un sistema Kubuntu (enfocado en KDE Plasma 6 / 5).

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
   - Paquetes universales: `flatpak`, `plasma-discover-backend-flatpak`

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   sudo apt install -y kubuntu-restricted-extras libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers
   ```

---

## 2. Personalización de KDE Plasma (`kde-settings.sh` y `apariencia.sh`)

Aplica la configuración recomendada para KDE Plasma 6 / 5 vía CLI:
- **Luz Nocturna (Night Color)** a 3500K.
- **Tema Oscuro Breeze Dark** e iconos **Papirus** / **Breeze**.
- **Gestión de Energía**: Desactiva la suspensión al estar conectado a corriente alterna.
- **Atajo Global de Terminal**: Meta + T para Konsole.

```bash
just kde
just apariencia
```

---

## 3. Entorno de Terminal y Shell (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

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

En Kubuntu/Ubuntu se configuran enlaces simbólicos en `~/.local/bin` para `bat` y `fd`.

### Prompt Starship
Se descarga y configura la versión más reciente del prompt de Starship con diseño personalizado en `~/.config/starship.toml`.

### Fuentes de Desarrollo (Nerd Fonts)
Descarga e instala fuentes optimizadas (`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo` y `Hack`).

### Fastfetch
Muestra información estética y completa del sistema al abrir la terminal.

---

## 4. Hardware y Utilidades del Sistema

### Navegador Firefox Nativo (.deb) (`firefox.sh`)
Instala la versión oficial de Mozilla desde su repositorio APT con prioridad (Pin-Priority 900) y elimina la versión Snap para lograr el máximo rendimiento y menor tiempo de apertura:
```bash
just firefox
```

### Optimización de Portátil (`laptop-setup.sh`)
Servicios de ahorro de batería (`power-profiles-daemon`), soporte bluetooth, gráficos híbridos y configuración de touchpad (tap-to-click) y suspensión:
```bash
just laptop
```

### Huella Dactilar (`fingerprint-setup.sh`)
Configura `fprintd`, PAM para `sudo`, `polkit-1` y pantalla de bloqueo SDDM:
```bash
just fingerprint
```

### Impresora HP LaserJet Pro M15w (`hp-printer-setup.sh`)
Configura CUPS, drivers HPLIP y descarga el plugin propietario de HP:
```bash
just printer
```

### Automontaje de Workspace (`mount-workspace.sh`)
Configura el montaje permanente y seguro de la partición de datos `/home/caballero/Workspace` en `/etc/fstab`.

---

## 5. Panel de Administración Cockpit (`cockpit.sh`)

Instala Cockpit con soporte para gestión de almacenamiento, redes, máquinas virtuales KVM (`cockpit-machines`) y contenedores (`cockpit-podman`):
```bash
just cockpit
```
Acceso web disponible en [https://localhost:9090](https://localhost:9090).

---

## 6. Soporte Multimedia y yt-dlp (`yt-dlp-setup.sh`)

Instala `yt-dlp`, `ffmpeg` y configura el motor JS (Deno) vía `mise` para la descarga de audio y vídeo de alta fidelidad.

---

## Verificación

Para comprobar que los componentes principales se instalaron y configuraron correctamente:

- **Terminal y Utilidades**: Abre una nueva sesión de Konsole/terminal. Deberías ver el prompt de **Starship** cargado y el resumen de **Fastfetch**.
- **KDE Plasma**: Verifica el tema Breeze Dark y la Luz Nocturna en Preferencias del Sistema.
- **Cockpit**: Abre tu navegador e ingresa a [https://localhost:9090](https://localhost:9090).
