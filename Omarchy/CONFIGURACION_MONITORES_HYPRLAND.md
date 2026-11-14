# Configuración de Monitores y Escritorios en Omarchy 4.5 (Arch Linux + Hyprland)

Este documento detalla la arquitectura, posicionamiento multi-monitor, asignación de escritorios (*workspaces*) y las nuevas funciones de **Omarchy 4.5 ("Quattro RS")** para el portátil **HP ProBook 455 G10** (AMD Ryzen 7 7730U + Radeon Graphics Vega 8).

---

## 1. Esquema Físico y Coordenadas del Entorno Triple Pantalla

La estación de trabajo opera con una topología de tres pantallas Full HD 1080p a 60Hz:

```text
               +---------------------------+  +---------------------------+
               |      LG 32" (DP-3)        |  |      SONY 32" (DP-4)      |
               |        (Principal)        |  |        (Secundaria)       |
               |      1920x1080 @ 60Hz     |  |      1920x1080 @ 60Hz     |
               |      Posición: 0,0        |  |      Posición: 1920,0     |
               |   [ Workspaces: 1..4 ]    |  |   [ Workspaces: 5..7 ]    |
               +---------------------------+  +---------------------------+
               |    PORTÁTIL 15.6" (eDP-1) |
               |      1920x1080 @ 60Hz     |
               |      Posición: 0,1080     |
               |   [ Workspaces: 8 y 9 ]   |
               +---------------------------+
```

### Tabla de Monitores y Asignación de Workspaces

| Monitor | Conector | Resolución / Refresco | Posición `(X, Y)` | Workspaces Asignados | Rol Principal |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LG 32"** | `DP-3` | 1920x1080 @ 60Hz | `0x0` (`0,0`) | `1`, `2`, `3`, `4` | Monitor Principal (Código, IDE, Navegación activa) |
| **Sony 32"** | `DP-4` | 1920x1080 @ 60Hz | `1920x0` (`1920,0`) | `5`, `6`, `7` | Monitor Secundario Lateral (Docs, Chat, Logs) |
| **Portátil 15.6"** | `eDP-1` | 1920x1080 @ 60Hz | `0x1080` (`0,1080`) | `8`, `9` | Pantalla Integrada Inferior (Terminales, Monitorización) |

---

## 2. Novedades y Control de Espacios en Omarchy 4.5 ("Quattro RS")

Omarchy 4.5 introduce un motor híbrido que permite combinar la eficiencia de los compositores tiling con la flexibilidad de los entornos flotantes clásicos:

- **Alternancia de Modo por Workspace (`Super + L`):**
  Puedes alternar instantáneamente cualquier escritorio individual entre **Tiling (mosaico)**, **Scrolling** y **Floating Desktop Mode (modo escritorio flotante)**.
- **Dock Dinámico y Barra de Título en Modo Flotante:**
  Al cambiar un escritorio a modo flotante, las ventanas obtienen barras de título tematizadas y aparece un dock inferior para lanzar o fijar aplicaciones.
- **Minimización de Ventanas (`Super + M`):**
  En modo flotante, minimiza ventanas directamente al dock sin cerrarlas.
- **Lanzador Visual Grid (`Super + Space`):**
  Abre la cuadrícula de aplicaciones visual de Omarchy 4.5 con soporte de búsqueda instantánea.
- **Terminal Desplegable (`Super + ~`):**
  Acceso directo a una consola flotante tipo Quake/Drop-down.

---

## 3. Configuración en Omarchy

Dependiendo de si tu instalación de Omarchy utiliza módulos en **Lua** (`~/.config/hypr/monitors.lua`) o configuración nativa de **Hyprland** (`~/.config/hypr/hyprland.conf`), aplica la opción correspondiente:

### Opción A: Formato Lua (`~/.config/hypr/monitors.lua`)

```lua
-- ~/.config/hypr/monitors.lua
-- Topología Triple Monitor para HP ProBook 455 G10 en Omarchy 4.5

-- Desactivar sobreescritura del panel GUI para respetar estrictamente las coordenadas Lua
omarchy_monitor_panel_settings = false

local omarchy_monitor_scale = 1
local omarchy_gdk_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- =============================================================================
-- 1. POSICIONAMIENTO DE MONITORES
-- =============================================================================

-- LG 32" FHD (Principal)
hl.monitor({
  output = "DP-3",
  mode = "1920x1080@60",
  position = "0x0",
  scale = omarchy_monitor_scale,
})

-- Sony 32" FHD (A la derecha de LG)
hl.monitor({
  output = "DP-4",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = omarchy_monitor_scale,
})

-- Pantalla Integrada Portátil 15.6" FHD (Debajo de LG)
hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60",
  position = "0x1080",
  scale = omarchy_monitor_scale,
})

-- Fallback genérico para proyectores o pantallas externas
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- =============================================================================
-- 2. REGLAS DE WORKSPACES
-- =============================================================================

-- DP-3 (Principal) -> Workspaces 1..4
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-3", persistent = true })

-- DP-4 (Lateral) -> Workspaces 5..7
hl.workspace_rule({ workspace = "5", monitor = "DP-4", default = true, persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "DP-4", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "DP-4", persistent = true })

-- eDP-1 (Portátil) -> Workspaces 8, 9
hl.workspace_rule({ workspace = "8", monitor = "eDP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1", persistent = true })
```

### Opción B: Formato Nativo Hyprland (`~/.config/hypr/hyprland.conf`)

Si tu perfil de Omarchy 4.5 lee directamente la sintaxis estándar de Hyprland:

```ini
# ~/.config/hypr/monitors.conf (o dentro de hyprland.conf)
# -------------------------------------------------------------
# Monitores: name, resolution, position, scale
# -------------------------------------------------------------
monitor = DP-3, 1920x1080@60, 0x0, 1
monitor = DP-4, 1920x1080@60, 1920x0, 1
monitor = eDP-1, 1920x1080@60, 0x1080, 1
monitor = , preferred, auto, 1

# -------------------------------------------------------------
# Asignación Exclusiva de Workspaces
# -------------------------------------------------------------
workspace = 1, monitor:DP-3, default:true, persistent:true
workspace = 2, monitor:DP-3, persistent:true
workspace = 3, monitor:DP-3, persistent:true
workspace = 4, monitor:DP-3, persistent:true
workspace = 5, monitor:DP-3, persistent:true

workspace = 6, monitor:DP-4, default:true, persistent:true
workspace = 7, monitor:DP-4, persistent:true

workspace = 8, monitor:eDP-1, default:true, persistent:true
workspace = 9, monitor:eDP-1, persistent:true
```

---

## 4. Control de Brillo y Teclas del Portátil HP

En el portátil HP ProBook 455 G10, el brillo de la pantalla integrada `eDP-1` se controla mediante `brightnessctl` (instalado en el setup):

```ini
# En tu configuración de atajos de Hyprland (~/.config/hypr/hyprland.conf):
bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Control de volumen de audio PipeWire / WirePlumber:
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

---

## 5. Recarga y Diagnóstico Rápido

Para aplicar y verificar la configuración sin reiniciar:

1. **Recargar Hyprland:**
   ```bash
   hyprctl reload
   ```
2. **Revisar si existen errores de sintaxis:**
   ```bash
   hyprctl configerrors
   ```
3. **Comprobar la lista de pantallas activas y coordenadas:**
   ```bash
   hyprctl monitors
   ```
4. **Reiniciar el shell gráfico de Omarchy (barra y dock):**
   ```bash
   omarchy restart shell
   ```
