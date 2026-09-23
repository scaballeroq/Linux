#!/bin/bash
# ==============================================================================
# DNS-OVER-TLS CON SYSTEMD-RESOLVED (seguridad-dot.sh) - openSUSE Tumbleweed
# ==============================================================================
# Script opcional para gestionar DNS cifrado (DNS-over-TLS) vía systemd-resolved.
# NOTA: En redes domésticas de desarrollo, DoT suele ser innecesario y puede
# interferir con la resolución de nombres locales del router (.local, .lan, NAS).
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

DOT_CONF="/etc/systemd/resolved.conf.d/dot.conf"

show_help() {
    cat <<EOF
🔒 Gestor de DNS-over-TLS (DoT) - openSUSE Tumbleweed

Uso:
  $0 [OPCIÓN]

Opciones:
  --status, -s        Muestra el estado de systemd-resolved y DNS-over-TLS.
  --disable, -d       Desactiva DoT, elimina la configuración y restaura el DNS del router (Recomendado en casa).
  --enable, -e        Activa DNS-over-TLS con Cloudflare (1.1.1.1) y Quad9 (9.9.9.9).
  --help, -h          Muestra este mensaje de ayuda.

💡 Recomendación para portátiles que no salen de casa:
  En tu red local doméstica, mantener DoT desactivado permite resolver sin problemas
  los nombres de tu router, dispositivos locales (.local / .lan) y contenedores.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE DNS-OVER-TLS (DoT) - SYSTEMD-RESOLVED"
    echo "================================================================="
    local svc_status
    svc_status=$(systemctl is-active systemd-resolved 2>/dev/null || true)
    [ -z "$svc_status" ] && svc_status="inactivo"
    echo "• Servicio systemd-resolved:  $svc_status"
    echo "• Archivo de configuración:   $(if [ -f "$DOT_CONF" ]; then echo "Presente ($DOT_CONF)"; else echo "No configurado (usando DNS nativo del router)"; fi)"
    if [ -f "$DOT_CONF" ]; then
        echo "• Modo DoT configurado:       $(grep -o 'DNSOverTLS=.*' "$DOT_CONF" 2>/dev/null || echo 'desconocido')"
        echo "• Servidores DNS:             $(grep -o 'DNS=.*' "$DOT_CONF" 2>/dev/null || echo 'desconocido')"
    fi
    echo "-----------------------------------------------------------------"
    echo "💡 Nota: Si tu portátil no sale de casa, el DNS nativo de tu router"
    echo "   es el recomendado para evitar problemas con dominios locales."
    echo "================================================================="
}

enable_dot() {
    echo "================================================================="
    echo "🔒 Activando DNS cifrado (DNS-over-TLS) con systemd-resolved..."
    echo "================================================================="

    # Instalar si falta
    if ! rpm -q systemd-resolved &>/dev/null && ! systemctl list-unit-files | grep -q systemd-resolved; then
        echo "ℹ️ Instalando systemd-resolved vía Zypper..."
        $SUDO zypper --non-interactive install -y systemd-resolved 2>/dev/null || true
    fi

    # Configuración DoT (oportunista para no cortar la conexión ante fallos)
    $SUDO mkdir -p /etc/systemd/resolved.conf.d/
    cat <<'EOF' | $SUDO tee "$DOT_CONF" > /dev/null
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=1.0.0.1#cloudflare-dns.com 8.8.8.8#dns.google
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF

    $SUDO systemctl enable --now systemd-resolved
    $SUDO systemctl restart systemd-resolved
    echo "✅ DNS-over-TLS activado correctamente."
    echo "💡 Comprobación rápida: resolvectl status"
    echo "================================================================="
}

disable_dot() {
    echo "================================================================="
    echo "🔓 Desactivando DNS-over-TLS y restaurando DNS nativo de red..."
    echo "================================================================="
    if [ -f "$DOT_CONF" ]; then
        $SUDO rm -f "$DOT_CONF"
        echo "  • Eliminado archivo de configuración: $DOT_CONF"
    fi

    $SUDO systemctl disable --now systemd-resolved 2>/dev/null || true
    echo "✅ systemd-resolved desactivado. El sistema utiliza el DNS de tu router doméstico."
    echo "================================================================="
}

case "${1:-}" in
    --disable|-d|disable)
        disable_dot
        ;;
    --enable|-e|enable)
        enable_dot
        ;;
    --status|-s|status)
        show_status
        ;;
    --help|-h|help)
        show_help
        ;;
    "")
        echo "ℹ️ Modo interactivo / por defecto:"
        show_status
        echo ""
        echo "💡 Para mantener tu entorno doméstico óptimo sin alterar la resolución de tu router,"
        echo "   no es necesario ejecutar cambios. Usa '--enable' solo si deseas forzar DoT."
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
