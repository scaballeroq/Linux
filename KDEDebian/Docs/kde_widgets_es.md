---
sidebar_position: 10
---

# Guía Completa de Widgets, Klipper y Personalización de KDE Plasma 6

Esta guía detalla el ecosistema de **Widgets (Plasmoids)**, **KWin Scripts**, **Klipper** y herramientas auxiliares que se configuran de forma automatizada en **KDEDebian** a través del script [`Setup/kde-widgets.sh`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebian/Setup/kde-widgets.sh) y el comando `just widgets`.

KDE Plasma 6 sobre Debian Testing (Trixie) ofrece una arquitectura modular extremadamente potente y eficiente, donde la mayoría de capacidades avanzadas (gestor de portapapeles, monitores de recursos, fondos dinámicos, control de audio por aplicación y mosaico de ventanas) están integradas de manera nativa sin sobrecargar el sistema.

---

## 🛠️ Herramientas de Gestión e Infraestructura

| Herramienta / Módulo | Tipo | Descripción |
| :--- | :--- | :--- |
| **`kdeplasma-addons`** | Paquete APT | Colección oficial de plasmoids, applets y componentes de interfaz adicionales para KDE Plasma. |
| **`plasma-systemmonitor`** | Aplicación Qt6 | Suite moderna de monitorización en tiempo real de CPU, RAM, discos, red y sensores de temperatura. |
| **`kwriteconfig6` / `kwriteconfig5`** | Herramienta CLI | Utilidad oficial de KDE para modificar parámetros de configuración atómicamente en `~/.config/`. |
| **`plasma-apply-colorscheme`** | Herramienta CLI | Aplica esquemas de color (ej. BreezeDark) de forma instantánea a todas las aplicaciones Qt. |

---

## 🧩 Características y Plasmoids Clave de KDE Plasma 6

---

### 1. Gestión de Ventanas y Escritorio (Window & Workspace Management)

#### 🪟 Quick Tile y Mosaico Nativo de Ventanas (KWin Tiling)
* **Atajos**: `Meta + Flechas` (Cuadrantes y mitades) | `Meta + T` (Editor visual de mosaico en Plasma 6)
* **Descripción**: Permite dividir la pantalla en rejillas y encajar ventanas arrastrándolas con modificadores o mediante atajos de teclado sin depender de extensiones externas inestables.
* **Características Clave**:
  - Personalización visual de la cuadrícula pulsando `Meta + T`.
  - Soporte multimonitor independiente y Wayland nativo.
  - Compatibilidad opcional con scripts KWin avanzados (Polonium / Bismuth / Krohnkite).

#### ⚓ Panel Flotante e Icon-Only Task Manager
* **Componente**: `org.kde.plasma.icontasks`
* **Descripción**: Panel de tareas basado en iconos similar a macOS/Windows 11 con previsualización en miniatura al pasar el cursor, insignias de notificaciones y diseño flotante.
* **Características Clave**:
  - Ocultación automática inteligente (Dodge Windows / Auto Hide).
  - Agrupación por aplicación y menú de acciones rápidas al hacer clic derecho.
  - Espaciado y márgenes configurables con bordes redondeados modernos.

#### 🔄 Selector de Ventanas y Overview
* **Atajos**: `Meta + W` (Overview / Visión General) | `Meta + G` (Grid View) | `Alt + Tab` (Task Switcher)
* **Descripción**: Ofrece vistas panorámicas de todos los escritorios virtuales y ventanas abiertas con animaciones fluidas a 60/120 FPS.

---

### 2. Productividad y Flujo de Trabajo (Productivity & Workflow)

#### 📋 Klipper: Gestor de Portapapeles Avanzado
* **Atajo**: `Meta + V` o `Ctrl + Alt + V`
* **Descripción**: El gestor de portapapeles nativo más potente del ecosistema Linux, integrado en la bandeja del sistema.
* **Características Clave**:
  - Historial persistente configurable (hasta cientos de elementos de texto, URLs y fragmentos).
  - Búsqueda instantánea en el historial del portapapeles.
  - Acciones automáticas mediante expresiones regulares (ej. generar código QR, abrir URL en navegador).
  - Sincronización bidireccional segura entre selección y portapapeles.

#### ☕ Inhibición de Suspensión (Caffeine Nativo)
* **Componente**: Applet de Batería y Brillo (`org.kde.plasma.battery`)
* **Descripción**: Permite bloquear manualmente el apagado de pantalla y la suspensión con un solo clic directamente desde el área de estado.
* **Características Clave**:
  - Detección automática al reproducir medios a pantalla completa o ejecutar presentaciones.

#### 🔒 Indicador de Bloqueo de Teclas (Lock Keys)
* **Componente**: `org.kde.plasma.lockkeys`
* **Descripción**: Muestra notificaciones OSD e iconos en la barra de estado cuando Bloq Mayús (Caps Lock) o Bloq Num (Num Lock) están activos.

---

### 3. Monitorización y Sistema (Monitoring & System)

#### 📊 Plasma System Monitor Applets
* **Componentes**: `org.kde.plasma.systemmonitor.*`
* **Descripción**: Monitores individuales o agrupados para la barra de tareas y el escritorio.
* **Características Clave**:
  - Uso de núcleos de CPU, consumo de memoria RAM, velocidades de lectura/escritura en NVMe/SSD y tráfico de red.
  - Apertura con un clic de la herramienta completa `plasma-systemmonitor`.

#### 🔔 Soporte Nativo SNI / AppIndicator
* **Componente**: Bandeja del Sistema de Plasma (`org.kde.plasma.systemtray`)
* **Descripción**: Soporte de primera clase para aplicaciones en segundo plano como Telegram, Steam, Discord, VS Code, Nextcloud o Spotify.

#### 🔊 Mezclador de Audio por Aplicación (Plasma-PA)
* **Componente**: `org.kde.plasma.volume`
* **Descripción**: Control de volumen individual para cada aplicación en ejecución, conmutación instantánea entre altavoces/auriculares/micrófono y soporte PipeWire.

---

### 4. Estética Visual y Fondos Dinámicos

#### 🖼️ Imagen del Día Nativa (Bing / NASA APOD / Unsplash)
* **Componente**: Plugin de Wallpaper nativo de Plasma
* **Descripción**: Sincroniza automáticamente el fondo de pantalla y la pantalla de bloqueo con la imagen diaria en alta resolución (UHD/4K) de Bing, NASA APOD o Unsplash sin requerir scripts en segundo plano.

#### 🧊 Efectos KWin (Desenfoque / Blur y Translucidez)
* **Componente**: Compositor KWin
* **Descripción**: Efecto cristal esmerilado translúcido aplicado en Konsole, paneles, menús contextuales y decoraciones de ventana.

---

## 🚀 Resumen de Comandos

Para aplicar toda la configuración de widgets y entorno gráfico:

```bash
just widgets
# O bien:
./Setup/kde-widgets.sh
```
