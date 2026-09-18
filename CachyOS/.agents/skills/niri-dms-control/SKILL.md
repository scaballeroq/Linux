---
name: niri-dms-control
description: >-
  Use this skill when managing Niri window compositor actions, outputs and monitors (LG 32", Sony TV 32", Laptop), workspace layouts, and Dank Material Shell (DMS) quickshell components.
---

# Niri & Dank Material Shell Control Skill

Esta skill proporciona los comandos y directrices necesarios para inspeccionar y controlar el compositor Wayland Niri y el entorno de escritorio Dank Material Shell (DMS).

## 1. Gestión de Monitores y Salidas (Triple Monitor 1080p)
El sistema dispone de 3 pantallas en resolución 1920x1080:
1. **Pantalla LG 32"** (Principal/Extendida)
2. **TV Sony 32"** (Secundaria/Multimedia)
3. **Pantalla Integrada Portátil 15.6"** (Interna eDP-1)

### Comandos de diagnóstico de pantallas:
```bash
# Consultar todas las salidas detectadas por Niri
niri msg outputs

# Ver resoluciones, modos y tasas de refresco activas
niri msg outputs | grep -E "Output|Mode|Scale"
```

### Configuración en `~/.config/niri/config.kdl`:
Las salidas se configuran en el bloque `output`:
```kdl
output "eDP-1" {
    mode "1920x1080@60.0"
    scale 1.0
    position x=0 y=0
}

output "HDMI-A-1" {
    mode "1920x1080@60.0"
    scale 1.0
    position x=1920 y=0
}
```

---

## 2. IPC de Niri: Acciones de Ventanas y Navegación
Niri utiliza el comando `niri msg action` para interactuar en tiempo real con el compositor:

```bash
# Recargar configuración al vuelo (sin reiniciar sesión)
niri msg action reload-config

# Navegación entre columnas y ventanas
niri msg action focus-column-left
niri msg action focus-column-right
niri msg action focus-window-up
niri msg action focus-window-down

# Organización de la cinta (Scrollable Tiling)
niri msg action consume-window-into-column
niri msg action expel-window-from-column
niri msg action set-column-width "+10%"
niri msg action set-column-width "-10%"

# Maximizar y pantalla completa
niri msg action maximize-column
niri msg action fullscreen-window
```

---

## 3. Dank Material Shell (DMS)
DMS gestiona la barra, dock, centro de control y notificaciones con diseño Material 3.

```bash
# Diagnóstico general del estado de DMS
dms doctor

# Reiniciar el servicio de usuario de DMS
systemctl --user restart dms.service

# Comprobar el estado del servicio
systemctl --user status dms.service

# Aplicar o regenerar paleta de colores dinámica con Matugen
dms theme apply
```
