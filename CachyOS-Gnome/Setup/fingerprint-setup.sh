#!/usr/bin/env bash
# ==============================================================================
# fingerprint-setup.sh - Configuración de Huella Dactilar en CachyOS (GNOME)
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Sensor ELAN / Synaptics)
# ==============================================================================
# Características:
#   - Autenticación en pantalla de bloqueo y login (GDM y GNOME Shell Wayland)
#   - Autenticación gráfica de administración (PolKit GNOME)
#   - Autenticación en terminal (sudo con PAM pam_fprintd.so)
#   - Gestión de sensores compatibles mediante fprintd
#   - Opciones CLI: --status, --enroll, --verify, --delete, --help
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

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
${BOLD}👆 Configurador de Huella Dactilar (fprintd) - CachyOS (GNOME)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica dependencias, activa servicio fprintd y habilita PAM.
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
    echo "🔍 DIAGNÓSTICO DEL SENSOR BIOMÉTRICO - CACHYOS (GNOME)"
    echo "================================================================="
    echo "• Lector de Huella detectado por hardware (USB):"
    local reader
    reader=$(lsusb 2>/dev/null | grep -iE 'fingerprint|synaptics|elan|goodix|broadcom|authentec' || echo "")
    if [ -n "$reader" ]; then
        echo "  ${GREEN}✅ $reader${NC}"
    else
        echo "  ${YELLOW}⚠️ No se detectó un lector biométrico reconocido por USB.${NC}"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Paquetes y Servicio fprintd:"
    echo "  - fprintd:          $(if pacman -Q fprintd &>/dev/null; then echo "${GREEN}✅ Instalado${NC}"; else echo "${RED}❌ No instalado${NC}"; fi)"
    echo "  - Servicio fprintd: $(systemctl is-active fprintd 2>/dev/null && echo "${GREEN}Activo${NC}" || echo "${YELLOW}Bajo demanda (D-Bus)${NC}")"

    echo "-----------------------------------------------------------------"
    echo "• Integración PAM en Arch / CachyOS:"
    if grep -q "pam_fprintd.so" /etc/pam.d/system-auth 2>/dev/null; then
        echo "  - system-auth:      ${GREEN}✅ pam_fprintd.so configurado${NC}"
    else
        echo "  - system-auth:      ${YELLOW}⚠️ pam_fprintd.so no presente (GNOME usa D-Bus)${NC}"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Huellas registradas para el usuario '$REAL_USER':"
    if command -v fprintd-list &>/dev/null; then
        run_as_user fprintd-list "$REAL_USER" 2>&1 || true
    else
        echo "  ${RED}❌ Herramienta fprintd-list no disponible.${NC}"
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
    echo "👆 CONFIGURANDO SOPORTE DE HUELLA DACTILAR EN CACHYOS"
    echo "================================================================="

    if ! pacman -Q fprintd &>/dev/null; then
        echo "📦 Instalando paquete fprintd con pacman..."
        $SUDO pacman -S --needed --noconfirm fprintd
    else
        echo "✅ Paquete fprintd ya está instalado."
    fi

    echo "⚡ Habilitando servicio fprintd.service..."
    $SUDO systemctl enable --now fprintd.service 2>/dev/null || true

    # Configuración opcional segura de PAM en system-auth si no existe
    PAM_AUTH="/etc/pam.d/system-auth"
    if [ -f "$PAM_AUTH" ] && ! grep -q "pam_fprintd.so" "$PAM_AUTH"; then
        echo "⚡ Configurando PAM system-auth para fprintd..."
        $SUDO sed -i '/auth.*pam_unix.so/i auth [success=1 default=ignore] pam_fprintd.so max-tries=2 timeout=10' "$PAM_AUTH" 2>/dev/null || true
    fi

    echo ""
    show_status
    echo "================================================================="
    echo "✅ Huella dactilar configurada en CachyOS."
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
        exit 0
        ;;
    *)
        echo "❌ Opción desconocida: $1"
        show_help
        exit 1
        ;;
esac
