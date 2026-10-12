#!/usr/bin/env bash
# ==============================================================================
# python.sh - Verificación de Python Nativo (Fedora) y Gestor 'uv' vía Mise
# Fedora 44 Workstation (KDE Plasma 6 + Wayland / Systemd User Environment)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Vega 7 / Btrfs)
# ==============================================================================
# Principio de Diseño:
# - Python NO se instala de forma global a través de gestores de versiones (Mise/Pyenv)
#   para garantizar la integridad absoluta de las herramientas del sistema Fedora
#   (DNF5, Firewalld, Libvirt, Cockpit, KDE Plasma).
# - Se valida que el sistema tenga instalado y saludable el Python nativo de Fedora.
# - Para proyectos que requieran versiones específicas de Python (3.11, 3.12, etc.),
#   se utiliza 'uv' de forma aislada por proyecto (per-project) sin tocar el sistema.
# - Optimización para Btrfs: UV_LINK_MODE=copy para compatibilidad con snapshots.
# - Integración con KDE Plasma 6 (environment.d) y Shells (Bash predeterminado / Zsh).
# - Generación automática de autocompletados nativos para 'uv' y 'uvx'.
# - Comandos CLI: --status / -s, --update / -u, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS
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

# Variables de entorno para Python & uv (Copy mode esencial para Btrfs)
export UV_LINK_MODE="copy"
export PYTHONUNBUFFERED=1

# Exportar PATH para este proceso
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            UV_LINK_MODE="copy" PYTHONUNBUFFERED=1 \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        UV_LINK_MODE="copy" PYTHONUNBUFFERED=1 \
        PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🐍 Gestor de Entorno Python & uv - Fedora 44 (KDE Plasma 6)

Filosofía:
  • El sistema operativo utiliza el Python nativo de Fedora (/usr/bin/python3).
  • Python NO se instala globalmente en Mise para no romper herramientas de sistema
    (DNF5, Firewalld, Libvirt, Btrfs, CUPS/HPLIP, KDE).
  • Los proyectos que necesiten versiones específicas de Python se gestionan
    de forma aislada mediante 'uv' (ej: 'uv init', 'uv venv --python 3.12').
  • Optimización Btrfs: UV_LINK_MODE=copy previene errores entre subvolúmenes y snapshots.

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica el Python nativo del sistema, asegura 'uv' en Mise,
                      desactiva shims globales conflictivos y genera autocompletados.
  --status, -s        Muestra el diagnóstico del Python nativo de Fedora, módulos
                      (venv, pip), gestor 'uv' y aislamiento de Mise.
  --update, -u        Actualiza 'uv' a la última versión disponible en Mise.
  --help, -h          Muestra este mensaje de ayuda.

Herramientas per-project:
  Para crear un nuevo proyecto Python aislado:
    ./ProgrammingLanguages/python-uv-init.sh (o 'just python-uv')
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO PYTHON (NATIVO FEDORA + GESTOR UV)"
    echo "================================================================="

    local py_bin py_ver py_pkg venv_status pip_status mise_py uv_status uvx_status

    py_bin=$(which python3 2>/dev/null || echo "No encontrado")
    py_ver=$(python3 --version 2>/dev/null || echo "No disponible")
    py_pkg=$(rpm -q python3 2>/dev/null || echo "python3")

    if python3 -m venv --help &>/dev/null; then
        venv_status="✅ Operativo (módulo venv nativo)"
    else
        venv_status="❌ No disponible"
    fi

    if python3 -m pip --version &>/dev/null; then
        local pip_ver
        pip_ver=$(python3 -m pip --version 2>/dev/null | awk '{print $2}')
        pip_status="✅ v$pip_ver (paquete Fedora)"
    else
        pip_status="⚠️ No instalado a nivel de sistema"
    fi

    if run_as_user mise which python 2>/dev/null >/dev/null; then
        mise_py="⚠️ Detectado shim de Python en Mise (se recomienda eliminar para proteger el sistema)"
    else
        mise_py="✅ Ninguno (Intacto: /usr/bin/python3 protegido)"
    fi

    if command -v uv &>/dev/null; then
        local uv_v
        uv_v=$(uv --version 2>/dev/null | awk '{print $2}')
        uv_status="✅ v$uv_v (Astral / Rust)"
    else
        uv_status="❌ No instalado"
    fi

    if command -v uvx &>/dev/null; then
        uvx_status="✅ Activo (ejecutor de herramientas CLI efímeras)"
    else
        uvx_status="ℹ️ No disponible"
    fi

    echo "1. Python Nativo del Sistema (Fedora 44):"
    echo "   • Binario:              $py_bin"
    echo "   • Versión:              $py_ver"
    echo "   • Paquete RPM:          $py_pkg"
    echo "   • Módulo venv:          $venv_status"
    echo "   • Gestor pip:           $pip_status"
    echo "-----------------------------------------------------------------"
    echo "2. Aislamiento Global (Mise):"
    echo "   • Shims globales:       $mise_py"
    echo "-----------------------------------------------------------------"
    echo "3. Gestor de Proyectos Aislados (uv per-project):"
    echo "   • Gestor uv:            $uv_status"
    echo "   • Runner uvx:           $uvx_status"
    echo "   • Modo Btrfs:           UV_LINK_MODE=copy (compatible con snapshots Btrfs)"
    echo "   • Entorno KDE Plasma 6: $(if [ -f "$USER_HOME/.config/environment.d/10-python.conf" ]; then echo "✅ Configurado"; else echo "ℹ️ No presente"; fi)"
    echo "   • Autocompletado Bash:  $(if [ -f "$USER_HOME/.local/share/bash-completion/completions/uv" ]; then echo "✅ uv & uvx activos"; else echo "ℹ️ No generado"; fi)"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --update|-u|update)
        echo "🔄 Actualizando gestor 'uv' vía Mise..."
        run_as_user mise upgrade uv@latest 2>/dev/null || run_as_user mise use --global uv@latest
        run_as_user mise reshim 2>/dev/null || true
        echo "✅ Gestor 'uv' actualizado con éxito."
        show_status
        exit 0
        ;;
esac

echo "================================================================="
echo "🐍 Verificando Python Nativo de Fedora y Gestor 'uv' (Mise)"
echo "================================================================="

# 1. Comprobar integridad del Python nativo de Fedora
echo "ℹ️ [1/4] Comprobando integridad del Python nativo de Fedora..."
MISSING_PKGS=()

check_pkg() {
    rpm -q "$1" >/dev/null 2>&1
}

if ! check_pkg python3; then MISSING_PKGS+=("python3"); fi
if ! check_pkg python3-pip; then MISSING_PKGS+=("python3-pip"); fi
if ! check_pkg python3-devel; then MISSING_PKGS+=("python3-devel"); fi
if ! check_pkg git; then MISSING_PKGS+=("git"); fi
if ! check_pkg curl; then MISSING_PKGS+=("curl"); fi

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  📦 Instalando paquetes nativos faltantes (${MISSING_PKGS[*]}) vía DNF5..."
    if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
        echo "❌ Error: Se requieren permisos administrativos para instalar: ${MISSING_PKGS[*]}"
        exit 1
    fi
    $SUDO dnf5 install -y "${MISSING_PKGS[@]}"
    echo "  ✅ Paquetes nativos instalados."
else
    echo "  ✅ Python nativo de Fedora ($(python3 --version 2>/dev/null)) y librerías base intactos."
fi

# 2. Asegurar que Mise no bloquee el Python del sistema
echo "ℹ️ [2/4] Asegurando que Mise no bloquee ni enmascare el Python del sistema..."
if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
    run_as_user mise unuse --global python 2>/dev/null || true
    run_as_user mise reshim 2>/dev/null || true
    echo "  ✅ Aislamiento garantizado: ningún shim global de Python interfiere con Fedora."
fi

# 3. Instalar / verificar gestor 'uv' vía Mise
echo "ℹ️ [3/4] Verificando gestor 'uv' para gestión aislada per-project..."
if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/mise.sh" ]; then
        echo "  ℹ️ Mise no encontrado. Ejecutando $SCRIPT_DIR/mise.sh..."
        bash "$SCRIPT_DIR/mise.sh"
    else
        echo "❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero."
        exit 1
    fi
fi

run_as_user mise use --global uv@latest
run_as_user mise reshim 2>/dev/null || true

# 4. Integración con KDE Plasma 6 y Shells
echo "ℹ️ [4/4] Configurando variables de entorno para Btrfs y autocompletados..."

# KDE Plasma 6 (environment.d)
run_as_user mkdir -p "$USER_HOME/.config/environment.d"
cat << 'EOF' | run_as_user tee "$USER_HOME/.config/environment.d/10-python.conf" > /dev/null
# Entorno Python y optimización para Btrfs
UV_LINK_MODE=copy
PYTHONUNBUFFERED=1
EOF

# Bash completion
run_as_user mkdir -p "$USER_HOME/.local/share/bash-completion/completions"
if command -v uv &>/dev/null; then
    run_as_user uv generate-shell-completion bash > "$USER_HOME/.local/share/bash-completion/completions/uv" 2>/dev/null || true
    run_as_user uvx --generate-shell-completion bash > "$USER_HOME/.local/share/bash-completion/completions/uvx" 2>/dev/null || true
fi

# Zsh completion
run_as_user mkdir -p "$USER_HOME/.zfunc"
if command -v uv &>/dev/null; then
    run_as_user uv generate-shell-completion zsh > "$USER_HOME/.zfunc/_uv" 2>/dev/null || true
    run_as_user uvx --generate-shell-completion zsh > "$USER_HOME/.zfunc/_uvx" 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Entorno de Python y gestor 'uv' configurado exitosamente."
echo "💡 Para crear un proyecto nuevo con entorno aislado: 'just python-uv'"
echo "================================================================="
show_status
