#!/bin/bash
# =============================================================================
# fingerprint-setup.sh - Configuración de Huella Dactilar Opcional / Dual en Manjaro Linux
# =============================================================================
# Configura fprintd y los módulos PAM (sudo y polkit) para que la huella y la
# contraseña se puedan usar indistintamente de forma opcional (huella O contraseña),
# sin exigir ambos métodos a la vez.
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

require_non_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Este script NO debe ejecutarse directamente como root."
        log_error "Ejecútalo como tu usuario normal (el script solicitará sudo cuando sea necesario)."
        exit 1
    fi
}

install_dependencies() {
    if ! command -v fprintd-enroll &>/dev/null; then
        log_info "Instalando fprintd vía Pacman..."
        sudo pacman -S --needed --noconfirm fprintd
        log_ok "fprintd instalado"
    else
        log_ok "fprintd ya está instalado en el sistema"
    fi
}

enable_service() {
    log_info "Habilitando e iniciando el servicio fprintd..."
    sudo systemctl enable --now fprintd.service
    log_ok "Servicio fprintd activo"
}

revert_pam() {
    log_info "Revirtiendo configuración de PAM al estado estándar..."

    # Revertir sudo
    if [ -f /etc/pam.d/sudo.bak ]; then
        sudo cp /etc/pam.d/sudo.bak /etc/pam.d/sudo
        log_ok "Restaurado /etc/pam.d/sudo desde copia de respaldo"
    else
        sudo tee /etc/pam.d/sudo >/dev/null <<'EOF'
#%PAM-1.0
auth		include		system-auth
account		include		system-auth
session		include		system-auth
EOF
        log_ok "Reestablecido /etc/pam.d/sudo a valores por defecto"
    fi

    # Revertir polkit-1
    if [ -f /etc/pam.d/polkit-1.bak ]; then
        sudo cp /etc/pam.d/polkit-1.bak /etc/pam.d/polkit-1
        log_ok "Restaurado /etc/pam.d/polkit-1 desde copia de respaldo"
    else
        sudo tee /etc/pam.d/polkit-1 >/dev/null <<'EOF'
#%PAM-1.0
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF
        log_ok "Reestablecido /etc/pam.d/polkit-1 a valores por defecto"
    fi

    echo ""
    log_ok "Configuración PAM restaurada con éxito (solo contraseña)."
}

configure_pam() {
    log_info "Configurando módulos PAM para autenticación dual (huella O contraseña)..."

    # 1. Configurar /etc/pam.d/sudo
    if [ ! -f /etc/pam.d/sudo.bak ]; then
        sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
        log_info "Copia de respaldo creada en /etc/pam.d/sudo.bak"
    fi

    sudo tee /etc/pam.d/sudo >/dev/null <<'EOF'
#%PAM-1.0
auth		sufficient	pam_fprintd.so
auth		include		system-auth
account		include		system-auth
session		include		system-auth
EOF
    log_ok "/etc/pam.d/sudo configurado (huella suficiente con fallback a contraseña)"

    # 2. Configurar /etc/pam.d/polkit-1 (diálogos gráficos de elevación de privilegios)
    if [ ! -f /etc/pam.d/polkit-1.bak ]; then
        sudo cp /etc/pam.d/polkit-1 /etc/pam.d/polkit-1.bak
        log_info "Copia de respaldo creada en /etc/pam.d/polkit-1.bak"
    fi

    sudo tee /etc/pam.d/polkit-1 >/dev/null <<'EOF'
#%PAM-1.0
auth       sufficient   pam_fprintd.so
auth       include      system-auth
account    include      system-auth
password   include      system-auth
session    include      system-auth
EOF
    log_ok "/etc/pam.d/polkit-1 configurado (huella suficiente con fallback a contraseña)"
}

enroll_fingerprint() {
    echo ""
    echo "================================================================="
    echo "💡 Opciones de Registro de Huella Dactilar:"
    echo "   1) Por terminal ahora mismo: fprintd-enroll"
    echo "   2) Desde GNOME: Configuración -> Usuarios -> Huella Dactilar"
    echo "================================================================="
    echo ""

    local user_name
    user_name="$(id -un)"

    read -rp "¿Deseas registrar o actualizar tu huella ahora para el usuario '$user_name'? (s/N): " ENROLL_NOW || true
    if [[ "${ENROLL_NOW:-n}" =~ ^[Ss]$ ]]; then
        log_step "Ejecutando fprintd-enroll..."
        fprintd-enroll "$user_name" || {
            log_error "No se pudo registrar la huella o el proceso fue cancelado."
        }
    fi
}

test_fingerprint() {
    local user_name
    user_name="$(id -un)"

    echo ""
    read -rp "¿Deseas verificar la huella registrada ahora? (s/N): " TEST_NOW || true
    if [[ "${TEST_NOW:-n}" =~ ^[Ss]$ ]]; then
        log_step "Ejecutando fprintd-verify (coloca tu dedo en el lector)..."
        fprintd-verify "$user_name" || true
    fi
}

main() {
    if [[ "${1:-}" == "--revert" || "${1:-}" == "-r" ]]; then
        require_non_root
        revert_pam
        exit 0
    fi

    echo "================================================================="
    echo "  Configuración de Huella Dactilar (Opcional / Dual) - Manjaro"
    echo "================================================================="
    echo ""

    require_non_root
    install_dependencies
    enable_service
    configure_pam
    enroll_fingerprint
    test_fingerprint

    echo ""
    echo "================================================================="
    log_ok "Configuración de autenticación dual completada con éxito."
    echo "================================================================="
    echo ""
    echo "ℹ️ Comportamiento a partir de ahora:"
    echo "  • Al solicitar sudo o permisos: coloca el dedo para entrar de inmediato."
    echo "  • O bien presiona [Enter] / ingresa tu contraseña directamente."
    echo "  • Puedes alternar entre huella o contraseña en cualquier momento."
    echo "  • Para revertir esta configuración en el futuro: ./Setup/fingerprint-setup.sh --revert"
    echo ""
}

main "$@"
