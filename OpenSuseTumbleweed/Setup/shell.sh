#!/bin/bash
# ==============================================================================
# shell.sh - Instalación y Optimización de Herramientas Modernas de Terminal
# openSUSE Tumbleweed (KDE Plasma 6)
# (eza, bat, fzf, zoxide, ripgrep, fd, duf, dust, procs, btop, jq)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
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

CLI_TOOLS=(
    eza
    bat
    fzf
    zoxide
    ripgrep
    fd
    duf
    dust
    procs
    btop
    curl
    git
    jq
)

BASHRC="$USER_HOME/.bashrc"
BASHRC_D="$USER_HOME/.bashrc.d"
ZSHRC="$USER_HOME/.zshrc"
ZSHRC_D="$USER_HOME/.zshrc.d"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BASH_SETUP_DIR="$WORKSPACE_ROOT/Bash.Setup"

show_help() {
    cat <<EOF
🐚 Optimizador y Gestor de Shell Moderna - openSUSE Tumbleweed

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala las utilidades CLI faltantes, configura zoxide y fzf
                      en Bash/Zsh y enlaza los scripts modulares de Bash.Setup/.
  --status, -s        Muestra el estado de instalación de las herramientas CLI,
                      integraciones de Zoxide/FZF y symlinks en ~/.bashrc.d.
  --help, -h          Muestra este mensaje de ayuda.

Herramientas gestionadas:
  • eza:       Sustituto moderno de 'ls' con soporte git, iconos y colores.
  • bat:       Visor de archivos ('cat' mejorado) con syntax highlighting y paginación.
  • fzf:       Buscador difuso interactivo (Ctrl+R para historial, Ctrl+T para archivos, Alt+C).
  • zoxide:    Navegación inteligente de directorios ('cd' rápido con memoria de frecuencias).
  • ripgrep:   Búsqueda ultra-rápida de texto (rg) respetando .gitignore.
  • fd:        Búsqueda intuitiva y rápida de archivos en lugar de find.
  • duf/dust:  Visualización estética del uso de disco y directorios.
  • procs:     Visualizador moderno de procesos con jerarquía y colores.
  • btop:      Monitor interactivo de recursos del sistema con aceleración y gráficos.
  • jq/curl:   Manipulación JSON e interacción con APIs y red.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE HERRAMIENTAS CLI Y SHELL - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "📦 Utilidades CLI Modernas:"
    for tool in "${CLI_TOOLS[@]}"; do
        if rpm -q "$tool" &>/dev/null; then
            local ver
            ver=$(rpm -q --qf '%{VERSION}' "$tool" 2>/dev/null || echo "instalado")
            printf "  • %-10s ✅ Instalado (v%s)\n" "$tool" "$ver"
        else
            printf "  • %-10s ❌ No instalado\n" "$tool"
        fi
    done
    echo "-----------------------------------------------------------------"
    echo "🐚 Integración en Bash ($BASHRC):"
    echo "  • Cargador modular (.bashrc.d): $(if grep -q "\.bashrc\.d" "$BASHRC" 2>/dev/null; then echo "✅ Configurado"; else echo "❌ No presente"; fi)"
    echo "  • Zoxide (smart cd):            $(if grep -q "zoxide init bash" "$BASHRC" 2>/dev/null; then echo "✅ Activo"; else echo "❌ No presente"; fi)"
    echo "  • FZF (Ctrl+R / Ctrl+T / Alt+C): $(if grep -q "fzf --bash" "$BASHRC" 2>/dev/null; then echo "✅ Activo"; else echo "❌ No presente"; fi)"
    echo "  • Scripts enlazados (~/.bashrc.d/): $(find "$BASHRC_D" -maxdepth 1 -name "*.sh" 2>/dev/null | wc -l) archivos"

    if [ -f "$ZSHRC" ]; then
        echo "-----------------------------------------------------------------"
        echo "🐚 Integración en Zsh ($ZSHRC):"
        echo "  • Cargador modular (.zshrc.d):  $(if grep -q "\.zshrc\.d" "$ZSHRC" 2>/dev/null; then echo "✅ Configurado"; else echo "❌ No presente"; fi)"
        echo "  • Zoxide (smart cd):            $(if grep -q "zoxide init zsh" "$ZSHRC" 2>/dev/null; then echo "✅ Activo"; else echo "❌ No presente"; fi)"
        echo "  • FZF (Ctrl+R / Ctrl+T / Alt+C): $(if grep -q "fzf --zsh" "$ZSHRC" 2>/dev/null; then echo "✅ Activo"; else echo "❌ No presente"; fi)"
    fi
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
esac

echo "================================================================="
echo "🐚 CONFIGURANDO UTILIDADES MODERNAS DE TERMINAL (OPENSUSE TUMBLEWEED)"
echo "================================================================="

# 1. Instalación idempotente de herramientas CLI
echo "ℹ️ [1/4] Verificando estado de paquetes CLI..."
MISSING_PACKAGES=()
for pkg in "${CLI_TOOLS[@]}"; do
    if ! rpm -q "$pkg" &>/dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo "  ✅ Todas las utilidades CLI ya están instaladas en el sistema."
else
    echo "  ⬇️ Instalando utilidades faltantes vía Zypper: ${MISSING_PACKAGES[*]}..."
    $SUDO zypper --non-interactive install -y "${MISSING_PACKAGES[@]}"
    echo "  ✅ Paquetes instalados con éxito."
fi

# 2. Integración de Zoxide, FZF y Carga Modular en Bash
echo "⚙️ [2/4] Configurando integraciones en Bash (~/.bashrc)..."
run_as_user touch "$BASHRC"
run_as_user mkdir -p "$BASHRC_D"

# 2.1. Zoxide en Bash
if ! grep -q "zoxide init bash" "$BASHRC" 2>/dev/null; then
    cat << 'EOF' | run_as_user tee -a "$BASHRC" > /dev/null

# Zoxide (Smart cd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi
EOF
    echo "  ✅ Zoxide integrado en ~/.bashrc"
else
    echo "  ℹ️ Zoxide ya presente en ~/.bashrc"
fi

# 2.2. FZF (Keybindings y autocompletado en Bash)
if ! grep -q "fzf --bash" "$BASHRC" 2>/dev/null; then
    cat << 'EOF' | run_as_user tee -a "$BASHRC" > /dev/null

# FZF (Fuzzy Finder: Ctrl+R, Ctrl+T, Alt+C y completion)
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash)"
fi
EOF
    echo "  ✅ FZF integrado en ~/.bashrc (Ctrl+R, Ctrl+T, Alt+C)"
else
    echo "  ℹ️ FZF ya presente en ~/.bashrc"
fi

# 2.3. Cargador modular en ~/.bashrc
if ! grep -q "\.bashrc\.d" "$BASHRC" 2>/dev/null; then
    cat << 'EOF' | run_as_user tee -a "$BASHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.bashrc.d)
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
    echo "  ✅ Cargador modular añadido a ~/.bashrc"
else
    echo "  ℹ️ Cargador modular ya presente en ~/.bashrc"
fi

# 3. Integración en Zsh (si existe ~/.zshrc)
if [ -f "$ZSHRC" ]; then
    echo "⚙️ [3/4] Detectado ~/.zshrc. Configurando integraciones en Zsh..."
    run_as_user mkdir -p "$ZSHRC_D"

    # 3.1. Zoxide en Zsh
    if ! grep -q "zoxide init zsh" "$ZSHRC" 2>/dev/null; then
        cat << 'EOF' | run_as_user tee -a "$ZSHRC" > /dev/null

# Zoxide (Smart cd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi
EOF
        echo "  ✅ Zoxide integrado en ~/.zshrc"
    else
        echo "  ℹ️ Zoxide ya presente en ~/.zshrc"
    fi

    # 3.2. FZF en Zsh
    if ! grep -q "fzf --zsh" "$ZSHRC" 2>/dev/null; then
        cat << 'EOF' | run_as_user tee -a "$ZSHRC" > /dev/null

# FZF (Fuzzy Finder: Ctrl+R, Ctrl+T, Alt+C y completion)
if command -v fzf &>/dev/null; then
    eval "$(fzf --zsh)"
fi
EOF
        echo "  ✅ FZF integrado en ~/.zshrc (Ctrl+R, Ctrl+T, Alt+C)"
    else
        echo "  ℹ️ FZF ya presente en ~/.zshrc"
    fi

    # 3.3. Cargador modular en ~/.zshrc
    if ! grep -q "\.zshrc\.d" "$ZSHRC" 2>/dev/null; then
        cat << 'EOF' | run_as_user tee -a "$ZSHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
        echo "  ✅ Cargador modular añadido a ~/.zshrc"
    else
        echo "  ℹ️ Cargador modular ya presente en ~/.zshrc"
    fi
else
    echo "ℹ️ [3/4] No se detectó ~/.zshrc. Se omite Zsh (entorno exclusivo Bash activo)."
fi

# 4. Enlazar scripts de Bash.Setup a ~/.bashrc.d (y ~/.zshrc.d)
echo "🔗 [4/4] Sincronizando scripts modulares desde Bash.Setup/..."
if [ -d "$BASH_SETUP_DIR" ]; then
    # Limpiar symlinks rotos o residuos obsoletos
    run_as_user rm -f "$BASHRC_D/gnome_settings.sh" 2>/dev/null || true
    [ -d "$ZSHRC_D" ] && run_as_user rm -f "$ZSHRC_D/gnome_settings.sh" 2>/dev/null || true
    run_as_user find -L "$BASHRC_D" -maxdepth 1 -type l -exec rm -f {} + 2>/dev/null || true
    [ -d "$ZSHRC_D" ] && run_as_user find -L "$ZSHRC_D" -maxdepth 1 -type l -exec rm -f {} + 2>/dev/null || true

    for sh_file in "$BASH_SETUP_DIR"/*.sh; do
        if [ -f "$sh_file" ]; then
            base_name="$(basename "$sh_file")"
            run_as_user ln -sf "$sh_file" "$BASHRC_D/$base_name"
            if [ -f "$ZSHRC" ] && [ -d "$ZSHRC_D" ]; then
                run_as_user ln -sf "$sh_file" "$ZSHRC_D/$base_name"
            fi
        fi
    done
    echo "  ✅ Scripts de Bash.Setup enlazados en ~/.bashrc.d/"
    [ -f "$ZSHRC" ] && echo "  ✅ Scripts de Bash.Setup enlazados en ~/.zshrc.d/"
fi

run_as_user mkdir -p "$USER_HOME/.local/bin"

echo "================================================================="
echo "✅ Entorno de terminal configurado con éxito para openSUSE Tumbleweed."
echo "💡 Para cargar las nuevas configuraciones en tu sesión actual:"
echo "   source ~/.bashrc"
if [ -f "$ZSHRC" ]; then
    echo "   (O en Zsh: source ~/.zshrc)"
fi
echo "================================================================="
