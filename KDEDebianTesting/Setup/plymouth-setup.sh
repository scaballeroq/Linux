#!/usr/bin/env bash
# ==============================================================================
# plymouth-setup.sh - Tema Plymouth Moderno: Logo Debian + Spinner Circular
# Sistema: Debian Testing (forky/sid) | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U, Radeon Vega 7)
# ==============================================================================
# Características:
# 1. Crea el tema personalizado 'debian-spinner' basado en el módulo nativo C 'two-step':
#    - Logo oficial de Debian (alta resolución, fondo transparente).
#    - Animación de spinner circular suave (36 fotogramas).
#    - Fondo negro puro (0x000000) para transición limpia y sin cortes con el monitor.
# 2. Soporta dos variantes de logo oficial:
#    - 'swirl': Espiral roja icónica de Debian (minimalista).
#    - 'text' : Espiral roja con texto oficial 'debian' (predeterminada).
# 3. Optimización para AMDGPU (Early KMS):
#    - Incluye el módulo 'amdgpu' en initramfs para arranque 'flicker-free' a resolución nativa.
# 4. Verificación de parámetros del kernel en GRUB ('quiet splash').
# 5. Soporte para previsualización en vivo (mediante plymouth-x11 / Xwayland).
# 6. Reversibilidad completa (--restore al tema original 'ceratopsian' o previo).
# ==============================================================================

set -euo pipefail

THEME_NAME="debian-spinner"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
SPINNER_BASE_DIR="/usr/share/plymouth/themes/spinner"
DEBIAN_LOGOS_DIR="/usr/share/desktop-base/debian-logos"
GRUB_CONFIG="/etc/default/grub"
INITRAMFS_MODULES="/etc/initramfs-tools/modules"

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "🔒 Se requieren permisos de superusuario para modificar Plymouth y el initramfs."
    fi
}

is_pkg_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

# ------------------------------------------------------------------------------
# 1. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
ensure_dependencies() {
    local missing=()
    for pkg in plymouth plymouth-themes desktop-base; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Instalando dependencias de Plymouth y temas oficiales: ${missing[*]}..."
        require_root
        export DEBIAN_FRONTEND=noninteractive
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${missing[@]}"
    else
        echo "  ✅ Paquetes de Plymouth requeridos (plymouth, plymouth-themes) ya instalados."
    fi
}

# ------------------------------------------------------------------------------
# 2. OPTIMIZACIÓN AMDGPU EARLY KMS (Arranque sin parpadeos)
# ------------------------------------------------------------------------------
configure_early_kms() {
    echo "⚡ Verificando Early KMS para tarjeta gráfica AMD Radeon Vega..."
    if [ -f "$INITRAMFS_MODULES" ]; then
        if ! grep -q "^amdgpu" "$INITRAMFS_MODULES"; then
            require_root
            echo "   Añadiendo módulo 'amdgpu' a $INITRAMFS_MODULES para inicio nativo sin parpadeos..."
            echo "amdgpu" | $SUDO tee -a "$INITRAMFS_MODULES" >/dev/null
            echo "  ✅ Módulo amdgpu configurado en initramfs."
        else
            echo "  ✅ Módulo 'amdgpu' ya presente en initramfs."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN DE PARÁMETROS DEL KERNEL EN GRUB
# ------------------------------------------------------------------------------
verify_grub_splash() {
    echo "🔍 Comprobando parámetros del kernel en GRUB..."
    if [ -f "$GRUB_CONFIG" ]; then
        if grep -q "quiet" "$GRUB_CONFIG" && grep -q "splash" "$GRUB_CONFIG"; then
            echo "  ✅ Parámetros 'quiet splash' activos en $GRUB_CONFIG."
        else
            echo "  ⚠️ Advertencia: 'quiet splash' no parece estar activo en $GRUB_CONFIG."
            echo "     Asegúrate de que GRUB_CMDLINE_LINUX_DEFAULT incluya 'quiet splash' para ver el arranque gráfico."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 4. CREACIÓN Y CONFIGURACIÓN DEL TEMA 'debian-spinner'
# ------------------------------------------------------------------------------
install_theme() {
    local variant="${1:-text}" # 'text' (logo + debian) o 'swirl' (solo espiral)

    ensure_dependencies
    configure_early_kms
    verify_grub_splash

    echo ""
    echo "🎨 Creando tema personalizado '$THEME_NAME' (Variante: $variant)..."
    require_root

    $SUDO mkdir -p "$THEME_DIR"

    # 1. Copiar/Enlazar recursos base del spinner (animaciones, diálogos, iconos)
    if [ ! -d "$SPINNER_BASE_DIR" ]; then
        echo "❌ Error: El directorio base '$SPINNER_BASE_DIR' no existe. Asegúrate de instalar plymouth-themes."
        exit 1
    fi

    # Enlazar todos los recursos del tema spinner (animaciones 0001 a 0036, throbbers, etc.)
    for file in "$SPINNER_BASE_DIR"/*.png; do
        local base_file
        base_file="$(basename "$file")"
        if [ "$base_file" != "watermark.png" ]; then
            $SUDO cp -p "$file" "$THEME_DIR/$base_file"
        fi
    done

    # 2. Seleccionar y colocar el logo de Debian como watermark
    local logo_source=""
    case "$variant" in
        swirl)
            logo_source="$DEBIAN_LOGOS_DIR/logo-256.png"
            if [ ! -f "$logo_source" ]; then
                logo_source="/usr/share/plymouth/debian-logo.png"
            fi
            ;;
        text|*)
            logo_source="$DEBIAN_LOGOS_DIR/logo-text-256.png"
            if [ ! -f "$logo_source" ]; then
                logo_source="$DEBIAN_LOGOS_DIR/logo-256.png"
            fi
            ;;
    esac

    if [ -f "$logo_source" ]; then
        $SUDO cp -p "$logo_source" "$THEME_DIR/watermark.png"
        echo "  ✅ Logotipo de Debian configurado desde: $logo_source"
    else
        echo "❌ Error: No se encontró el logotipo oficial de Debian en $DEBIAN_LOGOS_DIR."
        exit 1
    fi

    # 3. Generar archivo .plymouth optimizado con alineaciones centradas
    # - Watermark (Logo): centrado horizontal (.5) y a una altura del 42% (.42)
    # - Spinner (Animación): centrado horizontal (.5) y a una altura del 60% (.60, justo debajo del logo)
    # - Fondo: 0x000000 (Negro puro)
    cat <<'EOF' | $SUDO tee "$THEME_DIR/${THEME_NAME}.plymouth" >/dev/null
[Plymouth Theme]
Name=Debian Spinner
Description=Tema moderno con el logo oficial de Debian y spinner circular
ModuleName=two-step

[two-step]
Font=Cantarell 12
TitleFont=Cantarell Light 30
ImageDir=/usr/share/plymouth/themes/debian-spinner
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.382
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.382
HorizontalAlignment=.5
VerticalAlignment=.60
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.42
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
ProgressBarBackgroundColor=0x606060
ProgressBarForegroundColor=0xffffff
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false

[shutdown]
UseEndAnimation=false

[reboot]
UseEndAnimation=false

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Instalando actualizaciones...
SubTitle=No apague el equipo

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Actualizando sistema...
SubTitle=No apague el equipo

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Actualizando firmware...
SubTitle=No apague el equipo

[system-reset]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Restableciendo sistema...
SubTitle=No apague el equipo
EOF

    $SUDO chmod 644 "$THEME_DIR/${THEME_NAME}.plymouth"
    echo "  ✅ Archivo de configuración ${THEME_NAME}.plymouth generado."

    # 4. Establecer como tema predeterminado y reconstruir initramfs
    echo ""
    echo "🔄 Aplicando tema '$THEME_NAME' y actualizando initramfs..."
    $SUDO /usr/sbin/plymouth-set-default-theme -R "$THEME_NAME"

    echo ""
    echo "================================================================="
    echo "✅ Tema Plymouth '$THEME_NAME' activado y configurado con éxito."
    echo "   En el próximo arranque verás el logo de Debian con el spinner."
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 5. RESTAURACIÓN DEL TEMA ORIGINAL
# ------------------------------------------------------------------------------
restore_theme() {
    local target_theme="${1:-ceratopsian}"
    echo "🔄 Restaurando tema predeterminado de Debian ('$target_theme')..."
    require_root

    if [ ! -d "/usr/share/plymouth/themes/$target_theme" ]; then
        if [ -d "/usr/share/plymouth/themes/details" ]; then
            target_theme="details"
        fi
    fi

    $SUDO /usr/sbin/plymouth-set-default-theme -R "$target_theme"
    echo "  ✅ Tema '$target_theme' restaurado e initramfs actualizado."
}

# ------------------------------------------------------------------------------
# 6. PREVISUALIZACIÓN EN VIVO (Vía X11 / Xwayland)
# ------------------------------------------------------------------------------
preview_theme() {
    echo "👁️  Iniciando previsualización de Plymouth en ventana..."
    if ! is_pkg_installed "plymouth-x11"; then
        echo "📦 Instalando paquete 'plymouth-x11' necesario para la ventana de prueba..."
        require_root
        $SUDO apt-get install -y plymouth-x11
    fi

    require_root
    echo "   (La previsualización durará 8 segundos. Presiona Ctrl+C para salir antes)."
    
    # Iniciar daemon plymouth con renderer x11
    $SUDO /sbin/plymouthd --debug --tty=/dev/tty1 2>/dev/null || true
    $SUDO /bin/plymouth --show-splash 2>/dev/null || true

    for i in {1..8}; do
        sleep 1
        $SUDO /bin/plymouth --update="Iniciando Debian GNU/Linux... ($i/8)" 2>/dev/null || true
    done

    $SUDO /bin/plymouth --quit 2>/dev/null || true
    echo "  ✅ Previsualización finalizada."
}

# ------------------------------------------------------------------------------
# 7. DIAGNÓSTICO Y ESTADO
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "🖥️  ESTADO DE PLYMOUTH (BOOT SPLASH)"
    echo "   Sistema: Debian Testing | Entorno: KDE Plasma 6 (Wayland)"
    echo "   Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U)"
    echo "================================================================="

    # 1. Tema actual
    local current_theme
    current_theme=$(/usr/sbin/plymouth-set-default-theme 2>/dev/null || echo "Desconocido")
    echo "🎨 Tema actual de arranque:   ✅ $current_theme"

    # 2. Paquetes instalados
    local plymouth_ver plymouth_themes_ver
    plymouth_ver=$(dpkg-query -W -f='${Version}\n' plymouth 2>/dev/null || echo "No instalado")
    plymouth_themes_ver=$(dpkg-query -W -f='${Version}\n' plymouth-themes 2>/dev/null || echo "No instalado")
    echo "📦 Paquete plymouth:          $plymouth_ver"
    echo "📦 Paquete plymouth-themes:   $plymouth_themes_ver"

    # 3. Estado del tema debian-spinner
    if [ -f "$THEME_DIR/${THEME_NAME}.plymouth" ]; then
        echo "🌟 Tema debian-spinner:       ✅ Creado y disponible en $THEME_DIR"
    else
        echo "🌟 Tema debian-spinner:       ⚠️ Aún no creado (Ejecuta 'just plymouth' para crearlo)"
    fi

    # 4. Early KMS amdgpu
    if grep -q "^amdgpu" "$INITRAMFS_MODULES" 2>/dev/null; then
        echo "⚡ Early KMS (initramfs):     ✅ 'amdgpu' activo (Arranque sin parpadeos)"
    else
        echo "⚡ Early KMS (initramfs):     ⚠️ 'amdgpu' no añadido a $INITRAMFS_MODULES"
    fi

    # 5. Parámetros del kernel en GRUB
    local grub_cmdline
    grub_cmdline=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG" 2>/dev/null || echo "No encontrado")
    echo "⚙️  Línea GRUB_CMDLINE_LINUX:   $grub_cmdline"

    # 6. Temas instalados
    echo "-----------------------------------------------------------------"
    echo "📂 Temas instalados en el sistema:"
    /usr/sbin/plymouth-set-default-theme -l 2>/dev/null | sed 's/^/   • /' || true
    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Configura y optimiza el splash de arranque de Plymouth en Debian Testing con
el logotipo oficial de Debian y un spinner circular animado.

OPCIONES:
  (sin argumentos)       Instala y activa el tema 'debian-spinner' con el logo oficial completo (texto + espiral).
  -s, --status           Muestra el tema actual, paquetes, estado de KMS y temas disponibles.
  --swirl                Usa exclusivamente la espiral roja minimalista de Debian (sin texto).
  --text                 Usa la espiral roja con el texto oficial 'debian' (predeterminado).
  -p, --preview          Muestra una previsualización de prueba en ventana durante 8 segundos.
  -r, --restore [TEMA]   Restaura el tema original de Debian (por defecto: 'ceratopsian').
  -h, --help             Muestra este mensaje de ayuda.

EJEMPLOS:
  $(basename "$0")              # Aplica el tema 'debian-spinner' con logo y spinner
  $(basename "$0") --swirl      # Aplica con la espiral minimalista de Debian
  $(basename "$0") --status     # Diagnóstico del estado de Plymouth
  $(basename "$0") --preview    # Previsualiza el arranque en ventana
  $(basename "$0") --restore    # Vuelve al tema predeterminado previo
EOF
}

# ------------------------------------------------------------------------------
# 8. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
ACTION="install"
VARIANT="text"
RESTORE_THEME="ceratopsian"

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        --swirl)
            VARIANT="swirl"
            shift
            ;;
        --text)
            VARIANT="text"
            shift
            ;;
        -p|--preview)
            ACTION="preview"
            shift
            ;;
        -r|--restore)
            ACTION="restore"
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                RESTORE_THEME="$1"
                shift
            fi
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Opción desconocida: $1"
            echo "Usa '$(basename "$0") --help' para ver las opciones disponibles."
            exit 1
            ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        exit 0
        ;;
    preview)
        preview_theme
        exit 0
        ;;
    restore)
        restore_theme "$RESTORE_THEME"
        exit 0
        ;;
    install)
        install_theme "$VARIANT"
        exit 0
        ;;
esac
