---
sidebar_position: 2
---

# Configuración del Sistema en Soplos Linux Tyson

Esta guía detalla el proceso de personalización de KDE Plasma 6, terminales Konsole/Kitty, shell unificado (Bash y Zsh con Starship), seguridad UFW para desarrollo con Podman y panel de administración web aplicados a **Soplos Linux Tyson** (derivada directa de **Debian Testing** con **KDE Plasma 6**, **dracut**, **GRUB** y **systemd**).

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup`.

---

## 1. Personalización y Widgets de KDE Plasma 6 (`kde-settings.sh` y `kde-widgets.sh`)

Configura de manera nativa y atómica:
- **Luz Nocturna (Night Color)** desactivada.
- **Reloj 24h** y porcentaje de batería.
- **Botones de ventana**: minimizar, maximizar y cerrar a la derecha.
- **Touchpad**: Tap-to-click y desplazamiento natural.
- **Klipper**: Gestor de portapapeles persistente de 100 elementos con búsqueda rápida (`Meta + V`).
- **Efectos KWin**: Blur y translucidez a 60/120 FPS, atajos de overview y tiling.

```bash
just kde
just widgets
```

---

## 2. Terminal Konsole Translúcida y Kitty (`konsole.sh` y `kitty.sh`)

- **Konsole**: Perfil oscuro translúcido (85% opacidad) con efecto blur, fuente JetBrainsMono Nerd Font, atajo de teclado `Ctrl + Alt + T` e integración con Dolphin (`F4`).
- **Kitty**: Terminal acelerada por GPU, atajos de opacidad dinámica y menú contextual en Dolphin.

```bash
just konsole
just kitty
```

---

## 3. Entorno de Shell Unificado (`shell.sh`, `fastfetch.sh` y `fonts.sh`)

Instala utilidades modernas de consola (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`, `fd`, `duf`), tipografías para desarrollo (Nerd Fonts) y el prompt interactivo **Starship** unificado tanto para **Bash** como para **Zsh**.

```bash
just shell
just fonts
just fastfetch
```

---

## 4. Seguridad y Firewall para Desarrollo con Podman (`seguridad.sh`)

Configura UFW y Fail2ban para proteger el portátil en cualquier red Wi-Fi sin bloquear las funciones esenciales de desarrollo:
- Tráfico en `localhost` / `127.0.0.1` permitido.
- Reenvío e interfaces virtuales de **Podman** y **KVM** habilitadas.
- Soporte para **KDE Connect** y descubrimiento mDNS / impresoras.
- Rate-limiting para SSH y Cockpit.

```bash
just security
```

---

## 5. Panel de Administración Web Cockpit (`cockpit.sh`)

Instala Cockpit con módulos para administrar el equipo desde el navegador ([https://localhost:9090](https://localhost:9090)):
- `cockpit-podman`: Gestión de contenedores Podman.
- `cockpit-machines`: Gestión de MVs en KVM/QEMU.
- `cockpit-storaged`: Estado de discos SSD/NVMe y datos SMART.

```bash
just cockpit
```

---

## 6. Temas e Iconos de Escritorio (`apariencia.sh`)

Aplica paquetes de diseño para un entorno visual limpio y homogéneo con temas Breeze Dark, Papirus-Dark y consistencia entre aplicaciones Qt y GTK.

```bash
just apariencia
```
