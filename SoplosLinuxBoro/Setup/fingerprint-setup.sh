#!/bin/bash
# =============================================================================
# fingerprint-setup.sh - Configuración de Huella Dactilar en Soplos Linux Boro (GNOME)
# Optimizado para HP ProBook 455 G10 (Sensor Synaptics / fprintd)
# =============================================================================
# Características:
#   - Autenticación en pantalla de bloqueo (GDM y GNOME Shell)
#   - Autenticación gráfica de administración (PolKit GNOME)
#   - Autenticación en terminal (sudo con PAM)
#   - Gestión de sensores compatibles mediante fprintd
#   - Opciones CLI: --status, --enroll, --verify, --delete, --help
# =============================================================================

set -euo pipefail

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

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
👆 Configurador de Huella Dactilar (fprintd) - Soplos Linux Boro Workstation (GNOME)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala dependencias, habilita PAM e inicia el asistente de registro.
  --status, -s           Muestra el estado del lector y las huellas registradas.
  --enroll [DEDO]        Registra una huella (por defecto: right-index-finger).
  --verify [DEDO]        Prueba la verificación de la huella en el lector.
  --delete               Elimina las huellas registradas del usuario actual.
  --help, -h             Muestra este mensaje de ayuda.

Dedos disponibles para --enroll:
  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger
  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE HUELLA DACTILAR - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="
    echo "• Servicio fprintd:            $(systemctl is-active --quiet fprintd.service 2>/dev/null && echo '✅ Activo' || echo '❌ Inactivo')"
    echo "• Lector detectado por USB:"
    if lsusb 2>/dev/null | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan|goodix" >/dev/null 2>&1; then
        lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan|goodix" | sed 's/^/    /'
    else
        echo "    (No se detectó ningún lector por lsusb)"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Huellas registradas para '$REAL_USER':"
    run_as_user fprintd-list "$REAL_USER" 2>/dev/null || echo "    (Sin huellas registradas o fprintd no inicializado)"
    echo "================================================================="
    echo "💡 Puedes administrar tus huellas también desde GNOME en:"
    echo "   'Configuración -> Sistema -> Usuarios -> Inicio de sesión con huella'"
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
        FINGER="${2:-right-index-finger}"
        echo "👆 Registrando huella: $FINGER para $REAL_USER..."
        echo "💡 Coloca y levanta tu dedo sobre el sensor repetidamente cuando la luz parpadee."
        run_as_user fprintd-enroll -f "$FINGER" "$REAL_USER"
        exit 0
        ;;
    --verify)
        FINGER="${2:-right-index-finger}"
        echo "🔍 Verificando huella: $FINGER..."
        run_as_user fprintd-verify -f "$FINGER" "$REAL_USER"
        exit 0
        ;;
    --delete)
        echo "🗑️ Eliminando huellas de $REAL_USER..."
        run_as_user fprintd-delete "$REAL_USER"
        echo "✅ Huellas eliminadas."
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac

echo "================================================================="
echo "👆 CONFIGURANDO HUELLA DACTILAR (FPRINTD) - SOPLOS LINUX BORO WORKSTATION"
echo "================================================================="

# 1. Instalar paquetes de fprintd
echo "ℹ️ [1/3] Instalando fprintd y módulo PAM..."
$SUDO apt update
$SUDO apt install -y fprintd libpam-fprintd

# 2. Habilitar servicio fprintd
echo "ℹ️ [2/3] Habilitando servicio fprintd..."
$SUDO systemctl enable --now fprintd.service 2>/dev/null || true

# 3. Habilitar PAM si procede
echo "ℹ️ [3/3] Habilitando autenticación biométrica en PAM (pam-auth-update)..."
$SUDO pam-auth-update --enable fprintd 2>/dev/null || true

echo ""
echo "================================================================="
echo "✅ Huella dactilar configurada en Soplos Linux Boro."
echo "💡 Para registrar tu dedo índice derecho ahora, ejecuta:"
echo "   ./Setup/fingerprint-setup.sh --enroll right-index-finger"
echo "================================================================="
