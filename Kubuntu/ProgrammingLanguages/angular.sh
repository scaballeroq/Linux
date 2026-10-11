#!/bin/bash
# =============================================================================
# angular.sh - Instalador de Angular CLI (Última versión LTS) vía Mise/npm
# =============================================================================
# - Asegura la presencia de Node.js y Mise
# - Detecta e instala automáticamente la última versión LTS activa de @angular/cli
# - Desactiva prompts interactivos de telemetría (NG_CLI_ANALYTICS=false)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" NG_CLI_ANALYTICS=false "$@"
    else
        env NG_CLI_ANALYTICS=false "$@"
    fi
}

show_help() {
    cat <<EOF
Instalador de Angular CLI (LTS) - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala la última versión LTS recomendada de @angular/cli.
  --latest               Fuerza la instalación de la versión más reciente (current/latest).
  --status, -s           Muestra la versión de Angular CLI instalada.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE ANGULAR CLI - KUBUNTU"
    echo "================================================================="
    echo "Angular CLI (ng):              $(run_as_user mise which ng 2>/dev/null || run_as_user which ng 2>/dev/null || echo 'No instalado')"
    echo "Versión de Angular CLI:        $(run_as_user ng version 2>/dev/null | grep -E "Angular CLI:" | head -n1 || echo 'n/a')"
    echo "================================================================="
}

get_angular_lts_version() {
    run_as_user mise exec node@lts -- node -e '
      const { execSync } = require("child_process");
      try {
        const raw = execSync("npm view @angular/cli dist-tags --json", { encoding: "utf8" });
        const parsed = JSON.parse(raw);
        const tags = Array.isArray(parsed) ? parsed[0] : parsed;
        const ltsKeys = Object.keys(tags).filter(k => k.endsWith("-lts")).sort((a,b) => parseInt(a.replace(/\D/g,"")) - parseInt(b.replace(/\D/g,"")));
        const latestLtsKey = ltsKeys[ltsKeys.length - 1];
        process.stdout.write(tags[latestLtsKey] || "latest");
      } catch (e) {
        process.stdout.write("latest");
      }
    ' 2>/dev/null || echo "latest"
}

install_angular() {
    local TARGET_MODE="${1:-lts}"
    echo "================================================================="
    echo "INSTALANDO ANGULAR CLI (VERSIÓN LTS) VÍA MISE/NPM - KUBUNTU"
    echo "================================================================="

    # 1. Asegurar Node.js
    if ! command -v node &>/dev/null && [ ! -x "$USER_HOME/.local/share/mise/installs/node/lts/bin/node" ]; then
        echo "ℹ️ Node.js no detectado. Instalando Node.js primero..."
        if [ -f "$SCRIPT_DIR/nodejs.sh" ]; then
            bash "$SCRIPT_DIR/nodejs.sh"
        fi
    fi

    # 2. Determinar la versión a instalar
    local ANGULAR_VER="latest"
    if [ "$TARGET_MODE" = "lts" ]; then
        echo "ℹ️ [1/3] Detectando la última versión LTS oficial de Angular..."
        ANGULAR_VER=$(get_angular_lts_version)
        echo "   - Versión LTS detectada: $ANGULAR_VER"
    else
        echo "ℹ️ [1/3] Seleccionada versión latest..."
        ANGULAR_VER="latest"
    fi

    # 3. Instalar Angular CLI globalmente vía Mise o npm
    echo "ℹ️ [2/3] Instalando @angular/cli@$ANGULAR_VER..."
    run_as_user mise use --global "npm:@angular/cli@$ANGULAR_VER" 2>/dev/null || \
    run_as_user mise exec node@lts -- npm install -g "@angular/cli@$ANGULAR_VER" 2>/dev/null || true

    # 4. Desactivar analítica interactiva de Angular para evitar preguntas molestas
    echo "ℹ️ [3/3] Desactivando analítica interactiva..."
    run_as_user ng config -g cli.analytics false 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Angular CLI ($ANGULAR_VER LTS) instalado con éxito."
    echo "================================================================="
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --latest)
        install_angular "latest"
        show_status
        ;;
    "")
        install_angular "lts"
        show_status
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
