---
sidebar_position: 2
---

# Configuración del Sistema en Debian Testing (KDEDebian)

Esta guía detalla el proceso de configuración base, automontaje de partición de trabajo, compilación de kernel nativo `x86_64-v3`, personalización de KDE Plasma 6, terminal Konsole y panel de administración web aplicados a un sistema **Debian Testing (Trixie)** con **KDE Plasma 6**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base configurando repositorios oficiales adicionales, instalando software esencial, PipeWire, la suite KDE Plasma y aceleración por hardware.

1. **Actualización base del sistema**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Habilitación de repositorios Extra** (Contrib, Non-Free, Non-Free-Firmware):
   ```bash
   sudo apt install -y curl ca-certificates gnupg lsb-release
   # En Debian Testing los repositorios principales entregan los paquetes más recientes
   ```

3. **Software Esencial y Utilidades**:
   Instala utilidades de compilación, suite KDE y monitorización:
   - Compilación: `build-essential`, `cmake`
   - Memoria: `zram-tools` (ZRAM con ZSTD al 50%)
   - Monitorización: `btop`, `htop`, `inxi`, `plasma-systemmonitor`
   - Utilidades: `curl`, `fuse3`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`
   - Entorno KDE y Aplicaciones: `kde-plasma-desktop`, `plasma-workspace`, `dolphin`, `konsole`, `ark`, `spectacle`, `gwenview`, `kate`, `kcalc`, `kdeconnect`
   - Paquetes universales: `flatpak`, `plasma-discover`, `plasma-discover-backend-flatpak`

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   sudo apt install -y libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers vainfo
   ```

---

## 2. Automontaje de Partición Workspace (`mount-workspace.sh`)

Monta automáticamente la partición de datos `/home/caballero/Workspace` mediante `/etc/fstab` usando su UUID `3d81e6d2-6011-484a-8123-6bcf68f365ba`.
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

## 4. Personalización y Widgets de KDE Plasma 6 (`kde-settings.sh` y `kde-widgets.sh`)

Configura de manera nativa y atomizada:
- **Luz Nocturna (Night Color)** a 3500K.
- **Reloj 24h** y porcentaje de batería.
- **Botones de ventana**: minimizar, maximizar y cerrar a la derecha.
- **Touchpad**: Tap-to-click y desplazamiento natural.
- **Klipper**: Gestor de portapapeles persistente con búsqueda rápida.
- **Efectos KWin**: Blur y translucidez a 60/120 FPS.

```bash
just kde
just widgets
```

---

## 5. Terminal Konsole Translúcida e Integración (`konsole.sh`)

Instala y configura Konsole con un perfil oscuro translúcido (85% opacidad) con efecto blur, fuente JetBrainsMono Nerd Font, atajo de teclado `Ctrl + Alt + T` e integración con Dolphin (`F4`).

```bash
just konsole
```

---

## 6. Entorno de Shell (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`), tipografías para desarrollo (Nerd Fonts) y el prompt interactivo Starship.

---

## 7. Panel de Administración Web Cockpit (`cockpit.sh`)

Instala Cockpit con módulos para administrar el equipo desde el navegador ([https://localhost:9090](https://localhost:9090)):
- `cockpit-podman`: Gestión de contenedores Podman.
- `cockpit-machines`: Gestión de MVs en KVM/QEMU.
- `cockpit-storaged`: Estado de discos SSD/NVMe y datos SMART.

---

## 8. Temas e Iconos de Escritorio (`apariencia.sh`)

Aplica paquetes de diseño para un entorno visual limpio y homogéneo con temas Breeze Dark, Papirus-Dark y consistencia entre aplicaciones Qt y GTK.

```bash
just apariencia
```
