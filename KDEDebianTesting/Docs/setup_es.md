---
sidebar_position: 2
---

# Configuración del Sistema en Debian Testing (DebianTesting)

Esta guía detalla el proceso de configuración base, automontaje de partición de trabajo, compilación de kernel nativo `x86_64-v3`, personalización de GNOME, terminal Ptyxis, extensiones GNOME Shell y panel de administración web aplicados a un sistema **Debian Testing (Trixie)** con **GNOME**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base configurando repositorios oficiales adicionales, instalando software esencial, PipeWire, la suite GNOME y aceleración por hardware.

1. **Actualización base del sistema**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Habilitación de repositorios Extra** (Contrib, Non-Free, Non-Free-Firmware):
   ```bash
   sudo apt install -y curl ca-certificates gnupg lsb-release
   # En Debian Testing los repositorios principales entregan los paquetes más recientes directamente
   ```

3. **Software Esencial y Utilidades**:
   Instala utilidades de compilación, suite GNOME y monitorización:
   - Compilación: `build-essential`, `cmake`
   - Memoria: `zram-tools` (ZRAM con ZSTD al 50%)
   - Monitorización: `btop`, `htop`, `inxi`, `gnome-system-monitor`
   - Utilidades: `curl`, `fuse3`, `exfatprogs`, `p7zip-full`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`, `evince`, `seahorse`
   - Entorno GNOME y Aplicaciones: `gnome-core`, `gnome-shell`, `gnome-control-center`, `gnome-tweaks`, `ptyxis`, `nautilus`, `file-roller`, `gnome-text-editor`, `gnome-calculator`, `gnome-disk-utility`, `power-profiles-daemon`, `switcheroo-control`, `ffmpegthumbnailer`
   - Paquetes universales: `flatpak`, `gnome-software`, `gnome-software-plugin-flatpak`

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   sudo apt install -y libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers vainfo vulkan-tools
   ```

---

## 2. Automontaje de Partición Workspace (`mount-workspace.sh`)

Monta automáticamente la partición de datos `/home/caballero/Workspace` mediante `/etc/fstab` usando su UUID.
Utiliza las opciones `defaults,noatime,nofail` para evitar cualquier bloqueo del sistema durante el arranque si la partición secundaria estuviese desconectada.

```bash
./Setup/mount-workspace.sh
# O usando just:
just workspace
```

---

## 3. Compilador de Kernel Linux NATIVO x86_64-v3 (`build-custom-kernel.sh`)

Script que consulta la API de `kernel.org` (`https://www.kernel.org/releases.json`) para descargar la última versión estable oficial del Kernel Linux, compilar paquetes `.deb` nativos con optimizaciones de arquitectura `x86_64-v3`, latencia a **1000Hz** y **Preemption Dinámica**.

```bash
./Setup/build-custom-kernel.sh
# O usando just:
just build-kernel
```

---

## 4. Instalación Limpia de Extensiones GNOME (`gnome-extensions.sh`)

Instala `gnome-browser-connector`, `extension-manager` y descarga las 17 extensiones personalizadas utilizando el instalador nativo por DBus `gnome-extensions install --force` y compilando automáticamente los esquemas GSettings (`glib-compile-schemas`), evitando el estado de error o deshabilitado en el gestor de extensiones (ver [Guía de Extensiones GNOME](./gnome_extensions_es.md)).

```bash
just extensions
```

---

## 5. Personalización de GNOME vía GSettings (`gnome-settings.sh`)

Configura de manera nativa y atomizada:
- **Luz Nocturna (Night Light)** a 3500K.
- **Reloj 24h** y porcentaje de batería en el panel superior.
- **Botones de ventana**: minimizar, maximizar y cerrar a la derecha.
- **Touchpad**: Tap-to-click, desplazamiento natural y dos dedos.
- **VRR y Escalado Fraccional** en Mutter Wayland.
- **Tema Oscuro Preferido**: `prefer-dark`.

```bash
just gnome
```

---

## 6. Terminales Modernas (Ptyxis y Kitty)

### Ptyxis (`ptyxis.sh`)
Instala y configura Ptyxis (el emulador moderno para GNOME) con perfil oscuro translúcido (85% de opacidad), sin scrollbar, atajo de teclado `Ctrl + Alt + T` e integración directa en Nautilus mediante `nautilus-open-any-terminal`.

```bash
just ptyxis
```

### Kitty (`kitty.sh`)
Instala y configura Kitty (emulador acelerado por GPU) con perfil Catppuccin Mocha / Tokyo Night translúcido (85% opacidad) con efectos blur, tipografía JetBrainsMono Nerd Font, barra de pestañas Powerline inclinada y control dinámico de opacidad al vuelo (`Ctrl+Shift+A` + `M`/`L`/`1`).

```bash
just kitty
```

---

## 7. Salvapantallas 3D y Bloqueo (`screensaver-setup.sh`)

Instala la suite XScreenSaver con efectos 3D OpenGL (Matrix, Tuberías, Flurry), registra el demonio en autostart de GNOME y vincula el atajo `Super + L` para activar el salvapantallas animado al bloquear la pantalla.

```bash
just screensaver
```

---

## 8. Entorno de Shell (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`), tipografías para desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode) y el prompt interactivo Starship.

```bash
just shell
just fonts
just fastfetch
```

---

## 9. Panel de Administración Web Cockpit (`cockpit.sh`)

Instala Cockpit con módulos para administrar el equipo desde el navegador ([https://localhost:9090](https://localhost:9090)):
- `cockpit-podman`: Gestión de contenedores Podman.
- `cockpit-machines`: Gestión de MVs en KVM/QEMU.
- `cockpit-storaged`: Estado de discos SSD/NVMe y datos SMART.

```bash
just cockpit
```

---

## 10. Temas e Iconos de Escritorio (`apariencia.sh`)

Aplica temas e iconos Papirus-Dark y Adwaita, integrando visualmente aplicaciones GTK y Qt.

```bash
just apariencia
```
