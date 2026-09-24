#!/bin/bash
# ==============================================================================
# nodejs.sh - Instalación y Optimización de Node.js (Última LTS) vía Mise
# openSUSE Tumbleweed (KDE Plasma 6 + Wayland / Systemd User Environment)
# ==============================================================================
# Características:
# - Despliegue idempotente y rootless en espacio de usuario vía Mise.
# - Detección inteligente de dependencias (gcc-c++, make, curl, python3) sin
#   llamadas innecesarias a 'sudo' ni bloqueos del gestor Zypper si ya existen.
# - Optimización multinúcleo para compilación de módulos nativos C++ (node-gyp).
# - Habilitación de Corepack (pnpm, yarn) con descargas desatendidas.
# - Integración nativa con KDE Plasma 6 (environment.d) y Shells (Bash / Zsh).
# - Generación automática de autocompletados nativos para npm y pnpm.
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

# Flags de optimización multinúcleo (AMD Ryzen / multinúcleo) para node-gyp
NPROC=$(nproc 2>/dev/null || echo 8)
export MAKEFLAGS="-j$NPROC"
export JOBS="$NPROC"
export npm_config_jobs="$NPROC"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Exportar PATH para este proceso y funciones
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            MAKEFLAGS="-j$NPROC" JOBS="$NPROC" npm_config_jobs="$NPROC" \
            COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        MAKEFLAGS="-j$NPROC" JOBS="$NPROC" npm_config_jobs="$NPROC" \
        COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
        PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🟢 Instalador y Optimizador de Node.js (LTS) - openSUSE Tumbleweed (Mise)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala/actualiza Node.js LTS, Corepack (pnpm/yarn), optimizaciones
                      y genera autocompletados e integración con KDE Plasma 6.
  --status, -s        Muestra el diagnóstico de Node.js, npm, pnpm, yarn, mise y node-gyp.
  --update, -u        Fuerza la actualización de Node.js LTS y refresca Corepack y shims.
  --help, -h          Muestra este mensaje de ayuda.

EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO NODE.JS (MISE + OPENSUSE TUMBLEWEED)"
    echo "================================================================="

    local mise_status node_ver npm_ver pnpm_ver yarn_ver nodegyp_status

    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        local mise_ver
        mise_ver=$(run_as_user mise --version 2>/dev/null | head -n1 || echo "Instalado")
        mise_status="✅ Activo ($mise_ver)"
    else
        mise_status="❌ No instalado"
    fi

    node_ver=$(run_as_user mise exec node@lts -- node --version 2>/dev/null || echo "No disponible")
    npm_ver=$(run_as_user mise exec node@lts -- npm --version 2>/dev/null || echo "No disponible")
    pnpm_ver=$(run_as_user mise exec node@lts -- pnpm --version 2>/dev/null || echo "No disponible")
    yarn_ver=$(run_as_user mise exec node@lts -- yarn --version 2>/dev/null || echo "No disponible")

    # Comprobar herramientas para compilación de módulos C++ nativos (node-gyp)
    local gyp_tools=()
    if rpm -q gcc-c++ &>/dev/null; then gyp_tools+=("g++: ✅"); else gyp_tools+=("g++: ❌"); fi
    if rpm -q make &>/dev/null; then gyp_tools+=("make: ✅"); else gyp_tools+=("make: ❌"); fi
    if command -v python3 &>/dev/null; then gyp_tools+=("python3: ✅"); else gyp_tools+=("python3: ❌"); fi
    nodegyp_status="${gyp_tools[*]}"

    echo "• Gestor de Runtimes:      $mise_status"
    echo "• Node.js (LTS):           $node_ver"
    echo "• Gestor npm:              $npm_ver"
    echo "• Gestor pnpm:             $pnpm_ver"
    echo "• Gestor yarn:             $yarn_ver"
    echo "• Entorno nativo node-gyp: $nodegyp_status"
    echo "• Núcleos para compilar:   $NPROC hilos paralelos"
    echo "• Directorio Shims Mise:   $USER_HOME/.local/share/mise/shims"
    echo "• Entorno KDE Plasma 6:    $(if [ -f "$USER_HOME/.config/environment.d/10-nodejs.conf" ]; then echo "✅ Configurado"; else echo "ℹ️ No presente"; fi)"
    echo "• Autocompletado Bash:     $(if [ -f "$USER_HOME/.local/share/bash-completion/completions/npm" ]; then echo "✅ npm & pnpm activos"; else echo "ℹ️ No generado"; fi)"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. CONTROL DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
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
        echo "🔄 Actualizando Node.js LTS vía Mise..."
        run_as_user mise upgrade node@lts 2>/dev/null || run_as_user mise use --global node@lts
        run_as_user mise exec node@lts -- corepack enable 2>/dev/null || true
        run_as_user mise reshim 2>/dev/null || true
        echo "✅ Node.js LTS y Corepack actualizados con éxito."
        show_status
        exit 0
        ;;
esac

echo "================================================================="
echo "🟢 Instalando y Optimizando Node.js (LTS) para openSUSE Tumbleweed"
echo "================================================================="

# ------------------------------------------------------------------------------
# 4. ASEGURAR GESTOR MISE
# ------------------------------------------------------------------------------
if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/mise.sh" ]; then
        echo "ℹ️ Mise no encontrado. Ejecutando instalador $SCRIPT_DIR/mise.sh..."
        bash "$SCRIPT_DIR/mise.sh"
    else
        echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# 5. DEPENDENCIAS DEL SISTEMA (IDEMPOTENTE Y SIN SUDO INNECESARIO)
# ------------------------------------------------------------------------------
echo "ℹ️ [1/4] Verificando dependencias del sistema para módulos nativos (node-gyp)..."
MISSING_PKGS=()
if ! rpm -q gcc-c++ &>/dev/null; then MISSING_PKGS+=("gcc-c++"); fi
if ! rpm -q make &>/dev/null; then MISSING_PKGS+=("make"); fi
if ! rpm -q curl &>/dev/null; then MISSING_PKGS+=("curl"); fi
if ! command -v python3 &>/dev/null; then MISSING_PKGS+=("python3-base"); fi

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  📦 Instalando dependencias faltantes (${MISSING_PKGS[*]}) vía Zypper..."
    if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
        echo "❌ Error: Se requieren permisos administrativos para instalar: ${MISSING_PKGS[*]}"
        exit 1
    fi
    $SUDO zypper --non-interactive install -y "${MISSING_PKGS[@]}"
    echo "  ✅ Dependencias de sistema instaladas."
else
    echo "  ✅ Dependencias de compilación (gcc-c++, make, curl, python3) ya satisfechas."
fi

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN / CONFIGURACIÓN DE NODE.JS LTS VÍA MISE
# ------------------------------------------------------------------------------
echo "ℹ️ [2/4] Instalando / Verificando Node.js LTS vía Mise..."
run_as_user mise use --global node@lts

# ------------------------------------------------------------------------------
# 7. ACTIVAR COREPACK (PNPM & YARN) Y REGENERAR SHIMS
# ------------------------------------------------------------------------------
echo "ℹ️ [3/4] Habilitando Corepack (pnpm y yarn) y regenerando shims..."
run_as_user mise exec node@lts -- corepack enable 2>/dev/null || true
run_as_user mise reshim 2>/dev/null || true

# ------------------------------------------------------------------------------
# 8. INTEGRACIÓN CON KDE PLASMA 6, SHELLS Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
echo "ℹ️ [4/4] Configurando variables de entorno, sesión KDE y autocompletados..."

ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
BASH_COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"

run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D" "$BASH_COMPLETIONS_DIR"

# 8.1. Integración con sesión gráfica KDE Plasma 6 (systemd user)
cat << EOF | run_as_user tee "$ENV_DIR/10-nodejs.conf" > /dev/null
# Node.js Environment Settings (KDE Plasma 6 + Wayland)
COREPACK_ENABLE_DOWNLOAD_PROMPT=0
JOBS=$NPROC
npm_config_jobs=$NPROC
EOF

# 8.2. Shell Bash (predeterminada)
cat << EOF | run_as_user tee "$BASHRC_D/nodejs.sh" > /dev/null
# Node.js & Corepack Environment Settings
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export JOBS=$NPROC
export npm_config_jobs=$NPROC
EOF

# 8.3. Shell Zsh (compatibilidad condicional)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << EOF | run_as_user tee "$ZSHRC_D/nodejs.zsh" > /dev/null
# Node.js & Corepack Environment Settings
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
export JOBS=$NPROC
export npm_config_jobs=$NPROC
EOF
fi

# 8.4. Autocompletados para Bash
if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
    run_as_user mise exec node@lts -- npm completion > "$BASH_COMPLETIONS_DIR/npm" 2>/dev/null || true
    run_as_user mise exec node@lts -- pnpm completion bash > "$BASH_COMPLETIONS_DIR/pnpm" 2>/dev/null || true
fi

# 8.5. Autocompletados para Zsh (si existe ~/.zshrc)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
    ZFUNC_DIR="$USER_HOME/.zfunc"
    run_as_user mkdir -p "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        run_as_user mise exec node@lts -- pnpm completion zsh > "$ZSH_COMPLETIONS_DIR/_pnpm" 2>/dev/null || true
        run_as_user mise exec node@lts -- pnpm completion zsh > "$ZFUNC_DIR/_pnpm" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 9. RESUMEN FINAL
# ------------------------------------------------------------------------------
NODE_VER=$(run_as_user mise exec node@lts -- node --version 2>/dev/null || echo "instalado")
NPM_VER=$(run_as_user mise exec node@lts -- npm --version 2>/dev/null || echo "instalado")
PNPM_VER=$(run_as_user mise exec node@lts -- pnpm --version 2>/dev/null || echo "disponible vía corepack")
YARN_VER=$(run_as_user mise exec node@lts -- yarn --version 2>/dev/null || echo "disponible vía corepack")

echo "================================================================="
echo "✅ Node.js LTS configurado con éxito para openSUSE Tumbleweed y KDE 6:"
echo "  • Node.js:      $NODE_VER (LTS)"
echo "  • npm:          $NPM_VER"
echo "  • pnpm:         $PNPM_VER (Corepack)"
echo "  • yarn:         $YARN_VER (Corepack)"
echo "  • Compilación:  node-gyp optimizado para $NPROC hilos paralelos"
echo "  • Entorno KDE:  ~/.config/environment.d/10-nodejs.conf"
echo "  • Shells:       Bash (predeterminada)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (compatible)") con autocompletados nativos"
echo "  • Shims Mise:   $USER_HOME/.local/share/mise/shims"
echo "================================================================="
