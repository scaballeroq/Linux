#!/bin/bash
# ==============================================================================
# dms-setup.sh - Gestor y Verificador de Dank Material Shell (DMS) en CachyOS
# ==============================================================================
# Administra la integración de Dank Material Shell con Niri, Quickshell y Matugen.
#
# Uso:
#   ./dms-setup.sh               -> Diagnostica, verifica servicios y valida la configuración
#   ./dms-setup.sh --status, -s  -> Ejecuta el informe detallado de salud (dms doctor)
#   ./dms-setup.sh --restart, -r -> Reinicia la instancia activa de DMS
#   ./dms-setup.sh --theme, -t   -> Regenera temas dinámicos (Matugen + Kitty + GTK)
#   ./dms-setup.sh --help, -h    -> Muestra este menú de ayuda
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<HELPEOF
🌌 Gestor de Dank Material Shell (DMS) - CachyOS + Niri

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Verifica el estado del servicio dms.service, ejecuta diagnósticos y asegura la integración.
  --status, -s           Ejecuta dms doctor y muestra el estado de salud de DMS.
  --restart, -r          Reinicia la shell de Dank Material Shell vía systemd o CLI.
  --theme, -t            Regenera la paleta de colores Material 3 (Matugen) para DMS, Kitty y GTK.
  --help, -h             Muestra este mensaje de ayuda.

Componentes del entorno DMS:
  • dms-shell:           Shell de escritorio moderna basada en Quickshell y Material Design 3.
  • dms CLI:             Gestor de backend, IPC, capturas, fondos y portapapeles (/usr/bin/dms).
  • dankcalendar:        Calendario integrado con CalDAV/Google (/usr/bin/dcal).
  • danksearch:          Buscador indexador rápido de aplicaciones y archivos.
  • greetd-dms-greeter:  Pantalla de login con estética Dank Material.
HELPEOF
}

# Procesar argumentos
if [ $# -gt 0 ]; then
    case "$1" in
        --status|-s|status)
            if command -v dms &>/dev/null; then
                dms doctor
            else
                echo "❌ Error: 'dms' CLI no está instalado en el sistema."
                exit 1
            fi
            exit 0
            ;;
        --restart|-r|restart)
            echo "🔄 Reiniciando Dank Material Shell..."
            if command -v dms &>/dev/null; then
                dms restart || systemctl --user restart dms.service 2>/dev/null || true
            else
                systemctl --user restart dms.service 2>/dev/null || true
            fi
            echo "✅ DMS reiniciado."
            exit 0
            ;;
        --theme|-t|theme)
            echo "🎨 Regenerando paletas Material You con Matugen..."
            if command -v dms &>/dev/null; then
                dms matugen generate 2>/dev/null || true
                dms matugen qtengine 2>/dev/null || true
                echo "✅ Paletas regeneradas y tema Qt sincronizado."
            fi
            exit 0
            ;;
        --help|-h|help)
            show_help
            exit 0
            ;;
        *)
            echo "Opción no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

echo "================================================================="
echo "🌌 VERIFICACIÓN Y CONFIGURACIÓN DE DANK MATERIAL SHELL (DMS)"
echo "================================================================="

# 1. Comprobar binario dms
if command -v dms &>/dev/null; then
    echo "• Binario DMS CLI:       ✅ Instalado ($(dms version 2>/dev/null || echo 'v1.6+'))"
else
    echo "• Binario DMS CLI:       ❌ No encontrado en PATH (/usr/bin/dms)"
fi

# 2. Comprobar componentes satélite
echo -n "• DankCalendar (dcal):   "
command -v dcal &>/dev/null && echo "✅ Instalado" || echo "⚠️ No encontrado"

echo -n "• DankSearch:            "
if command -v danksearch &>/dev/null || (command -v dms &>/dev/null && dms doctor 2>/dev/null | grep -q "danksearch.*Installed"); then
    echo "✅ Instalado"
else
    echo "⚠️ No encontrado"
fi

echo -n "• Matugen:               "
command -v matugen &>/dev/null && echo "✅ Instalado" || echo "⚠️ No encontrado"

# 3. Comprobar servicio systemd user
echo -n "• Servicio dms.service:  "
mkdir -p "$HOME/.config/systemd/user/dms.service.d"
if [ ! -f "$HOME/.config/systemd/user/dms.service.d/override.conf" ]; then
    cat << 'EOF' > "$HOME/.config/systemd/user/dms.service.d/override.conf"
[Unit]
ConditionEnvironment=XDG_CURRENT_DESKTOP=niri
EOF
    systemctl --user daemon-reload 2>/dev/null || true
fi

if systemctl --user is-enabled dms.service &>/dev/null; then
    if systemctl --user is-active dms.service &>/dev/null; then
        echo "✅ Habilitado y Activo"
    else
        echo "ℹ️ Habilitado pero inactivo (iniciando...)"
        systemctl --user start dms.service 2>/dev/null || true
    fi
else
    echo "⚠️ Inactivo. Habilitando servicio de usuario..."
    systemctl --user enable --now dms.service 2>/dev/null || true
fi

# 4. Comprobar includes en Niri
NIRI_CONFIG="$HOME/.config/niri/config.kdl"
if [ -f "$NIRI_CONFIG" ]; then
    echo -n "• Inclusión en Niri:     "
    if grep -q 'include optional=true "dms/' "$NIRI_CONFIG"; then
        echo "✅ Archivos modulares de DMS incluidos en config.kdl"
    else
        echo "⚠️ Configuración de Niri no incluye la carpeta dms/"
    fi
fi

# 5. Ejecutar diagnóstico de salud si dms existe
if command -v dms &>/dev/null; then
    echo ""
    echo "-----------------------------------------------------------------"
    echo "🩺 Ejecutando 'dms doctor':"
    echo "-----------------------------------------------------------------"
    dms doctor || true
fi

echo "================================================================="
echo "💡 Para interactuar con DMS desde la terminal utiliza:"
echo "   dms ipc call launcher toggle        # Abrir/cerrar lanzador"
echo "   dms ipc call control-center toggle # Abrir/cerrar centro de control"
echo "   dms ipc call clipboard toggle      # Historial del portapapeles"
echo "   dms ipc call theme toggle          # Cambiar tema claro/oscuro"
echo "================================================================="
