#!/usr/bin/env bash
# ==============================================================================
# plymouth-setup.sh - Administrador de Splash Screen (Plymouth) y Early KMS
# Sistema: Fedora 44 Workstation | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7 / Btrfs)
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

# Detectar modo UEFI
IS_UEFI=false
if [ -d "/sys/firmware/efi" ]; then
    IS_UEFI=true
fi

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 1. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
ensure_plymouth_installed() {
    echo "ℹ️ Verificando e instalando Plymouth y temas oficiales vía DNF5..."
    $SUDO dnf5 install -y \
        plymouth \
        plymouth-plugin-two-step \
        plymouth-theme-spinner \
        plymouth-theme-breeze \
        plymouth-kcm \
        plymouth-system-theme 2>/dev/null || $SUDO dnf5 install -y plymouth plymouth-theme-spinner plymouth-theme-breeze 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# 2. OPTIMIZACIÓN AMDGPU EARLY KMS (Dracut - Arranque sin parpadeos)
# ------------------------------------------------------------------------------
configure_early_kms() {
    echo "⚡ Verificando Early KMS para tarjeta gráfica AMD Radeon Vega..."
    local DRACUT_CONF="/etc/dracut.conf.d/amdgpu.conf"
    if [ ! -f "$DRACUT_CONF" ] || ! grep -q "amdgpu" "$DRACUT_CONF"; then
        echo "   Añadiendo módulo 'amdgpu' en $DRACUT_CONF para inicio nativo sin parpadeos..."
        $SUDO mkdir -p /etc/dracut.conf.d/
        echo 'force_drivers+=" amdgpu "' | $SUDO tee "$DRACUT_CONF" >/dev/null
        echo "  ✅ Módulo amdgpu configurado en dracut."
    else
        echo "  ✅ Módulo 'amdgpu' ya presente en dracut ($DRACUT_CONF)."
    fi
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN DE PARÁMETROS DEL KERNEL
# ------------------------------------------------------------------------------
verify_grub_splash() {
    echo "🔍 Comprobando parámetros del kernel en GRUB..."
    local GRUB_FILE="/etc/default/grub"
    if [ -f "$GRUB_FILE" ]; then
        if grep -q "quiet" "$GRUB_FILE" && grep -q "rhgb" "$GRUB_FILE"; then
            echo "  ✅ Parámetros 'quiet rhgb' activos en $GRUB_FILE."
        elif grep -q "splash" "$GRUB_FILE"; then
            echo "  ✅ Parámetro 'splash' activo en $GRUB_FILE."
        else
            echo "  ⚠️ Advertencia: 'rhgb quiet' o 'splash' no parecen estar activos en $GRUB_FILE."
        fi
    fi
}

list_themes() {
    ensure_plymouth_installed
    echo "================================================================="
    echo "🎨 TEMAS PLYMOUTH INSTALADOS EN FEDORA 44"
    echo "================================================================="
    plymouth-set-default-theme --list 2>/dev/null || ls -1 /usr/share/plymouth/themes/
    echo "-----------------------------------------------------------------"
    echo "💡 Tema activo actual: $(plymouth-set-default-theme 2>/dev/null || echo 'desconocido')"
    echo "================================================================="
}

preview_theme() {
    ensure_plymouth_installed
    echo "👁️ Iniciando previsualización de Plymouth durante 8 segundos..."
    $SUDO plymouthd 2>/dev/null || true
    $SUDO plymouth --show-splash
    for ((i=0; i<8; i++)); do
        sleep 1
    done
    $SUDO plymouth --quit
    echo "✅ Previsualización finalizada."
}

apply_theme() {
    local target_theme="$1"
    ensure_plymouth_installed
    configure_early_kms

    echo "⚙️ Configurando tema Plymouth: '$target_theme'..."
    $SUDO plymouth-set-default-theme -R "$target_theme" 2>/dev/null || {
        $SUDO plymouth-set-default-theme "$target_theme"
        echo "🔄 Regenerando initramfs con Dracut..."
        $SUDO dracut -f
    }

    echo "================================================================="
    echo "✅ Tema Plymouth '$target_theme' activado con éxito en Fedora 44."
    echo "================================================================="
}

disable_plymouth() {
    ensure_plymouth_installed
    echo "⚙️ Desactivando splash gráfico de Plymouth (estableciendo tema 'details')..."
    $SUDO plymouth-set-default-theme -R details 2>/dev/null || {
        $SUDO plymouth-set-default-theme details
        echo "🔄 Regenerando initramfs con Dracut..."
        $SUDO dracut -f
    }
    echo "================================================================="
    echo "✅ Splash gráfico desactivado. El arranque mostrará los mensajes del kernel/systemd."
    echo "================================================================="
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE PLYMOUTH Y SPLASH SCREEN - FEDORA 44"
    echo "================================================================="
    echo "• Plymouth instalado:       $(if is_pkg_installed plymouth; then echo "✅ Sí"; else echo "❌ No instalado"; fi)"
    echo "• Tema activo:              $(plymouth-set-default-theme 2>/dev/null || echo 'No configurado')"
    echo "• Early KMS Dracut (AMD):   $(if [ -f /etc/dracut.conf.d/amdgpu.conf ] && grep -q "amdgpu" /etc/dracut.conf.d/amdgpu.conf; then echo "✅ Configurado (/etc/dracut.conf.d/amdgpu.conf)"; else echo "❌ No configurado"; fi)"
    echo "• Modo Firmware:            $(if [ "$IS_UEFI" = true ]; then echo "✅ UEFI"; else echo "ℹ️ Legacy BIOS"; fi)"
    verify_grub_splash
    echo "================================================================="
}

show_help() {
    cat <<EOF
🎨 Administrador de Splash Screen (Plymouth) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN] [TEMA]

Opciones:
  (sin argumentos)    Instala dependencias, configura Early KMS y activa el tema recomendado (breeze/bgrt/spinner).
  --status, -s        Muestra diagnóstico del estado de Plymouth, tema activo y Early KMS.
  --list, -l          Lista todos los temas instalados en el sistema.
  --preview, -p       Previsualiza el splash screen en pantalla completa durante 8 segundos.
  --disable, -d       Desactiva el splash gráfico (modo de depuración 'details').
  --help, -h          Muestra este mensaje de ayuda.
  <nombre_tema>       Aplica e integra en Dracut un tema específico (ej: breeze, spinner, bgrt).
EOF
}

# ------------------------------------------------------------------------------
# DESPACHADOR DE COMANDOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --list|-l|list)
        list_themes
        exit 0
        ;;
    --preview|-p|preview)
        preview_theme
        exit 0
        ;;
    --disable|-d|disable)
        disable_plymouth
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        if [ -d "/usr/share/plymouth/themes/breeze" ]; then
            apply_theme "breeze"
        elif [ "$IS_UEFI" = true ] && [ -d "/usr/share/plymouth/themes/bgrt" ]; then
            apply_theme "bgrt"
        else
            apply_theme "spinner"
        fi
        ;;
    *)
        apply_theme "$1"
        ;;
esac
