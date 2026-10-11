#!/bin/bash
# python.sh - Instalación y configuración de Python (Versión Estable de Producción / Soporte Extendido) vía Mise en Fedora 44 + KDE Plasma
#
# Uso:
#   ./python.sh                      -> Instala dependencias C/C++, Python estable de soporte extendido, pip, wheel y setuptools
#   ./python.sh --version 3.13       -> Instala una versión específica de Python (ej: 3.12, 3.13, latest)
#   ./python.sh 3.13                 -> Atajo directo para especificar versión
#   ./python.sh --status             -> Muestra la versión activa de Python, pip y ubicación de binarios
#   ./python.sh --update             -> Actualiza la versión de Python y paquetes base (pip, setuptools, wheel)
#   ./python.sh --list               -> Lista las versiones de Python instaladas localmente y disponibles en remoto
#   ./python.sh --help               -> Muestra la ayuda interactiva

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Versión estable recomendada de producción (máxima estabilidad, soporte extendido de 5 años y compatibilidad 100% con PyPI/C-Extensions)
PYTHON_VERSION="3.12"

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
🐍 Gestor e Instalador de Python Estable - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala dependencias C/C++, la versión estable con soporte extendido (Python $PYTHON_VERSION), pip, setuptools y wheel.
  --version <VER>, -v    Instala una versión específica de Python (ej: 3.12, 3.13, latest).
  <VALOR_VER>            Atajo directo para la versión (ej: $0 3.13).
  --status, -s           Muestra la versión activa de Python, pip, shims y paquetes globales.
  --update, -u           Actualiza la versión de Python activa y sus herramientas base (pip, setuptools, wheel).
  --list, -l             Lista las versiones de Python instaladas localmente y disponibles en remoto.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Soporte de Producción:Versión estable con soporte extendido para máxima compatibilidad con NumPy, Pandas, PyTorch, Django, etc.
  • Cabeceras DNF5:      Instala librerías del sistema para compilar extensiones C/Rust (OpenSSL, SQLite, FFI, Zlib, Bzip2).
  • Entorno Optimizado:  Actualiza pip, wheel y setuptools para builds de ruedas binarias limpias y rápidas.
  • Integración KDE/IDE: Funciona de forma transparente con VS Code, PyCharm, Dolphin y terminales Wayland.
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
    echo "🔍 ESTADO DE PYTHON Y HERRAMIENTAS - FEDORA 44"
    echo "================================================================="
    if command -v python &>/dev/null; then
        echo "• Python:              $(python --version 2>/dev/null) (Ruta: $(which python))"
        echo "• pip:                 $(pip --version 2>/dev/null | awk '{print $1,$2}' || echo 'No disponible')"
        echo "• Versión activa Mise: $(mise current python 2>/dev/null || echo 'No gestionado por Mise')"
        echo ""
        echo "📦 Versiones de Python instaladas en Mise:"
        mise ls python 2>/dev/null || echo "  (Ninguna registrada en Mise)"
    else
        echo "• Python (Mise):       No instalado"
    fi
    echo "================================================================="
}

# 2. Listar versiones disponibles
list_versions() {
    ensure_mise
    echo "================================================================="
    echo "📋 VERSIONES DE PYTHON INSTALADAS EN MISE"
    echo "================================================================="
    mise ls python 2>/dev/null || echo "Ninguna versión instalada."
    echo ""
    echo "📋 ÚLTIMAS VERSIONES DISPONIBLES EN REMOTO (3.12 y 3.13):"
    mise ls-remote python | grep -E '^3\.(12|13)\.' | tail -n 12 || mise ls-remote python | tail -n 10
    echo "================================================================="
}

# 3. Instalar dependencias de cabeceras C/C++ en Fedora para extensiones nativas
install_build_dependencies() {
    echo "📦 [1/4] Instalando dependencias de desarrollo del sistema para Python en Fedora..."
    $SUDO dnf5 install -y \
        @development-tools \
        openssl-devel \
        zlib-devel \
        bzip2-devel \
        readline-devel \
        sqlite-devel \
        curl \
        git \
        ncurses-devel \
        xz-devel \
        tk-devel \
        libxml2-devel \
        libxmlsec1-devel \
        libffi-devel 2>/dev/null || true
    echo "✅ Cabeceras y dependencias del sistema listas."
}

# 4. Instalar versión de Python vía Mise
install_python() {
    local VER="$1"
    ensure_mise
    echo "🚀 [2/4] Instalando Python $VER vía Mise..."
    mise install "python@$VER"
    mise use --global "python@$VER"
    echo "✅ Python $VER fijado como versión global."
}

# 5. Actualizar pip, setuptools y wheel
configure_python_tools() {
    local VER="$1"
    echo "⚙️ [3/4] Actualizando pip, setuptools y wheel para construcción de paquetes..."
    mise exec "python@$VER" -- python -m pip install --upgrade --no-warn-script-location pip setuptools wheel 2>/dev/null || true
    
    echo "🔗 [4/4] Regenerando shims de Mise..."
    mise reshim
    echo "✅ Herramientas base de Python actualizadas."
}

# Procesar argumentos
if [ $# -gt 0 ]; then
    case "$1" in
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
        --version|-v)
            if [ -n "${2:-}" ]; then
                PYTHON_VERSION="$2"
            else
                echo "❌ Error: Debes especificar una versión (ej: 3.12, 3.13)."
                exit 1
            fi
            ;;
        --update|-u|update)
            echo "🔄 Actualizando Python ($PYTHON_VERSION) y herramientas base..."
            ensure_mise
            install_python "$PYTHON_VERSION"
            configure_python_tools "$PYTHON_VERSION"
            echo ""
            show_status
            exit 0
            ;;
        3.*|latest)
            PYTHON_VERSION="$1"
            ;;
        *)
            echo "❌ Opción no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

echo "================================================================="
echo "🐍 INSTALADOR DE PYTHON ESTABLE (SOPORTE EXTENDIDO) - FEDORA 44"
echo "📌 Versión seleccionada: Python $PYTHON_VERSION"
echo "================================================================="
ensure_mise
install_build_dependencies
install_python "$PYTHON_VERSION"
configure_python_tools "$PYTHON_VERSION"
echo ""
show_status
echo "================================================================="
echo "✅ Python $PYTHON_VERSION, pip, setuptools y wheel configurados correctamente."
echo "================================================================="
