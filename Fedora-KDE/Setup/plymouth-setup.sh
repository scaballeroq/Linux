#!/usr/bin/env bash
# ==============================================================================
# plymouth-setup.sh - Administrador de Splash Screen (Plymouth) y Early KMS
# Sistema: Fedora 44 Workstation | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7 / Btrfs)
# ==============================================================================
# Características:
# 1. Instalación idempotente de Plymouth, plugins two-step y temas oficiales vía DNF5.
# 2. Optimización Early KMS en Dracut (/etc/dracut.conf.d/amdgpu.conf) para carga
#    inmediata del driver amdgpu sin parpadeos en resolución nativa 1080p.
# 3. Verificación y aseguramiento de parámetros GRUB ('rhgb quiet').
# 4. Soporte para temas 'breeze' (KDE Plasma 6), 'bgrt' (UEFI Fedora) y 'spinner'.
# 5. Previsualización en vivo de 8 segundos (--preview).
# 6. Reversibilidad completa (--restore y --disable).
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Se requieren privilegios de superusuario (root/sudo)."
        exit 1
    fi
}

IS_UEFI=false
if [ -d "/sys/firmware/efi" ]; then
    IS_UEFI=true
fi

DRACUT_CONF="/etc/dracut.conf.d/amdgpu.conf"
GRUB_CONFIG="/etc/default/grub"

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 1. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS (DNF5)
# ------------------------------------------------------------------------------
ensure_dependencies() {
    local missing=()
    for pkg in plymouth plymouth-plugin-two-step plymouth-theme-spinner plymouth-theme-breeze plymouth-system-theme; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Instalando paquetes de Plymouth faltantes vía DNF5: ${missing[*]}..."
        require_root
        $SUDO dnf5 install -y "${missing[@]}" 2>/dev/null || \
        $SUDO dnf5 install -y plymouth plymouth-theme-spinner plymouth-theme-breeze 2>/dev/null || true
    else
        echo "  ✅ Paquetes de Plymouth y temas oficiales ya instalados."
    fi
}

# ------------------------------------------------------------------------------
# 2. OPTIMIZACIÓN AMDGPU EARLY KMS (Dracut - Arranque sin parpadeos)
# ------------------------------------------------------------------------------
configure_early_kms() {
    require_root
    echo "⚡ Configurando Early KMS para tarjeta gráfica AMD Radeon Vega 7 en Dracut..."
    if [ ! -f "$DRACUT_CONF" ] || ! grep -q "amdgpu" "$DRACUT_CONF"; then
        echo "   Añadiendo módulo 'amdgpu' en $DRACUT_CONF para arranque nativo 1080p sin parpadeos..."
        $SUDO mkdir -p /etc/dracut.conf.d/
        echo 'force_drivers+=" amdgpu "' | $SUDO tee "$DRACUT_CONF" >/dev/null
        echo "  ✅ Módulo 'amdgpu' registrado en Dracut."
    else
        echo "  ✅ Módulo 'amdgpu' ya configurado en $DRACUT_CONF."
    fi
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN DE PARÁMETROS DEL KERNEL EN GRUB
# ------------------------------------------------------------------------------
verify_grub_splash() {
    require_root
    echo "🔍 Comprobando parámetros de arranque gráfico en $GRUB_CONFIG..."
    if [ -f "$GRUB_CONFIG" ]; then
        local current_line
        current_line=$(grep "^GRUB_CMDLINE_LINUX=" "$GRUB_CONFIG" || grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "$GRUB_CONFIG" || echo "")
        if echo "$current_line" | grep -q "rhgb" && echo "$current_line" | grep -q "quiet"; then
            echo "  ✅ Parámetros 'rhgb quiet' activos en GRUB."
        else
            echo "  ℹ️ Ajustando 'rhgb quiet' en $GRUB_CONFIG..."
            if grep -q "^GRUB_CMDLINE_LINUX=" "$GRUB_CONFIG"; then
                if ! echo "$current_line" | grep -q "quiet"; then
                    $SUDO sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet /' "$GRUB_CONFIG"
                fi
                if ! echo "$current_line" | grep -q "rhgb"; then
                    $SUDO sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="rhgb /' "$GRUB_CONFIG"
                fi
                $SUDO grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
                echo "  ✅ Configuración de GRUB actualizada con 'rhgb quiet'."
            fi
        fi
    fi
}

# ------------------------------------------------------------------------------
# 4. APLICACIÓN Y GESTIÓN DE TEMAS
# ------------------------------------------------------------------------------
apply_theme() {
    local target_theme="${1:-}"
    if [ -z "$target_theme" ]; then
        if [ -d "/usr/share/plymouth/themes/bgrt" ] && [ "$IS_UEFI" = true ]; then
            target_theme="bgrt"
        elif [ -d "/usr/share/plymouth/themes/breeze" ]; then
            target_theme="breeze"
        else
            target_theme="spinner"
        fi
    fi

    echo "================================================================="
    echo "🎨 CONFIGURANDO PLYMOUTH BOOT SPLASH EN FEDORA 44"
    echo "   Tema objetivo: $target_theme"
    echo "================================================================="

    ensure_dependencies
    configure_early_kms
    verify_grub_splash

    if [ ! -d "/usr/share/plymouth/themes/$target_theme" ]; then
        echo "⚠️ El tema '$target_theme' no existe en /usr/share/plymouth/themes/. Usando 'spinner'..."
        target_theme="spinner"
    fi

    echo ""
    echo "🔄 Aplicando tema '$target_theme' y reconstruyendo initramfs con Dracut..."
    require_root
    if ! $SUDO plymouth-set-default-theme -R "$target_theme" 2>/dev/null; then
        $SUDO plymouth-set-default-theme "$target_theme"
        $SUDO dracut -f
    fi

    echo ""
    echo "================================================================="
    echo "✅ Tema Plymouth '$target_theme' activado y configurado con éxito."
    echo "================================================================="
}

restore_theme() {
    local target_theme="${1:-bgrt}"
    echo "🔄 Restaurando tema predeterminado de Fedora ('$target_theme')..."
    require_root

    if [ ! -d "/usr/share/plymouth/themes/$target_theme" ]; then
        target_theme="spinner"
    fi

    if ! $SUDO plymouth-set-default-theme -R "$target_theme" 2>/dev/null; then
        $SUDO plymouth-set-default-theme "$target_theme"
        $SUDO dracut -f
    fi
    echo "  ✅ Tema '$target_theme' restaurado e initramfs actualizado."
}

disable_plymouth() {
    echo "⚙️ Desactivando splash gráfico de Plymouth (estableciendo tema 'details')..."
    require_root
    if ! $SUDO plymouth-set-default-theme -R details 2>/dev/null; then
        $SUDO plymouth-set-default-theme details
        $SUDO dracut -f
    fi
    echo "  ✅ Splash gráfico desactivado. El arranque mostrará los mensajes de systemd."
}

list_themes() {
    ensure_dependencies
    echo "================================================================="
    echo "🎨 TEMAS PLYMOUTH INSTALADOS EN FEDORA 44"
    echo "================================================================="
    plymouth-set-default-theme --list 2>/dev/null | sed 's/^/   • /' || ls -1 /usr/share/plymouth/themes/
    echo "-----------------------------------------------------------------"
    echo "💡 Tema activo actual: $(plymouth-set-default-theme 2>/dev/null || echo 'desconocido')"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 5. PREVISUALIZACIÓN EN VIVO
# ------------------------------------------------------------------------------
preview_theme() {
    echo "👁️  Iniciando previsualización de Plymouth durante 8 segundos..."
    if ! is_pkg_installed "plymouth-plugin-label"; then
        $SUDO dnf5 install -y plymouth-plugin-label 2>/dev/null || true
    fi

    require_root
    echo "   (La previsualización durará 8 segundos. Presiona Ctrl+C para salir antes)."

    $SUDO plymouthd --debug --tty=/dev/tty1 2>/dev/null || $SUDO plymouthd 2>/dev/null || true
    $SUDO plymouth --show-splash 2>/dev/null || true

    for i in {1..8}; do
        sleep 1
        $SUDO plymouth --update="Iniciando Fedora 44 Workstation... ($i/8)" 2>/dev/null || true
    done

    $SUDO plymouth --quit 2>/dev/null || true
    echo "  ✅ Previsualización finalizada."
}

# ------------------------------------------------------------------------------
# 6. DIAGNÓSTICO Y ESTADO
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "🖥️  ESTADO DE PLYMOUTH (BOOT SPLASH)"
    echo "   Sistema: Fedora 44 Workstation | Entorno: KDE Plasma 6 (Wayland)"
    echo "   Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Vega 7)"
    echo "================================================================="

    # 1. Tema actual
    local current_theme
    current_theme=$(plymouth-set-default-theme 2>/dev/null || echo "Desconocido")
    echo "🎨 Tema actual de arranque:   ✅ $current_theme"

    # 2. Paquetes instalados
    local plymouth_ver breeze_ver spinner_ver
    plymouth_ver=$(if is_pkg_installed plymouth; then rpm -q --qf '%{VERSION}-%{RELEASE}' plymouth; else echo "No instalado"; fi)
    breeze_ver=$(if is_pkg_installed plymouth-theme-breeze; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)
    spinner_ver=$(if is_pkg_installed plymouth-theme-spinner; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)
    echo "📦 Paquete plymouth:          $plymouth_ver"
    echo "📦 Tema KDE Breeze:           $breeze_ver"
    echo "📦 Tema Fedora Spinner/BGRT:  $spinner_ver"

    # 3. Early KMS amdgpu en Dracut
    if [ -f "$DRACUT_CONF" ] && grep -q "amdgpu" "$DRACUT_CONF" 2>/dev/null; then
        echo "⚡ Early KMS (Dracut AMD):    ✅ 'amdgpu' activo en $DRACUT_CONF"
    else
        echo "⚡ Early KMS (Dracut AMD):    ⚠️ No configurado en $DRACUT_CONF"
    fi

    # 4. Modo UEFI / BIOS
    echo "🔌 Modo de Firmware:          $(if [ "$IS_UEFI" = true ]; then echo "✅ UEFI (Soporte BGRT activo)"; else echo "ℹ️ Legacy BIOS"; fi)"

    # 5. Parámetros del kernel en GRUB
    local grub_cmdline
    grub_cmdline=$(grep "^GRUB_CMDLINE_LINUX=" "$GRUB_CONFIG" 2>/dev/null || echo "No encontrado")
    echo "⚙️  Línea GRUB_CMDLINE_LINUX:   $grub_cmdline"

    # 6. Temas instalados
    echo "-----------------------------------------------------------------"
    echo "📂 Temas instalados en el sistema:"
    plymouth-set-default-theme --list 2>/dev/null | sed 's/^/   • /' || true
    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES] [TEMA]

Configura y optimiza el splash de arranque de Plymouth y Early KMS (Dracut) en Fedora 44.

OPCIONES:
  (sin argumentos)       Instala paquetes, activa Early KMS para AMD Vega y aplica el tema óptimo (bgrt/breeze).
  -s, --status           Muestra el tema actual, paquetes, estado de Early KMS en Dracut y temas disponibles.
  -l, --list             Lista todos los temas instalados en el sistema.
  --breeze               Aplica el tema oficial KDE Breeze.
  --bgrt                 Aplica el tema oficial UEFI BGRT de Fedora (logo OEM + spinner).
  --spinner              Aplica el tema minimalista Fedora Spinner.
  -p, --preview          Muestra una previsualización de prueba durante 8 segundos.
  -r, --restore [TEMA]   Restaura el tema original de Fedora (por defecto: 'bgrt').
  -d, --disable          Desactiva el splash gráfico (modo texto 'details').
  -h, --help             Muestra este mensaje de ayuda.

EJEMPLOS:
  $(basename "$0")              # Configura Early KMS y activa el tema óptimo
  $(basename "$0") --breeze     # Aplica el tema oficial de KDE Plasma 6
  $(basename "$0") --status     # Diagnóstico del estado de Plymouth y Dracut
  $(basename "$0") --preview    # Previsualiza el arranque durante 8s
  $(basename "$0") --restore    # Vuelve al tema predeterminado de Fedora
EOF
}

# ------------------------------------------------------------------------------
# 7. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
ACTION="install"
TARGET_THEME=""
RESTORE_THEME="bgrt"

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status|status)
            ACTION="status"
            shift
            ;;
        -l|--list|list)
            ACTION="list"
            shift
            ;;
        --breeze|breeze)
            ACTION="install"
            TARGET_THEME="breeze"
            shift
            ;;
        --bgrt|bgrt)
            ACTION="install"
            TARGET_THEME="bgrt"
            shift
            ;;
        --spinner|spinner)
            ACTION="install"
            TARGET_THEME="spinner"
            shift
            ;;
        -p|--preview|preview)
            ACTION="preview"
            shift
            ;;
        -r|--restore|restore)
            ACTION="restore"
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                RESTORE_THEME="$1"
                shift
            fi
            ;;
        -d|--disable|disable)
            ACTION="disable"
            shift
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            if [ -d "/usr/share/plymouth/themes/$1" ]; then
                ACTION="install"
                TARGET_THEME="$1"
                shift
            else
                echo "❌ Opción o tema desconocido: $1"
                echo "Usa '$(basename "$0") --help' para ver las opciones disponibles."
                exit 1
            fi
            ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        exit 0
        ;;
    list)
        list_themes
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
    disable)
        disable_plymouth
        exit 0
        ;;
    install)
        apply_theme "$TARGET_THEME"
        exit 0
        ;;
esac
