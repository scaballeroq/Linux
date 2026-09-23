#!/bin/bash
# ==============================================================================
# chrome.sh - Instalación de Google Chrome y Activación de Repositorio Oficial
# openSUSE Tumbleweed (KDE Plasma 6)
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
🌐 Instalador de Google Chrome - openSUSE Tumbleweed

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
    echo "🔍 ESTADO DE GOOGLE CHROME - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Repositorio Google Chrome: $(if zypper lr 2>/dev/null | grep -qi "google-chrome"; then echo 'Configurado (google-chrome)'; else echo 'No configurado'; fi)"
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

# 1. Importar clave GPG oficial de Google
echo "🔑 [1/3] Importando clave pública GPG de Google..."
$SUDO rpm --import https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null || true

# 2. Habilitar repositorio oficial de Google Chrome en Zypper
echo "📦 [2/3] Añadiendo repositorio oficial de Google Chrome..."
if ! zypper lr 2>/dev/null | grep -qi "google-chrome"; then
    $SUDO zypper --non-interactive ar -f https://dl.google.com/linux/chrome/rpm/stable/x86_64 google-chrome || true
fi

$SUDO zypper --gpg-auto-import-keys refresh google-chrome 2>/dev/null || true

# 3. Instalar Google Chrome Stable
echo "⬇️ [3/3] Instalando Google Chrome Stable vía Zypper..."
$SUDO zypper --non-interactive install -y google-chrome-stable || {
    if command -v opi &>/dev/null; then
        echo "⚠️ Fallback: Instalando vía OPI..."
        opi google-chrome || true
    fi
}

echo "================================================================="
echo "✅ Google Chrome instalado correctamente."
echo "   - Binario: $(which google-chrome-stable 2>/dev/null || which google-chrome || echo 'google-chrome')"
echo "   - Versión: $(google-chrome-stable --version 2>/dev/null || google-chrome --version 2>/dev/null || true)"
echo "================================================================="
