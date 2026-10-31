---
sidebar_position: 2
---

# Configuración del Sistema en Debian GNU/Linux (GNOME Shell Wayland)

Esta guía detalla el proceso de configuración base, optimización de la terminal, instalación de herramientas esenciales, soporte multimedia y personalización del entorno de usuario aplicados a un sistema **Debian GNU/Linux** con **GNOME Shell**.

Las configuraciones están automatizadas a través de los scripts ubicados en la carpeta `Setup` y orquestadas mediante el `justfile`.

---

## 1. Post-Instalación Base (`post-install.sh`)

Prepara el sistema base detectando la CPU del equipo y ejecutando el aprovisionamiento adecuado:
- **`post-install-amd.sh`**: Para AMD Ryzen 7 7730U / Radeon Graphics (Vega 8) (Mesa RADV, VA-API hardware, PipeWire, ZRAM, Flatpak Flathub).
- **`post-install-intel.sh`**: Para procesadores Intel Core (i965/iHD VA-API, Kodi, PipeWire).

Comando:
```bash
just post-install
```

---

## 2. Entorno de Terminal y Shell (`shell.sh`, `fastfetch.sh`, `fonts.sh` y `kitty.sh`)

Instala utilidades modernas de consola, tipografías para desarrollo, el prompt interactivo Starship y el emulador Kitty acelerado por GPU.

### Utilidades Modernas de Terminal
Se instalan alternativas modernas a comandos clásicos:
- `eza` (reemplazo de `ls` con git e iconos)
- `bat` (reemplazo de `cat` con sintaxis coloreada vía `batcat`)
- `fzf` (buscador difuso interactivo para Ctrl+R, Ctrl+T, Alt+C)
- `zoxide` (navegación inteligente con `cd`)
- `ripgrep` (`rg`, búsqueda rápida de texto)
- `fd-find` (`fd`, búsqueda intuitiva de archivos)
- `duf` y `du-dust` (visualización de espacio en disco)
- `procs` (reemplazo moderno de `ps`)
- `btop` (monitor de recursos del sistema)

### Kitty Terminal Acelerada por GPU
Configura Kitty con:
- Opacidad al 75% con desenfoque de fondo (*blur 32*) acelerado por GPU Mesa RADV.
- Esquema de color Catppuccin Mocha (#181825).
- Tipografía JetBrainsMono Nerd Font.
- Atajo global `Ctrl+Alt+T` en GNOME Shell.
- Script contextual en Nautilus para "Abrir en Kitty".

### Fuentes de Desarrollo (Nerd Fonts)
Descarga e instala fuentes optimizadas para programación y glifos de terminal:
`JetBrainsMono`, `FiraCode`, `CascadiaCode`, `Meslo` y `Hack`.

### Fastfetch
Muestra información estética del hardware y sistema. Soporta temas oficiales de Debian (`debian`) y diseño minimalista (`compact`).

---

## 3. Escritorio GNOME Shell y GSConnect (`gnome-settings.sh` y `gsconnect.sh`)

- **Modo Oscuro**: Aplica `prefer-dark` y tema `Yaru-dark`.
- **Luz Nocturna**: Temperatura cálida a 4000K para descanso visual.
- **Ventanas**: Botones minimizar y maximizar visibles.
- **Nautilus Scripts**: Menú contextual con accesos a Kitty, Google Antigravity y VS Code.
- **GSConnect**: Integración nativa de KDE Connect sin dependencias de KDE/Qt, con reglas en Firewalld (puertos 1714-1764 TCP/UDP).
- **Extensiones**: Soporte para Dash to Dock, AppIndicator, Blur my Shell y Tiling Shell.

---

## 4. Navegadores y Software Desacoplado

- **Google Chrome**: Repositorio oficial de Google con optimización Wayland (`--ozone-platform-hint=auto` y aceleración VA-API).
- **Mozilla Firefox**: Paquete nativo `.deb` oficial de Mozilla con APT Pin-Priority 1000, eliminando el wrapper Snap.
- **Flatpak**: Catálogo completo (Flatseal, Podman Desktop, Warehouse, VLC, Celluloid, OBS Studio, Shotcut, Spotify, Vesktop).
- **Steam**: Cliente nativo con arquitectura 32 bits (`i386`), drivers Mesa RADV de 32 bits, GameMode y MangoHud.

---

## 5. Resumen de Comandos con Just

```bash
just post-install        # Despachador de post-instalación
just gnome-setup         # Configura entorno GNOME
just gnome-extensions    # Instala y activa extensiones
just gsconnect           # Configura GSConnect y Firewalld
just shell               # Instala herramientas CLI modernas
just kitty               # Configura terminal Kitty
just fonts               # Instala fuentes Nerd Fonts
just fastfetch           # Configura banner estético Fastfetch
just flatpak             # Instala catálogo Flatpak
just chrome              # Instala Google Chrome oficial
just firefox             # Instala Firefox nativo (.deb)
just steam               # Instala Steam y librerías 32-bit
```
