#!/bin/bash
# seguridad.sh - Configuración básica de Firewalld para Arch Linux

set -e

echo "🔒 Configurando Firewalld..."

sudo systemctl enable --now firewalld

# SSH solo permitido desde redes locales (RFC1918)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" service name="ssh" accept' || true
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="172.16.0.0/12" service name="ssh" accept' || true
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.0.0/16" service name="ssh" accept' || true
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv6" source address="fd00::/8" service name="ssh" accept' || true

sudo firewall-cmd --reload

echo "✅ Firewalld habilitado y activo"
