---
sidebar_position: 3
---

# Guía de Dank Material Shell (DMS) y Niri Compositor

Esta guía proporciona una referencia detallada sobre la arquitectura, utilidades de línea de comandos, comandos IPC y atajos de teclado para la integración de **Dank Material Shell (DMS)** y el compositor scrollable-tiling **Niri** en **CachyOS**.

---

## 1. Arquitectura de Dank Material Shell

Dank Material Shell es una shell de escritorio avanzada desarrollada sobre **Quickshell** que implementa los principios de diseño de **Material Design 3 (Material You)**.

### Componentes Clave:
- **`dms-shell`**: Paquete principal que contiene la interfaz de usuario reactiva en QML/Quickshell.
- **`dms` (CLI & Backend)**: Binario de gestión ubicado en `/usr/bin/dms` que ofrece:
  - Servidor de backend y bus de comunicación IPC.
  - Generador de temas Material You (`dms matugen`).
  - Herramienta de capturas de pantalla (`dms screenshot` o `dms ipc call niri screenshot`).
  - Gestor de portapapeles, atajos, fondos de pantalla y respaldos (`dms backup`).
- **`dms.service`**: Servicio de usuario en systemd (`systemctl --user status dms.service`).
- **`dankcalendar` (`dcal`)**: Calendario integrado con soporte local, Google Calendar y CalDAV.
- **`danksearch`**: Buscador ultrarrápido indexado para lanzar aplicaciones y abrir documentos.

---

## 2. Comandos CLI e IPC de DMS

Puedes invocar y controlar cualquier panel o función de DMS desde la terminal o desde atajos de Niri mediante `dms ipc call <target> <function>`:

| Objetivo | Función | Descripción | Alias en Shell |
| :--- | :--- | :--- | :--- |
| `launcher` | `toggle` | Abre o cierra el lanzador de aplicaciones | `dms-launcher` |
| `control-center` | `toggle` | Abre o cierra el panel de control y ajustes rápidos | `dms-control` |
| `clipboard` | `toggle` | Muestra el gestor de portapapeles con vista previa | `dms-clipboard` |
| `settings` | `toggle` | Abre la ventana de configuración de DMS | `dms-settings` |
| `theme` | `toggle` | Alterna entre tema claro y oscuro | `dms-theme-toggle` |
| `powermenu` | `toggle` | Muestra el menú de apagado, reinicio y suspensión | `dms-powermenu` |
| `lock` | `lock` | Bloquea la sesión actual | `dms-lock` |
| `keybinds` | `toggle` | Muestra la chuleta gráfica de atajos de teclado | `dms-keybinds` |
| `notifications` | `toggle` | Abre o cierra el panel de notificaciones | `dms-notifications` |
| `audio` | `increment` / `decrement` / `mute` | Control de volumen de audio PipeWire | `dms-volup` / `dms-voldown` / `dms-mute` |
| `wallpaper` | `set <ruta>` | Aplica un nuevo fondo y regenera los colores | `dms-set-wallpaper <img.jpg>` |

### Diagnóstico del Sistema
Para auditar la instalación y detectar dependencias faltantes:
```bash
dms doctor
# o mediante alias
dms-doc
```

---

## 3. Integración con Niri Compositor

Niri organiza las ventanas en una cinta horizontal infinita ("scrollable tiling"). La configuración se estructura modularmente en `~/.config/niri/`:

- `config.kdl`: Archivo maestro donde se definen monitores, reglas de ventana, atajos y animaciones.
- `dms/`: Directorio gestionado por DMS que contiene:
  - `binds.kdl`: Atajos de teclado que invocan comandos `dms ipc`.
  - `colors.kdl`: Colores de bordes y sombras sincronizados por Matugen.
  - `layout.kdl`: Gaps, márgenes y alineación de columnas.
  - `alttab.kdl`: Selector de ventanas Alt+Tab.
  - `outputs.kdl`: Perfiles de monitores y resoluciones.

### Comandos de Control de Niri:
```bash
niri-reload       # Recarga la configuración en caliente
niri-validate     # Valida la sintaxis de config.kdl
niri-windows      # Lista las ventanas activas y sus workspaces
niri-focused      # Muestra información de la ventana en foco
niri-outputs      # Muestra los monitores detectados
```

---

## 4. Tematización Dinámica con Matugen

DMS utiliza **Matugen** para extraer una paleta armónica de colores Material You a partir de la imagen de fondo:
- Los colores se exportan a `~/.config/kitty/dank-theme.conf` y `~/.config/kitty/dank-tabs.conf`.
- Se generan hojas de estilo GTK en `~/.config/gtk-3.0/dank-colors.css` y `~/.config/gtk-4.0/dank-colors.css`.
- Niri actualiza sus bordes activos e inactivos mediante `dms/colors.kdl`.

Para forzar la regeneración manual de temas:
```bash
dms matugen generate
```
