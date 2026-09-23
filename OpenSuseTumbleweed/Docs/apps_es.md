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

## Verificación

- **KDE Plasma**: Lanza las aplicaciones desde el menú de inicio (Kicker/Kickoff) o mediante KRunner (`Alt+Space`).
- **Chrome**: Ejecuta `google-chrome` o compruébalo con `./Setup/chrome.sh --status`.
- **Steam**: Abre Steam, ve a *Parámetros > Compatibilidad* y verifica la habilitación de Steam Play / Proton.
