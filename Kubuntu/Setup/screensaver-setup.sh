#!/bin/bash
# screensaver-setup.sh - Configuracion de KScreenLocker para Kubuntu

set -euo pipefail

echo "Configuracion de KScreenLocker..."

KWRITECFG=""
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
fi

if [ -z "$KWRITECFG" ]; then
    echo "No se encontro kwriteconfig. Abortando."
    exit 0
fi

# Bloqueo automatico tras 5 minutos de inactividad
$KWRITECFG --file kscreenlockerrc --group Daemon --key Autolock true 2>/dev/null || true
$KWRITECFG --file kscreenlockerrc --group Daemon --key Timeout 5 2>/dev/null || true

# Requerir password al reanudar
$KWRITECFG --file kscreenlockerrc --group Daemon --key LockOnResume true 2>/dev/null || true

# Tema de pantalla de bloqueo
$KWRITECFG --file kscreenlockerrc --group Greeter --key Theme org.kde.breezedark.desktop 2>/dev/null || true

echo "KScreenLocker configurado: bloqueo automatico 5 min, password al reanudar."
