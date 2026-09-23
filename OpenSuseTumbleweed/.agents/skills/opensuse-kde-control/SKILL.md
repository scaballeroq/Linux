---
name: opensuse-kde-control
description: >-
  Use this skill when managing KDE Plasma 6 desktop environment, KWin window manager, multi-monitor configuration via KScreen (LG 32", Sony TV 32", Laptop), Plasma themes/colorschemes, Night Color, Dolphin file manager integration, Spectacle screenshots, and Wayland desktop integration on openSUSE Tumbleweed.
---

# KDE Plasma 6 & KWin Control Skill (openSUSE Tumbleweed)

Esta skill proporciona los comandos y directrices para inspeccionar, configurar y gestionar el entorno de escritorio **KDE Plasma 6** y el gestor de ventanas/compositor **KWin** sobre **Wayland** en openSUSE Tumbleweed.

---

## 1. Gestión de Monitores y Salidas (Triple Monitor 1080p con KScreen)

La estación de trabajo cuenta con una topología de tres pantallas Full HD (1920x1080):
1. **Pantalla LG 32"**: Monitor principal / extendido de trabajo.
2. **TV Sony 32"**: Monitor secundario / multimedia.
3. **Pantalla Integrada Portátil 15.6"**: Pantalla del HP EliteBook (eDP-1).

### Consultas y configuración de pantallas:
KDE Plasma gestiona las salidas mediante KScreen y KWin Wayland:

```bash
# Abrir el panel de configuración gráfica de pantallas
systemsettings kcm_kscreen &

# Diagnóstico de salidas mediante kscreen-doctor
kscreen-doctor -o

# Habilitar o cambiar resolución/modo de una salida específica
# kscreen-doctor output.<nombre>.mode.1920x1080@60 output.<nombre>.enable
```

---

## 2. Gestión de Temas, Apariencia y Modo Oscuro

Plasma 6 provee herramientas CLI oficiales para la alternancia instantánea de Look and Feel y combinaciones de color:

```bash
# Aplicar tema global oscuro (Breeze Dark)
plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || \
plasma-apply-colorscheme BreezeDark

# Aplicar tema global claro (Breeze Light)
plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || \
plasma-apply-colorscheme BreezeLight

# Configurar cursor e iconos
plasma-apply-cursortheme breeze_cursors
kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus-Dark"

# Tipografía para programación (JetBrainsMono Nerd Font)
kwriteconfig6 --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"

# Recargar configuración de KWin y temas
qdbus org.kde.KWin /KWin reconfigure
```

---

## 3. Ventanas, KWin (Wayland) y Luz Nocturna (Night Color)

```bash
# Botones de ventana completos (Minimizar, Maximizar, Cerrar a la derecha)
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "ButtonsOnRight" "IAX"
qdbus org.kde.KWin /KWin reconfigure

# Activar Luz Nocturna (Night Color a 4000K)
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

## 4. Dolphin (Gestor de Archivos de KDE) & KIO Servicemenus

Dolphin utiliza archivos `.desktop` en `~/.local/share/kio/servicemenus/` para acciones contextuales:

- **Abrir en Kitty**: `~/.local/share/kio/servicemenus/open-in-kitty.desktop`
- **Abrir con Antigravity**: `~/.local/share/kio/servicemenus/open-in-antigravity.desktop`
- **Abrir con Antigravity IDE**: `~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`

### Vista en lista y detalles:
```bash
# Establecer vista de Detalles por defecto en Dolphin
kwriteconfig6 --file dolphinrc --group "General" --key "ViewMode" 1
```

---

## 5. Terminal Kitty e Integración con Atajos de Teclado

```bash
# Terminal predeterminada en KDE
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty"
kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop"

# Atajo global Ctrl+Alt+T para Kitty Terminal en KDE Plasma 6
kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,none,Kitty Terminal"
```

---

## 6. Capturas de Pantalla y Portapapeles (Wayland)

```bash
# Captura de pantalla nativa de KDE (Spectacle)
spectacle &             # Interfaz completa
spectacle -r &          # Captura interactiva de región rectangular
spectacle -a -c &       # Captura de ventana activa al portapapeles

# Portapapeles Wayland nativo con wl-clipboard
wl-copy < archivo.txt
wl-paste
```

---

## 7. Diagnóstico de Sesión y Servicios de Plasma 6

```bash
# Comprobar tipo de sesión gráfica (debe ser wayland y KDE)
echo $XDG_SESSION_TYPE
echo $XDG_CURRENT_DESKTOP

# Versión de Plasma y KWin
plasmashell --version 2>/dev/null || kwin_wayland --version

# Reiniciar shell gráfico de Plasma sin cerrar la sesión
systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell 2>/dev/null; kstart plasmashell &)

# Logs de Plasma y KWin en la sesión actual
journalctl --user -u plasma-plasmashell.service -n 50 --no-pager
journalctl --user -u plasma-kwin_wayland.service -n 50 --no-pager
```
