#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD BÁSICO (seguridad.sh)
# ==============================================================================
# Este script aplica configuraciones básicas de seguridad para Debian:
#   - Firewall UFW (cortafuegos)
#
# Para seguridad avanzada (DNS-over-TLS), ejecutar seguridad-dot.sh
# ==============================================================================

# 'set -e' hace que el script se detenga inmediatamente si algún comando falla.
# 'set -u' detiene el script si se intenta usar una variable que no existe.
# 'set -o pipefail' asegura que si un comando en una tubería (pipe) falla,
# el error se propague y detenga el script.
set -euo pipefail

echo "🚀 Iniciando el proceso de endurecimiento de seguridad del sistema..."

# ==============================================================================
# PASO 1: CONFIGURACIÓN DEL CORTAFUEGOS (FIREWALL - UFW)
# ==============================================================================
# UFW (Uncomplicated Firewall) es una interfaz simplificada para iptables/nftables.
# Nos permite definir reglas para decidir qué tráfico de red puede entrar o 
# salir de nuestro ordenador.
# ==============================================================================
echo "ℹ️ Paso 1: Configurando UFW (Uncomplicated Firewall)..."

# 1.1 Comprobar e instalar UFW si no está presente
# Si el comando 'ufw' no está instalado en el sistema, lo instalamos usando 'apt'.
if ! command -v ufw &> /dev/null; then
    echo "   - UFW no detectado. Procediendo a la instalación..."
    sudo apt update
    sudo apt install -y ufw
fi

# 1.2 Establecer las políticas de seguridad por defecto
# La regla más segura es: "Prohibir que nadie entre desde fuera, pero permitir
# que nuestros programas salgan a internet".
# - 'deny incoming': Bloquea cualquier intento de conexión desde el exterior.
sudo ufw default deny incoming
# - 'allow outgoing': Permite que nuestro equipo navegue por internet, descargue cosas, etc.
sudo ufw default allow outgoing

# 1.3 Permitir y limitar el acceso por SSH
# Configurable mediante variable de entorno SSH_ALLOWED_NETWORK
SSH_ALLOWED_NETWORK="${SSH_ALLOWED_NETWORK:-192.168.1.0/24}"
sudo ufw limit from "$SSH_ALLOWED_NETWORK" to any port ssh

# 1.4 Activar el Firewall
# Una vez definidas las reglas, encendemos el firewall. 
# El parámetro '--force' evita que el comando nos pida confirmación manual,
# lo que es ideal para scripts automáticos.
sudo ufw --force enable

# ==============================================================================
# FIN DEL PROCESO
# ==============================================================================
echo "✅ Configuración de seguridad básica completada con éxito."
echo "💡 Para DNS cifrado (DNS-over-TLS), ejecuta: ./Setup/seguridad-dot.sh"
