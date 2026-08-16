---
sidebar_position: 10
---

# Guía Completa de Extensiones de GNOME Shell

Esta guía detalla el conjunto de **17 extensiones de GNOME Shell** y herramientas auxiliares que se instalan y configuran de forma automatizada a través del script [`Setup/gnome-extensions.sh`](file:///home/caballero/Workspace/Respositorios/Linux/Debian/Setup/gnome-extensions.sh) y el comando `just extensions`.

El objetivo de esta selección es optimizar el entorno de escritorio GNOME en Debian 13 (Trixie), combinando **gestión avanzada de ventanas**, **monitoreo de recursos en tiempo real**, **mejora de la productividad** y una **estética visual moderna** (glassmorphism/blur, transparencia y fondos dinámicos).

---

## 🛠️ Herramientas de Gestión e Infraestructura

Antes de instalar las extensiones, el script despliega el soporte base para garantizar una integración limpia sin errores de compilación ni problemas de compatibilidad:

| Herramienta | Tipo | Descripción |
| :--- | :--- | :--- |
| **`gnome-browser-connector`** | Paquete APT | Conector nativo que permite instalar y gestionar extensiones directamente desde el sitio web [extensions.gnome.org](https://extensions.gnome.org/). |
| **`extension-manager`** | Aplicación GTK4/Adwaita | Aplicación gráfica para buscar, instalar, actualizar y configurar extensiones de GNOME de forma nativa sin necesidad de navegador. |
| **`gnome-extensions-cli` (`gext`)** | Herramienta CLI (Python/pipx) | Utilidad de línea de comandos utilizada por los scripts para instalar y actualizar extensiones masivamente mediante la API oficial. |
| **`glib-compile-schemas`** | Compilador GSettings | Compila automáticamente las esquemas GSettings en `~/.local/share/gnome-shell/extensions/<UUID>/schemas`, previniendo errores de estado `Disabled` o `Error`. |

---

## 🧩 Catálogo de Extensiones (17 Extensiones)

---

### 1. Gestión de Ventanas y Escritorio (Window & Workspace Management)

#### 🪟 Tiling Shell
* **ID / UUID**: `7065` | `tilingshell@ferrarodomenico.com`
* **Enlace**: [extensions.gnome.org/extension/7065/tiling-shell](https://extensions.gnome.org/extension/7065/tiling-shell/)
* **Descripción**: Mosaico avanzado de ventanas inspirado en **FancyZones** de Windows 11. Permite dividir la pantalla en cuadrículas personalizables y encajar ventanas arrastrándolas con una tecla modificadora o mediante atajos de teclado.
* **Características Clave**:
  - Ajuste de mosaico automático y asistido (Snap Assistant).
  - Diseños de cuadrícula totalmente personalizables por el usuario.
  - Soporte multimonitor independiente.
  - Atajos de teclado para mover ventanas entre zonas.

#### ⚓ Dash to Dock
* **ID / UUID**: `307` | `dash-to-dock@micxgx.gmail.com`
* **Enlace**: [extensions.gnome.org/extension/307/dash-to-dock](https://extensions.gnome.org/extension/307/dash-to-dock/)
* **Descripción**: Transforma el panel de aplicaciones del menú Resumen (Overview) en un dock flotante o anclado persistente en el escritorio.
* **Características Clave**:
  - Posicionamiento en cualquier borde de la pantalla (abajo, izquierda, derecha, arriba).
  - Ocultación automática inteligente (autohide).
  - Indicadores de número de ventanas abiertas y contadores de notificaciones.
  - Opciones de tamaño de icono, opacidad y temas de color.

#### 🎛️ Dash to Panel
* **ID / UUID**: `1160` | `dash-to-panel@jderose9.github.com`
* **Enlace**: [extensions.gnome.org/extension/1160/dash-to-panel](https://extensions.gnome.org/extension/1160/dash-to-panel/)
* **Descripción**: Combina la barra superior de GNOME y la barra de tareas en un único panel unificado (estilo Windows 10/11 o KDE Plasma).
* **Características Clave**:
  - Elimina la necesidad de un dock separado, ahorrando espacio vertical de pantalla.
  - Agrupa ventanas por aplicación con previsualización en miniatura al pasar el cursor.
  - Altamente configurable en tamaño, posición y comportamiento de los iconos de estado.

#### 🖥️ Desktop Icons NG (DING)
* **ID / UUID**: `2087` | `ding@rastersoft.com`
* **Enlace**: [extensions.gnome.org/extension/2087/desktop-icons-ng-ding](https://extensions.gnome.org/extension/2087/desktop-icons-ng-ding/)
* **Descripción**: Fork mejorado de la extensión original de iconos de escritorio para GNOME Shell, añadiendo soporte nativo para archivos, carpetas y accesos directos en el escritorio.
* **Características Clave**:
  - Soporte para arrastrar y soltar (drag and drop) desde y hacia el gestor de archivos.
  - Menú contextual nativo al hacer clic derecho en el escritorio.
  - Vistas previas de imágenes, documentos y archivos multimedia.

#### 🔄 Coverflow Alt-Tab
* **ID / UUID**: `97` | `CoverflowAltTab@palatis.blogspot.com`
* **Enlace**: [extensions.gnome.org/extension/97/coverflow-alt-tab](https://extensions.gnome.org/extension/97/coverflow-alt-tab/)
* **Descripción**: Reemplaza el selector de ventanas estándar `Alt + Tab` por una animación 3D estilo **Cover Flow**, mostrando vistas previas tridimensionales de las ventanas activas.
* **Características Clave**:
  - Alternancia fluida entre aplicaciones abiertas con vista previa completa de cada ventana.
  - Efectos visuales personalizables (estilo Cover Flow o Timeline).
  - Filtrado de ventanas por espacio de trabajo o por monitor.

---

### 2. Productividad y Flujo de Trabajo (Productivity & Workflow)

#### 📋 Clipboard Indicator
* **ID / UUID**: `779` | `clipboard-indicator@tudmotu.com`
* **Enlace**: [extensions.gnome.org/extension/779/clipboard-indicator](https://extensions.gnome.org/extension/779/clipboard-indicator/)
* **Descripción**: El gestor de portapapeles más popular para GNOME. Mantiene un historial accesible desde un icono en la barra superior.
* **Características Clave**:
  - Historial de textos copiados configurable (hasta cientos de entradas).
  - Búsqueda rápida de texto en el historial del portapapeles.
  - Posibilidad de fijar (pin) elementos frecuentes.
  - Atajos de teclado y modo de privacidad (desactivación temporal del historial).

#### ☕ Caffeine
* **ID / UUID**: `517` | `caffeine@patapon.info`
* **Enlace**: [extensions.gnome.org/extension/517/caffeine](https://extensions.gnome.org/extension/517/caffeine/)
* **Descripción**: Añade un icono en forma de taza de café en el panel superior para inhibir el protector de pantalla y el bloqueo/suspensión automática del sistema.
* **Características Clave**:
  - Activación/desactivación manual con un solo clic.
  - Activación automática al ejecutar aplicaciones a pantalla completa (reproductores de vídeo, juegos, presentaciones).

#### 🎯 Grand Theft Focus
* **ID / UUID**: `5410` | `grand-theft-focus@zalckos.github.com`
* **Enlace**: [extensions.gnome.org/extension/5410/grand-theft-focus](https://extensions.gnome.org/extension/5410/grand-theft-focus/)
* **Descripción**: Elimina el aviso emergente del sistema `"La ventana está lista"` ("Window is ready") y otorga el foco de teclado/pantalla inmediatamente a la aplicación recién abierta.
* **Características Clave**:
  - Evita interrupciones y clics extra cuando una aplicación tarda un par de segundos en arrancar.
  - Mejora la fluidez al lanzar herramientas desde la terminal o aplicaciones externas.

#### 🔒 Lock Keys
* **ID / UUID**: `36` | `lockkeys@vaina.lt`
* **Enlace**: [extensions.gnome.org/extension/36/lock-keys](https://extensions.gnome.org/extension/36/lock-keys/)
* **Descripción**: Muestra indicadores gráficos en la barra superior para los estados de **Bloq Num** (Num Lock) y **Bloq Mayús** (Caps Lock).
* **Características Clave**:
  - Iconos de estado en tiempo real en el área de notificaciones/barra superior.
  - Notificaciones OSD (On-Screen Display) en el centro de la pantalla al presionar las teclas.

#### ⚙️ Extension List
* **ID / UUID**: `3088` | `extension-list@tu.berry`
* **Enlace**: [extensions.gnome.org/extension/3088/extension-list](https://extensions.gnome.org/extension/3088/extension-list/)
* **Descripción**: Añade un menú desplegable directo en el panel superior que enumera todas las extensiones de GNOME instaladas.
* **Características Clave**:
  - Habilita o deshabilita extensiones individualmente con un conmutador.
  - Acceso directo a la pantalla de preferencias/configuración de cada extensión.
  - Ideal para desarrolladores o usuarios que prueban diferentes utilidades sin abrir Extension Manager.

---

### 3. Monitorización y Sistema (Monitoring & System)

#### 📊 Astra Monitor
* **ID / UUID**: `6682` | `monitor@astraext.github.io`
* **Enlace**: [extensions.gnome.org/extension/6682/astra-monitor](https://extensions.gnome.org/extension/6682/astra-monitor/)
* **Descripción**: Monitor de recursos de última generación, ligero y altamente personalizable que se integra directamente en la barra superior de GNOME.
* **Características Clave**:
  - Métricas en tiempo real: Uso de CPU, frecuencia, uso de RAM, consumo de GPU, actividad de disco I/O, tráfico de red (subida/bajada) y sensores de temperatura.
  - Gráficos integrados y menú desplegable detallado al hacer clic.
  - Personalización de colores, intervalos de refresco e indicadores visibles.

#### 🔔 AppIndicator and KStatusNotifierItem Support
* **ID / UUID**: `615` | `appindicatorsupport@rgcjonas.gmail.com`
* **Enlace**: [extensions.gnome.org/extension/615/appindicator-support](https://extensions.gnome.org/extension/615/appindicator-support/)
* **Descripción**: Proporciona soporte para iconos de la bandeja del sistema (System Tray) a aplicaciones que utilicen el protocolo AppIndicator o KStatusNotifierItem.
* **Características Clave**:
  - Permite ver y controlar aplicaciones en segundo plano como Telegram, Steam, Discord, Dropbox, VS Code, Nextcloud o Spotify.
  - Soporte para menús contextuales al hacer clic con el botón derecho en los iconos del tray.

#### 🔊 Quick Settings Audio Panel
* **ID / UUID**: `5940` | `quick-settings-audio-panel@rayzeq.github.io`
* **Enlace**: [extensions.gnome.org/extension/5940/quick-settings-audio-panel](https://extensions.gnome.org/extension/5940/quick-settings-audio-panel/)
* **Descripción**: Agrega una sección extendida de audio dentro del menú de Ajustes Rápidos (Quick Settings) de GNOME Shell.
* **Características Clave**:
  - Control de volumen independiente por aplicación (Stream Mixer).
  - Selección rápida del dispositivo de salida/entrada de audio (altavoces, auriculares, micrófono).
  - Control de reproducción multimedia integrado.

---

### 4. Estética y Personalización Visual (Aesthetics & Customization)

#### 🧊 Blur my Shell
* **ID / UUID**: `3193` | `blur-my-shell@aunetx`
* **Enlace**: [extensions.gnome.org/extension/3193/blur-my-shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)
* **Descripción**: Aplica un efecto de desenfoque estilo cristal esmerilado (glassmorphism) a varios elementos de GNOME Shell.
* **Características Clave**:
  - Aplica desenfoque en la barra superior, el resumen (Overview), el Dash, las ventanas de aplicaciones y la terminal.
  - Altamente optimizado para mantener un rendimiento de renderizado fluido a 60 FPS / 120 FPS.
  - Configuración detallada del radio de desenfoque, brillo y sombras.

#### 🖼️ Bing Wallpaper
* **ID / UUID**: `1262` | `BingWallpaper@ineffable-gmail.com`
* **Enlace**: [extensions.gnome.org/extension/1262/bing-wallpaper-changer](https://extensions.gnome.org/extension/1262/bing-wallpaper-changer/)
* **Descripción**: Sincroniza automáticamente el fondo de escritorio y la pantalla de bloqueo con la imagen diaria en alta resolución (UHD/4K) publicada por Microsoft Bing.
* **Características Clave**:
  - Descarga automática una vez al día sin consumo apreciable de recursos en segundo plano.
  - Muestra la descripción, título e historia detrás de la fotografía del día.
  - Permite explorar y seleccionar imágenes descargadas previamente en modo aleatorio o manual.

#### 🔍 Transparent Top Bar (Adjustable transparency)
* **ID / UUID**: `3960` | `transparent-top-bar@ftpix.com`
* **Enlace**: [extensions.gnome.org/extension/3960/transparent-top-bar-adjustable-transparency](https://extensions.gnome.org/extension/3960/transparent-top-bar-adjustable-transparency/)
* **Descripción**: Restaura la barra superior transparente en GNOME Shell cuando no hay ninguna ventana maximizada tocando el borde superior.
* **Características Clave**:
  - Opacidad personalizable en estado reposo y estado maximizado.
  - Transición suave al maximizar o desmaximizar ventanas.

#### 📐 Status Area Horizontal Spacing
* **ID / UUID**: `355` | `status-area-horizontal-spacing@mathematical.coffee.gmail.com`
* **Enlace**: [extensions.gnome.org/extension/355/status-area-horizontal-spacing](https://extensions.gnome.org/extension/355/status-area-horizontal-spacing/)
* **Descripción**: Permite reducir o personalizar el margen horizontal entre los iconos de la barra superior.
* **Características Clave**:
  - Optimiza el espacio disponible en la barra superior, permitiendo albergar más monitores de sistema e indicadores sin saturar la pantalla.

---

## 🚀 Resumen de Instalación y Comandos Útiles

Todas estas extensiones se instalan automáticamente ejecutando:

```bash
just extensions
# O directamente el script:
./Setup/gnome-extensions.sh
```

### Comandos de Gestión Rápida

- **Listar extensiones instaladas**:
  ```bash
  gnome-extensions list
  ```
- **Habilitar / Deshabilitar una extensión**:
  ```bash
  gnome-extensions enable <UUID>
  gnome-extensions disable <UUID>
  ```
- **Abrir las preferencias de una extensión**:
  ```bash
  gnome-extensions prefs <UUID>
  ```
- **Abrir el gestor visual de extensiones**:
  ```bash
  extension-manager
  ```
