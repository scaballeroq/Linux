# 🐧 Soplos Linux Tyson: Configuración de Entorno Debian Testing + KDE Plasma 6

Este repositorio contiene una colección organizada, modular y automatizada de scripts de configuración para sistemas **Soplos Linux Tyson** (derivada directa de **Debian Testing**) con el entorno de escritorio **KDE Plasma 6**, gestión de initramfs con **dracut**, gestor de arranque **GRUB** y administración de servicios y contenedores con **systemd** y **Podman**.

---

## 📂 Organización del Repositorio

La configuración está estructurada de forma modular para facilitar su mantenimiento y despliegue:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal (compartida entre Bash y Zsh).
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados y utilidades modernas en Rust (`eza`, `bat`, `duf`, `dust`).
- **`environment.sh`**: Variables globales que afectan el comportamiento de la shell (`PATH`, `EDITOR`, paginador `less` con colores).
- **`functions.sh`**: Colección de funciones avanzadas y utilidades multimedia (FFmpeg, ImageMagick, extracción unificada).
- **`kde_settings.sh`**: Configuraciones de entorno para KDE Plasma 6, luz nocturna, temas, reinicio de shell y accesos a Preferencias KCM.
- **`history.sh`**: Controla cómo recuerda los comandos (sin duplicados, hasta 20k líneas).
- **`options.sh`**: Configura el comportamiento interno de la shell (`autocd`, `globstar`).
- **`podman-functions.sh`**: Funciones para gestión simplificada de contenedores Podman.
- **`rclone_aliases.sh`**: Atajos para sincronización en la nube con Google Drive.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas con yt-dlp y ffmpeg.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización de KDE Plasma 6 y seguridad:
- **`kde-settings.sh`**: Personalización automatizada de KDE Plasma 6 (Luz nocturna desactivada, reloj 24h, botones de ventana, temas oscuros).
- **`kde-widgets.sh`**: Configuración de widgets, Klipper (portapapeles persistente de 100 elementos), KWin tiling y atajos globales.
- **`kde-plasma-customization.sh`**: Personalización visual avanzada (Klassy, Kvantum Fluent-Dark, Material You, Panel Colorizer, Tela Icons).
- **`konsole.sh`**: Instalación y perfil moderno de Konsole (translúcido con blur al 85%, JetBrainsMono Nerd Font, sin scrollbar, atajo `Ctrl+Alt+T` e integración en Dolphin `F4`).
- **`kitty.sh`**: Terminal Kitty acelerada por GPU con opacidad, blur y menú contextual en Dolphin.
- **`apariencia.sh`**: Instalación de temas e iconos (Breeze Dark, Papirus-Dark y consistencia Qt/GTK).
- **`laptop-setup.sh`**: Optimización para portátiles de desarrollo (Touchpad, Bluetooth, `power-profiles-daemon`, HiDPI, VRR en Wayland).
- **`fingerprint-setup.sh`**: Desbloqueo y autenticación por huella dactilar (`fprintd`, PAM para `sudo`, `sddm`, `kde` y `polkit-1`).
- **`hp-printer-setup.sh`**: Impresora HP LaserJet Pro M15w vía USB (CUPS, HPLIP, plugin propietario y `print-manager` de KDE).
- **`debian-tuning.sh`**: Ajustes de Kernel Sysctl (`inotify`, `max_map_count`, swappiness) y soporte de `distrobox`.
- **`cockpit.sh`**: Panel de administración web Cockpit con módulos Podman, Virtualización y Almacenamiento.
- **`fastfetch.sh`**: Información estética del sistema al abrir la terminal (Fastfetch).
- **`firefox.sh`**: Instalación de Mozilla Firefox oficial (.deb de Mozilla APT).
- **`fonts.sh`**: Fuentes tipográficas de desarrollo (JetBrainsMono, FiraCode, CascadiaCode Nerd Fonts).
- **`seguridad.sh`**: Endurecimiento con Firewall UFW y Fail2ban adaptado para portátil de desarrollo con Podman y KDE Connect.
- **`shell.sh`**: Herramientas modernas de terminal (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`) y prompt Starship unificado para Bash y Zsh.
- **`yt-dlp-setup.sh`**: Dependencias multimedia (yt-dlp, ffmpeg y motor JS Deno vía mise).

### 🐳 [Podman](./Podman/)
Ecosistema completo para contenedores Rootless y Systemd Quadlets:
- **Instalación**: `podman-install.sh`, `quadlets-setup.sh`
- **Servicios Compartidos**: Traefik, PostgreSQL, Redis, Keycloak.
- **Templates**: Python-Postgres, Python-Postgres-Redis, Fullstack.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Instalación y configuración de KVM/QEMU, Libvirt, sockets modulares, VirtIO y Nested KVM optimizado para Debian.

### 💻 [IDEs y Editores](./IDE/)
- **`neovim.sh`**: Neovim moderno con LazyVim.
- **`vscode.sh`**: Visual Studio Code nativo (.deb oficial de Microsoft).
- **`antigravity.sh`**: Google Antigravity Desktop 2.0.
- **`antigravity-cli.sh`** & **`antigravity-ide.sh`**: Suite de CLI y motor IDE de Antigravity.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### 🎮 [Juegos](./Juegos/)
- **`steam.sh`**: Steam aislado vía Flatpak con soporte para **Proton-GE**.

---

## 🚀 Despliegue Rápido con Just

Para ejecutar la configuración completa del sistema:

```bash
just setup-all
```

O ejecutar componentes de forma individual:
```bash
just shell        # Configura Starship unificado en Bash y Zsh
just security     # Configura Firewall UFW para portátil + Podman
just kde          # Aplica configuración de KDE Plasma 6
just konsole      # Configura terminal Konsole translúcida
just widgets      # Configura widgets, Klipper y atajos de KWin
just ides         # Instala Neovim, VSCode, Antigravity y OpenCode
```

---
*Mantenido por [caballero](https://github.com/scaballeroq)*
