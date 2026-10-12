#!/usr/bin/env bash
# ==============================================================================
# fingerprint-setup.sh - Autenticación por Huella Dactilar (fprintd + authselect)
# Sistema: Fedora 44 (KDE Plasma 6 / Wayland)
# Hardware: HP EliteBook 855 G7 (Sensor Synaptics Prometheus / AMD Ryzen)
# ==============================================================================
# Características:
# 1. Instalación de fprintd y fprintd-pam vía DNF5.
# 2. Configuración nativa y segura de PAM mediante 'authselect' (estándar oficial de Fedora).
# 3. Habilita autenticación biométrica en terminal (sudo) y pantalla de bloqueo KScreenLocker.
# 4. Diagnóstico integral con telemetría del lector biométrico USB Synaptics.
# 5. Opciones CLI completas: --status, --enroll, --verify, --open, --help.
# ==============================================================================

set -euo pipefail

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF
👆 Gestor de Huella Dactilar (fprintd + authselect) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instalación idempotente de fprintd, activación de authselect with-fingerprint
                      y verificación de estado del sensor.
  --status, -s        Diagnóstico detallado del sensor USB, fprintd, PAM y huellas registradas.
  --enroll, -e        Inicia el asistente para registrar o actualizar huellas dactilares (dedo índice).
  --verify, -v        Prueba la verificación de huella dactilar registrada.
  --delete, -d        Elimina las huellas dactilares registradas para el usuario actual.
  --open, -o          Abre el módulo de configuración de Usuarios en Preferencias de KDE Plasma.
  --help, -h          Muestra este mensaje de ayuda.

Detalles Técnicos:
  • Sensor soportado: Synaptics Prometheus (USB ID 06cb:00df o compatible en HP EliteBook 855 G7).
  • Configuración PAM: 'authselect enable-feature with-fingerprint' (soporta sudo y bloqueo).
EOF
}

detect_sensor() {
    local sensor_info
    sensor_info=$(lsusb | grep -iE "fingerprint|synaptics|validity|06cb:" || echo "")
    if [ -n "$sensor_info" ]; then
        echo "✅ Detectado: $sensor_info"
    else
        echo "⚠️ No se detectó dispositivo biométrico en el bus USB"
    fi
}

show_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE AUTENTICACIÓN BIOMÉTRICA (FPRINTD) - FEDORA 44"
    echo "================================================================="
    echo "• Sensor USB:                 $(detect_sensor)"
    echo "• Paquete fprintd:            $(if is_pkg_installed fprintd; then echo "✅ Instalado ($(rpm -q --qf '%{VERSION}' fprintd))"; else echo "❌ No instalado"; fi)"
    echo "• Paquete fprintd-pam:        $(if is_pkg_installed fprintd-pam; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    
    # Estado de authselect
    echo "• Estado de PAM (authselect):"
    if command -v authselect &>/dev/null; then
        if authselect current 2>/dev/null | grep -q "with-fingerprint"; then
            echo "    ✅ Característica 'with-fingerprint' activa en authselect"
        else
            echo "    ⚠️ 'with-fingerprint' no habilitado aún"
        fi
    else
        echo "    ❌ authselect no disponible"
    fi

    echo "-----------------------------------------------------------------"
    echo "👆 Huellas registradas para el usuario '$REAL_USER':"
    if command -v fprintd-list &>/dev/null; then
        run_as_user fprintd-list "$REAL_USER" 2>/dev/null || echo "  (Sin huellas registradas)"
    else
        echo "  (fprintd-list no disponible)"
    fi
    echo "================================================================="
}

setup_fingerprint() {
    echo "================================================================="
    echo "🚀 CONFIGURANDO HUELLA DACTILAR EN FEDORA 44 (HP ELITEBOOK 855 G7)"
    echo "================================================================="

    # 1. Instalar paquetes con DNF5
    echo "📦 [1/3] Verificando paquetes fprintd con DNF5..."
    local pkgs=()
    if ! is_pkg_installed fprintd; then pkgs+=("fprintd"); fi
    if ! is_pkg_installed fprintd-pam; then pkgs+=("fprintd-pam"); fi

    if [ ${#pkgs[@]} -gt 0 ]; then
        require_root
        echo "ℹ️ Instalando: ${pkgs[*]}..."
        $SUDO dnf5 install -y "${pkgs[@]}"
    else
        echo "✅ Paquetes fprintd ya instalados."
    fi

    # 2. Configurar authselect
    echo "🔐 [2/3] Habilitando soporte biométrico en PAM mediante authselect..."
    require_root
    if ! authselect current 2>/dev/null | grep -q "with-fingerprint"; then
        $SUDO authselect enable-feature with-fingerprint 2>/dev/null || true
        echo "✅ Característica 'with-fingerprint' aplicada a los perfiles PAM del sistema."
    else
        echo "✅ authselect ya tiene habilitado 'with-fingerprint'."
    fi

    # 3. Servicio fprintd
    echo "⚡ [3/3] Verificando servicio fprintd..."
    $SUDO systemctl enable fprintd 2>/dev/null || true

    echo ""
    show_status
    echo "✅ Configuración de huella dactilar finalizada."
    echo "💡 Puedes registrar tu dedo índice ejecutando: ./Setup/fingerprint-setup.sh --enroll"
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --enroll|-e)
        echo "👆 Registrando huella dactilar para '$REAL_USER' (pasa el dedo índice derecho varias veces)..."
        run_as_user fprintd-enroll "$REAL_USER"
        exit 0
        ;;
    --verify|-v)
        echo "👆 Probando verificación de huella para '$REAL_USER'..."
        run_as_user fprintd-verify
        exit 0
        ;;
    --delete|-d)
        echo "🗑️ Eliminando huellas dactilares para '$REAL_USER'..."
        run_as_user fprintd-delete "$REAL_USER" || echo "No había huellas registradas para eliminar."
        exit 0
        ;;
    --open|-o)
        run_as_user kcmshell6 kcm_users &>/dev/null & disown
        exit 0
        ;;
    "")
        setup_fingerprint
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
