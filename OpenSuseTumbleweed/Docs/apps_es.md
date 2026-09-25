---
sidebar_position: 9
---

# Aplicaciones y Juegos en openSUSE Tumbleweed (KDE Plasma 6)

Esta guía detalla la suite de aplicaciones de escritorio, herramientas visuales y plataformas de juegos configuradas en las carpetas `Setup` y `Juegos`.

---

## 1. Suite Nativa de KDE Plasma 6

openSUSE Tumbleweed incorpora la suite completa de KDE Gear y aplicaciones de KDE Plasma 6:

- **Dolphin**: Administrador de archivos rápido con vista de detalles por defecto y menús contextuales KIO para Kitty y Google Antigravity.
- **Kate & KWrite**: Editores de texto avanzados con resaltado de sintaxis y terminal integrada.
- **Spectacle**: Captura de pantalla y grabación de región en Wayland (atajo `Print Screen` o comando `captura`).
- **Okular**: Visor universal de documentos (PDF, ePub, Markdown).
- **Gwenview**: Visor de imágenes optimizado.
- **Ark**: Gestor de archivos comprimidos con soporte multi-formato (`tar`, `zip`, `7z`, `rar`).
- **KCalc**: Calculadora de precisión científica.
- **Discover**: Tienda de software integrada con backend Flathub activado.

---

## 2. Navegador Google Chrome (`chrome.sh`)

Instala la versión oficial estable de Google Chrome con repositorio firmado por Google:

```bash
just chrome
# o ./Setup/chrome.sh
```

Diagnóstico del repositorio y binario:
```bash
./Setup/chrome.sh --status
```

---

## 3. Steam, Rendimiento y Juegos (`steam.sh`)

Configura la estación de juegos nativa con aceleración por hardware:

- **Steam nativo**: Paquete oficial con dependencias de 32 bits (`libvulkan_radeon-32bit`, `Mesa-dri-32bit`).
- **Optimizadores de rendimiento**: GameMode (`gamemoderun`) y MangoHud para monitorización en tiempo real de FPS, temperaturas y uso de GPU.
- **Proton-GE**: Capa de compatibilidad GloriousEggroll para ejecutar videojuegos de Windows con máxima fluidez.

```bash
just steam
# o ./Setup/steam.sh
```

---

## 4. Centro Multimedia Kodi (`kodi`)

Transforma el equipo en un Media Center de alta fidelidad:

- Paquete oficial `kodi` con aceleración VA-API.
- Complementos de streaming: `kodi-inputstream-adaptive`, `kodi-inputstream-rtmp`, `kodi-pvr-iptvsimple`.

```bash
just kodi
```

---

## 5. Meld: Comparación Visual de Archivos y Git Diff

Herramienta gráfica para resolución de conflictos en Git y comparación de directorios:

```bash
sudo zypper --non-interactive install -y meld
```

---

## 6. Aplicaciones Desacopladas vía Flatpak (`flatpak.sh`)

Para mantener el sistema base de openSUSE Tumbleweed 100% puro contra los repositorios oficiales y evitar cualquier conflicto o rotura con `zypper dup`, las aplicaciones multimedia y herramientas de escritorio se ejecutan sobre runtimes estándar de **Flathub**:

- **Gestión y Contenedores**:
  - `Flatseal` (`com.github.tchx84.Flatseal`): Control gráfico granular de permisos del sandbox (carpetas, sockets Wayland, red, dispositivos).
  - `Podman Desktop` (`io.podman_desktop.PodmanDesktop`): Panel visual completo para gestionar contenedores, imágenes, pods y servicios Quadlet de Podman Rootless.
  - `Warehouse` (`io.github.flattool.Warehouse`): Mantenimiento de Flatpaks, visualizador de propiedades y limpiador de restos/datos huérfanos.
- **Multimedia y Creación (con códecs completos y VA-API)**:
  - `VLC Media Player` (`org.videolan.VLC`): Reproductor universal desacoplado.
  - `Celluloid` (`io.github.celluloid_player.Celluloid`): Reproductor basado en MPV acelerado por hardware con GPU AMD Radeon Vega 7.
  - `OBS Studio` (`com.obsproject.Studio`): Grabación y streaming con soporte PipeWire/Wayland nativo.
  - `Kdenlive` (`org.kde.kdenlive`): Editor de vídeo profesional no lineal con códecs completos integrados.
  - `Kodi` (`tv.kodi.Kodi`): Centro multimedia avanzado para streaming y reproducción en alta definición.
  - `Stremio` (`com.stremio.Stremio`): Centro y agregador de contenidos multimedia y streaming.
  - `Spotify` (`com.spotify.Client`): Reproductor oficial de música en streaming.
  - `Audacity` (`org.audacityteam.Audacity`): Editor y grabador de audio profesional multi-pista.
- **Desarrollo y Bases de Datos**:
  - `Bruno` (`com.usebruno.Bruno`): Cliente API REST y GraphQL ligero, offline y versionable en Git (sustituto libre de Postman).
  - `DBeaver Community` (`io.dbeaver.DBeaverCommunity`): Gestor universal de bases de datos para desarrollo local y contenedores Podman.
- **Productividad, Notas y Copias de Seguridad**:
  - `Obsidian` (`md.obsidian.Obsidian`): Bóveda de conocimiento y notas interconectadas en Markdown local.
  - `LocalSend` (`org.localsend.localsend_app`): Envío seguro y ultrarrápido de archivos en red local entre Linux, Android e iOS.
  - `Pika Backup` (`org.gnome.World.PikaBackup`): Copias de seguridad incrementales, deduplicadas y cifradas con BorgBackup.
- **Diseño y Creatividad**:
  - `GIMP` (`org.gimp.GIMP`): Editor avanzado de imágenes y retoque fotográfico con runtimes gráficos aislados.
  - `Inkscape` (`org.inkscape.Inkscape`): Editor profesional de gráficos vectoriales SVG.
- **Comunicación y Gaming**:
  - `Vesktop` (`dev.vencord.Vesktop`): Discord optimizado para Wayland con screen sharing funcional por PipeWire.
  - `Telegram Desktop` (`org.telegram.desktop`): Mensajería rápida y segura en sandbox.
  - `Proton-GE` (`com.valvesoftware.Steam.CompatibilityTool.Proton-GE`): Capa de compatibilidad para videojuegos en Steam.

### Uso y Comandos:

```bash
# Diagnóstico del estado de repositorios y aplicaciones instaladas
just flatpak-status
# o ./flatpak --status

# Instalación modular por perfiles
./flatpak --essential   # Flatseal, Podman Desktop, Warehouse
./flatpak --multimedia  # VLC, Celluloid, OBS Studio, Kdenlive, Kodi, Stremio...
./flatpak --dev         # Bruno, DBeaver Community
./flatpak --productivity # Obsidian, LocalSend, Pika Backup
./flatpak --graphics    # GIMP, Inkscape
./flatpak --comms       # Vesktop, Telegram
./flatpak --all         # Todo el catálogo disponible

# Instalar aplicaciones individuales por alias o ID
./flatpak install bruno
./flatpak install dbeaver
./flatpak install obsidian
./flatpak install localsend
./flatpak install gimp

# Mantenimiento del entorno Flatpak
just flatpak-update     # Actualizar aplicaciones y runtimes
just flatpak-clean      # Limpiar runtimes huérfanos sin usar
```

---

## Verificación

- **KDE Plasma**: Lanza las aplicaciones desde el menú de inicio (Kicker/Kickoff) o mediante KRunner (`Alt+Space`).
- **Chrome**: Ejecuta `google-chrome` o compruébalo con `./Setup/chrome.sh --status`.
- **Flatpak**: Verifica el estado con `just flatpak-status` o inspecciona permisos con `Flatseal`.
- **Steam**: Abre Steam, ve a *Parámetros > Compatibilidad* y verifica la habilitación de Steam Play / Proton.
