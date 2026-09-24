#!/usr/bin/env bash
# ==============================================================================
# fingerprint-setup.sh - Autenticación y Desbloqueo por Huella Dactilar (fprintd + PAM)
# Sistema: openSUSE Tumbleweed | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (Sensor Synaptics 06cb:00df)
# ==============================================================================
# Características:
# - Integración oficial y segura en PAM mediante pam-config (--fprintd).
# - Soporte nativo en KDE Plasma 6: KScreenLocker (bloqueo), SDDM (login) y Polkit.
# - Diagnóstico integral del lector USB biométrico y del daemon fprintd por D-Bus.
# - Detección de huellas registradas para el usuario actual.
# - Comandos CLI: --status, --enroll, --verify, --disable, --help.
# - Ejecución rootless para diagnósticos, enrolamiento y verificación.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PERMISOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 2. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
ensure_dependencies() {
    local missing=()
    for pkg in fprintd fprintd-pam; do
        if ! rpm -q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Dependencias biométricas faltantes: ${missing[*]}"
        echo "   Instalando paquetes vía Zypper..."
        require_root
        $SUDO zypper --non-interactive install -y "${missing[@]}"
    else
        echo "  ✅ Paquetes requeridos (fprintd, fprintd-pam) ya están instalados."
    fi
}

# ------------------------------------------------------------------------------
# 3. GESTIÓN DE PAM (pam-config y SDDM)
# ------------------------------------------------------------------------------
SDDM_PAM_FILE="/etc/pam.d/sddm"

configure_sddm_bypass() {
    require_root
    echo "🖥️  Configurando optimización para SDDM (login inmediato con contraseña)..."
    cat <<'EOF' | $SUDO tee "$SDDM_PAM_FILE" >/dev/null
#%PAM-1.0
# Configuración optimizada de SDDM para openSUSE Tumbleweed + KDE Plasma 6
# Evita el retardo de timeout de fprintd (30s) en el inicio de sesión inicial
# y garantiza el desbloqueo automático de KWallet mediante la contraseña.
# (La huella dactilar permanece activa para sudo, kscreenlocker y polkit).

auth     requisite      pam_nologin.so
auth     optional       pam_kwallet5.so
auth     required       pam_unix.so      try_first_pass

account  substack       common-account
account  include        postlogin-account

password substack       common-password
password include        postlogin-password

session  required       pam_loginuid.so
session  optional       pam_keyinit.so   revoke force
session  substack       common-session
session  include        postlogin-session
EOF
    $SUDO chmod 644 "$SDDM_PAM_FILE"
    echo "  ✅ SDDM configurado: Contraseña inmediata sin retardo y auto-desbloqueo de KWallet."
}

remove_sddm_bypass() {
    require_root
    if [ -f "$SDDM_PAM_FILE" ]; then
        echo "🗑️  Restaurando configuración predeterminada de SDDM..."
        $SUDO rm -f "$SDDM_PAM_FILE"
        echo "  ✅ Archivo /etc/pam.d/sddm eliminado (SDDM volverá a usar la configuración global)."
    fi
}

enable_pam() {
    require_root
    echo "🔐 Habilitando módulo de autenticación por huella (pam_fprintd.so) en PAM..."
    
    # Limpiar flag obsoleto --fp si existiera
    if /usr/sbin/pam-config -q --fp &>/dev/null; then
        $SUDO /usr/sbin/pam-config -d --fp 2>/dev/null || true
    fi

    # Habilitar --fprintd de forma oficial
    $SUDO /usr/sbin/pam-config -a --fprintd
    echo "  ✅ Módulo pam_fprintd.so integrado exitosamente en /etc/pam.d/common-auth."

    # Configurar bypass de SDDM para login rápido y KWallet automático
    configure_sddm_bypass
}

disable_pam() {
    require_root
    echo "🔓 Deshabilitando autenticación por huella dactilar en PAM..."
    $SUDO /usr/sbin/pam-config -d --fprintd 2>/dev/null || true
    $SUDO /usr/sbin/pam-config -d --fp 2>/dev/null || true
    remove_sddm_bypass
    echo "  ✅ Autenticación biométrica desactivada de PAM."
}

# ------------------------------------------------------------------------------
# 4. ENROLAMIENTO Y VERIFICACIÓN
# ------------------------------------------------------------------------------
enroll_finger() {
    local finger="${1:-right-index-finger}"
    echo "🖐️  Iniciando registro de huella dactilar para el usuario '$REAL_USER'..."
    echo "   Dedo seleccionado: $finger"
    echo "   (Coloca y levanta tu dedo en el sensor cuando se indique)"
    echo "-----------------------------------------------------------------"
    run_as_user fprintd-enroll -f "$finger" "$REAL_USER"
}

verify_finger() {
    local finger="${1:-}"
    echo "🔍 Probando verificación de huella dactilar en el sensor..."
    echo "   (Coloca tu dedo registrado en el lector biométrico)"
    echo "-----------------------------------------------------------------"
    if [ -n "$finger" ]; then
        run_as_user fprintd-verify -f "$finger" "$REAL_USER"
    else
        run_as_user fprintd-verify "$REAL_USER"
    fi
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO Y ESTADO
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "🔐 ESTADO DE AUTENTICACIÓN POR HUELLA DACTILAR"
    echo "   Sistema: openSUSE Tumbleweed | Entorno: KDE Plasma 6 (Wayland)"
    echo "================================================================="
    echo "👤 Usuario:                $REAL_USER"

    # 1. Detección de hardware USB
    local hw_desc hw_id
    hw_desc=$(lsusb 2>/dev/null | grep -iE "fingerprint|synaptics|fprint|validity|elan|authentec" | sed 's/.*ID [0-9a-f:]* //' | head -n 1)
    hw_id=$(lsusb 2>/dev/null | grep -iE "fingerprint|synaptics|fprint|validity|elan|authentec" | grep -oE "ID [0-9a-f:]*" | head -n 1)
    if [ -n "$hw_desc" ]; then
        echo "💻 Lector Biométrico USB:   ✅ $hw_id $hw_desc"
    else
        echo "💻 Lector Biométrico USB:   ⚠️ No detectado en el bus USB"
    fi

    # 2. Driver libfprint / Daemon fprintd por D-Bus
    local fp_dev
    fp_dev=$(run_as_user fprintd-list "$REAL_USER" 2>&1 || true)
    if echo "$fp_dev" | grep -q "found [1-9]"; then
        local dev_path
        dev_path=$(echo "$fp_dev" | grep "Using device" | sed 's/Using device //')
        echo "🔌 Reconocimiento fprintd:  ✅ Operativo ($dev_path)"
    else
        echo "🔌 Reconocimiento fprintd:  ❌ No reconocido por libfprint"
    fi

    # 3. Paquetes instalados
    local fprintd_ver fprintd_pam_ver
    fprintd_ver=$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' fprintd 2>/dev/null || echo "No instalado")
    fprintd_pam_ver=$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' fprintd-pam 2>/dev/null || echo "No instalado")
    echo "📦 Paquete fprintd:         $fprintd_ver"
    echo "📦 Paquete fprintd-pam:     $fprintd_pam_ver"

    # 4. Estado en PAM
    local pam_status="❌ Inactivo (El sistema NO solicitará huella en login/sudo)"
    if grep -q "pam_fprintd.so" /etc/pam.d/common-auth 2>/dev/null; then
        pam_status="✅ Activo (pam_fprintd.so habilitado en /etc/pam.d/common-auth)"
    fi
    echo "🛡️  Estado de PAM:          $pam_status"

    local sddm_status="⚠️ Predeterminado (Hereda timeout de 30s de fprintd)"
    if [ -f "$SDDM_PAM_FILE" ]; then
        if grep -q "pam_unix.so" "$SDDM_PAM_FILE" && ! grep -q "pam_fprintd" "$SDDM_PAM_FILE"; then
            sddm_status="✅ Optimizado (Contraseña inmediata + KWallet auto-unlock)"
        else
            sddm_status="ℹ️ Personalizado"
        fi
    fi
    echo "🖥️  Login SDDM:            $sddm_status"

    # 5. Huellas registradas para el usuario
    echo "-----------------------------------------------------------------"
    echo "🖐️  Huellas registradas para $REAL_USER:"
    if echo "$fp_dev" | grep -qi "no fingers enrolled"; then
        echo "   ⚠️ Ninguna huella registrada todavía."
    else
        local enrolled
        enrolled=$(echo "$fp_dev" | grep -E "^\s*-\s*#" || true)
        if [ -n "$enrolled" ]; then
            echo "$enrolled" | sed 's/^[[:space:]]*/   ✅ /'
        else
            echo "   ℹ️ No se detectaron registros."
        fi
    fi

    echo "================================================================="
    if ! grep -q "pam_fprintd.so" /etc/pam.d/common-auth 2>/dev/null; then
        echo "💡 PAM no está habilitado. Ejecuta 'just fingerprint' para activarlo."
    fi
    if echo "$fp_dev" | grep -qi "no fingers enrolled"; then
        echo "💡 Para registrar tu huella dactilar:"
        echo "   - Gráficamente: Preferencias del Sistema -> Usuarios -> Configurar huella dactilar"
        echo "   - Por terminal: just fingerprint --enroll (o fprintd-enroll)"
    fi
    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Configuración, diagnóstico y gestión de autenticación biométrica por huella dactilar
(fprintd + PAM + KDE Plasma 6 Wayland) en openSUSE Tumbleweed.

Hardware: HP EliteBook 855 G7 (Sensor Synaptics 06cb:00df)

OPCIONES:
  -s, --status         Muestra el estado detallado del hardware, paquetes, PAM y huellas.
  -e, --enroll [DEDO]  Registra una huella en la terminal (por defecto: right-index-finger).
  -v, --verify [DEDO]  Prueba la verificación en el sensor con las huellas registradas.
  -d, --disable        Deshabilita la autenticación por huella dactilar en PAM.
      --sddm-bypass    Configura SDDM para contraseña inmediata (sin retardo) y desbloqueo de KWallet.
      --sddm-reset     Restaura SDDM a la configuración predeterminada de PAM.
  -h, --help           Muestra esta ayuda.

EJEMPLOS:
  $(basename "$0")                  # Habilita dependencias, PAM y optimización SDDM
  $(basename "$0") --status         # Diagnóstico de sensor, PAM, SDDM y huellas registradas
  $(basename "$0") --enroll         # Registra el índice derecho vía terminal
  $(basename "$0") --verify         # Prueba el lector biométrico
  $(basename "$0") --sddm-bypass    # Aplica optimización de contraseña rápida para SDDM
  $(basename "$0") --disable        # Desactiva la huella de PAM (login/sudo/bloqueo)

DEDOS ADMITIDOS POR fprintd:
  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger
  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger

CONFIGURACIÓN GRÁFICA EN KDE PLASMA 6:
  Preferencias del Sistema -> Usuarios -> (Tu usuario) -> Configurar huella dactilar
EOF
}

# ------------------------------------------------------------------------------
# 6. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
ACTION=""
ARG_PARAM=""

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        -e|--enroll)
            ACTION="enroll"
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                ARG_PARAM="$1"
                shift
            fi
            ;;
        -v|--verify)
            ACTION="verify"
            shift
            if [ $# -gt 0 ] && [[ ! "$1" =~ ^- ]]; then
                ARG_PARAM="$1"
                shift
            fi
            ;;
        -d|--disable)
            ACTION="disable"
            shift
            ;;
        --sddm-bypass)
            ACTION="sddm-bypass"
            shift
            ;;
        --sddm-reset)
            ACTION="sddm-reset"
            shift
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
    enroll)
        enroll_finger "$ARG_PARAM"
        exit 0
        ;;
    verify)
        verify_finger "$ARG_PARAM"
        exit 0
        ;;
    disable)
        disable_pam
        exit 0
        ;;
    sddm-bypass)
        configure_sddm_bypass
        exit 0
        ;;
    sddm-reset)
        remove_sddm_bypass
        exit 0
        ;;
esac

# Flujo por defecto: Verificación e instalación de PAM
echo "================================================================="
echo "🚀 Configurando autenticación por huella dactilar en openSUSE Tumbleweed"
echo "   Entorno: KDE Plasma 6 (Wayland) | Hardware: HP EliteBook 855 G7"
echo "================================================================="

ensure_dependencies
enable_pam

echo "-----------------------------------------------------------------"
echo "✅ Huella dactilar configurada y optimizada en el sistema (PAM + SDDM)."
echo "💡 Siguiente paso (Registro de huellas para $REAL_USER):"
echo "   1. Desde el entorno gráfico KDE Plasma 6:"
echo "      Preferencias del Sistema -> Usuarios -> Configurar huella dactilar"
echo "   2. O directamente desde tu terminal:"
echo "      just fingerprint --enroll"
echo "================================================================="
