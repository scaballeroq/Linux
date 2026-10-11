# Reglas del Agente: Experto en Linux & Hardware HP EliteBook

## Directrices de Entorno
1. **Comandos Idempotentes y Modernos**:
   - Para inspección de hardware AMD: utiliza `lscpu`, `radeontop`, `sensors` o `amdgpu_top`.
   - Para administración de servicios: prioriza `systemctl --user` para servicios de usuario (como PipeWire, pods de Podman, GNOME session).
   - Para audio: usa herramientas de PipeWire (`wpctl status`, `pw-cli`).
   - Para gestión de paquetes: utiliza `pacman` para repos oficiales y `paru` (preferido en CachyOS) o `yay` para paquetes de AUR. Nunca uses `sudo yay` ni `sudo paru`.

2. **Integración con GNOME Shell & Mutter (Wayland)**:
   - Toda interacción y configuración del entorno de escritorio debe realizarse a través de herramientas nativas de GNOME: `gsettings`, `dconf`, `gnome-extensions` y paneles de `gnome-control-center`.
   - La gestión de ventanas y composición corre a cargo de Mutter sobre Wayland nativo.
   - No sugieras comandos incompatibles con Wayland como `xdotool`, `xclip`, `xrandr` o `wmctrl`.

3. **Topología de Monitores**:
   - El sistema cuenta con 3 salidas a 1080p:
     - Pantalla LG 32" (1920x1080)
     - TV Sony 32" (1920x1080)
     - Pantalla de portátil 15.6" (1920x1080)
   - Ten en cuenta esta configuración al sugerir reglas de ventanas, scripts de captura de pantalla o disposiciones en `~/.config/monitors.xml`.

4. **Cortafuegos y Seguridad de Red (Firewalld Obligatorio)**:
   - El sistema utiliza exclusivamente **Firewalld** (`firewall-cmd`).
   - Zona predeterminada del equipo: `home` (red local confiable).
   - Zona para Podman Rootless: `trusted` (interfaces `podman0`).
   - Zona para QEMU/KVM: `libvirt` (interfaz `virbr0`).
   - **Prohibición**: NUNCA sugieras ni utilices comandos de `ufw` ni reglas crudas de `iptables`.
   - Ante cualquier propuesta de despliegue de servidor de desarrollo (ej. Vite, FastAPI, Django, Docker/Podman, bases de datos), comprueba o añade la regla en Firewalld:
     `sudo firewall-cmd --zone=home --add-port=<puerto>/tcp --permanent && sudo firewall-cmd --reload`
