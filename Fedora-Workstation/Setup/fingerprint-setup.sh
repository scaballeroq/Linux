#!/usr/bin/env bash
# ==============================================================================
# fingerprint-setup.sh - Configuración de Huella Dactilar en Fedora (GNOME)
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Sensor Synaptics)
# ==============================================================================
# Características:
#   - Autenticación en pantalla de bloqueo y login (GDM y GNOME Shell)
#   - Autenticación gráfica de administración (PolKit GNOME)
#   - Autenticación en terminal (sudo con authselect PAM)
#   - Gestión de sensores compatibles mediante fprintd y fprintd-pam
#   - Opciones CLI: --status, --enroll, --verify, --delete, --help
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

if command -v dnf5 &>/dev/null; then
    DNF_CMD="dnf5"
else
    DNF_CMD="dnf"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
👆 Configurador de Huella Dactilar (fprintd) - Fedora Workstation (GNOME)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica dependencias, activa servicio fprintd y habilita PAM vía authselect.
  --status, -s        Muestra diagnóstico del lector biométrico, fprintd, PAM y huellas registradas.
  --enroll [DEDO]     Registra una nueva huella dactilar (por defecto: right-index-finger).
  --verify            Verifica una huella dactilar previamente registrada en el sensor.
  --delete            Elimina todas las huellas dactilares registradas del usuario.
  --help, -h          Muestra este mensaje de ayuda.

Dedos admitidos:
  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger
  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DEL SENSOR BIOMÉTRICO - FEDORA WORKSTATION"
    echo "================================================================="
    echo "• Lector de Huella detectado por hardware (USB):"
    local reader
    reader=$(lsusb 2>/dev/null | grep -iE 'fingerprint|synaptics|elan|goodix|broadcom|authentec' || echo "")
    if [ -n "$reader" ]; then
        echo "  ✅ $reader"
    else
        echo "  ⚠️ No se detectó un lector biométrico reconocido por USB."
    fi

    echo "-----------------------------------------------------------------"
    echo "• Paquetes y Servicio fprintd:"
    echo "  - fprintd:          $(if rpm -q fprintd &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - fprintd-pam:      $(if rpm -q fprintd-pam &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Servicio fprintd: $(systemctl is-active fprintd 2>/dev/null || echo "inactivo / bajo demanda")"

    echo "-----------------------------------------------------------------"
    echo "• Integración PAM (authselect):"
    if command -v authselect &>/dev/null; then
        local auth_features
        auth_features=$(authselect check 2>/dev/null || echo "")
        if authselect current 2>/dev/null | grep -q "with-fingerprint"; then
            echo "  - authselect:       ✅ with-fingerprint activo"
        else
            echo "  - authselect:       ⚠️ with-fingerprint no habilitado"
        fi
    fi

    echo "-----------------------------------------------------------------"
    echo "• Huellas registradas para el usuario '$REAL_USER':"
    if command -v fprintd-list &>/dev/null; then
        run_as_user fprintd-list "$REAL_USER" 2>&1 || true
    else
        echo "  ❌ Herramienta fprintd-list no disponible."
    fi
    echo "================================================================="
}

enroll_finger() {
    local finger="${1:-right-index-finger}"
    echo "👆 Registrando huella ($finger) para el usuario '$REAL_USER'..."
    echo "Coloca tu dedo en el sensor repetidamente cuando se te indique:"
    run_as_user fprintd-enroll -f "$finger" "$REAL_USER"
    echo "✅ Huella registrada con éxito."
}

verify_finger() {
    echo "👆 Verificando huella dactilar para el usuario '$REAL_USER'..."
    echo "Coloca el dedo registrado en el lector:"
    run_as_user fprintd-verify "$REAL_USER"
}

delete_fingers() {
    echo "🗑️ Eliminando huellas registradas para el usuario '$REAL_USER'..."
    run_as_user fprintd-delete "$REAL_USER" || true
    echo "✅ Huellas eliminadas."
}

setup_system() {
    echo "================================================================="
    echo "👆 CONFIGURANDO SOPORTE DE HUELLA DACTILAR EN FEDORA WORKSTATION"
    echo "================================================================="
    local missing=()
    for pkg in fprintd fprintd-pam; do
        if ! rpm -q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Instalando paquetes requeridos con $DNF_CMD: ${missing[*]}..."
        $SUDO $DNF_CMD install -y "${missing[@]}"
    else
        echo "✅ Paquetes fprintd y fprintd-pam ya están instalados."
    fi

    echo "⚡ Habilitando característica biométrica en authselect..."
    if command -v authselect &>/dev/null; then
        $SUDO authselect enable-feature with-fingerprint 2>/dev/null || true
    fi

    echo "⚡ Iniciando y habilitando fprintd.service..."
    $SUDO systemctl enable --now fprintd.service 2>/dev/null || true

    echo ""
    show_status
    echo "================================================================="
    echo "✅ Huella dactilar configurada en PAM y sistema."
    echo "💡 Para registrar tu dedo índice derecho ahora, ejecuta:"
    echo "   $0 --enroll"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --enroll)
        enroll_finger "${2:-right-index-finger}"
        exit 0
        ;;
    --verify)
        verify_finger
        exit 0
        ;;
    --delete)
        delete_fingers
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        setup_system
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
