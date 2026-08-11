---
sidebar_position: 2
---

# Configuración del Sistema en Debian 13

Esta guía detalla el proceso de configuración base, automontaje de partición de trabajo, compilación de kernel nativo `x86_64-v3`, salvapantallas 3D, extensiones GNOME, optimización de la terminal y panel de administración web aplicados a un sistema Debian 13 (Trixie).

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
   CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)
   echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list
   sudo apt update
   ```

3. **Software Esencial y Utilidades**:
   Instala utilidades de compilación y monitorización del sistema:
   - Compilación: `build-essential`, `cmake`
   - Paquetes: `zram-tools`
   - Monitorización: `btop`, `htop`, `inxi`
   - Utilidades: `curl`, `fuse3`, `libfuse2t64`, `exfatprogs`, `p7zip`, `unrar`, `zip`, `unzip`, `bzip2`, `xz-utils`
   - Gráficos y Multimedia: `vlc`, `gimp`, `gparted`
   - Paquetes universales: `flatpak`, `gnome-software-plugin-flatpak`

4. **Codecs Multimedia y Aceleración HW**:
   ```bash
   sudo apt install -y libavcodec-extra ffmpeg mesa-va-drivers mesa-vdpau-drivers
   ```

---

## 2. Automontaje de Partición Workspace (`mount-workspace.sh`)

Monta automáticamente la partición de datos `/home/caballero/Workspace` mediante `/etc/fstab` usando su UUID `3d81e6d2-6011-484a-8123-6bcf68f365ba`.
Utiliza las opciones `defaults,noatime,nofail` para evitar cualquier bloqueo del sistema durante el arranque si la partición secundaria estuviese desconectada.

```bash
./Setup/mount-workspace.sh
```

---

## 3. Compilador de Kernel Linux NATIVO x86_64-v3 (`build-custom-kernel.sh`)

Script que consulta la API de `kernel.org` (`https://www.kernel.org/releases.json`) para descargar la última versión estable oficial del Kernel Linux (ej. `v6.13.2`), recortar la configuración mediante `make localmodconfig` para la CPU y dispositivos de tu portátil, y compilar paquetes `.deb` nativos con optimizaciones de arquitectura `x86_64-v3`, latencia a **1000Hz** y **Preemption Dinámica**.

```bash
./Setup/build-custom-kernel.sh
# O usando just:
just build-kernel
```

---

## 4. Instalación Limpia de Extensiones GNOME (`gnome-extensions.sh`)

Instala `gnome-browser-connector`, `extension-manager` y descarga las 17 extensiones personalizadas utilizando el instalador nativo por DBus `gnome-extensions install --force` y compilando automáticamente los esquemas GSettings (`glib-compile-schemas`), evitando el estado de error o deshabilitado en el gestor de extensiones.

```bash
./Setup/gnome-extensions.sh
# O usando just:
just extensions
```

---

## 5. Salvapantallas 3D y Bloqueo (`screensaver-setup.sh`)

Instala la suite XScreenSaver con efectos 3D OpenGL (Matrix, Tuberías, Flurry), registra el demonio en autostart de GNOME y vincula el atajo `Super + L` para activar el salvapantallas animado al bloquear la pantalla.

```bash
./Setup/screensaver-setup.sh
# Personalización de efectos:
xscreensaver-demo
```

---

## 6. Entorno de Terminal y Shell (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo (Nerd Fonts) y el prompt interactivo Starship.

### Utilidades Modernas de Terminal
Se instalan alternativas modernas a comandos clásicos: `eza`, `bat`, `fzf`, `zoxide`, `ripgrep` (`rg`), `fd-find` (`fd`), `duf`, `dust`, `procs`.

### Prompt Starship
Se configura `starship` en `~/.bashrc.d/starship.sh` y se aplica el diseño personalizado `Setup/starship.toml`.

---

## 7. Panel de Administración Web Cockpit (`cockpit.sh`)

Instala Cockpit con su suite completa de módulos para administrar el portátil o servidor desde el navegador:

- `cockpit-podman`: Gestión de contenedores Podman.
- `cockpit-machines`: Gestión visual de MVs en KVM/QEMU.
- `cockpit-storaged`: Estado de discos SSD/NVMe, LVM y datos SMART.
- `cockpit-networkmanager`: Configuración de interfaces y redes.
- `lm-sensors`: Monitorización de temperaturas de CPU/GPU y ventiladores.

Aplica protección en UFW (`sudo ufw limit 9090/tcp`) y utiliza el socket en segundo plano `cockpit.socket` para consumir 0 MB de RAM cuando no se está navegando. Acceso en [https://localhost:9090](https://localhost:9090).

---

## 8. Temas e Iconos de Escritorio (`apariencia.sh`)

Aplica paquetes de diseño para un entorno visual limpio y homogéneo con Papirus y Adwaita.

---

## Verificación

Para comprobar que los componentes principales se instalaron y configuraron correctamente:

- **Kernel Optimizado**: Ejecuta `uname -r` o escribe `check-kernel` en la terminal.
- **Salvapantallas**: Presiona `Super + L` para verificar el bloqueo animado.
- **Cockpit**: Ingresa a [https://localhost:9090](https://localhost:9090) desde tu navegador.
