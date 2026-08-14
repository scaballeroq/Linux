#!/bin/bash
# firefox.sh - Instalar Firefox nativo (.deb) desde el repositorio oficial de Mozilla
# Compatible con Kubuntu 24.04 LTS y superiores (incluyendo 24.10 y 26.04 LTS)

set -euo pipefail

echo "🚀 Instalando Firefox nativo (.deb) desde Mozilla..."

# Verificar si se está ejecutando como root o con sudo
if [[ $EUID -ne 0 ]]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "⚠️ Este script requiere privilegios de root (sudo)."
        exit 1
    fi
else
    SUDO=""
fi

# 1. Crear directorio para keyrings si no existe
$SUDO mkdir -p /etc/apt/keyrings
$SUDO chmod 755 /etc/apt/keyrings

# 2. Descargar e instalar la clave GPG de Mozilla
echo "ℹ️ Descargando clave GPG de Mozilla..."
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | $SUDO tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

# 3. Añadir el repositorio oficial de Mozilla
echo "ℹ️ Añadiendo repositorio de Mozilla..."
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | $SUDO tee /etc/apt/sources.list.d/mozilla.list > /dev/null

# 4. Configurar prioridad (Pinning) - 900 para no sobrescribir repos de seguridad de Ubuntu/Kubuntu
echo "ℹ️ Configurando prioridad del repositorio (Pin-Priority: 900)..."
cat <<'EOF' | $SUDO tee /etc/apt/preferences.d/mozilla > /dev/null
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 900
EOF

# 5. Actualizar lista de paquetes
echo "ℹ️ Actualizando lista de paquetes..."
$SUDO apt update

# 6. Eliminar versiones previas (Snap, ESR, paquete Ubuntu/Kubuntu)
echo "ℹ️ Eliminando versiones previas de Firefox..."

# Eliminar Firefox Snap si está instalado y snap existe
if command -v snap &>/dev/null && snap list firefox &>/dev/null; then
    echo "   - Eliminando Firefox Snap..."
    $SUDO snap remove firefox || true
fi

# Eliminar Firefox ESR y paquetes de localización si existen
$SUDO apt purge -y firefox-esr firefox-esr-l10n-es-ar firefox-esr-l10n-es-cl firefox-esr-l10n-es-es firefox-esr-l10n-es-mx 2>/dev/null || true

# Eliminar paquete firefox de Ubuntu/Kubuntu si es metapaquete snap o deb antiguo
$SUDO apt purge -y firefox 2>/dev/null || true

# 7. Instalar Firefox nativo (.deb) desde Mozilla
echo "ℹ️ Instalando Firefox nativo (.deb)..."
$SUDO apt install -y firefox firefox-l10n-es-es

echo "✅ Firefox nativo (.deb) instalado correctamente."
echo "💡 Verifica la instalación ejecutando: firefox --version"
