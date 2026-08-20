---
sidebar_position: 9
---

# Aplicaciones y Juegos en OpenSUSE Tumbleweed

Esta guía detalla la instalación de software, herramientas de escritorio y plataformas de ocio digital descritas en las carpetas `Setup` y `Juegos`.

OpenSUSE Tumbleweed permite instalar tanto herramientas visuales del sistema mediante Zypper como software de ocio de forma nativa o aislada a través de Flatpak.

---

## 1. Meld: Comparación Visual de Archivos

Meld es una herramienta gráfica para comparar y fusionar diferencias entre archivos, directorios y repositorios de control de versiones. Es ideal para resolver conflictos de mezcla en Git.

* **Instalación**:
  ```bash
  sudo zypper install -y meld
  ```

---

## 2. Steam: Plataforma de Juegos y Compatibilidad (`steam.sh`)

Steam puede instalarse de forma nativa mediante Zypper o a través de Flatpak/Flathub con soporte para **Proton-GE**.

1. **Instalación de Steam**:
   ```bash
   just steam
   # o ./Juegos/steam.sh
   ```

2. **Capa de Compatibilidad (Proton-GE)**:
   Se instala **Proton GloriousEggroll (Proton-GE)** para maximizar el rendimiento y compatibilidad de videojuegos sobre Linux.

---

## Verificación

- **Meld**: Ejecuta `meld` en consola o ábrelo desde el menú de aplicaciones.
- **Steam**: Lanza Steam desde GNOME y activa Proton-GE en Parámetros > Compatibilidad.
