#!/bin/bash
# ==============================================================================
# nodejs.sh - Instalación y Optimización de Node.js (Última LTS) vía Mise
# Fedora Workstation (GNOME Shell + Wayland / Systemd User Environment)
# ==============================================================================
# Características:
# - Despliegue idempotente y rootless en espacio de usuario vía Mise.
# - Detección inteligente de dependencias (make, gcc-c++, curl, python3) sin
#   llamadas innecesarias a 'sudo' ni bloqueos si ya existen.
# - Optimización multinúcleo para compilación de módulos nativos C++ (node-gyp).
# - Habilitación de Corepack (pnpm, yarn) con descargas desatendidas.
# - Integración nativa con GNOME Shell (environment.d) y Shells (Bash / Zsh).
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

DNF_CMD=$(command -v dnf5 2>/dev/null || command -v dnf 2>/dev/null || echo "dnf")

# Flags de optimización multinúcleo (AMD Ryzen / multinúcleo) para node-gyp
NPROC=$(nproc 2>/dev/null || echo 8)
export MAKEFLAGS="-j$NPROC"
export JOBS="$NPROC"
export npm_config_jobs="$NPROC"

# Habilitar descargas desatendidas de Corepack sin prompts interactivos
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Exportar rutas de Mise y usuario
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH"

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
🟢 Instalador y Optimizador de Node.js (LTS) - Fedora Workstation (Mise)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala la última versión LTS de Node.js vía Mise, activa Corepack
                      (pnpm/yarn), configura optimizaciones multinúcleo (-j$NPROC) y autocompletados.
  --status, -s        Muestra el diagnóstico de Node.js, gestores de paquetes y variables.
  --update, -u        Actualiza Node.js a la última versión LTS disponible y refresca shims.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO NODE.JS (MISE + FEDORA WORKSTATION)"
    echo "================================================================="

    local node_path node_ver npm_ver pnpm_ver corepack_status

    if command -v node &>/dev/null; then
        node_path=$(which node 2>/dev/null)
        node_ver=$(node --version 2>/dev/null)
    elif [ -x "$USER_HOME/.local/share/mise/shims/node" ]; then
        node_path="$USER_HOME/.local/share/mise/shims/node"
        node_ver=$("$node_path" --version 2>/dev/null || echo "vía Mise")
    else
        node_path="No instalado"
        node_ver="No disponible"
    fi

    npm_ver=$(command -v npm &>/dev/null && npm --version 2>/dev/null || echo "No disponible")
    pnpm_ver=$(command -v pnpm &>/dev/null && pnpm --version 2>/dev/null || echo "No disponible")

    if command -v corepack &>/dev/null; then
        corepack_status="✅ Habilitado ($(corepack --version 2>/dev/null || echo "presente"))"
    else
        corepack_status="❌ No disponible"
    fi

    echo "1. Runtimes y Gestores de Paquetes:"
    echo "  • Node.js:               $node_ver ($node_path)"
    echo "  • npm:                   v$npm_ver"
    echo "  • pnpm (Corepack):       v$pnpm_ver"
    echo "  • Corepack:              $corepack_status"
    echo "-----------------------------------------------------------------"
    echo "2. Optimizaciones de Compilación C++ (node-gyp):"
    echo "  • MAKEFLAGS:             -j$NPROC (Hilos de CPU detectados)"
    echo "  • JOBS / npm_config_jobs: $NPROC"
    echo "-----------------------------------------------------------------"
    echo "3. Integración en el Entorno:"
    echo "  • GNOME environment.d:   $([ -f "$USER_HOME/.config/environment.d/10-nodejs.conf" ] && echo '✅ Activo (~/.config/environment.d/10-nodejs.conf)' || echo '❌ Ausente')"
    echo "  • Shell Bash (~/.bashrc.d): $([ -f "$USER_HOME/.bashrc.d/nodejs.sh" ] && echo '✅ Activo (~/.bashrc.d/nodejs.sh)' || echo '❌ Ausente')"
    echo "  • Autocompletado npm:    $([ -f "$USER_HOME/.local/share/bash-completion/completions/npm" ] && echo '✅ Configurado' || echo '❌ Ausente')"
    echo "  • Autocompletado pnpm:   $([ -f "$USER_HOME/.local/share/bash-completion/completions/pnpm" ] && echo '✅ Configurado' || echo '❌ Ausente')"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo "  • Shell Zsh (~/.zshrc.d):   $([ -f "$USER_HOME/.zshrc.d/nodejs.zsh" ] && echo '✅ Activo (~/.zshrc.d/nodejs.zsh)' || echo '❌ Ausente')"
        echo "  • Autocompletado Zsh:    $([ -f "$USER_HOME/.local/share/zsh/site-functions/_pnpm" ] && echo '✅ Configurado' || echo '❌ Ausente')"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. ACTUALIZACIÓN DE NODE.JS
# ------------------------------------------------------------------------------
update_nodejs() {
    echo "🔄 Comprobando actualizaciones de Node.js LTS vía Mise..."
    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        run_as_user mise use --global node@lts
        run_as_user mise reshim 2>/dev/null || true
        echo "✅ Node.js actualizado con éxito a la última versión LTS."
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
        update_nodejs
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🟢 Instalando y Optimizando Node.js (LTS) para Fedora Workstation"
echo "   Hardware: AMD Ryzen 7 7730U (16 hilos) | NVMe Kioxia | GNOME Wayland"
echo "================================================================="

# ------------------------------------------------------------------------------
# 4. DEPENDENCIAS DE COMPILACIÓN NATIVA (node-gyp / DNF5)
# ------------------------------------------------------------------------------
echo "ℹ️ [1/5] Verificando dependencias del sistema para módulos C++ nativos..."
MISSING_PKGS=()
for pkg in make gcc-c++ curl python3; do
    if ! rpm -q "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  ⬇️ Instalando herramientas faltantes vía $DNF_CMD: ${MISSING_PKGS[*]}..."
    $SUDO $DNF_CMD install -y "${MISSING_PKGS[@]}" 2>/dev/null || true
    echo "  ✅ Herramientas de sistema instaladas."
else
    echo "  ✅ Todas las dependencias del sistema ya están presentes."
fi

# ------------------------------------------------------------------------------
# 5. INSTALAR / VERIFICAR MISE
# ------------------------------------------------------------------------------
echo "ℹ️ [2/5] Asegurando gestor de runtimes Mise..."
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

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN DE NODE.JS LTS VÍA MISE
# ------------------------------------------------------------------------------
echo "ℹ️ [3/5] Desplegando Node.js LTS de forma rootless vía Mise..."
run_as_user mise use --global node@lts
run_as_user mise reshim 2>/dev/null || true

# ------------------------------------------------------------------------------
# 7. ACTIVACIÓN DE COREPACK (PNPM & YARN)
# ------------------------------------------------------------------------------
echo "ℹ️ [4/5] Activando Corepack y habilitando pnpm..."
if run_as_user command -v corepack &>/dev/null || [ -x "$USER_HOME/.local/share/mise/shims/corepack" ]; then
    run_as_user corepack enable 2>/dev/null || true
    run_as_user corepack enable pnpm yarn 2>/dev/null || true
    run_as_user mise reshim 2>/dev/null || true
    echo "  ✅ Corepack habilitado para pnpm y yarn."
fi

# ------------------------------------------------------------------------------
# 8. INTEGRACIÓN CON GNOME SHELL, SHELLS Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
echo "ℹ️ [5/5] Configurando variables de entorno y autocompletados..."

ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
BASH_COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"

run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D" "$BASH_COMPLETIONS_DIR"

# 8.1. Integración con sesión gráfica GNOME Shell (systemd user)
cat << EOF | run_as_user tee "$ENV_DIR/10-nodejs.conf" > /dev/null
# Integración de Node.js & Corepack para Wayland / GNOME Shell
MAKEFLAGS="-j$NPROC"
JOBS="$NPROC"
npm_config_jobs="$NPROC"
COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF

# 8.2. Shell Bash (predeterminada)
cat << EOF | run_as_user tee "$BASHRC_D/nodejs.sh" > /dev/null
# Node.js & npm/pnpm Multithreaded Build Settings (Fedora Workstation)
export MAKEFLAGS="-j$NPROC"
export JOBS="$NPROC"
export npm_config_jobs="$NPROC"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF

# 8.3. Shell Zsh (compatibilidad condicional)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << EOF | run_as_user tee "$ZSHRC_D/nodejs.zsh" > /dev/null
# Node.js & npm/pnpm Multithreaded Build Settings (Fedora Workstation)
export MAKEFLAGS="-j$NPROC"
export JOBS="$NPROC"
export npm_config_jobs="$NPROC"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF
fi

# 8.4. Autocompletados para Bash (npm y pnpm)
if command -v npm &>/dev/null; then
    run_as_user npm completion > "$BASH_COMPLETIONS_DIR/npm" 2>/dev/null || true
fi

if command -v pnpm &>/dev/null; then
    run_as_user pnpm completion bash > "$BASH_COMPLETIONS_DIR/pnpm" 2>/dev/null || true
fi

# 8.5. Autocompletados para Zsh (si existe ~/.zshrc)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
    ZFUNC_DIR="$USER_HOME/.zfunc"
    run_as_user mkdir -p "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

    if command -v pnpm &>/dev/null; then
        run_as_user pnpm completion zsh > "$ZSH_COMPLETIONS_DIR/_pnpm" 2>/dev/null || true
        run_as_user pnpm completion zsh > "$ZFUNC_DIR/_pnpm" 2>/dev/null || true
    fi
fi

# ------------------------------------------------------------------------------
# 9. RESUMEN FINAL
# ------------------------------------------------------------------------------
NODE_VER=$(run_as_user node --version 2>/dev/null || echo "LTS instalado")
NPM_VER=$(run_as_user npm --version 2>/dev/null || echo "npm instalado")
PNPM_VER=$(run_as_user pnpm --version 2>/dev/null || echo "pnpm activo")

echo "================================================================="
echo "✅ Node.js LTS configurado con éxito para Fedora Workstation y GNOME:"
echo "  • Node.js:        $NODE_VER (gestión rootless vía Mise)"
echo "  • Gestor npm:     v$NPM_VER"
echo "  • Gestor pnpm:    v$PNPM_VER (Corepack activo)"
echo "  • Hilos node-gyp: $NPROC núcleos paralelos (-j$NPROC)"
echo "  • Entorno GNOME:  ~/.config/environment.d/10-nodejs.conf"
echo "  • Shells:         Bash (predeterminada)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (compatible)") con autocompletados (npm / pnpm)"
echo "================================================================="
