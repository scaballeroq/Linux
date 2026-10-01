---
name: debian-testing-kde-control
description: >-
  Use this skill when managing KDE Plasma 6 desktop environment, KWin window manager, multi-monitor configuration via KScreen (DP-3, DP-4, eDP-1), Plasma themes/colorschemes, Night Color, Dolphin file manager integration, Spectacle screenshots, PipeWire audio, and Wayland desktop integration on Debian Testing.
---

# KDE Plasma 6 & KWin Control Skill (Debian Testing)

Esta skill proporciona los comandos, utilidades CLI y directrices para inspeccionar, configurar y gestionar el entorno de escritorio **KDE Plasma 6** y el compositor de ventanas **KWin** sobre **Wayland** nativo en Debian Testing.

---

## 1. Gestión de Monitores y Salidas (Triple Monitor 1080p con KScreen)

La estación de trabajo cuenta con una topología multi-monitor de tres salidas Full HD (1920x1080):
1. **DP-3 (Principal / Trabajo)**: Salida DisplayPort a 1920x1080 @ 60Hz (Posición `0,0`, Prioridad 1).
2. **DP-4 (Secundaria / Lateral)**: Salida DisplayPort a 1920x1080 @ 60Hz (Posición `1920,0`, Prioridad 3).
3. **eDP-1 (Pantalla Integrada Portátil)**: Pantalla interna 15.6" HP EliteBook a 1920x1080 @ 60Hz (Posición `0,1080`, Prioridad 2).

### Consultas y Control de Pantallas con `kscreen-doctor`:
```bash
# Diagnóstico completo de salidas, resoluciones activas y coordenadas
kscreen-doctor -o

# Abrir el módulo gráfico de configuración de pantallas en Preferencias del Sistema
kcmshell6 kcm_kscreen &

# Activar o desactivar una salida específica
kscreen-doctor output.DP-3.enable
kscreen-doctor output.eDP-1.disable

# Establecer modo de resolución y refresco
kscreen-doctor output.DP-3.mode.1920x1080@60 output.DP-3.position.0,0
```

---

## 2. Gestión de Temas, Apariencia y Modo Oscuro

KDE Plasma 6 incluye utilidades CLI oficiales para alternar el estilo visual sin necesidad de reiniciar la sesión:

```bash
# Aplicar tema global oscuro Breeze Dark
plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || \
plasma-apply-colorscheme BreezeDark

# Aplicar tema global claro Breeze Light
plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || \
plasma-apply-colorscheme BreezeLight

# Configurar cursor e iconos
plasma-apply-cursortheme breeze_cursors
kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus-Dark"

# Tipografía de ancho fijo para programación (JetBrainsMono Nerd Font)
kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"

# Notificar a KWin para recargar la decoración y colores
qdbus org.kde.KWin /KWin reconfigure
```

---

## 3. Decoración de Ventanas y Luz Nocturna (Night Color)

```bash
# Disposición de botones de ventana (IAX: Minimizar, Maximizar, Cerrar a la derecha)
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX"
qdbus org.kde.KWin /KWin reconfigure

# Activar Luz Nocturna (temperatura cálida 4000K para descanso visual)
kwriteconfig6 --file kwinrc --group NightColor --key Active true
kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature 4000
qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive true 2>/dev/null || true
qdbus org.kde.KWin /KWin reconfigure

# Desactivar Luz Nocturna
kwriteconfig6 --file kwinrc --group NightColor --key Active false
qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive false 2>/dev/null || true
qdbus org.kde.KWin /KWin reconfigure
```

---

## 4. Dolphin (Gestor de Archivos) y KIO Servicemenus

Dolphin implementa acciones en el menú contextual mediante archivos `.desktop` en el directorio de usuario `~/.local/share/kio/servicemenus/`:

- **Abrir en Kitty**: `~/.local/share/kio/servicemenus/open-in-kitty.desktop`
- **Abrir con Antigravity**: `~/.local/share/kio/servicemenus/open-in-antigravity.desktop`
- **Abrir con Antigravity IDE**: `~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`

### Preferencias de visualización:
```bash
# Establecer vista detallada (lista con detalles) por defecto
kwriteconfig6 --file dolphinrc --group "General" --key "ViewMode" 1

# Ocultar o mostrar archivos ocultos en Dolphin
kwriteconfig6 --file dolphinrc --group "General" --key "ShowHiddenFiles" true
```

---

## 5. Terminal Kitty y Atajos Globales de Teclado

```bash
# Definir Kitty como emulador de terminal predeterminado del sistema en KDE
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty"
kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop"

# Configurar atajo global Ctrl+Alt+T para lanzar Kitty Terminal en Plasma 6
kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,none,Kitty Terminal"
```

---

## 6. Capturas de Pantalla y Portapapeles (Wayland Nativo)

```bash
# Captura interactiva de pantalla completa o selector
spectacle &

# Captura de región rectangular interactiva
spectacle -r &

# Captura de la ventana activa directamente al portapapeles
spectacle -a -c &

# Copiar contenido al portapapeles Wayland (mediante wl-clipboard)
wl-copy < archivo.txt
echo "Texto" | wl-copy

# Pegar contenido desde el portapapeles Wayland
wl-paste
```

---

## 7. Control de Audio (PipeWire & WirePlumber)

KDE Plasma 6 integra el control de audio directamente con el servidor PipeWire mediante WirePlumber:

```bash
# Estado general de dispositivos de reproducción y captura
wpctl status

# Subir / bajar volumen de la salida de audio predeterminada
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-

# Silenciar / alternar mute en salida y micrófono
wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
```

---

## 8. Gestión de Energía y Cierre de Tapa (Laptop HP EliteBook)

Evitar que el portátil se suspenda al cerrar la tapa cuando hay monitores externos conectados:

```bash
# Configurar comportamiento en corriente alterna (AC): No suspender si hay pantallas externas
kwriteconfig6 --file powermanagementprofilesrc --group "AC" --group "LidAction" --key "LidAction" 0
kwriteconfig6 --file powermanagementprofilesrc --group "AC" --group "LidAction" --key "StopWhenExternalMonitorConnected" true

# Seleccionar perfil de rendimiento con power-profiles-daemon
powerprofilesctl set performance   # Modo alto rendimiento
powerprofilesctl set balanced      # Modo equilibrado
powerprofilesctl set power-saver   # Modo ahorro de batería
```

---

## 9. Diagnóstico de Sesión y Servicios de Plasma 6

```bash
# Verificar variables de sesión gráfica Wayland
echo "Sesión: $XDG_SESSION_TYPE | Escritorio: $XDG_CURRENT_DESKTOP"

# Versión de componentes centrales de KDE Plasma 6
plasmashell --version 2>/dev/null
kwin_wayland --version 2>/dev/null

# Reiniciar el shell de Plasma limpiamente sin cerrar la sesión de usuario
systemctl --user restart plasma-plasmashell.service

# Inspeccionar logs de fallos o eventos recientes de KWin y Plasma
journalctl --user -u plasma-plasmashell.service -n 50 --no-pager
journalctl --user -u plasma-kwin_wayland.service -n 50 --no-pager
```
