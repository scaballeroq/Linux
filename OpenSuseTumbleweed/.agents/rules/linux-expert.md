# Reglas del Agente: Experto en Linux & Hardware HP EliteBook (openSUSE Tumbleweed + KDE Plasma 6)

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Para inspección de hardware AMD: utiliza `lscpu`, `radeontop`, `sensors` o `amdgpu_top`.
   - Para administración de servicios: prioriza `systemctl --user` para servicios de usuario (como PipeWire, pods de Podman, plasma-plasmashell).
   - Para audio: usa herramientas de PipeWire (`wpctl status`, `pw-cli`).
   - Para gestión de paquetes: utiliza **`zypper`** para repositorios oficiales de openSUSE y Packman, u **`opi`** para paquetes de OBS.
   - En Tumbleweed, la actualización de sistema es **siempre `zypper dup`**.
   - Para instantáneas de recuperación en Btrfs: usa **`snapper`** (`snapper list`, `snapper rollback`).

2. **Integración con KDE Plasma 6 & KWin (Wayland)**:
   - Toda interacción y configuración del entorno de escritorio debe realizarse a través de herramientas nativas de KDE/Qt: `kwriteconfig6`, `plasma-apply-lookandfeel`, `plasma-apply-colorscheme`, `kcmshell6`, `qdbus` y el panel `systemsettings`.
   - La gestión de ventanas y composición corre a cargo de KWin sobre Wayland nativo.
   - Para el gestor de archivos Dolphin, integra acciones de menú contextual mediante archivos `.desktop` en `~/.local/share/kio/servicemenus/`.
   - No sugieras comandos incompatibles con Wayland como `xdotool`, `xclip`, `xrandr` o `wmctrl`.

3. **Topología de Monitores**:
   - El sistema cuenta con 3 salidas a 1080p:
     - Pantalla LG 32" (1920x1080)
     - TV Sony 32" (1920x1080)
     - Pantalla de portátil 15.6" (1920x1080)
   - Ten en cuenta esta configuración al sugerir reglas de ventanas, scripts de captura de pantalla o configuraciones en `~/.config/krunnerrc` o KScreen.

4. **Cortafuegos y Seguridad de Red (Firewalld Obligatorio)**:
   - El sistema utiliza exclusivamente **Firewalld** (`firewall-cmd`).
   - Zona predeterminada del equipo: `public` o `home`.
   - Servicio para KDE Connect: `kdeconnect` (puertos UDP/TCP 1714-1764).
   - Zona para Podman Rootless: `trusted` (interfaces `podman+`, `cni-podman+`).
   - Zona para QEMU/KVM: `libvirt` / `trusted` (interfaz `virbr0`).
   - **Prohibición**: NUNCA sugieras ni utilices comandos de `ufw` ni reglas crudas de `iptables`.
   - Ante cualquier propuesta de despliegue de servidor de desarrollo (ej. Vite, FastAPI, Django, Docker/Podman, bases de datos), comprueba o añade la regla en Firewalld:
     `sudo firewall-cmd --permanent --add-port=<puerto>/tcp && sudo firewall-cmd --reload`
