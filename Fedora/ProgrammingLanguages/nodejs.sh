#!/bin/bash
# nodejs.sh - Instalación y configuración de Node.js (Última versión LTS) y Corepack vía Mise en Fedora 44 + KDE Plasma
#
# Uso:
#   ./nodejs.sh                      -> Instala dependencias, la última versión LTS de Node.js y habilita Corepack (pnpm/yarn)
#   ./nodejs.sh --status             -> Muestra las versiones activas de Node.js, npm, npx, pnpm y yarn
#   ./nodejs.sh --update             -> Actualiza Node.js a la última versión LTS disponible
#   ./nodejs.sh --list               -> Lista las versiones de Node.js instaladas y disponibles en Mise
#   ./nodejs.sh --help               -> Muestra la ayuda interactiva

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

show_help() {
    cat <<EOF
📦 Gestor e Instalador de Node.js LTS - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala dependencias nativas de compilación (node-gyp), la última versión LTS de Node.js y habilita Corepack.
  --status, -s           Muestra el estado de Node.js, npm, pnpm, yarn y la versión activa en el sistema.
  --update, -u           Actualiza Node.js a la versión LTS más reciente y actualiza Corepack.
  --list, -l             Lista las versiones de Node.js instaladas localmente y disponibles.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Versión Dinámica:    Siempre instala y fija 'node@lts' (última versión Long Term Support activa).
  • Dependencias DNF5:   Instala @development-tools, gcc-c++, make y cabeceras C/C++ requeridas por node-gyp.
  • Gestores de Paquetes:Habilita Corepack de forma nativa para soportar pnpm y yarn sin instalaciones globales conflictivas.
  • Integración KDE/IDE: Funciona de forma transparente con VS Code, JetBrains y terminales bajo Wayland.
EOF
}

# Verificar e instalar Mise si no está presente
ensure_mise() {
    if ! command -v mise &> /dev/null; then
        echo "⚠️ Mise no está instalado. Ejecutando ./mise.sh automáticamente..."
        if [ -f "$SCRIPT_DIR/mise.sh" ]; then
            "$SCRIPT_DIR/mise.sh"
            export PATH="$HOME/.local/share/mise/shims:$PATH"
            eval "$(mise activate bash 2>/dev/null || true)"
        else
            echo "❌ Error: No se encontró $SCRIPT_DIR/mise.sh. Instala Mise primero."
            exit 1
        fi
    fi
}

# 1. Mostrar estado actual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE NODE.JS Y ECOSISTEMA JS - FEDORA 44"
    echo "================================================================="
    if command -v node &>/dev/null; then
        echo "• Node.js:             $(node --version 2>/dev/null) (Ruta: $(which node))"
        echo "• npm:                 $(npm --version 2>/dev/null || echo 'No disponible')"
        echo "• npx:                 $(npx --version 2>/dev/null || echo 'No disponible')"
        echo "• pnpm:                $(pnpm --version 2>/dev/null || (mise exec node@lts -- pnpm --version 2>/dev/null) || echo 'No activo (usa corepack)')"
        echo "• yarn:                $(yarn --version 2>/dev/null || (mise exec node@lts -- yarn --version 2>/dev/null) || echo 'No activo (usa corepack)')"
        echo ""
        echo "📦 Versiones de Node gestionadas por Mise:"
        mise ls node 2>/dev/null || echo "  (Ninguna registrada en Mise)"
    else
        echo "• Node.js:             No instalado"
    fi
    echo "================================================================="
}

# 2. Listar versiones disponibles
list_versions() {
    ensure_mise
    echo "================================================================="
    echo "📋 VERSIONES DE NODE.JS INSTALADAS EN MISE"
    echo "================================================================="
    mise ls node 2>/dev/null || echo "Ninguna versión instalada."
    echo ""
    echo "📋 ÚLTIMAS VERSIONES LTS DISPONIBLES EN REMOTO:"
    mise ls-remote node | grep -E '^2[0-9]\.' | tail -n 10 || mise ls-remote node | tail -n 10
    echo "================================================================="
}

# 3. Instalar dependencias de compilación para node-gyp
install_build_dependencies() {
    echo "📦 [1/4] Instalando herramientas de compilación C/C++ (necesarias para node-gyp y módulos nativos)..."
    $SUDO dnf5 install -y \
        @development-tools \
        gcc-c++ \
        make \
        curl \
        python3 \
        libstdc++-devel 2>/dev/null || true
    echo "✅ Herramientas de compilación listas."
}

# 4. Instalar última versión Node.js LTS vía Mise
install_node_lts() {
    ensure_mise
    echo "🚀 [2/4] Descargando e instalando la última versión LTS de Node.js..."
    mise install node@lts
    mise use --global node@lts
    echo "✅ Node.js LTS ($(mise current node 2>/dev/null || echo 'lts')) fijado como versión global."
}

# 5. Habilitar Corepack (pnpm y yarn) y reshim
configure_package_managers() {
    echo "⚙️ [3/4] Habilitando Corepack oficial para soporte nativo de pnpm y yarn..."
    mise exec node@lts -- corepack enable 2>/dev/null || true
    mise exec node@lts -- corepack prepare pnpm@latest --activate 2>/dev/null || true
    mise exec node@lts -- corepack prepare yarn@stable --activate 2>/dev/null || true

    echo "🔗 [4/4] Regenerando shims de Mise..."
    mise reshim
    echo "✅ Corepack, pnpm y yarn preparados."
}

# Procesar argumentos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --list|-l|list)
        list_versions
        exit 0
        ;;
    --update|-u|update)
        echo "🔄 Actualizando Node.js a la última versión LTS..."
        ensure_mise
        mise install node@lts
        mise use --global node@lts
        configure_package_managers
        echo ""
        show_status
        ;;
    "")
        echo "================================================================="
        echo "📦 INSTALADOR DE NODE.JS (ÚLTIMA VERSIÓN LTS) - FEDORA 44"
        echo "================================================================="
        ensure_mise
        install_build_dependencies
        install_node_lts
        configure_package_managers
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Node.js LTS, npm, npx, pnpm y yarn configurados correctamente."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
