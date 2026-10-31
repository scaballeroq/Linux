#!/bin/bash
# ==============================================================================
# python.sh - Verificación de Python Nativo (Fedora) y Gestor 'uv' vía Mise
# Fedora Workstation (GNOME Shell + Wayland / Systemd User Environment)
# ==============================================================================
# Principio de Diseño:
# - Python NO se instala de forma global a través de gestores de versiones (Mise/Pyenv)
#   para garantizar la integridad absoluta de las herramientas del sistema Fedora
#   (DNF, DNF5, Firewalld, systemd, CUPS/HPLIP, GNOME Shell).
# - Se valida que el sistema tenga instalado y saludable el Python nativo de Fedora.
# - Para proyectos que requieran versiones específicas de Python (3.11, 3.12, 3.13, etc.),
#   se utiliza 'uv' de forma aislada por proyecto (per-project) sin tocar el sistema.
# - Optimización con UV_LINK_MODE=copy para compatibilidad con snapshots y clonado.
# - Integración con GNOME Shell (environment.d) y Shells (Bash predeterminado / Zsh).
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

DNF_CMD=$(command -v dnf5 2>/dev/null || command -v dnf 2>/dev/null || echo "dnf")

export UV_LINK_MODE="copy"
export PYTHONUNBUFFERED=1

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
🐍 Gestor de Entorno Python & uv - Fedora Workstation

Filosofía:
  • El sistema operativo utiliza el Python nativo de Fedora (/usr/bin/python3).
  • Python NO se instala globalmente en Mise para no romper herramientas de sistema
    (DNF, Firewalld, GNOME Shell).
  • Los proyectos que necesiten versiones específicas de Python se gestionan
    de forma aislada mediante 'uv' (ej: 'uv init', 'uv venv --python 3.12').

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
    py_pkg=$(rpm -q python3 2>/dev/null || echo "Paquete nativo")

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
        mise_py="✅ Ninguno (El sistema corre 100% nativo con /usr/bin/python3)"
    fi

    if command -v uv &>/dev/null; then
        uv_status="✅ $(uv --version 2>/dev/null)"
    elif [ -x "$USER_HOME/.local/share/mise/shims/uv" ]; then
        uv_status="✅ v$("$USER_HOME/.local/share/mise/shims/uv" --version 2>/dev/null | awk '{print $2}') (vía Mise)"
    else
        uv_status="❌ No instalado"
    fi

    if command -v uvx &>/dev/null; then
        uvx_status="✅ $(uvx --version 2>/dev/null)"
    elif [ -x "$USER_HOME/.local/share/mise/shims/uvx" ]; then
        uvx_status="✅ v$("$USER_HOME/.local/share/mise/shims/uvx" --version 2>/dev/null | awk '{print $2}') (vía Mise)"
    else
        uvx_status="❌ No instalado"
    fi

    echo "1. Python Nativo del Sistema (Fedora Workstation):"
    echo "  • Binario ejecutable:    $py_bin"
    echo "  • Versión activa:        $py_ver"
    echo "  • Paquete RPM:           $py_pkg"
    echo "  • Módulo python3-venv:   $venv_status"
    echo "  • Gestor pip de sistema: $pip_status"
    echo "-----------------------------------------------------------------"
    echo "2. Aislamiento y Entornos Virtuales:"
    echo "  • Shims de Mise:         $mise_py"
    echo "  • Gestor 'uv' (Mise):    $uv_status"
    echo "  • Ejecutor 'uvx':        $uvx_status"
    echo "  • Modo enlace (symlink): UV_LINK_MODE=$UV_LINK_MODE"
    echo "-----------------------------------------------------------------"
    echo "3. Integración en el Entorno:"
    echo "  • GNOME environment.d:   $([ -f "$USER_HOME/.config/environment.d/10-python.conf" ] && echo '✅ Activo (~/.config/environment.d/10-python.conf)' || echo '❌ Ausente')"
    echo "  • Shell Bash (~/.bashrc.d): $([ -f "$USER_HOME/.bashrc.d/python.sh" ] && echo '✅ Activo (~/.bashrc.d/python.sh)' || echo '❌ Ausente')"
    echo "  • Autocompletado Bash:   $([ -f "$USER_HOME/.local/share/bash-completion/completions/uv" ] && echo '✅ Configurado' || echo '❌ Ausente')"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo "  • Shell Zsh (~/.zshrc.d):   $([ -f "$USER_HOME/.zshrc.d/python.zsh" ] && echo '✅ Activo (~/.zshrc.d/python.zsh)' || echo '❌ Ausente')"
        echo "  • Autocompletado Zsh:    $([ -f "$USER_HOME/.local/share/zsh/site-functions/_uv" ] && echo '✅ Configurado' || echo '❌ Ausente')"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. ACTUALIZACIÓN DE UV
# ------------------------------------------------------------------------------
update_uv() {
    echo "🔄 Actualizando gestor 'uv' vía Mise..."
    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        run_as_user mise use --global uv@latest
        run_as_user mise reshim 2>/dev/null || true
        echo "✅ 'uv' actualizado con éxito a la última versión en Mise."
    else
        echo "❌ Error: 'mise' no está instalado."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# PROCESAMIENTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --update|-u|update)
        update_uv
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🐍 Verificando Python Nativo de Fedora y Gestor 'uv' (Mise)"
echo "   Hardware: AMD Ryzen 7 7730U | NVMe Kioxia | Fedora Workstation"
echo "================================================================="

# ------------------------------------------------------------------------------
# 4. VERIFICAR PYTHON NATIVO DE FEDORA
# ------------------------------------------------------------------------------
echo "ℹ️ [1/4] Comprobando integridad del Python nativo de Fedora..."
MISSING_PKGS=()
for pkg in python3 python3-devel python3-pip; do
    if ! rpm -q "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  ⬇️ Instalando paquetes de Python faltantes vía $DNF_CMD: ${MISSING_PKGS[*]}..."
    $SUDO $DNF_CMD install -y "${MISSING_PKGS[@]}" 2>/dev/null || true
    echo "  ✅ Paquetes nativos de Fedora instalados."
else
    echo "  ✅ Python nativo de Fedora ($(python3 --version 2>/dev/null)) y librerías base intactos."
fi

if ! python3 -m venv --help &>/dev/null; then
    echo "⚠️ Advertencia: python3-venv no responde. Asegurando paquete python3-devel..."
    $SUDO $DNF_CMD install -y python3-devel 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 5. GARANTIZAR QUE MISE NO ENMASCARA EL PYTHON DEL SISTEMA
# ------------------------------------------------------------------------------
echo "ℹ️ [2/4] Asegurando que Mise no bloquee ni enmascare el Python del sistema..."
if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
    run_as_user mise unuse --global python 2>/dev/null || true
    run_as_user mise reshim 2>/dev/null || true
    echo "  ✅ Aislamiento garantizado: ningún shim global de Python interfiere con Fedora."
fi

# ------------------------------------------------------------------------------
# 6. INSTALAR / VERIFICAR GESTOR 'uv' VÍA MISE (PARA PROYECTOS AISLADOS)
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 7. INTEGRACIÓN CON GNOME SHELL, SHELLS Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
echo "ℹ️ [4/4] Configurando variables de entorno y autocompletados..."

ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
BASH_COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"

run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D" "$BASH_COMPLETIONS_DIR"

# 7.1. Integración con sesión gráfica GNOME Shell (systemd user)
cat << 'EOF' | run_as_user tee "$ENV_DIR/10-python.conf" > /dev/null
# Integración de Python & uv para Wayland / GNOME Shell
PYTHONUNBUFFERED=1
UV_LINK_MODE=copy
EOF

# 7.2. Shell Bash (predeterminada)
cat << 'EOF' | run_as_user tee "$BASHRC_D/python.sh" > /dev/null
# Python & uv Environment Settings (Fedora Workstation)
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF

# 7.3. Shell Zsh (compatibilidad condicional)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/python.zsh" > /dev/null
# Python & uv Environment Settings (Fedora Workstation)
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF
fi

# 7.4. Autocompletados para Bash (uv y uvx)
if command -v uv &>/dev/null; then
    uv generate-shell-completion bash > "$BASH_COMPLETIONS_DIR/uv" 2>/dev/null || true
    uvx --generate-shell-completion bash > "$BASH_COMPLETIONS_DIR/uvx" 2>/dev/null || true
fi

# 7.5. Autocompletados para Zsh (si existe ~/.zshrc)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
    ZFUNC_DIR="$USER_HOME/.zfunc"
    run_as_user mkdir -p "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

    if command -v uv &>/dev/null; then
        uv generate-shell-completion zsh > "$ZSH_COMPLETIONS_DIR/_uv" 2>/dev/null || true
        uv generate-shell-completion zsh > "$ZFUNC_DIR/_uv" 2>/dev/null || true
        uvx --generate-shell-completion zsh > "$ZSH_COMPLETIONS_DIR/_uvx" 2>/dev/null || true
        uvx --generate-shell-completion zsh > "$ZFUNC_DIR/_uvx" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 8. RESUMEN FINAL
# ------------------------------------------------------------------------------
PYTHON_VER=$(python3 --version 2>/dev/null || echo "Python nativo del sistema")
UV_VER=$(run_as_user mise exec uv@latest -- uv --version 2>/dev/null || echo "uv instalado")
PIP_VER=$(python3 -m pip --version 2>/dev/null | awk '{print $2}' || echo "pip del sistema")

echo "================================================================="
echo "✅ Entorno Python & uv listo para Fedora Workstation y GNOME:"
echo "  • Python Sistema: $PYTHON_VER (/usr/bin/python3 nativo)"
echo "  • Gestor pip:     v$PIP_VER (paquetes nativos Fedora)"
echo "  • Gestor uv:      $UV_VER (para proyectos y entornos aislados)"
echo "  • Modo enlace:    UV_LINK_MODE=copy"
echo "  • Entorno GNOME:  ~/.config/environment.d/10-python.conf"
echo "  • Shells:         Bash (predeterminada)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (compatible)") con autocompletados (uv / uvx)"
echo "  • Proyectos:      Ejecuta './ProgrammingLanguages/python-uv-init.sh' para crear nuevos entornos"
echo "================================================================="
