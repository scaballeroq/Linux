#!/bin/bash
# seguridad.sh - Endurecimiento de seguridad para Fedora (Firewalld & Systemd)

set -e

echo "🚀 Configurando seguridad del sistema..."

# 1. Configuración de Firewall (Firewalld)
echo "ℹ️ Configurando Firewalld..."
sudo systemctl enable --now firewalld

# Mantener la zona predeterminada (en Fedora Workstation es 'FedoraWorkstation', optimizada para desarrolladores)
# Si te conectas a una red pública (cafetería, hotel), puedes cambiarla manualmente a 'work' o 'public'.
# sudo firewall-cmd --set-default-zone=work

# Eliminar servicios innecesarios en la zona predeterminada FedoraWorkstation
sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=samba-client 2>/dev/null || true
# Mantener mdns habilitado para resolución de nombres locales (.local)

# Permitir KDE Connect (esencial para integración con móvil en KDE)
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect 2>/dev/null || true

# Aplicar cambios
sudo firewall-cmd --reload

# 2. DNS-over-TLS (Privacidad)
echo "ℹ️ Configurando DNS seguro (Systemd-resolved)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf
[Resolve]
# No hardcodeamos IPs fijas para no interferir con la resolución de nombres internos de VPNs.
# 'opportunity' permite cifrar DNS si los servidores DNS de la red o la VPN lo soportan.
DNSOverTLS=opportunity
DNSSEC=allow-downgrade
EOF
sudo systemctl restart systemd-resolved

# 3. Privacidad en Redes (Wi-Fi MAC Randomization)
echo "ℹ️ Configurando privacidad Wi-Fi (MAC Randomization)..."
sudo mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf >/dev/null
[device]
wifi.scan-rand-mac-address=yes

[connection]
# 'stable' genera una MAC diferente por red, pero se mantiene siempre igual en la misma red.
wifi.cloned-mac-address=stable
EOF
sudo systemctl reload NetworkManager || true

# 4. Endurecimiento del Kernel (sysctl)
echo "ℹ️ Aplicando endurecimiento del Kernel (sysctl)..."
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf >/dev/null
# Restringir acceso al registro de kernel (dmesg) solo para root
kernel.dmesg_restrict=1
# Ocultar direcciones de memoria del kernel a usuarios no privilegiados
kernel.kptr_restrict=2
# Protección estricta contra IP Spoofing (Reverse Path Filtering)
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
# Proteger contra ataques SYN flood (Agotamiento de recursos TCP)
net.ipv4.tcp_syncookies=1
EOF
sudo sysctl --system >/dev/null

# 5. Auditoría de permisos
echo "ℹ️ Verificando permisos de archivos críticos..."
sudo chmod 700 /root
# NOTA: En Fedora /etc/shadow y /etc/gshadow tienen permisos 000 (----------) 
# por defecto. Cambiarlos a 600 degrada la seguridad, por lo que se omite.

echo "✅ Configuración de seguridad completada."
echo "💡 Nota: DNS-over-TLS configurado en modo oportuno (adaptable para redes y VPNs)."