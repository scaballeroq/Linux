#!/bin/bash
# =============================================================================
# firefox.sh - Instalar Firefox Nativo (.deb) Oficial de Mozilla en Kubuntu
# =============================================================================
# - Elimina la versión Snap por defecto de Ubuntu/Kubuntu
# - Configura el repositorio oficial APT de Mozilla con clave GPG y APT Pinning (1000)
# - Instala Firefox nativo (.deb) + paquete de idioma en español (es-ES)
# - Integra con KDE Plasma (plasma-browser-integration)
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario (sudo)."
        exit 1
    fi
else
    SUDO=""
fi

show_help() {
    cat <<EOF
Instalador de Firefox Nativo (.deb) - Kubuntu (KDE Plasma)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Elimina Firefox Snap e instala Firefox oficial (.deb) de Mozilla.
  --status, -s           Muestra la versión de Firefox instalada y la política APT activa.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE FIREFOX - KUBUNTU"
    echo "================================================================="
    echo "Firefox Binario:               $(command -v firefox 2>/dev/null || echo 'No instalado')"
    echo "Versión Firefox:               $(firefox --version 2>/dev/null || echo 'n/a')"
    echo "Snap Firefox:                  $(if command -v snap &>/dev/null && snap list firefox &>/dev/null; then echo 'Instalado (Snap)'; else echo 'No instalado (Limpio)'; fi)"
    echo "-----------------------------------------------------------------"
    echo "Política APT para Firefox (apt-cache policy firefox):"
    apt-cache policy firefox 2>/dev/null || true
    echo "================================================================="
}

install_native_firefox() {
    echo "================================================================="
    echo "INSTALANDO FIREFOX NATIVO (.DEB) DESDE EL REPOSITORIO DE MOZILLA"
    echo "================================================================="

    # 1. Eliminar Firefox Snap si está presente
    echo "ℹ️ [1/6] Comprobando y eliminando versión Snap de Firefox..."
    if command -v snap &>/dev/null && snap list firefox &>/dev/null; then
        echo "   - Desinstalando snap de Firefox..."
        $SUDO snap remove --purge firefox 2>/dev/null || $SUDO snap remove firefox 2>/dev/null || true
    fi

    # Eliminar el metapaquete transicional de Ubuntu
    $SUDO apt purge -y firefox 2>/dev/null || true

    # 2. Crear directorio de keyrings si no existe
    echo "ℹ️ [2/6] Configurando directorio de firmas APT..."
    $SUDO mkdir -p /etc/apt/keyrings
    $SUDO chmod 755 /etc/apt/keyrings

    # 3. Descargar e instalar la clave GPG oficial de Mozilla
    echo "ℹ️ [3/6] Descargando e instalando clave GPG de Mozilla..."
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | $SUDO tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

    # 4. Añadir repositorio oficial APT de Mozilla
    echo "ℹ️ [4/6] Añadiendo repositorio APT oficial de Mozilla..."
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | $SUDO tee /etc/apt/sources.list.d/mozilla.list > /dev/null

    # 5. Configurar APT Pinning (Prioridad 1000 para preferir siempre Mozilla oficial sobre el wrapper de Ubuntu)
    echo "ℹ️ [5/6] Configurando prioridad APT Pinning (1000)..."
    cat <<'EOF' | $SUDO tee /etc/apt/preferences.d/mozilla > /dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

    # 6. Actualizar e instalar Firefox nativo
    echo "ℹ️ [6/6] Actualizando APT e instalando Firefox nativo (.deb)..."
    $SUDO apt update
    $SUDO apt install -y \
        firefox \
        firefox-l10n-es-es \
        plasma-browser-integration

    echo ""
    echo "================================================================="
    echo "✅ Firefox nativo (.deb) instalado con éxito desde Mozilla."
    echo "Versión instalada: $(firefox --version 2>/dev/null || echo 'Instalado')"
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
    "")
        install_native_firefox
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
