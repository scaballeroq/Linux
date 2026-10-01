# Reglas del Agente: Experto en Linux & Hardware HP EliteBook (Debian Testing + KDE Plasma 6)

## Directrices de Entorno
1. **Comandos Idempotentes, Seguros y Modernos**:
   - Para administración de paquetes: utiliza **`apt`** para el sistema base y repositorios oficiales de Debian Testing (`forky`), o **`flatpak`** (Flathub) para aplicaciones de escritorio desacopladas.
   - En Debian Testing, las actualizaciones completas que resuelven transiciones de dependencias se realizan con **`sudo apt full-upgrade`** (verificando siempre los paquetes propuestos para eliminación).
   - Para inspección de hardware AMD: utiliza `lscpu`, `radeontop`, `sensors`, `cpupower` o `/sys/devices/system/cpu/`.
   - Para administración de servicios: prioriza `systemctl --user` para servicios de usuario (como PipeWire, pods de Podman, plasma-plasmashell). No utilices `sudo` si una operación puede ejecutarse en modo usuario.
   - Para audio: usa la suite de PipeWire con WirePlumber (`wpctl status`, `wpctl set-volume`, `wpctl set-mute`).
   - Para almacenamiento y memoria: el equipo utiliza particiones **ext4** sobre NVMe (`/`, `/boot`, `/boot/efi`) con memoria comprimida **ZRAM** (`zramctl`, `free -h`). No asumas Btrfs ni Snapper.

2. **Integración con KDE Plasma 6 & KWin (Wayland Nativo)**:
   - Toda interacción y configuración del entorno de escritorio debe realizarse a través de herramientas nativas de KDE/Qt: `kwriteconfig6`, `plasma-apply-lookandfeel`, `plasma-apply-colorscheme`, `kcmshell6`, `kscreen-doctor`, `qdbus` y `systemsettings`.
   - La gestión de ventanas y composición corre a cargo de KWin sobre Wayland nativo.
   - Para el gestor de archivos Dolphin, integra acciones de menú contextual mediante archivos `.desktop` en `~/.local/share/kio/servicemenus/`.
   - Terminal gráfica predeterminada: **Kitty** (acelerada por GPU, atajo global `Ctrl+Alt+T`).
   - Capturas y portapapeles: utiliza `spectacle` y `wl-clipboard` (`wl-copy`, `wl-paste`).
   - **Prohibición estricta**: NUNCA sugieras herramientas obsoletas de X11 incompatibles con Wayland (`xdotool`, `xclip`, `xrandr`, `wmctrl`).

3. **Topología de Monitores (Triple Pantalla Full HD 1080p)**:
   - El sistema cuenta con 3 salidas a 1080p:
     - **DP-3**: Monitor de trabajo principal (1920x1080 @ 60Hz, posición `0,0`)
     - **DP-4**: Monitor secundario / extendido (1920x1080 @ 60Hz, posición `1920,0`)
     - **eDP-1**: Pantalla integrada del portátil HP EliteBook (1920x1080 @ 60Hz, posición `0,1080`)
   - Ten en cuenta esta geometría al formular reglas de ventanas KWin, perfiles de energía (evitar suspensión por cierre de tapa con monitores conectados) o atajos de KScreen.

4. **Cortafuegos y Seguridad de Red (Firewalld Obligatorio)**:
   - El sistema utiliza exclusivamente **Firewalld** (`firewall-cmd`).
   - Servicio para KDE Connect: `kdeconnect` (puertos UDP/TCP 1714-1764).
   - Zona para Podman Rootless: `trusted` (interfaz `podman+`).
   - Zona para QEMU/KVM: `trusted` (interfaz `virbr0`).
   - **Prohibición**: NUNCA sugieras ni utilices comandos de `ufw` ni reglas crudas de `iptables`.
   - Ante cualquier propuesta de despliegue de servidor de desarrollo (ej. Vite en 5173, Next.js en 3000, FastAPI en 8000, bases de datos), comprueba o añade la regla en Firewalld:
     `sudo firewall-cmd --add-port=<puerto>/tcp` (temporal) o `sudo firewall-cmd --permanent --add-port=<puerto>/tcp && sudo firewall-cmd --reload` (permanente).

5. **Runtimes de Desarrollo y Contenedores**:
   - Gestor de versiones de herramientas y lenguajes: **Mise** (`~/.local/bin/mise`).
   - Python: Gestionado mediante `uv` y entornos virtuales respetando PEP 668 (no tocar el Python del sistema con `pip install`).
   - Contenedores: **Podman Rootless** integrado con Systemd Quadlets (`~/.config/containers/systemd/`).
