#!/bin/bash
# =============================================================================
# fingerprint-setup.sh - Configuración de Huella Dactilar en Kubuntu (Plasma 6)
# =============================================================================
# Optimizado para:
#   - Autenticación en pantalla de bloqueo (KScreenLocker / SDDM)
#   - Autenticación gráfica de administración (PolKit / KDE)
#   - Autenticación en terminal (sudo)
#   - Gestión de sensores Synaptics, Elan, Goodix, etc. mediante fprintd
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
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

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
Configurador de Huella Dactilar (fprintd) - Kubuntu (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala dependencias, habilita PAM y permite registrar huellas.
  --status, -s           Muestra el estado del lector de huellas y huellas registradas.
  --enroll [DEDO]        Registra una huella (ej: right-index-finger, right-thumb).
  --verify               Prueba la verificación de la huella registrada.
  --delete               Elimina las huellas registradas del usuario actual.
  --help, -h             Muestra esta ayuda.

Dedos disponibles para --enroll:
  right-thumb, right-index-finger (por defecto), right-middle-finger, right-ring-finger, right-little-finger
  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE HUELLA DACTILAR - KUBUNTU"
    echo "================================================================="
    echo "Servicio fprintd:              $(systemctl is-active --quiet fprintd.service 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "Lector detectado en USB:"
    if lsusb 2>/dev/null | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan|goodix" >/dev/null 2>&1; then
        lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan|goodix"
    else
        echo "  (No se detectó ningún lector por lsusb)"
    fi
    echo "-----------------------------------------------------------------"
    echo "Dispositivo en fprintd y huellas para '$REAL_USER':"
    run_as_user fprintd-list "$REAL_USER" 2>/dev/null || echo "  (Sin lector compatible activo o sin huellas registradas)"
    echo "================================================================="
    echo "💡 Puedes administrar tus huellas también desde KDE Plasma en:"
    echo "   'Preferencias del Sistema -> Usuarios -> Huella Dactilar'"
}

install_packages_and_pam() {
    echo "ℹ️ [1/3] Instalando paquetes fprintd y libpam-fprintd..."
    $SUDO apt update
    $SUDO apt install -y fprintd libpam-fprintd

    echo "ℹ️ [2/3] Habilitando servicio fprintd..."
    $SUDO systemctl enable --now fprintd.service 2>/dev/null || true

    echo "ℹ️ [3/3] Configurando integración PAM (pam-auth-update)..."
    # Configuración oficial de PAM para Ubuntu/Kubuntu (aplica a sudo, polkit, SDDM y kscreenlocker)
    if command -v pam-auth-update &> /dev/null; then
        $SUDO pam-auth-update --enable fprintd 2>/dev/null || true
    fi

    echo "✅ Integración de PAM y fprintd configurada correctamente."
}

enroll_finger() {
    local FINGER="${1:-right-index-finger}"
    echo "================================================================="
    echo "REGISTRO DE HUELLA DACTILAR ($FINGER) PARA '$REAL_USER'"
    echo "================================================================="
    echo "👆 Coloca y levanta el dedo varias veces sobre el sensor cuando se indique..."
    echo ""
    run_as_user fprintd-enroll --finger "$FINGER" || {
        echo ""
        echo "⚠️ El registro no se completó."
        echo "💡 También puedes registrar tu huella gráficamente en:"
        echo "   Preferencias del Sistema -> Usuarios -> Huella Dactilar"
        return 1
    }
    echo "✅ Huella registrada con éxito."
}

verify_finger() {
    echo "================================================================="
    echo "VERIFICANDO HUELLA DACTILAR PARA '$REAL_USER'"
    echo "================================================================="
    echo "👆 Coloca tu dedo registrado sobre el sensor..."
    run_as_user fprintd-verify || echo "❌ Verificación fallida."
}

delete_fingers() {
    echo "================================================================="
    echo "ELIMINANDO HUELLAS DACTILARES DE '$REAL_USER'"
    echo "================================================================="
    run_as_user fprintd-delete "$REAL_USER" || true
    echo "✅ Huellas eliminadas."
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
    --enroll)
        shift
        FINGER_NAME="${1:-right-index-finger}"
        enroll_finger "$FINGER_NAME"
        ;;
    --verify)
        verify_finger
        ;;
    --delete)
        delete_fingers
        ;;
    "")
        echo "================================================================="
        echo "CONFIGURACIÓN DE HUELLA DACTILAR (FPRINTD) - KUBUNTU (PLASMA 6)"
        echo "================================================================="
        install_packages_and_pam
        echo ""
        show_status
        echo ""
        read -rp "¿Deseas registrar tu huella dactilar ahora mismo? (S/n): " REG_PROMPT || true
        REG_PROMPT="${REG_PROMPT:-s}"
        if [[ "$REG_PROMPT" =~ ^[Ss]$ ]]; then
            enroll_finger "right-index-finger"
        fi
        echo ""
        echo "================================================================="
        echo "✅ Configuración de huella dactilar completada."
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
