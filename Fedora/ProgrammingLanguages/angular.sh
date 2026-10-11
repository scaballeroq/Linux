#!/bin/bash
# angular.sh - Instalación y configuración de Angular CLI (Última versión estable) vía Mise en Fedora 44 + KDE Plasma
#
# Uso:
#   ./angular.sh                     -> Instala Angular CLI latest vía Mise, desactiva telemetría y configura autocompletado
#   ./angular.sh --status            -> Muestra la versión de Angular CLI, Node.js y paquetes globales
#   ./angular.sh --update            -> Actualiza Angular CLI a la última versión disponible
#   ./angular.sh --help              -> Muestra la ayuda interactiva

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat <<EOF
🅰️ Gestor e Instalador de Angular CLI (Latest) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala la última versión oficial de Angular CLI vía Mise, desactiva telemetría y configura autocompletado.
  --status, -s           Muestra la versión instalada de Angular CLI, Node y herramientas globales.
  --update, -u           Actualiza Angular CLI (@angular/cli@latest) a la última versión disponible.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Angular CLI Latest:  Instala npm:@angular/cli@latest gestionado de forma aislada e independiente con Mise.
  • Requisito Node.js:   Asegura la presencia previa de Node.js LTS.
  • Rendimiento y Telemetría: Configura NG_CLI_ANALYTICS=false para agilizar la ejecución y evitar prompts interactivos.
  • Autocompletado:      Genera autocompletado para el comando 'ng' en el shell Bash.
EOF
}

# Asegurar que Mise y Node.js LTS estén instalados
ensure_node() {
    if ! command -v mise &> /dev/null; then
        echo "⚠️ Mise no está instalado. Ejecutando ./mise.sh..."
        if [ -f "$SCRIPT_DIR/mise.sh" ]; then
            "$SCRIPT_DIR/mise.sh"
            export PATH="$HOME/.local/share/mise/shims:$PATH"
            eval "$(mise activate bash 2>/dev/null || true)"
        fi
    fi

    if ! command -v node &> /dev/null; then
        echo "⚠️ Node.js no está instalado. Ejecutando ./nodejs.sh..."
        if [ -f "$SCRIPT_DIR/nodejs.sh" ]; then
            "$SCRIPT_DIR/nodejs.sh"
            export PATH="$HOME/.local/share/mise/shims:$PATH"
            eval "$(mise activate bash 2>/dev/null || true)"
        fi
    fi
}

# 1. Mostrar estado de Angular CLI
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE ANGULAR CLI - FEDORA 44"
    echo "================================================================="
    if command -v ng &>/dev/null; then
        echo "• Angular CLI:         $(ng version 2>/dev/null | grep 'Angular CLI:' | awk '{print $3}' || echo 'Instalado')"
        echo "• Ruta binario ng:     $(which ng 2>/dev/null || echo 'n/a')"
        echo "• Node.js asociado:    $(node --version 2>/dev/null || echo 'No detectado')"
    else
        echo "• Angular CLI:         No instalado"
    fi
    echo "================================================================="
}

# 2. Actualizar Angular CLI
update_angular() {
    echo "🔄 Actualizando Angular CLI a la última versión (@angular/cli@latest)..."
    ensure_node
    mise install npm:@angular/cli@latest
    mise use --global npm:@angular/cli@latest
    mise reshim
    echo "✅ Angular CLI actualizado con éxito."
}

# 3. Instalar Angular CLI vía Mise
install_angular() {
    ensure_node
    echo "🚀 [1/3] Instalando Angular CLI latest vía Mise..."
    mise install npm:@angular/cli@latest
    mise use --global npm:@angular/cli@latest
    echo "✅ Angular CLI instalado globalmente en Mise."
}

# 4. Configurar telemetría y autocompletado
configure_angular() {
    echo "⚙️ [2/3] Desactivando telemetría analítica interactiva para agilizar ejecución..."
    export NG_CLI_ANALYTICS=false
    
    # 4.1. Variables de entorno en ~/.bashrc.d/angular.sh
    mkdir -p "$HOME/.bashrc.d"
    cat <<'EOF' > "$HOME/.bashrc.d/angular.sh"
# Angular CLI Analytics Opt-Out
export NG_CLI_ANALYTICS=false
EOF

    # 4.2. Autocompletado para Bash
    echo "🔗 [3/3] Configurando autocompletado para el comando 'ng'..."
    mkdir -p "$HOME/.local/share/bash-completion/completions"
    if command -v ng &>/dev/null; then
        ng completion script > "$HOME/.local/share/bash-completion/completions/ng" 2>/dev/null || true
    fi

    mise reshim
    echo "✅ Angular CLI y autocompletado listos."
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
    --update|-u|update)
        update_angular
        show_status
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🅰️ INSTALADOR DE ANGULAR CLI (LATEST) - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        install_angular
        configure_angular
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Angular CLI configurado correctamente."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
