# 📺 CachyOS TV & Centro Multimedia (HP Z230 SFF / Sony TV)

Configuración automatizada, modular y de alto rendimiento para convertir el ordenador **HP Z230 SFF Workstation** en un centro multimedia de salón de última generación utilizando **CachyOS (Arch Linux)** con entorno **GNOME Shell (Wayland)** conectado a un televisor **Sony TV**.

---

## 💻 Especificaciones del Hardware (HP Z230 SFF)

Basado en la telemetría e información real del equipo:

| Componente | Especificación Técnica | Optimización en CachyOS |
| :--- | :--- | :--- |
| **Modelo** | HP Z230 SFF Workstation | Chasis compacto silencioso para mueble de salón |
| **Procesador (CPU)** | Intel® Core™ i7-4790 (4C / 8T @ 3.60 GHz - 4.00 GHz Turbo) | Arquitectura Haswell compatible con repositorios `x86-64-v3` de CachyOS |
| **Gráficos (GPU)** | Intel® HD Graphics 4600 (HSW GT2) | Driver Mesa Crocus + VA-API hardware driver `i965` (`LIBVA_DRIVER_NAME=i965`) |
| **Memoria RAM** | 8.0 GiB DDR3 | ZRAM swap comprimida con algoritmo `zstd` al 50% (4 GB) vía `zram-generator` |
| **Almacenamiento** | 256.1 GB SSD | TRIM periódico habilitado (`fstrim.timer`) y limpieza automática de cachés |
| **Pantalla** | Sony TV (Full HD 1920x1080 @ 60Hz) | Conexión HDMI/DisplayPort, escala visual 1.15 y supresión de reposo en vídeo |
| **Audio** | Salida Digital HDMI hacia altavoces Sony TV | PipeWire + WirePlumber con quantum 1024 y normalización estéreo downmix |
| **Red & NAS** | Gigabit Ethernet / Wi-Fi | Integración con NAS doméstico para streaming de películas y series en Kodi |

---

## 🍿 Pila Multimedia y Aplicaciones Principales

El sistema está configurado para proporcionar una experiencia de televisor fluida, accesible desde el mando a distancia, teclado inalámbrico o ratón:

### 1. 🌐 Google Chrome con Widevine DRM (Streaming Web)
Acceso nativo a plataformas protegidas por DRM con aceleración por hardware en 1080p:
- **YouTube** (`https://www.youtube.com`)
- **Netflix** (`https://www.netflix.com`)
- **Amazon Prime Video** (`https://www.primevideo.com`)
- **Pluto TV** (`https://pluto.tv`)
- **RTVE Play** (`https://www.rtve.es/play/`)
- **Orange TV** (`https://orangetv.orange.es`)

Cada servicio cuenta con un lanzador `.desktop` en modo WebApp independiente (`--app=URL`) e iconos vectoriales SVG de alta definición integrados en el Dock de favoritos de GNOME Shell.

### 2. 📺 Kodi Media Center (Nativo Pacman)
- Instalación nativa mediante `pacman` para integración total con el driver VA-API `i965` y backend de audio PipeWire.
- Integración de red con el **NAS doméstico** para explorar y reproducir colecciones de películas y series mediante SMB/CIFS, NFS y auto-descubrimiento Avahi (mDNS).
- Puntos de montaje preconfigurados en `/mnt/nas/peliculas` y `/mnt/nas/series`.

### 3. 🎬 Stremio (Flatpak Flathub)
- Ejecutado en contenedor desacoplado con permisos específicos para la GPU Haswell (`--env=GSK_RENDERER=gl`, `--env=LIBVA_DRIVER_NAME=i965`).
- Perfil personalizado `mpv.conf` para evitar ruidos o chasquidos en altavoces de televisión HDMI estéreo (`ao=pulse`, `audio-channels=stereo`, `audio-normalize-downmix=yes`).

### 4. 🎞️ VLC Media Player (Flatpak Flathub)
- Reproductor de contingencia para archivos locales y discos extraíbles.

---

## ⚡ Automatización mediante Justfile

El centro multimedia se gestiona de forma completamente declarativa mediante `just`:

```bash
# Configuración inicial desatendida del centro multimedia completo
just setup-tv

# Diagnóstico integral del sistema, VA-API, audio HDMI, NAS y aplicaciones
just status

# --- Aplicaciones y Streaming ---
just kodi              # Iniciar Kodi Media Center con VA-API Haswell y PipeWire
just stremio           # Iniciar Stremio
just vlc               # Iniciar VLC
just tv-webapps        # Instalar / actualizar lanzadores WebApp e iconos SVG
just tv-dock           # Configurar la barra de favoritos (Dock) de GNOME Shell para TV

# --- Almacenamiento NAS y Red ---
just nas-setup         # Configurar clientes SMB/NFS, Avahi y carpetas /mnt/nas
just nas-status        # Verificar estado de conexión y montaje del NAS

# --- Audio TV y Navegador ---
just audio             # Aplicar quantum y normalización de audio HDMI para Sony TV
just audio-status      # Diagnóstico PipeWire / WirePlumber
just chrome            # Instalar y optimizar Google Chrome para Wayland y VA-API

# --- Sistema y Mantenimiento ---
just tuning-status     # Ver métricas de ZRAM, Sysctl y planificador
just security-status   # Ver estado de Firewalld (puertos NAS, Samba, SSH)
just update            # Actualizar sistema completo (Pacman, AUR y Flatpak)
just clean             # Limpiar cachés de paquetes y runtimes de Flatpak huérfanos
```

---

## 📂 Estructura de Directorios

```text
CachyOS-TV/
├── .agents/                    # Perfiles de IA y skills especializadas
│   ├── AGENTS.md               # Directivas técnicas para HP Z230 SFF y CachyOS TV
│   └── skills/
│       └── cachyos-tv-multimedia/ # Skill para Kodi NAS, Stremio, Chrome y VA-API
├── Bash.Setup/                 # Configuración de terminal, aliases y entorno
│   ├── aliases.sh              # Atajos de terminal (cachy, kodi, stremio, nas)
│   └── environment.sh          # Variables de entorno VA-API y Wayland
├── Setup/                      # Scripts modulares de aprovisionamiento
│   ├── chrome.sh               # Instalador y optimizador de Google Chrome
│   ├── tv-streaming.sh         # Generador de WebApps e iconos SVG para Dock
│   ├── nas-setup.sh            # Integrador de almacenamiento NAS para Kodi
│   ├── multimedia.sh           # Suite de codecs, reproductores y audio TV HDMI
│   ├── post-install-intel.sh   # Post-instalación Haswell, VA-API i965 y ZRAM
│   ├── flatpak.sh              # Gestor de Flatpaks y overrides de hardware
│   ├── gnome-settings.sh       # Modo salón HTPC, tema oscuro y escala visual
│   ├── cachyos-tuning.sh       # Rendimiento de kernel sysctl y límites
│   ├── seguridad.sh            # Cortafuegos Firewalld exclusivo (Samba, NFS, mDNS)
│   └── icons/                  # Iconos vectoriales SVG para plataformas de streaming
│       ├── netflix.svg
│       ├── prime-video.svg
│       ├── rtve-play.svg
│       ├── pluto-tv.svg
│       ├── youtube.svg
│       └── orange-tv.svg
└── justfile                    # Orquestador de tareas declarativas
```

---

## 🛡️ Seguridad y Reglas de Red

- **Firewalld Obligatorio:** Todos los puertos se gestionan mediante `firewall-cmd` en la zona `home`.
- **Servicios Habilitados:** `samba-client`, `nfs`, `mdns` (Avahi), `ssh` y `kdeconnect` (GSConnect para usar el móvil como mando).
- **Prohibido:** `ufw` y reglas crudas de `iptables`.

---

## 🚀 Puesta en Marcha en el HP Z230 SFF

1. Clona el monorepo en el equipo HP Z230 SFF con CachyOS instalado:
   ```bash
   git clone -b feature/CachyOS-TV https://github.com/scaballeroq/Linux.git ~/Proyectos/Linux
   cd ~/Proyectos/Linux/CachyOS-TV
   ```
2. Ejecuta el aprovisionamiento completo:
   ```bash
   just setup-tv
   ```
3. Reinicia el equipo:
   ```bash
   sudo reboot
   ```
4. ¡Disfruta de tu centro multimedia CachyOS TV en tu televisor Sony!
