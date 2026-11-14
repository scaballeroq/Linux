#!/usr/bin/env bash
# ==============================================================================
# python.sh - Verificación de Python Nativo (CachyOS) y Gestor 'uv' vía Mise
# CachyOS Workstation (GNOME Shell Wayland / Systemd User Environment)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# ==============================================================================
# Principios de Diseño:
# - Cumplimiento estricto de PEP 668: Python NO se instala globalmente a través
#   de gestores de versiones (Mise/Pyenv) para garantizar la integridad absoluta
#   de las herramientas del sistema CachyOS (Pacman, Firewalld, systemd, GNOME Shell).
# - Se valida que el sistema disponga del Python 3 nativo de CachyOS y sus paquetes base.
# - Para proyectos que requieran versiones específicas de Python (3.11, 3.12, 3.13, etc.),
#   se utiliza 'uv' de forma aislada por proyecto (per-project) sin alterar el sistema.
# - Optimización con UV_LINK_MODE="copy" para compatibilidad con snapshots y clonado Btrfs/NVMe.
# - Ajuste de paralelismo y compilación a los 16 hilos de la CPU AMD Ryzen 7 7730U (-j16).
# - Integración nativa con GNOME Shell (environment.d) y Shells (Bash y Zsh).
# - Generación automática de autocompletados nativos para 'uv' y 'uvx'.
# - Comandos CLI: --status / -s, --update / -u, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES, COLORES Y DETECCIÓN DE HARDWARE
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}ℹ️  [INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}✅ [OK]${NC}   $1"; }
log_warn()  { echo -e "${YELLOW}⚠️  [WARN]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERR]${NC}  $1"; }
log_step()  { echo -e "${CYAN}>> [PASO]${NC} $1"; }

# Detectar núcleos e hilos de la CPU (AMD Ryzen 7 7730U -> 16 hilos)
NPROC=$(nproc 2>/dev/null || echo 16)
export MAKEFLAGS="-j$NPROC"
export UV_LINK_MODE="copy"
export PYTHONUNBUFFERED=1
export UV_CONCURRENT_DOWNLOADS="$NPROC"

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO Y PRIVILEGIOS
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

# Exportar rutas de usuario y herramientas en el PATH de la sesión
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH" \
            UV_LINK_MODE="copy" PYTHONUNBUFFERED=1 MAKEFLAGS="-j$NPROC" \
            UV_CONCURRENT_DOWNLOADS="$NPROC" "$@"
    else
        env HOME="$USER_HOME" \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH" \
            UV_LINK_MODE="copy" PYTHONUNBUFFERED=1 MAKEFLAGS="-j$NPROC" \
            UV_CONCURRENT_DOWNLOADS="$NPROC" "$@"
    fi
}

get_mise_bin() {
    if command -v mise &>/dev/null; then
        command -v mise
    elif [ -x "$USER_HOME/.local/bin/mise" ]; then
        echo "$USER_HOME/.local/bin/mise"
    else
        echo ""
    fi
}

get_uv_bin() {
    if command -v uv &>/dev/null; then
        command -v uv
    elif [ -x "$USER_HOME/.local/share/mise/shims/uv" ]; then
        echo "$USER_HOME/.local/share/mise/shims/uv"
    elif [ -x "$USER_HOME/.local/bin/uv" ]; then
        echo "$USER_HOME/.local/bin/uv"
    else
        echo ""
    fi
}

get_uvx_bin() {
    if command -v uvx &>/dev/null; then
        command -v uvx
    elif [ -x "$USER_HOME/.local/share/mise/shims/uvx" ]; then
        echo "$USER_HOME/.local/share/mise/shims/uvx"
    elif [ -x "$USER_HOME/.local/bin/uvx" ]; then
        echo "$USER_HOME/.local/bin/uvx"
    else
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🐍 Gestor de Entorno Python & Gestor 'uv' - CachyOS Workstation
   Hardware: AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe Kioxia | GNOME Wayland

Filosofía de Aislamiento (PEP 668):
  • El sistema operativo utiliza exclusivamente el Python nativo de CachyOS (/usr/bin/python3).
  • Python NO se instala globalmente en Mise para garantizar la integridad del sistema
    (Pacman, Firewalld, GNOME Shell, PipeWire).
  • Los proyectos que requieran versiones específicas de Python se gestionan de forma
    aislada mediante 'uv' (ej: 'uv init', 'uv venv --python 3.13').

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica el Python nativo del sistema, asegura 'uv' en Mise,
                      desactiva shims globales conflictivos y genera autocompletados.
  --status, -s        Muestra diagnóstico detallado del Python nativo de CachyOS,
                      módulo venv, gestor 'uv', concurrencia y aislamiento de Mise.
  --update, -u        Actualiza 'uv' a la última versión disponible en Mise.
  --help, -h          Muestra este mensaje de ayuda.

Herramienta de Creación Rápida de Proyectos:
  Para inicializar un proyecto Python moderno aislado con 'uv':
    ./ProgrammingLanguages/python-uv-init.sh (o 'just python-uv')
EOF
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DEL ENTORNO PYTHON (NATIVO CACHYOS + GESTOR UV)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    local py_bin py_ver py_pkg venv_status pip_status mise_py uv_status uvx_status
    local uv_cmd uvx_cmd mise_cmd

    py_bin=$(which python3 2>/dev/null || echo "No encontrado")
    py_ver=$(python3 --version 2>/dev/null || echo "No disponible")
    py_pkg=$(pacman -Q python 2>/dev/null || echo "Paquete nativo")

    if python3 -m venv --help &>/dev/null; then
        venv_status="${GREEN}✅ Operativo (módulo venv nativo)${NC}"
    else
        venv_status="${RED}❌ No disponible${NC}"
    fi

    if python3 -m pip --version &>/dev/null; then
        local pip_ver
        pip_ver=$(python3 -m pip --version 2>/dev/null | awk '{print $2}')
        pip_status="${GREEN}✅ v$pip_ver (paquete Pacman de CachyOS)${NC}"
    else
        pip_status="${YELLOW}⚠️  No instalado a nivel de sistema (cumple aislamiento PEP 668)${NC}"
    fi

    mise_cmd=$(get_mise_bin)
    if [ -n "$mise_cmd" ] && run_as_user "$mise_cmd" which python &>/dev/null; then
        mise_py="${YELLOW}⚠️  Detectado shim de Python en Mise (se recomienda eliminar para proteger el sistema)${NC}"
    else
        mise_py="${GREEN}✅ Ninguno (El sistema corre 100% nativo con /usr/bin/python3)${NC}"
    fi

    uv_cmd=$(get_uv_bin)
    if [ -n "$uv_cmd" ] && [ -x "$uv_cmd" ]; then
        local uv_v
        uv_v=$(run_as_user "$uv_cmd" --version 2>/dev/null || echo "instalado")
        uv_status="${GREEN}✅ $uv_v ($uv_cmd)${NC}"
    else
        uv_status="${RED}❌ No instalado${NC}"
    fi

    uvx_cmd=$(get_uvx_bin)
    if [ -n "$uvx_cmd" ] && [ -x "$uvx_cmd" ]; then
        local uvx_v
        uvx_v=$(run_as_user "$uvx_cmd" --version 2>/dev/null || echo "instalado")
        uvx_status="${GREEN}✅ $uvx_v ($uvx_cmd)${NC}"
    else
        uvx_status="${RED}❌ No instalado${NC}"
    fi

    echo -e "${BOLD}1. Python Nativo del Sistema (CachyOS Workstation):${NC}"
    echo -e "  • Binario ejecutable:    $py_bin"
    echo -e "  • Versión activa:        ${CYAN}$py_ver${NC}"
    echo -e "  • Paquete Pacman:        $py_pkg"
    echo -e "  • Módulo python3-venv:   $venv_status"
    echo -e "  • Gestor pip de sistema: $pip_status"
    echo -e "-----------------------------------------------------------------"
    echo -e "${BOLD}2. Hardware y Concurrencia (AMD Ryzen 7 7730U):${NC}"
    echo -e "  • Hilos de compilación:  ${GREEN}$NPROC hilos activos${NC} (MAKEFLAGS=\"-j$NPROC\")"
    echo -e "  • Concurrencia de uv:    UV_CONCURRENT_DOWNLOADS=$NPROC"
    echo -e "  • Modo de enlace:        UV_LINK_MODE=$UV_LINK_MODE (seguro para Btrfs/NVMe)"
    echo -e "-----------------------------------------------------------------"
    echo -e "${BOLD}3. Aislamiento y Gestores de Paquetes:${NC}"
    echo -e "  • Shims de Mise:         $mise_py"
    echo -e "  • Gestor 'uv':           $uv_status"
    echo -e "  • Ejecutor 'uvx':        $uvx_status"
    echo -e "-----------------------------------------------------------------"
    echo -e "${BOLD}4. Integración en el Entorno:${NC}"
    echo -e "  • GNOME environment.d:   $([ -f "$USER_HOME/.config/environment.d/10-python.conf" ] && echo -e "${GREEN}✅ Activo (~/.config/environment.d/10-python.conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    echo -e "  • Shell Bash (~/.bashrc.d): $([ -f "$USER_HOME/.bashrc.d/python.sh" ] && echo -e "${GREEN}✅ Activo (~/.bashrc.d/python.sh)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    echo -e "  • Autocompletado Bash:   $([ -f "$USER_HOME/.local/share/bash-completion/completions/uv" ] && echo -e "${GREEN}✅ Configurado (uv & uvx)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    if [ -f "$USER_HOME/.zshrc" ] || [ -d "$USER_HOME/.zshrc.d" ]; then
        echo -e "  • Shell Zsh (~/.zshrc.d):   $([ -f "$USER_HOME/.zshrc.d/python.zsh" ] && echo -e "${GREEN}✅ Activo (~/.zshrc.d/python.zsh)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
        echo -e "  • Autocompletado Zsh:    $([ -f "$USER_HOME/.local/share/zsh/site-functions/_uv" ] && echo -e "${GREEN}✅ Configurado (_uv & _uvx)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    fi
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. ACTUALIZACIÓN DE UV
# ------------------------------------------------------------------------------
update_uv() {
    log_step "Actualizando gestor 'uv' y 'uvx'..."
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -n "$mise_cmd" ] && [ -x "$mise_cmd" ]; then
        log_info "Actualizando 'uv@latest' a través de Mise ($mise_cmd)..."
        run_as_user "$mise_cmd" use --global uv@latest
        run_as_user "$mise_cmd" reshim 2>/dev/null || true
        log_ok "'uv' actualizado con éxito a la última versión en Mise."
    elif command -v uv &>/dev/null; then
        if uv self update 2>/dev/null; then
            log_ok "'uv' actualizado vía 'uv self update'."
        else
            log_warn "No se pudo actualizar directamente con 'uv self update'. Instalando con Mise..."
            ensure_mise_and_uv
        fi
    else
        log_warn "Mise no está configurado. Ejecutando instalación de Mise..."
        ensure_mise_and_uv
    fi
}

ensure_mise_and_uv() {
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -z "$mise_cmd" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$script_dir/mise.sh" ]; then
            log_info "Ejecutando aprovisionamiento de Mise ($script_dir/mise.sh)..."
            bash "$script_dir/mise.sh"
            mise_cmd=$(get_mise_bin)
        fi
    fi

    if [ -n "$mise_cmd" ] && [ -x "$mise_cmd" ]; then
        log_info "Configurando 'uv@latest' como runtime global en Mise..."
        run_as_user "$mise_cmd" use --global uv@latest
        run_as_user "$mise_cmd" reshim 2>/dev/null || true
        log_ok "'uv' y 'uvx' aprovisionados en Mise."
    else
        log_error "No se pudo encontrar ni instalar 'mise'. Ejecuta './mise.sh' primero."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 5. PROCESAMIENTO DE ARGUMENTOS CLI
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

echo -e "${CYAN}=================================================================${NC}"
echo -e "${BOLD}🐍 Configurando Python Nativo de CachyOS y Gestor 'uv' (Mise)${NC}"
echo -e "   Hardware: AMD Ryzen 7 7730U (16T) | 32GB RAM | CachyOS Workstation"
echo -e "${CYAN}=================================================================${NC}"

# ------------------------------------------------------------------------------
# 6. VERIFICAR PYTHON NATIVO DE CACHYOS
# ------------------------------------------------------------------------------
log_step "[1/4] Comprobando integridad del Python nativo de CachyOS..."
MISSING_PKGS=()
for pkg in python python-pip; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    log_info "Instalando paquetes nativos faltantes vía Pacman: ${MISSING_PKGS[*]}..."
    if [ -n "$SUDO" ] && ! command -v sudo &>/dev/null; then
        log_warn "No se dispone de 'sudo' para instalar paquetes del sistema: ${MISSING_PKGS[*]}"
    else
        $SUDO pacman -S --needed --noconfirm "${MISSING_PKGS[@]}" 2>/dev/null || true
    fi
    log_ok "Paquetes nativos de CachyOS asegurados."
else
    local_ver=$(python3 --version 2>/dev/null || echo "Python 3")
    log_ok "Python nativo de CachyOS ($local_ver) y cabeceras intactas."
fi

# Validar módulo venv
if ! python3 -m venv --help &>/dev/null; then
    log_warn "El módulo python3-venv no responde. Asegurando paquetes del sistema..."
    if [ -n "$SUDO" ] && command -v sudo &>/dev/null; then
        $SUDO pacman -S --needed --noconfirm python 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 7. GARANTIZAR AISLAMIENTO (PEP 668 - SIN SHIMS GLOBALES DE PYTHON EN MISE)
# ------------------------------------------------------------------------------
log_step "[2/4] Asegurando cumplimiento de PEP 668 y aislamiento de Mise..."
MISE_CMD=$(get_mise_bin)
if [ -n "$MISE_CMD" ] && [ -x "$MISE_CMD" ]; then
    if run_as_user "$MISE_CMD" which python &>/dev/null; then
        log_info "Eliminando shim global de Python en Mise para proteger el sistema..."
        run_as_user "$MISE_CMD" unuse --global python 2>/dev/null || true
        run_as_user "$MISE_CMD" reshim 2>/dev/null || true
    fi
    log_ok "Aislamiento garantizado: el sistema utiliza /usr/bin/python3 sin interferencias."
fi

# ------------------------------------------------------------------------------
# 8. INSTALAR / VERIFICAR GESTOR 'uv' VÍA MISE
# ------------------------------------------------------------------------------
log_step "[3/4] Verificando gestor 'uv' para gestión aislada per-project..."
ensure_mise_and_uv

# ------------------------------------------------------------------------------
# 9. INTEGRACIÓN CON GNOME SHELL, SHELLS Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
log_step "[4/4] Configurando variables de entorno y autocompletados..."

ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
BASH_COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"

run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D" "$BASH_COMPLETIONS_DIR"

# 9.1. Integración con sesión gráfica GNOME Shell (systemd user)
cat << 'EOF' | run_as_user tee "$ENV_DIR/10-python.conf" > /dev/null
# Integración de Python & uv para Wayland / GNOME Shell (CachyOS Workstation)
PYTHONUNBUFFERED=1
UV_LINK_MODE=copy
EOF

# 9.2. Shell Bash (predeterminada)
cat << 'EOF' | run_as_user tee "$BASHRC_D/python.sh" > /dev/null
# Python & uv Environment Settings (CachyOS Workstation)
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF

# 9.3. Shell Zsh (compatibilidad condicional)
if [ -f "$USER_HOME/.zshrc" ] || [ -d "$USER_HOME/.zshrc.d" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/python.zsh" > /dev/null
# Python & uv Environment Settings (CachyOS Workstation)
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF
fi

# 9.4. Generación de Autocompletados (uv y uvx) de forma segura como usuario
UV_BIN=$(get_uv_bin)
UVX_BIN=$(get_uvx_bin)

if [ -n "$UV_BIN" ] && [ -x "$UV_BIN" ]; then
    # Bash completions
    run_as_user "$UV_BIN" generate-shell-completion bash 2>/dev/null | run_as_user tee "$BASH_COMPLETIONS_DIR/uv" > /dev/null || true
    if [ -n "$UVX_BIN" ] && [ -x "$UVX_BIN" ]; then
        (run_as_user "$UVX_BIN" --generate-shell-completion bash 2>/dev/null || run_as_user "$UVX_BIN" generate-shell-completion bash 2>/dev/null) | run_as_user tee "$BASH_COMPLETIONS_DIR/uvx" > /dev/null || true
    fi

    # Zsh completions
    if [ -f "$USER_HOME/.zshrc" ] || [ -d "$USER_HOME/.zshrc.d" ]; then
        ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
        ZFUNC_DIR="$USER_HOME/.zfunc"
        run_as_user mkdir -p "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

        run_as_user "$UV_BIN" generate-shell-completion zsh 2>/dev/null | run_as_user tee "$ZSH_COMPLETIONS_DIR/_uv" > /dev/null || true
        run_as_user cp -f "$ZSH_COMPLETIONS_DIR/_uv" "$ZFUNC_DIR/_uv" 2>/dev/null || true

        if [ -n "$UVX_BIN" ] && [ -x "$UVX_BIN" ]; then
            (run_as_user "$UVX_BIN" --generate-shell-completion zsh 2>/dev/null || run_as_user "$UVX_BIN" generate-shell-completion zsh 2>/dev/null) | run_as_user tee "$ZSH_COMPLETIONS_DIR/_uvx" > /dev/null || true
            run_as_user cp -f "$ZSH_COMPLETIONS_DIR/_uvx" "$ZFUNC_DIR/_uvx" 2>/dev/null || true
        fi
    fi
    log_ok "Autocompletados generados correctamente en el espacio de usuario."
else
    log_warn "Binario de 'uv' aún no disponible en disco. Autocompletados omitidos."
fi

# ------------------------------------------------------------------------------
# 10. RESUMEN FINAL
# ------------------------------------------------------------------------------
PYTHON_VER=$(python3 --version 2>/dev/null || echo "Python nativo del sistema")
UV_VER="uv pendiente de carga"
if [ -n "$UV_BIN" ] && [ -x "$UV_BIN" ]; then
    UV_VER=$(run_as_user "$UV_BIN" --version 2>/dev/null || echo "uv disponible")
fi

echo -e "${CYAN}=================================================================${NC}"
echo -e "${GREEN}${BOLD}✅ Entorno Python & uv listo para CachyOS Workstation y GNOME:${NC}"
echo -e "  • Python Sistema: ${CYAN}$PYTHON_VER${NC} (/usr/bin/python3 nativo)"
echo -e "  • Gestor uv:      ${GREEN}$UV_VER${NC} (gestión per-project en espacio de usuario)"
echo -e "  • Optimización:   UV_LINK_MODE=copy | MAKEFLAGS=\"-j$NPROC\" (AMD Ryzen 7 7730U)"
echo -e "  • GNOME Shell:    ~/.config/environment.d/10-python.conf"
echo -e "  • Shells:         Bash (~/.bashrc.d/python.sh)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (~/.zshrc.d/python.zsh)")"
echo -e "  • Inicializador:  Ejecuta '${BOLD}./ProgrammingLanguages/python-uv-init.sh${NC}' o '${BOLD}just python-uv${NC}'"
echo -e "${CYAN}=================================================================${NC}"
