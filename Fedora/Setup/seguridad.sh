#!/bin/bash
# seguridad.sh - Endurecimiento de seguridad para Fedora (Firewalld & Systemd)

set -e

echo "🚀 Configurando seguridad del sistema..."

# 1. Configuración de Firewall (Firewalld)
echo "ℹ️ Configurando Firewalld..."
sudo systemctl enable --now firewalld

# Establecer zona 'work' como predeterminada (más segura que 'public')
sudo firewall-cmd --set-default-zone=work

# Eliminar servicios innecesarios
sudo firewall-cmd --permanent --zone=work --remove-service=mdns
sudo firewall-cmd --permanent --zone=work --remove-service=samba-client
# SSH suele venir habilitado por defecto en algunas zonas. Lo removemos por seguridad,
# a menos que planees conectarte REMOTAMENTE a esta máquina.
sudo firewall-cmd --permanent --zone=work --remove-service=ssh

# Aplicar cambios
sudo firewall-cmd --reload

# 2. DNS-over-TLS (Privacidad)
echo "ℹ️ Configurando DNS seguro (Systemd-resolved)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSOverTLS=yes
DNSSEC=allow-downgrade
FallbackDNS=8.8.8.8
EOF
sudo systemctl restart systemd-resolved

# 3. Auditoría de permisos
echo "ℹ️ Verificando permisos de archivos críticos..."
sudo chmod 700 /root
# NOTA: En Fedora /etc/shadow y /etc/gshadow tienen permisos 000 (----------) 
# por defecto. Cambiarlos a 600 degrada la seguridad, por lo que se omite.

echo "✅ Configuración de seguridad completada."
echo "💡 Nota: DNS-over-TLS configurado con Cloudflare (1.1.1.1)."