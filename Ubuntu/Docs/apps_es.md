---
sidebar_position: 9
---

# Aplicaciones y Juegos en Debian 13

Esta guía detalla la instalación de software y herramientas de escritorio, así como plataformas de ocio digital descritas en las carpetas `Apps` y `Juegos`.

El ecosistema de Debian 13 (Trixie) permite instalar tanto herramientas visuales del sistema mediante gestores de paquetes tradicionales (APT) como software de ocio de forma aislada a través de formatos universales (Flatpak).

---

## 1. Meld: Comparación Visual de Archivos (`meld.sh`)

Meld es una herramienta gráfica para comparar y fusionar diferencias entre archivos, directorios y repositorios de control de versiones. Es ideal para resolver conflictos de mezcla en Git.

* **Instalación**:
  ```bash
  sudo apt update
  sudo apt install -y meld
  ```

---

## 2. Steam: Plataforma de Juegos y Compatibilidad (`steam.sh`)

Para garantizar que el sistema mantenga su estabilidad sin mezclar librerías de 32 bits (i386) a nivel de sistema APT, la instalación de Steam se realiza en formato aislado mediante Flatpak/Flathub.

1. **Instalación de Steam**:
   ```bash
   flatpak install flathub com.valvesoftware.Steam
   ```

2. **Capa de Compatibilidad (Proton-GE)**:
   Se instala **Proton GloriousEggroll (Proton-GE)** para mejorar la compatibilidad, velocidad y estabilidad de videojuegos de Windows sobre sistemas Linux:
   ```bash
   flatpak install flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
   ```

---

## Verificación

Para comprobar que las herramientas se han instalado correctamente:

- **Meld**: Ejecuta `meld` en consola o ábrelo desde tu lanzador de aplicaciones del escritorio.
- **Steam**: Lanza Steam desde el menú de aplicaciones de tu escritorio GNOME. Al iniciar sesión, puedes habilitar Proton-GE en los ajustes de compatibilidad de Steam (Steam > Parámetros > Compatibilidad > Habilitar Steam Play).
