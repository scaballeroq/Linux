#!/bin/bash
# seguridad.sh - Endurecimiento de seguridad para Fedora (Firewalld & Systemd)

set -e

echo "🚀 Configurando seguridad del sistema..."

# 1. Configuración de Firewall (Firewalld)
echo "ℹ️ Configurando Firewalld..."
sudo systemctl enable --now firewalld

# Establecer zona 'work' como predeterminada (más segura que 'public')
sudo firewall-cmd --set-default-zone=work

# Permitir solo lo esencial (SSH si es necesario)
sudo firewall-cmd --permanent --zone=work --add-service=ssh
sudo firewall-cmd --permanent --zone=work --remove-service=mdns
sudo firewall-cmd --permanent --zone=work --remove-service=samba-client

# Aplicar cambios
sudo firewall-cmd --reload

# 2. Protección contra ataques de fuerza bruta
echo "ℹ️ Instalando y configurando Fail2Ban..."
sudo dnf5 install -y fail2ban
sudo systemctl enable --now fail2ban

# 3. DNS-over-TLS (Privacidad)
echo "ℹ️ Configurando DNS seguro (Systemd-resolved)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSOverTLS=yes
DNSSEC=yes
FallbackDNS=8.8.8.8
EOF
sudo systemctl restart systemd-resolved

# 4. Auditoría de permisos (Opcional pero recomendado)
echo "ℹ️ Verificando permisos de archivos críticos..."
sudo chmod 700 /root
sudo chmod 600 /etc/shadow
sudo chmod 600 /etc/gshadow

echo "✅ Configuración de seguridad completada."
echo "💡 Nota: DNS-over-TLS configurado con Cloudflare (1.1.1.1)."