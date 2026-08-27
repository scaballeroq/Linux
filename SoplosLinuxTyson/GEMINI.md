# 🐧 Contexto del Sistema Operativo: Soplos Linux Tyson

Este documento define la base del entorno y las especificaciones técnicas fundamentales para todas las interacciones, generación de código, scripts y tareas en este proyecto.

---

## 📋 Especificaciones del Sistema

- **Distribución**: **Soplos Linux Tyson** (derivada directa de **Debian Testing**).
- **Entorno de Escritorio**: **KDE Plasma 6** (Frameworks 6, Qt 6, KWin).
- **Gestor de Arranque (Bootloader)**: **GRUB** (GNU GRUB).
- **Entorno previo al root (Initramfs)**: **dracut** (generación y módulos de initramfs gestionados vía `dracut` / `/etc/dracut.conf.d/`, sustituyendo a `initramfs-tools`).
- **Sistema Operativo Real (Init & Service Manager)**: **systemd** (control de servicios, targets, timers, sockets, journald y Podman Quadlets).

---

## 🛠️ Directrices de Desarrollo y Asistencia

Al generar scripts, configuraciones, comandos de terminal o resolver incidencias:

1. **Gestión de Paquetes y Repositorios**:
   - Utilizar herramientas del ecosistema **Debian Testing** (`apt`, `dpkg`, repositorios `trixie`/`testing`, componentes `main`, `contrib`, `non-free`, `non-free-firmware`).

2. **Arranque y Kernel**:
   - **Bootloader**: Configuraciones de arranque mediante GRUB (`/etc/default/grub`, `update-grub` / `grub-mkconfig`).
   - **Initramfs (dracut)**: En tareas relacionadas con el kernel, controladores o arranque temprano, utilizar `dracut` para la reconstrucción del initramfs (evitar comandos de `initramfs-tools` como `update-initramfs`).

3. **Gestión de Servicios y Sistema (systemd)**:
   - Todo servicio, demonio o tarea programada debe administrarse a través de `systemd` (`systemctl`, `journalctl`, unidades de sistema y de usuario).

4. **Entorno Gráfico y Aplicaciones (KDE Plasma 6)**:
   - Las configuraciones estéticas, atajos y utilidades deben integrarse con **KDE Plasma 6** y **Qt 6** (usando herramientas como `kwriteconfig6`, `qdbus6`, KWin scripts, Breeze themes, etc.).

5. **Entorno de Trabajo**:
   - Usuario principal: `caballero`
   - Directorio de repositorios: `/home/caballero/Workspace/Repositorios/...`
