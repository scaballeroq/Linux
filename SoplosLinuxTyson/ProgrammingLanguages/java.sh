#!/bin/bash
# java.sh - Instalación de OpenJDK (compatible con AutoFirma) y configuración de JAVA_HOME

set -euo pipefail

echo "ℹ️ Instalando OpenJDK y dependencias para AutoFirma (libnss3-tools)..."

# Verificar si se necesita sudo
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario (root o sudo)."
        exit 1
    fi
else
    SUDO=""
fi

$SUDO apt-get update
$SUDO apt-get install -y default-jre default-jdk libnss3-tools

# Configuración Modular de JAVA_HOME
JAVA_DEFAULT_PATH="/usr/lib/jvm/default-java"
if [ -d "$JAVA_DEFAULT_PATH" ]; then
    if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
        mkdir -p ~/.bashrc.d
        cat <<EOF > ~/.bashrc.d/java.sh
# Java Environment
export JAVA_HOME="$JAVA_DEFAULT_PATH"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
        echo "✅ Configuración modular de JAVA_HOME creada en ~/.bashrc.d/java.sh"
    else
        if ! grep -q "JAVA_HOME" ~/.bashrc; then
            echo -e "\n# Java Environment\nexport JAVA_HOME=\"$JAVA_DEFAULT_PATH\"\nexport PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.bashrc
        fi
    fi
fi

echo "✅ OpenJDK y dependencias para AutoFirma instalados y configurados correctamente."
