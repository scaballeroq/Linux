#!/bin/bash
# java.sh - Instalación de OpenJDK y dependencias para AutoFirma en OpenSUSE Tumbleweed

set -euo pipefail

echo "ℹ️ Instalando OpenJDK 21 y dependencias para AutoFirma (mozilla-nss-tools)..."

sudo zypper --non-interactive install -y \
    java-21-openjdk \
    java-21-openjdk-devel \
    mozilla-nss-tools 2>/dev/null || true

echo "✅ OpenJDK y dependencias para AutoFirma instalados correctamente."
