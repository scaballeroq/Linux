# Configuración de Monitores y Escritorios en Omarchy (Arch Linux + Hyprland)

Este documento detalla la configuración y el funcionamiento para desplegar un entorno multimonitor con asignación exclusiva de espacios de trabajo (*workspaces*) en **Omarchy** (distribución Arch Linux con Hyprland).

---

## 1. Esquema y Disposición de las Pantallas

La distribución física deseada y sus coordenadas en el espacio virtual de Hyprland es la siguiente:

```text
               +---------------------------+  +---------------------------+
               |      LG 32" (DP-3)        |  |      SONY 32" (DP-4)      |
               |       (Principal)         |  |                           |
               |      1920x1080 @ 60Hz     |  |      1920x1080 @ 60Hz     |
               |      Posición: 0x0        |  |      Posición: 1920x0     |
               |   [ Escritorios: 1..5 ]   |  |   [ Escritorios: 6 y 7 ]  |
               +---------------------------+  +---------------------------+
               |    PORTÁTIL 15.6" (eDP-1) |
               |      1920x1080 @ 60Hz     |
               |      Posición: 0x1080     |
               |   [ Escritorios: 8 y 9 ]  |
               +---------------------------+
```

### Tabla de Monitores y Asignaciones

| Monitor | Conector | Tamaño / Resolución | Posición (X, Y) | Escritorios Asignados |
| :--- | :--- | :--- | :--- | :--- |
| **LG 32"** *(Principal)* | `DP-3` | 1920x1080 @ 60Hz | `0x0` | `1`, `2`, `3`, `4`, `5` |
| **Sony 32"** *(Derecha)* | `DP-4` | 1920x1080 @ 60Hz | `1920x0` | `6`, `7` |
| **Portátil 15.6"** *(Debajo)* | `eDP-1` | 1920x1080 @ 60Hz | `0x1080` | `8`, `9` |

---

## 2. Cálculo de Coordenadas

Hyprland posiciona los monitores en una rejilla cartesiana 2D `(X, Y)`:

1. **Pantalla Principal (LG 32" - `DP-3`):**
   - Se sitúa en el origen: `position = "0x0"`.
   - Ocupa desde `X = 0` hasta `X = 1920` y desde `Y = 0` hasta `Y = 1080`.

2. **Pantalla Derecha (Sony 32" - `DP-4`):**
   - Comienza justo donde termina la pantalla LG horizontalmente (`X = 1920`) y al mismo nivel vertical (`Y = 0`): `position = "1920x0"`.

3. **Pantalla Inferior (Portátil 15.6" - `eDP-1`):**
   - Comienza en el mismo origen horizontal que la LG (`X = 0`) y justo donde termina verticalmente la pantalla LG (`Y = 1080`): `position = "0x1080"`.

---

## 3. Configuración en Hyprland (`~/.config/hypr/monitors.lua`)

Omarchy utiliza módulos en **Lua** para configurar Hyprland.

Edita el archivo:
```bash
~/.config/hypr/monitors.lua
```

Añade la siguiente configuración:

```lua
-- ~/.config/hypr/monitors.lua
-- Configuración de monitores y asignación de escritorios para Omarchy

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

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

-- Portátil 15.6" FHD (Debajo de LG)
hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60",
  position = "0x1080",
  scale = omarchy_monitor_scale,
})

-- Fallback genérico para pantallas desconectadas/adicionales
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- =============================================================================
-- 2. REGLAS DE ESCRITORIOS (WORKSPACES)
-- =============================================================================

-- LG 32" (DP-3) -> Escritorios 1, 2, 3, 4 y 5
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-3", persistent = true })

-- Sony 32" (DP-4) -> Escritorios 6 y 7
hl.workspace_rule({ workspace = "6", monitor = "DP-4", default = true, persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "DP-4", persistent = true })

-- Portátil 15.6" (eDP-1) -> Escritorios 8 y 9
hl.workspace_rule({ workspace = "8", monitor = "eDP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1", persistent = true })
```

### Explicación de los parámetros:
- `default = true`: Indica cuál es el escritorio visible por defecto en ese monitor al iniciar sesión o enfocar la pantalla.
- `persistent = true`: Asegura que el escritorio siempre exista y quede fijado a ese monitor, evitando que desaparezca si no tiene ventanas activas.

---

## 4. Filtrado de Escritorios en la Barra de Omarchy (`omarchy-shell`)

Por defecto, el widget de escritorios de Omarchy (`omarchy.workspaces`) lista los escritorios genéricos (1 a 5 y activos) en todas las pantallas. Para lograr que **en cada pantalla solo aparezcan sus escritorios correspondientes**, se debe crear una copia de usuario del plugin.

### Paso 1: Clonar el plugin de workspaces
Ejecuta en tu terminal:
```bash
omarchy plugin clone omarchy.workspaces
```
Esto creará el plugin personalizado en:
`~/.config/omarchy/plugins/<tu_usuario>.workspaces/` (por ejemplo `caballero.workspaces/`).

### Paso 2: Modificar el archivo QML
Abre el archivo:
```bash
nano ~/.config/omarchy/plugins/caballero.workspaces/Workspaces.qml
```

Busca la función `workspaceIds()` (alrededor de la línea 14) y sustitúyela por:

```qml
  function currentScreenName() {
    var win = root.QsWindow ? root.QsWindow.window : null
    return (win && win.screen && win.screen.name) ? win.screen.name : ""
  }

  function workspaceIds() {
    var screen = currentScreenName()

    if (screen === "DP-3") {
      return [1, 2, 3, 4, 5]
    } else if (screen === "DP-4") {
      return [6, 7]
    } else if (screen === "eDP-1") {
      return [8, 9]
    }

    return [1, 2, 3, 4, 5]
  }
```

Al guardar el archivo, la barra de Omarchy se recargará automáticamente.

---

## 5. Recarga y Verificación

Para aplicar los cambios y comprobar que no hay errores de sintaxis:

1. **Recargar configuración de Hyprland:**
   ```bash
   hyprctl reload
   ```

2. **Comprobar si existen errores:**
   ```bash
   hyprctl configerrors
   ```
   *(Si no produce ninguna salida, la configuración es correcta).*

3. **Reiniciar la barra de Omarchy:**
   ```bash
   omarchy restart shell
   ```

4. **Verificar estado de los monitores activos:**
   ```bash
   hyprctl monitors
   ```

---

## 6. Atajos de Teclado Útiles

| Atajo | Acción |
| :--- | :--- |
| `Super + [1 - 5]` | Cambiar a los escritorios 1 al 5 (enfoca pantalla LG). |
| `Super + [6 - 7]` | Cambiar a los escritorios 6 y 7 (enfoca pantalla Sony). |
| `Super + [8 - 9]` | Cambiar a los escritorios 8 y 9 (enfoca pantalla Portátil). |
| `Super + Shift + [1 - 9]` | Mover la ventana activa al escritorio especificado. |
| `Super + Shift + Alt + [Flechas]` | Mover el workspace completo al monitor adyacente (Izquierda, Derecha, Arriba, Abajo). |
