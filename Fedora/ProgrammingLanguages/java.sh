#!/bin/bash
# java.sh - Instalación de OpenJDK y dependencias para AutoFirma (Fedora 44)

set -euo pipefail

echo "ℹ️ Instalando OpenJDK y dependencias para AutoFirma (nss-tools) vía DNF5..."

sudo dnf5 install -y java-latest-openjdk java-latest-openjdk-devel nss-tools

echo "✅ OpenJDK y dependencias para AutoFirma instalados correctamente."
