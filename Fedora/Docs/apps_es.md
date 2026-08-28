---
sidebar_position: 9
---

# Aplicaciones y Herramientas de Escritorio en Fedora 44 (KDE Plasma 6)

Esta guía detalla las principales aplicaciones y herramientas de usuario integradas en el entorno **Fedora 44 Workstation** con **KDE Plasma 6**.

---

## 1. Aplicaciones del Ecosistema KDE Plasma

El sistema incluye las herramientas nativas y optimizadas de KDE:
- **Dolphin**: Gestor de archivos de alto rendimiento con integración de terminal Kitty (*Abrir en Kitty*), previsualizaciones multimedia e integración de Git.
- **Kate / KWrite**: Editores de texto avanzados con resaltado de sintaxis y soporte de proyectos.
- **Spectacle**: Utilidad de captura y grabación de pantalla para Wayland, vinculada a los atajos de consola `captura` y `grabacion`.
- **Ark**: Gestor visual de compresión y descompresión de archivos (soporte para 7z, tar, zip, rar, zstd).
- **Plasma System Monitor**: Monitor de recursos y procesos por GPU, CPU y memoria RAM.
- **KCalc**: Calculadora científica y de programador.

---

## 2. Centro Multimedia y Streaming (`kodi`)

Para equipos de sobremesa dedicados a centro de ocio multimedia y streaming:
- **Kodi**: Plataforma multimedia con aceleración por hardware VA-API.
- **Complementos**: `kodi-inputstream-adaptive` (reproducción DRM para streaming), `kodi-inputstream-rtmp` e `kodi-pvr-iptvsimple`.

Instalación rápida:
```bash
just kodi
# o sudo dnf5 install -y kodi kodi-inputstream-adaptive kodi-inputstream-rtmp kodi-pvr-iptvsimple
```

---

## 3. Comparación Visual y Resolución de Conflictos (`meld`)

Meld es una herramienta gráfica para comparar y fusionar diferencias entre archivos, directorios y repositorios de Git:

```bash
sudo dnf5 install -y meld
```

---

## 4. Paquetes Universales (Flatpak y Flathub)

El sistema viene preconfigurado con el repositorio global de **Flathub**, permitiendo instalar aplicaciones de terceros y videojuegos en entornos aislados (sandbox):

```bash
# Buscar aplicaciones en Flathub:
flatpak search <nombre>

# Instalar aplicación:
flatpak install flathub <id_aplicacion>
```
