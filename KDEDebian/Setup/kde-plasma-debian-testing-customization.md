# Guía de Automatización y Personalización de KDE Plasma 6 en Debian Testing

Este documento contiene la especificación técnica completa, comandos paso a paso y la estructura de scripts para automatizar la personalización de **KDE Plasma 6** en **Debian Testing**, basada en las configuraciones de *The Linux Experiment* y *The Markella's*.

---

## 1. Requisitos Previos y Dependencias del Sistema

Para compilar complementos de KWin, ejecutar scripts de temas dinámicos y gestionar motores Qt (Kvantum, Material You, Klassy, Better Blur), se deben instalar los siguientes paquetes base en Debian Testing:

```bash
sudo apt update && sudo apt install -y \
    build-essential \
    cmake \
    extra-cmake-modules \
    git \
    curl \
    wget \
    jq \
    pipx \
    python3-pip \
    python3-pyqt6 \
    python3-setuptools \
    python3-dbus \
    libdbus-1-dev \
    pkgconf \
    ninja-build \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-svg-dev \
    libkf6config-dev \
    libkf6coreaddons-dev \
    libkf6guiaddons-dev \
    libkf6i18n-dev \
    libkf6windowsystem-dev \
    libkf6kio-dev \
    libkf6colorscheme-dev \
    libkf6kcmutils-dev \
    libkf6iconthemes-dev \
    libkf6style-dev \
    libkf6xmlgui-dev \
    libkf6globalaccel-dev \
    libkf6newstuff-dev \
    libkf6breezeicons-dev \
    libkf6dbusaddons-dev \
    libkf6crash-dev \
    libkdecorations3-dev \
    kwin-dev \
    qt6-style-kvantum \
    qt-style-kvantum-themes \
    plasma-widgets-addons \
    plasma-workspace-dev \
    libplasma-dev
```

Asegurar la ruta de binarios de Python para pipx:
```bash
pipx ensurepath
```

---

## 2. Motor de Temas y Transparencias: Kvantum

Kvantum gestiona el renderizado vectorial SVG y la translucidez en aplicaciones Qt (como Dolphin).

### 2.1 Configuración de Kvantum
1. Establecer el estilo de aplicaciones Qt en Kvantum:
```bash
# Configurar Kvantum en el archivo de configuración de KDE
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
```

### 2.2 Instalación de Temas Kvantum (Windsur Dark & Fluent)
```bash
mkdir -p ~/.config/Kvantum
mkdir -p ~/.local/share/aurorae/themes

# Descargar e instalar temas Kvantum comunitarios
# Clonar repositorios de temas o extraer temas SVG en ~/.config/Kvantum/<nombre_tema>/
```

### 2.3 Parámetros recomendados en Kvantum Manager
- **Tema activo:** `Windsur-Dark` o `Fluent-Dark`
- **Compositing & General Look:**
  - `Translucent windows`: Activado
  - `Blurring`: Activado
  - `Transparent Dolphin view`: Activado
  - `Menu opacity`: 90-95%

---

## 3. Decoraciones de Ventana (Klassy & Nothing)

### Opción A: Klassy (Barras de título difuminadas y botones personalizables)
Compilación e instalación de Klassy para Plasma 6 / Qt6:
```bash
mkdir -p ~/src && cd ~/src
git clone https://github.com/paulmcauley/klassy.git
cd klassy
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DKDE_INSTALL_USE_QT_SYS_PATHS=ON \
    -DBUILD_QT5=OFF \
    -DBUILD_QT6=ON
make -j$(nproc)
sudo make install
```

Configurar Klassy como decoración por defecto:
```bash
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key plugin org.kde.klassy
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme klassy
```

### Opción B: Minimalista "Nothing"
```bash
# Instalación del tema Aurorae Nothing
kpackagetool6 -t Aurorae/Theme -i ~/.local/share/aurorae/themes/Nothing 2>/dev/null || true
```

---

## 4. Efecto de Desenfoque Global (Better Blur DX)

Para permitir desenfoque en ventanas que usan opacidad modificada:
```bash
cd ~/src
git clone https://github.com/xarblu/kwin-effects-better-blur-dx.git
cd kwin-effects-better-blur-dx
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
make -j$(nproc)
sudo make install
```

### Reglas de Ventana de KWin para Opacidad
Añadir una regla de KWin en `~/.config/kwinrulesrc` para aplicar opacidad (ej. 92% activo, 85% inactivo) a todas las ventanas normales.

---

## 5. Esquema Dinámico Material You (KDE Material You Colors)

Permite extraer la paleta de colores del fondo de pantalla y aplicarla dinámicamente al sistema.

### 5.1 Backend Python
```bash
pipx install kde-material-you-colors
```

### 5.2 Servicio Autostart de Systemd / Desktop Entry
Crear `~/.config/autostart/kde-material-you-colors.desktop`:
```ini
[Desktop Entry]
Type=Application
Exec=kde-material-you-colors --daemon
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=KDE Material You Colors Daemon
Comment=Dynamic system accent colors based on wallpaper
```

---

## 6. Configuración de Paneles Flotantes Modulares (Dock Style)

Estructura de panel superior dividido en tres bloques independientes:

1. **Panel Izquierdo (Alineación Izquierda - Fit Content):**
   - Menú de Aplicaciones / Application Dashboard (`org.kde.plasma.kickoff` / `org.kde.plasma.appmenu`)
   - Lugares (`org.kde.plasma.places`)
   - Monitor de Recursos CPU/RAM (`org.kde.plasma.systemmonitor`)
   - Reproductor Multimedia (`org.kde.plasma.mediacontroller`)
   - Pager estilo pastilla (Widget `Kar Pager` / `org.kde.plasma.pager`)

2. **Panel Central (Alineación Centro - Fit Content):**
   - Gestor de tareas solo iconos (`org.kde.plasma.icontasks`)

3. **Panel Derecho (Alineación Derecha - Fit Content):**
   - Bandeja del Sistema (`org.kde.plasma.systemtray`)
   - Reloj Digital (`org.kde.plasma.digitalclock`)

4. **Estilización con Panel Colorizer:**
   - Plasmoide: `Panel Colorizer` (`luisbocanegra.panelcolorizer`)
   - Altura: `36px`
   - Preset: `Dock` / `Rounder Translucent`

---

## 7. Scripts de KWin: Auto-Tiling y Dynamic Workspaces

### 7.1 Mouse Tiler (Tiling Asistido)
- Instalar vía KNewStuff / GH: `kwin-script-mouse-tiler`
- Atajo de acomodado: `Ctrl + Alt + A`
- Recargar scripts de KWin:
```bash
qdbus6 org.kde.KWin /KWin reconfigure
```

### 7.2 Dynamic Workspaces
- Instalar script KWin `dynamic-workspaces`
- Habilita la creación automática de escritorios virtuales al llenar el actual y su eliminación cuando quedan vacíos (comportamiento GNOME).

---

## 8. Aspecto Visual: Iconos, Cursores y Efectos

- **Iconos:** `Tela-blue-dark`
- **Cursores:** `Oxygen_White`
- **Sonidos:** `Oxygen`
- **Plugin de Wallpaper:** `Blurred Wallpaper` (`bouteillerAlan/blurredwallpaper`) o `Plasma Wallpaper Effects` (`luisbocanegra/plasma-wallpaper-effects`) (difumina el fondo cuando hay ventanas activas).

Comandos CLI para aplicar:
```bash
kwriteconfig6 --file kdeglobals --group Icons --key Theme Tela-blue-dark
kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme Oxygen_White
```

---

## 9. Estructura de Actividades para Aislamiento de Flujos

Separación de perfiles (ej. `Dev/Linux` vs `Multimedia/Ocio`):
- Asignación de fondos de pantalla diferenciados.
- Widgets de escritorio independientes.
- Aplicaciones ancladas específicas por actividad.

---

## 10. Script Automatizador Maestro (`kde-plasma-customization.sh`)

El script modular [`kde-plasma-customization.sh`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebian/Setup/kde-plasma-customization.sh) automatiza por completo la instalación de dependencias, compilación de Klassy y Better Blur, temas Kvantum, iconos Tela Dark, scripts de KWin y plasmoides.

### 10.1 Ejecución
```bash
# Vía justfile
just kde-custom

# O directamente mediante Bash
./Setup/kde-plasma-customization.sh
```

---

## 11. Pasos Manuales Post-Instalación (Entorno Gráfico)

Aunque el 90% del aprovisionamiento y compilación está automatizado, KDE Plasma requiere los siguientes ajustes manuales en su interfaz:

1. **Reinicio de sesión:** Cerrar sesión y volver a entrar (o reiniciar el equipo) para que KWin cargue los módulos compilados de Klassy y el motor Kvantum.
2. **Paneles modulares flotantes (Top Bar / Dock):**
   - Clic derecho en el escritorio -> *Entrar en modo edición*.
   - Crear 3 paneles superiores con longitud ajustada al contenido (*Fit Content*):
     - **Izquierda:** Menú de aplicaciones (`Kickoff`), Pager de escritorios y Monitor de recursos.
     - **Centro:** Gestor de tareas solo iconos (modo Dock flotante).
     - **Derecha:** Bandeja del sistema y Reloj digital.
   - Añadir el plasmoide `Panel Colorizer` al panel para darle fondo translúcido y bordes redondeados (Preset *Dock* / *Rounder Translucent*).
3. **Fondo de pantalla y Material You:**
   - Clic derecho en el escritorio -> *Configurar escritorio y fondo de pantalla*.
   - En *Tipo de fondo*, seleccionar `Active Blur` o tu imagen favorita. `kde-material-you-colors` generará dinámicamente la paleta de colores de acento.
4. **Kvantum Manager (Opcional):**
   - Abrir la aplicación `Kvantum Manager` para ajustar finamente el porcentaje de translucidez en Dolphin si deseas más o menos transparencia.
