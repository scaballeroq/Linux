#!/bin/bash
# ==============================================================================
# antigravity.sh - Instalador y Gestor de Google Antigravity Desktop 2.0
# Ubuntu Workstation (GNOME Shell Wayland)
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

show_help() {
    cat <<EOF
Uso: $0 [OPCIÓN]

Instalador de Google Antigravity Desktop para Ubuntu.

Opciones:
  (sin argumentos)    Configura el repositorio APT oficial e instala Google Antigravity.
  --status, -s        Muestra el estado de instalación y versión instalada.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GOOGLE ANTIGRAVITY - UBUNTU WORKSTATION"
    echo "================================================================="
    if dpkg -s antigravity &>/dev/null; then
        local ver
        ver=$(dpkg-query -W -f='${Version}' antigravity 2>/dev/null || echo "Desconocida")
        echo "• Estado:             ✅ Instalado (v$ver)"
        echo "• Binario:            $(command -v antigravity || echo '/usr/bin/antigravity')"
        echo "• Acceso directo:     /usr/share/applications/antigravity.desktop"
    else
        echo "• Estado:             ❌ No instalado"
    fi
    echo "• Repositorio APT:    $(if [ -f /etc/apt/sources.list.d/antigravity.list ]; then echo "✅ Configurado"; else echo "❌ No presente"; fi)"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s)
        show_status
        exit 0
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🚀 CONFIGURANDO GOOGLE ANTIGRAVITY DESKTOP PARA UBUNTU"
echo "================================================================="

# 1. Crear directorio para keyrings si no existe
$SUDO mkdir -p /etc/apt/keyrings

# 2. Descargar y añadir la clave GPG
echo "ℹ️ [1/3] Añadiendo clave de firma oficial de Google..."
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
$SUDO gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

# 3. Añadir el repositorio a la lista de fuentes
echo "ℹ️ [2/3] Registrando repositorio APT de Antigravity..."
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
$SUDO tee /etc/apt/sources.list.d/antigravity.list > /dev/null

# 4. Actualizar e instalar
echo "ℹ️ [3/3] Instalando Antigravity..."
$SUDO apt update
$SUDO apt install -y antigravity

# 5. Ajustar permisos sandbox si procede
if [ -f "/opt/antigravity/chrome-sandbox" ]; then
    $SUDO chown root:root "/opt/antigravity/chrome-sandbox"
    $SUDO chmod 4755 "/opt/antigravity/chrome-sandbox"
fi

echo "================================================================="
echo "✅ Google Antigravity Desktop instalado y listo para usar."
echo "================================================================="
