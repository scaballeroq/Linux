#!/usr/bin/env bash
# =============================================================================
# fingerprint-setup.sh - Configuración de Huella Dactilar en Soplos Linux Boro (GNOME)
# Optimizado para HP ProBook 455 G10 (Sensor Synaptics / Elan / Goodix / fprintd)
# =============================================================================
# Política de Autenticación:
#   1. Arranque del equipo (GDM Greeter): SÓLO contraseña.
#      - Evita conflictos de desbloqueo en GNOME Keyring.
#      - Solicita la contraseña maestra al iniciar en frío.
#   2. Bloqueo de pantalla (GNOME Lock Screen): Contraseña y huella indistintamente.
#   3. Terminal y consola (sudo / sudo -i): Contraseña y huella indistintamente.
#   4. Aplicaciones gráficas (PolKit-1): Contraseña y huella indistintamente.
#
# Opciones CLI:
#   (sin argumentos)       Instala dependencias, aplica la política híbrida y guía el registro.
#   --status, -s           Muestra el diagnóstico completo de hardware, servicios y reglas PAM.
#   --enroll [DEDO]        Registra una huella (por defecto: right-index-finger).
#   --verify [DEDO]        Prueba la verificación de la huella en el sensor.
#   --delete               Elimina las huellas registradas del usuario actual.
#   --restore              Restaura la configuración PAM y GDM a los valores predeterminados.
#   --help, -h             Muestra este mensaje de ayuda.
# =============================================================================

set -euo pipefail

# Comprobación de privilegios de ejecución
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario (sudo)."
        exit 1
    fi
else
    SUDO=""
fi

# Detección del usuario real no-root
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_UID=$(id -u "$SUDO_USER")
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
    REAL_UID=$(id -u)
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

run_as_user_dbus() {
    local bus_address="unix:path=/run/user/${REAL_UID}/bus"
    if [ -e "/run/user/${REAL_UID}/bus" ]; then
        run_as_user env DBUS_SESSION_BUS_ADDRESS="$bus_address" "$@"
    else
        run_as_user dbus-run-session "$@" 2>/dev/null || run_as_user "$@"
    fi
}

show_help() {
    cat <<EOF
👆 Configurador de Huella Dactilar Híbrida - Soplos Linux Boro (GNOME Wayland)
(Arranque con contraseña obligatoria + Huella/Contraseña indistinta en bloqueo, apps y terminal)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala dependencias, aplica la política biométrica híbrida
                         y asiste en el registro de huellas.
  --status, -s           Diagnóstico completo del sensor, servicio fprintd y políticas PAM/GDM.
  --enroll [DEDO]        Registra una huella (por defecto: right-index-finger).
  --verify [DEDO]        Verifica la respuesta del lector biométrico.
  --delete               Elimina todas las huellas del usuario actual.
  --restore              Revierte las reglas PAM y GDM a su configuración original.
  --help, -h             Muestra esta ayuda.

Dedos admitidos para --enroll:
  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger
  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger
EOF
}

check_pam_rule() {
    local file="$1"
    if [ -f "$file" ] && grep -E "^auth\s+sufficient\s+pam_fprintd\.so" "$file" >/dev/null 2>&1; then
        echo "✅ Habilitada (huella + contraseña indistintas)"
    else
        echo "❌ No configurada (sólo contraseña o herencia estándar)"
    fi
}

show_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE HUELLA DACTILAR - SOPLOS LINUX BORO"
    echo "================================================================="
    echo "• Servicio fprintd:            $(systemctl is-active --quiet fprintd.service 2>/dev/null && echo '✅ Activo (running)' || echo '❌ Inactivo / No instalado')"
    
    echo "• Lector biométrico USB:"
    local sensor_found=0
    if command -v lsusb >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                echo "    $line"
                sensor_found=1
            fi
        done < <(lsusb 2>/dev/null | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan|goodix" || true)
    fi
    if [ "$sensor_found" -eq 0 ]; then
        echo "    (No se detectó ningún sensor USB reconocido automáticamente)"
    fi

    echo "-----------------------------------------------------------------"
    echo "POLÍTICA DE AUTENTICACIÓN DEL SISTEMA:"
    
    # 1. GDM Arranque
    local gdm_dconf="/etc/dconf/db/gdm.d/99-fingerprint-boot-password.conf"
    if [ -f "$gdm_dconf" ] && grep -q "enable-fingerprint-authentication=false" "$gdm_dconf" 2>/dev/null; then
        echo "• Arranque en frío (GDM):      ✅ SÓLO CONTRASEÑA (Desbloqueo Keyring protegido)"
    else
        echo "• Arranque en frío (GDM):      ⚠️ Huella no deshabilitada explícitamente en GDM greeter"
    fi

    # 2. Bloqueo de pantalla (GNOME Lock Screen)
    local user_lock_setting
    user_lock_setting=$(run_as_user_dbus gsettings get org.gnome.login-screen enable-fingerprint-authentication 2>/dev/null || echo "true")
    if [ "$user_lock_setting" = "true" ]; then
        echo "• Pantalla de Bloqueo (GNOME): ✅ INDISTINTA (Huella y contraseña activas)"
    else
        echo "• Pantalla de Bloqueo (GNOME): ❌ Huella desactivada para el usuario ($user_lock_setting)"
    fi

    # 3. Terminal (sudo)
    echo "• Terminal (sudo):             $(check_pam_rule /etc/pam.d/sudo)"
    echo "• Terminal root (sudo -i):     $(check_pam_rule /etc/pam.d/sudo-i)"

    # 4. Apps Gráficas (PolKit)
    echo "• Aplicaciones (PolKit-1):     $(check_pam_rule /etc/pam.d/polkit-1)"

    # 5. common-auth limpieza
    if grep -E "^auth\s+.*pam_fprintd\.so" /etc/pam.d/common-auth >/dev/null 2>&1; then
        echo "• Pila central (common-auth):   ⚠️ pam_fprintd presente (podría interferir en el arranque)"
    else
        echo "• Pila central (common-auth):   ✅ Limpia (gestionada selectivamente)"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Huellas registradas para el usuario '$REAL_USER':"
    if command -v fprintd-list >/dev/null 2>&1; then
        run_as_user fprintd-list "$REAL_USER" 2>/dev/null || echo "    (Sin huellas registradas o servicio no disponible)"
    else
        echo "    (fprintd no instalado)"
    fi
    echo "================================================================="
    echo "💡 Puedes comprobar o modificar tus huellas en GNOME en:"
    echo "   Configuración ➔ Sistema ➔ Usuarios ➔ Inicio de sesión con huella"
}

inject_pam_rule() {
    local file="$1"
    local rule="auth       sufficient   pam_fprintd.so timeout=10"

    if [ ! -f "$file" ]; then
        return 0
    fi

    # Evitar duplicados
    if grep -E "^\s*auth\s+sufficient\s+pam_fprintd\.so" "$file" >/dev/null 2>&1; then
        return 0
    fi

    # Crear copia de respaldo si no existe
    if [ ! -f "${file}.bak_fprintd" ]; then
        $SUDO cp -p "$file" "${file}.bak_fprintd"
    fi

    # Insertar antes de @include common-auth
    if grep -q "@include common-auth" "$file"; then
        $SUDO sed -i "/@include common-auth/i $rule" "$file"
    else
        echo "$rule" | $SUDO tee -a "$file" >/dev/null
    fi
}

remove_pam_rule() {
    local file="$1"
    if [ -f "$file" ]; then
        if [ -f "${file}.bak_fprintd" ]; then
            $SUDO cp -p "${file}.bak_fprintd" "$file"
            $SUDO rm -f "${file}.bak_fprintd"
        else
            $SUDO sed -i '/pam_fprintd\.so/d' "$file"
        fi
    fi
}

restore_configuration() {
    echo "================================================================="
    echo "🔄 RESTAURANDO CONFIGURACIÓN ORIGINAL PAM Y GDM"
    echo "================================================================="
    echo "ℹ️ Restaurando archivos PAM (/etc/pam.d/sudo, sudo-i, polkit-1)..."
    remove_pam_rule /etc/pam.d/sudo
    remove_pam_rule /etc/pam.d/sudo-i
    remove_pam_rule /etc/pam.d/polkit-1

    echo "ℹ️ Eliminando excepción de GDM greeter..."
    $SUDO rm -f /etc/dconf/db/gdm.d/99-fingerprint-boot-password.conf
    $SUDO dconf update 2>/dev/null || true

    echo "ℹ️ Asegurando deshabilitación de fprintd en common-auth..."
    if command -v pam-auth-update >/dev/null 2>&1; then
        $SUDO pam-auth-update --package --disable fprintd 2>/dev/null || true
    fi

    echo "✅ Configuración restaurada a los valores por defecto del sistema."
    echo "================================================================="
}

# Procesamiento de banderas CLI
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --restore|--uninstall)
        restore_configuration
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
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac

# =============================================================================
# INSTALACIÓN Y CONFIGURACIÓN AUTOMÁTICA
# =============================================================================
echo "================================================================="
echo "👆 CONFIGURANDO HUELLA DACTILAR HÍBRIDA - SOPLOS LINUX BORO"
echo "================================================================="
echo "ℹ️ Política requerida:"
echo "   • Arranque del sistema (Boot/GDM): SÓLO contraseña (protege GNOME Keyring)."
echo "   • Bloqueo de pantalla (Lockscreen): Huella y contraseña indistintas."
echo "   • Terminal (sudo / sudo -i):        Huella y contraseña indistintas."
echo "   • Aplicaciones (PolKit-1):          Huella y contraseña indistintas."
echo "================================================================="

# 1. Instalar paquetes necesarios
echo "ℹ️ [1/5] Instalando dependencias (fprintd, libpam-fprintd)..."
$SUDO apt update
$SUDO apt install -y fprintd libpam-fprintd

# 2. Habilitar servicio del sistema
echo "ℹ️ [2/5] Habilitando servicio del demonio fprintd..."
$SUDO systemctl enable --now fprintd.service 2>/dev/null || true

# 3. Configurar GDM al arranque: SÓLO contraseña
echo "ℹ️ [3/5] Configurando GDM greeter para solicitar exclusivamente contraseña al arrancar..."
$SUDO mkdir -p /etc/dconf/db/gdm.d
$SUDO tee /etc/dconf/db/gdm.d/99-fingerprint-boot-password.conf >/dev/null <<'EOF'
# Configuración Soplos Linux Boro: Deshabilitar huella dactilar al arrancar
# Garantiza que el usuario ingrese la contraseña maestra y desbloquee GNOME Keyring automáticamente
[org/gnome/login-screen]
enable-fingerprint-authentication=false
EOF
$SUDO dconf update

# 4. Asegurar que la pantalla de bloqueo del usuario permita huella dactilar
echo "ℹ️ [4/5] Habilitando autenticación biométrica en la sesión de '$REAL_USER' (Pantalla de Bloqueo)..."
run_as_user_dbus gsettings set org.gnome.login-screen enable-fingerprint-authentication true 2>/dev/null || true

# 5. Configurar PAM para terminal y aplicaciones (indistinto con fallback inmediato a contraseña)
echo "ℹ️ [5/5] Configurando módulos PAM específicos (sudo, sudo-i, polkit-1)..."

# Mantener common-auth limpio de fprintd para evitar que gdm-password exija huella al inicio
if command -v pam-auth-update >/dev/null 2>&1; then
    $SUDO pam-auth-update --package --disable fprintd 2>/dev/null || true
fi

# Inyectar regla 'auth sufficient pam_fprintd.so timeout=10' en servicios objetivo
inject_pam_rule /etc/pam.d/sudo
inject_pam_rule /etc/pam.d/sudo-i
inject_pam_rule /etc/pam.d/polkit-1

echo ""
echo "================================================================="
echo "✅ Configuración biométrica híbrida completada con éxito."
echo "================================================================="
echo "📌 Resumen de comportamiento:"
echo "   1. Al encender/reiniciar el equipo: Se solicitará ÚNICAMENTE la contraseña."
echo "   2. Al bloquear la pantalla (Super + L): Podrás usar tu huella o tu contraseña."
echo "   3. En la terminal (sudo): Podrás apoyar el dedo en el sensor o presionar"
echo "      Enter / escribir tu contraseña indistintamente."
echo "   4. En aplicaciones que pidan permisos de administrador: Podrás usar tu"
echo "      huella dactilar o introducir la contraseña en la ventana de diálogo."
echo "-----------------------------------------------------------------"

# Comprobar si ya tiene huellas registradas
EXISTING_PRINTS=$(run_as_user fprintd-list "$REAL_USER" 2>/dev/null || true)
if echo "$EXISTING_PRINTS" | grep -q "finger"; then
    echo "🎉 Ya tienes huellas dactilares registradas para '$REAL_USER'."
    echo "💡 Puedes probar el sensor ejecutando: $0 --verify"
else
    echo "💡 Aún no tienes huellas registradas. Para registrar tu dedo índice derecho ahora:"
    echo "   $0 --enroll right-index-finger"
fi
echo "================================================================="
