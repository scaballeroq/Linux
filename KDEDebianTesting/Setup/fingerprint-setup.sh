#!/usr/bin/env bash
# ==============================================================================
# fingerprint-setup.sh - Autenticación y Desbloqueo por Huella Dactilar (fprintd + PAM)
# Sistema: Debian Testing (forky/sid) | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U, Sensor Synaptics 06cb:00df)
# ==============================================================================
# Características de la Arquitectura:
# 1. SDDM (Login inicial al arrancar):
#    - Exclusivamente por contraseña (evita retardo de timeout de fprintd).
#    - Garantiza el auto-desbloqueo inmediato del cofre de claves (KWallet / kdewallet)
#      al iniciar la sesión de Plasma.
#    - Preserva íntegramente la sesión de systemd-logind, límites, keyring y entorno.
# 2. KDE Plasma 6 KScreenLocker (Pantalla de bloqueo):
#    - Doble autenticador paralelo/concurrente:
#      * /etc/pam.d/kde: Autenticador interactivo de contraseña (inmediato, sin trabas).
#      * /etc/pam.d/kde-fingerprint: Autenticador biométrico en segundo plano.
#    - Huella y contraseña disponibles SIMULTÁNEAMENTE en todo momento.
# 3. Terminal (sudo) y Polkit (Ventanas de autorización KDE):
#    - Pide huella dactilar primero con fallback transparente a contraseña.
# 4. Diagnóstico integral con telemetría del lector biométrico USB Synaptics.
# 5. Soporte para registro por CLI (fprintd-enroll) o GUI (kcmshell6 kcm_users).
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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

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

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

is_pkg_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

# ------------------------------------------------------------------------------
# 2. CONSTANTES DE ARCHIVOS PAM
# ------------------------------------------------------------------------------
SDDM_PAM_FILE="/etc/pam.d/sddm"
SDDM_PAM_BACKUP="/etc/pam.d/sddm.orig"

KDE_PAM_FILE="/etc/pam.d/kde"
KDE_PAM_BACKUP="/etc/pam.d/kde.orig"

KDE_FP_PAM_FILE="/etc/pam.d/kde-fingerprint"
COMMON_AUTH_FILE="/etc/pam.d/common-auth"

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS
# ------------------------------------------------------------------------------
ensure_dependencies() {
    local missing=()
    for pkg in fprintd libpam-fprintd; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Dependencias biométricas faltantes: ${missing[*]}"
        echo "   Instalando paquetes vía APT..."
        require_root
        export DEBIAN_FRONTEND=noninteractive
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${missing[@]}"
        $SUDO systemctl enable --now fprintd.service 2>/dev/null || true
    else
        echo "  ✅ Paquetes requeridos (fprintd, libpam-fprintd) instalados."
    fi

    # Asegurar que el servicio de fprintd esté activo
    if systemctl is-enabled fprintd.service &>/dev/null; then
        $SUDO systemctl start fprintd.service 2>/dev/null || true
    else
        require_root
        $SUDO systemctl enable --now fprintd.service 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 4. CONFIGURACIÓN DE SDDM (LOGIN EXCLUSIVO POR CONTRASEÑA / KWALLET UNLOCK)
# ------------------------------------------------------------------------------
configure_sddm_bypass() {
    require_root
    echo "🖥️  Configurando SDDM (autenticación obligatoria por contraseña para auto-desbloqueo de KWallet)..."

    # Crear respaldo si aún no existe
    if [ -f "$SDDM_PAM_FILE" ] && [ ! -f "$SDDM_PAM_BACKUP" ]; then
        $SUDO cp -p "$SDDM_PAM_FILE" "$SDDM_PAM_BACKUP"
        echo "   💾 Copia de respaldo guardada en $SDDM_PAM_BACKUP"
    fi

    cat <<'EOF' | $SUDO tee "$SDDM_PAM_FILE" >/dev/null
#%PAM-1.0
# Configuración optimizada de SDDM para Debian Testing + KDE Plasma 6
# Hardware: HP EliteBook 855 G7
#
# Propósito:
# 1. Login inicial obligatorio por contraseña para desbloquear automáticamente KWallet (kdewallet).
# 2. Evita retrasos y timeouts de fprintd en la pantalla de inicio de sesión.
# 3. Preserva íntegramente la sesión de systemd-logind, límites, keyring y variables de entorno.

# Control de acceso inicial
auth     requisite      pam_nologin.so
auth     required       pam_succeed_if.so user != root quiet_success

# Autenticación exclusiva por contraseña (pasa PAM_AUTHTOK a pam_kwallet5)
auth     [success=1 default=ignore] pam_unix.so nullok try_first_pass
auth     requisite                  pam_deny.so
auth     required                   pam_permit.so
-auth    optional                   pam_gnome_keyring.so
-auth    optional                   pam_kwallet5.so

@include common-account

# Gestión de contexto SELinux, UID de login, keyring y límites del sistema
session  [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session  required       pam_loginuid.so
session  [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
session  optional       pam_keyinit.so force revoke
session  required       pam_limits.so

@include common-session

@include common-password

# Carga de variables de entorno de sesión
session  required       pam_env.so
session  required       pam_env.so envfile=/etc/default/locale user_readenv=1
EOF
    $SUDO chmod 644 "$SDDM_PAM_FILE"
    echo "  ✅ SDDM configurado: Contraseña inmediata en inicio y cofre KWallet auto-desbloqueado."
}

remove_sddm_bypass() {
    require_root
    echo "🗑️  Restaurando configuración predeterminada de SDDM..."
    if [ -f "$SDDM_PAM_BACKUP" ]; then
        $SUDO cp -p "$SDDM_PAM_BACKUP" "$SDDM_PAM_FILE"
        echo "  ✅ Archivo /etc/pam.d/sddm restaurado desde la copia de respaldo."
    else
        cat <<'EOF' | $SUDO tee "$SDDM_PAM_FILE" >/dev/null
#%PAM-1.0
auth    requisite       pam_nologin.so
auth    required        pam_succeed_if.so user != root quiet_success
@include common-auth
-auth   optional        pam_gnome_keyring.so
-auth   optional        pam_kwallet5.so
@include common-account
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session required        pam_loginuid.so
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
session optional        pam_keyinit.so force revoke
session required        pam_limits.so
@include common-session
@include common-password
session required        pam_env.so
session required        pam_env.so envfile=/etc/default/locale user_readenv=1
EOF
        $SUDO chmod 644 "$SDDM_PAM_FILE"
        echo "  ✅ Archivo /etc/pam.d/sddm reconfigurado al estándar de Debian."
    fi
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN DE KSCREENLOCKER (HUELLA Y CONTRASEÑA CONCURRENTES)
# ------------------------------------------------------------------------------
configure_kde_lockscreen() {
    require_root
    echo "🔒 Configurando pantalla de bloqueo (KScreenLocker: huella y contraseña simultáneas)..."

    # Respaldar archivo original de kde si no existe respaldo previo
    if [ -f "$KDE_PAM_FILE" ] && [ ! -f "$KDE_PAM_BACKUP" ]; then
        $SUDO cp -p "$KDE_PAM_FILE" "$KDE_PAM_BACKUP"
        echo "   💾 Copia de respaldo guardada en $KDE_PAM_BACKUP"
    fi

    # Configurar /etc/pam.d/kde para autenticación directa por contraseña
    # (El autenticador no interactivo kscreenlocker ejecutará concurrentemente /etc/pam.d/kde-fingerprint)
    cat <<'EOF' | $SUDO tee "$KDE_PAM_FILE" >/dev/null
#%PAM-1.0
# KDE Plasma 6 KScreenLocker - Servicio de Contraseña (Interactivo)
# Configuración optimizada para doble autenticador concurrente:
# - Este archivo gestiona el campo de contraseña inmediatamente sin bloquearse por fprintd.
# - El sensor de huella dactilar opera concurrentemente mediante /etc/pam.d/kde-fingerprint.

auth     requisite       pam_nologin.so
auth     required        pam_succeed_if.so user != root quiet_success

# Autenticación directa por contraseña para KScreenLocker
auth     [success=1 default=ignore] pam_unix.so nullok try_first_pass
auth     requisite                  pam_deny.so
auth     required                   pam_permit.so
auth     optional                   pam_kwallet5.so

@include common-account

session  [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session  required       pam_loginuid.so
session  [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
session  optional       pam_keyinit.so force revoke
session  required       pam_limits.so
session  required       pam_env.so readenv=1
session  required       pam_env.so readenv=1 envfile=/etc/default/locale

@include common-session
session  optional       pam_kwallet5.so auto_start
@include common-password
EOF
    $SUDO chmod 644 "$KDE_PAM_FILE"

    # Asegurar que /etc/pam.d/kde-fingerprint esté presente y habilitado
    if [ ! -f "$KDE_FP_PAM_FILE" ]; then
        cat <<'EOF' | $SUDO tee "$KDE_FP_PAM_FILE" >/dev/null
#%PAM-1.0
# KDE Plasma 6 KScreenLocker - Servicio Biométrico (No interactivo)
auth     requisite       pam_nologin.so
auth     required        pam_succeed_if.so user != root quiet_success
auth     required        pam_fprintd.so
auth     optional        pam_kwallet5.so

@include common-account

session  [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session  required       pam_loginuid.so
session  [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
session  optional       pam_keyinit.so force revoke
session  required       pam_limits.so
session  required       pam_env.so readenv=1
session  required       pam_env.so readenv=1 envfile=/etc/default/locale

@include common-session
session  optional       pam_kwallet5.so auto_start
password required       pam_fprintd.so
EOF
        $SUDO chmod 644 "$KDE_FP_PAM_FILE"
    fi

    echo "  ✅ KScreenLocker configurado: Huella y contraseña disponibles en paralelo al bloquear."
}

remove_kde_lockscreen() {
    require_root
    echo "🗑️  Restaurando configuración predeterminada de KScreenLocker..."
    if [ -f "$KDE_PAM_BACKUP" ]; then
        $SUDO cp -p "$KDE_PAM_BACKUP" "$KDE_PAM_FILE"
        echo "  ✅ Archivo /etc/pam.d/kde restaurado desde la copia de respaldo."
    else
        cat <<'EOF' | $SUDO tee "$KDE_PAM_FILE" >/dev/null
#%PAM-1.0
auth    requisite       pam_nologin.so
auth	required	pam_succeed_if.so user != root quiet_success
@include common-auth
auth    optional        pam_kwallet5.so
@include common-account
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session required        pam_loginuid.so
session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
session optional        pam_keyinit.so force revoke
session required        pam_limits.so
session required        pam_env.so readenv=1
session required        pam_env.so readenv=1 envfile=/etc/default/locale
@include common-session
session optional        pam_kwallet5.so auto_start
@include common-password
EOF
        $SUDO chmod 644 "$KDE_PAM_FILE"
        echo "  ✅ Archivo /etc/pam.d/kde reconfigurado al estándar de Debian."
    fi
}

# ------------------------------------------------------------------------------
# 6. GESTIÓN GLOBAL DE PAM (pam-auth-update)
# ------------------------------------------------------------------------------
enable_pam() {
    require_root
    echo "🔐 Habilitando módulo de autenticación biométrica (libpam-fprintd) en PAM..."

    if command -v pam-auth-update &>/dev/null; then
        $SUDO pam-auth-update --enable fprintd 2>/dev/null || true
    fi

    # Asegurar que el servicio fprintd esté activo
    $SUDO systemctl enable --now fprintd.service 2>/dev/null || true
    echo "  ✅ Módulo pam_fprintd.so integrado en PAM (sudo, polkit)."

    # 1. Configurar SDDM para contraseña exclusiva (KWallet auto-unlock en boot)
    configure_sddm_bypass

    # 2. Configurar KScreenLocker para huella y contraseña simultáneas
    configure_kde_lockscreen
}

disable_pam() {
    require_root
    echo "🔓 Deshabilitando autenticación biométrica en PAM..."
    if command -v pam-auth-update &>/dev/null; then
        $SUDO pam-auth-update --remove fprintd 2>/dev/null || true
    fi
    remove_sddm_bypass
    remove_kde_lockscreen
    echo "  ✅ Autenticación biométrica desactivada de PAM."
}

# ------------------------------------------------------------------------------
# 7. ENROLAMIENTO Y VERIFICACIÓN
# ------------------------------------------------------------------------------
enroll_finger() {
    local finger="${1:-right-index-finger}"
    echo "🖐️  Iniciando registro de huella dactilar para el usuario '$REAL_USER'..."
    echo "   Dedo seleccionado: $finger"
    echo "   Hardware: HP EliteBook 855 G7 (Sensor táctil capacitivo Synaptics 06cb:00df)"
    echo "   Tipo de sensor: Pulsación ('press') | Requiere 9 etapas de contacto"
    echo "   -----------------------------------------------------------------"
    echo "   👉 Apoya tu dedo firmemente sobre el sensor y levántalo cuando la terminal"
    echo "      indique el progreso hasta completar las 9 etapas."
    echo "-----------------------------------------------------------------"
    run_as_user fprintd-enroll -f "$finger" "$REAL_USER"
}

verify_finger() {
    local finger="${1:-}"
    echo "🔍 Probando verificación de huella dactilar en el sensor..."
    echo "   (Apoya tu dedo registrado en el lector biométrico)"
    echo "-----------------------------------------------------------------"
    if [ -n "$finger" ]; then
        run_as_user fprintd-verify -f "$finger" "$REAL_USER"
    else
        run_as_user fprintd-verify "$REAL_USER"
    fi
}

# ------------------------------------------------------------------------------
# 8. DIAGNÓSTICO Y ESTADO DETALLADO
# ------------------------------------------------------------------------------
show_status() {
    echo "================================================================="
    echo "🔐 ESTADO DE AUTENTICACIÓN POR HUELLA DACTILAR"
    echo "   Sistema: Debian Testing | Entorno: KDE Plasma 6 (Wayland)"
    echo "   Equipo:  HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U)"
    echo "================================================================="
    echo "👤 Usuario:                $REAL_USER"

    # 1. Detección de hardware USB
    local hw_desc hw_id
    hw_desc=$(lsusb 2>/dev/null | grep -iE "fingerprint|synaptics|fprint|validity|elan|authentec" | sed 's/.*ID [0-9a-f:]* //' | head -n 1)
    hw_id=$(lsusb 2>/dev/null | grep -iE "fingerprint|synaptics|fprint|validity|elan|authentec" | grep -oE "ID [0-9a-f:]*" | head -n 1)
    if [ -n "$hw_desc" ]; then
        echo "💻 Sensor Biométrico USB:  ✅ $hw_id $hw_desc"
    else
        echo "💻 Sensor Biométrico USB:  ⚠️ No detectado en el bus USB"
    fi

    # 2. Driver libfprint / Daemon fprintd por D-Bus
    local fp_dev
    fp_dev=$(run_as_user fprintd-list "$REAL_USER" 2>&1 || true)
    if echo "$fp_dev" | grep -q "found [1-9]"; then
        local dev_path
        dev_path=$(echo "$fp_dev" | grep "Using device" | sed 's/Using device //')
        echo "🔌 Reconocimiento fprintd: ✅ Operativo ($dev_path)"
        echo "   Tipo de escaneo:        Pulsación capacitiva ('press' - 9 etapas de contacto)"
    else
        echo "🔌 Reconocimiento fprintd: ❌ No reconocido por libfprint"
    fi

    # 3. Paquetes instalados
    local fprintd_ver fprintd_pam_ver
    fprintd_ver=$(dpkg-query -W -f='${Version}\n' fprintd 2>/dev/null || echo "No instalado")
    fprintd_pam_ver=$(dpkg-query -W -f='${Version}\n' libpam-fprintd 2>/dev/null || echo "No instalado")
    echo "📦 Paquete fprintd:        $fprintd_ver"
    echo "📦 Paquete libpam-fprintd: $fprintd_pam_ver"

    # 4. Estado en PAM (common-auth)
    local pam_status="❌ Inactivo (Huella no solicitada por PAM)"
    if grep -q "pam_fprintd.so" "$COMMON_AUTH_FILE" 2>/dev/null; then
        pam_status="✅ Activo (pam_fprintd.so habilitado con fallback a contraseña)"
    fi
    echo "🛡️  PAM Global (sudo/polkit): $pam_status"

    # 5. Estado de SDDM (Pantalla de login en arranque)
    local sddm_status="⚠️ Predeterminado (Pide huella o hereda timeout)"
    if [ -f "$SDDM_PAM_FILE" ]; then
        if grep -q "pam_unix.so" "$SDDM_PAM_FILE" && ! grep -q "pam_fprintd" "$SDDM_PAM_FILE" && ! grep -q "@include common-auth" "$SDDM_PAM_FILE"; then
            sddm_status="✅ Optimizado (Solo contraseña en boot -> KWallet desbloqueado)"
        fi
    fi
    echo "🖥️  Login SDDM (Boot):      $sddm_status"

    # 6. Estado de KScreenLocker (Pantalla de bloqueo KDE)
    local kde_status="⚠️ Predeterminado"
    if [ -f "$KDE_PAM_FILE" ] && [ -f "$KDE_FP_PAM_FILE" ]; then
        if ! grep -q "@include common-auth" "$KDE_PAM_FILE" && grep -q "pam_unix.so" "$KDE_PAM_FILE" && grep -q "pam_fprintd.so" "$KDE_FP_PAM_FILE"; then
            kde_status="✅ Optimizado (Huella y contraseña concurrentes en paralelo)"
        fi
    fi
    echo "🔒 Bloqueo KScreenLocker:  $kde_status"

    # 7. Huellas registradas para el usuario
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
    if ! grep -q "pam_fprintd.so" "$COMMON_AUTH_FILE" 2>/dev/null; then
        echo "💡 Para habilitar la configuración completa: 'just fingerprint'"
    fi
    if echo "$fp_dev" | grep -qi "no fingers enrolled"; then
        echo "💡 Para registrar tu huella dactilar:"
        echo "   - Por terminal:  just fingerprint --enroll (o just fingerprint-enroll)"
        echo "   - Gráficamente:  kcmshell6 kcm_users (o Ajustes del Sistema -> Usuarios)"
    fi
    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIONES]

Configuración, optimización y diagnóstico de huella dactilar (fprintd + PAM + KDE Plasma 6 Wayland).
Adaptado para HP EliteBook 855 G7 (Sensor Synaptics 06cb:00df).

POLÍTICA DE AUTENTICACIÓN IMPLEMENTADA:
  1. Login inicial (SDDM al arrancar):
     - Pide exclusivamente la contraseña para desbloquear el cofre de claves (KWallet).
     - Evita el retardo de 30s del sensor en el arranque.
  2. Pantalla de bloqueo (KScreenLocker):
     - Doble autenticador simultáneo: puedes desbloquear tocando el sensor biométrico
       O escribiendo la contraseña y presionando Enter, en paralelo sin bloqueos.
  3. Terminal (sudo) y Polkit (KDE):
     - Solicita huella dactilar primero con fallback transparente a contraseña.

OPCIONES:
  -s, --status         Muestra el estado detallado del hardware, paquetes, PAM y huellas.
  -e, --enroll [DEDO]  Registra una huella en terminal (por defecto: right-index-finger).
  -v, --verify [DEDO]  Prueba la verificación en el sensor con las huellas registradas.
  -d, --disable        Deshabilita la autenticación biométrica en PAM y restaura configuración.
      --sddm-bypass    Configura SDDM para contraseña exclusiva (KWallet auto-unlock).
      --sddm-reset     Restaura SDDM a la configuración predeterminada.
      --kde-parallel   Configura KScreenLocker para huella y contraseña concurrentes.
      --kde-reset      Restaura KScreenLocker a la configuración predeterminada.
  -h, --help           Muestra esta ayuda.

DEDOS ADMITIDOS POR fprintd:
  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger
  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger
EOF
}

# ------------------------------------------------------------------------------
# 9. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
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
        --kde-parallel)
            ACTION="kde-parallel"
            shift
            ;;
        --kde-reset)
            ACTION="kde-reset"
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
    kde-parallel)
        configure_kde_lockscreen
        exit 0
        ;;
    kde-reset)
        remove_kde_lockscreen
        exit 0
        ;;
esac

echo "================================================================="
echo "🖐️  Configuración de Huella Dactilar para Debian Testing ($REAL_USER)"
echo "   Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U)"
echo "================================================================="

ensure_dependencies
enable_pam

echo ""
show_status
echo "================================================================="
echo "✅ Configuración biométrica completada con éxito."
echo "================================================================="
