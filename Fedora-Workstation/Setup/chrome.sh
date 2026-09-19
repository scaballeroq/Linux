#!/bin/bash
# ==============================================================================
# chrome.sh - Instalación de Google Chrome y Activación de Repositorio Oficial
# Fedora 44 Workstation (GNOME)
# ==============================================================================

set -euo pipefail

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
🌐 Instalador de Google Chrome - Fedora 44 Workstation

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Activa el repositorio oficial de Google Chrome e instala google-chrome-stable.
  --status, -s        Muestra el estado del repositorio y la versión instalada de Google Chrome.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GOOGLE CHROME - FEDORA 44"
    echo "================================================================="
    echo "• Repositorio Google Chrome: $(if [ -f /etc/yum.repos.d/google-chrome.repo ]; then echo 'Presente (/etc/yum.repos.d/google-chrome.repo)'; else echo 'No configurado'; fi)"
    if command -v google-chrome &> /dev/null || command -v google-chrome-stable &> /dev/null; then
        local chrome_bin
        chrome_bin=$(command -v google-chrome-stable 2>/dev/null || command -v google-chrome)
        echo "• Google Chrome:            ✅ Instalado ($("$chrome_bin" --version 2>/dev/null || echo 'Presente'))"
    else
        echo "• Google Chrome:            ❌ No instalado"
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
echo "🌐 CONFIGURANDO REPOSITORIO E INSTALACIÓN DE GOOGLE CHROME"
echo "================================================================="

# 1. Habilitar repositorio mediante fedora-workstation-repositories o archivo directo
echo "📦 [1/2] Activando repositorio oficial de Google Chrome..."
if $SUDO dnf5 install -y fedora-workstation-repositories 2>/dev/null; then
    $SUDO dnf5 config-manager setopt google-chrome.enabled=1 2>/dev/null || true
fi

# Asegurar configuración del repositorio si no existe
if [ ! -f /etc/yum.repos.d/google-chrome.repo ]; then
    cat << 'EOF' | $SUDO tee /etc/yum.repos.d/google-chrome.repo > /dev/null
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
fi

# Importar clave GPG oficial de Google
$SUDO rpm --import https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null || true

# 2. Instalar Google Chrome Stable
echo "⬇️ [2/2] Instalando Google Chrome Stable vía DNF5..."
$SUDO dnf5 install -y google-chrome-stable

echo "================================================================="
echo "✅ Google Chrome instalado correctamente."
echo "   - Binario: $(which google-chrome-stable 2>/dev/null || which google-chrome)"
echo "   - Versión: $(google-chrome-stable --version 2>/dev/null || google-chrome --version 2>/dev/null || true)"
echo "================================================================="
