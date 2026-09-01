#!/bin/bash
# ==============================================================================
# SEGURIDAD AVANZADA (Kubuntu) - Entorno de Desarrollo
# ==============================================================================
# UFW firewall + Fail2ban + sysctl hardening + Podman rootless

set -euo pipefail

echo "Configurando seguridad avanzada del sistema..."

# ==============================================================================
# PASO 1: FIREWALL (UFW)
# ==============================================================================
echo "Paso 1: Configurando UFW..."

if ! command -v ufw &> /dev/null; then
    sudo apt update
    sudo apt install -y ufw
fi

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on lo to any
sudo ufw limit from 192.168.1.0/24 to any port ssh
sudo ufw limit 9090/tcp

sudo ufw --force enable

# ==============================================================================
# PASO 2: FAIL2BAN
# ==============================================================================
echo "Paso 2: Instalando y configurando Fail2ban..."

if ! command -v fail2ban-server &> /dev/null; then
    sudo apt install -y fail2ban
fi

sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
EOF

sudo systemctl enable --now fail2ban

# ==============================================================================
# PASO 3: SYSCTL HARDENING
# ==============================================================================
echo "Paso 3: Aplicando sysctl de seguridad..."

sudo tee /etc/sysctl.d/99-security.conf > /dev/null << 'EOF'
# Seguridad de red
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Restricciones de kernel
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 1

# Proteccion contra IP spoofing
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
EOF

sudo sysctl --system > /dev/null || true

# ==============================================================================
# PASO 4: PODMAN ROOTLESS
# ==============================================================================
echo "Paso 4: Configurando namespaces para Podman rootless..."

sudo tee /etc/sysctl.d/99-podman-rootless.conf > /dev/null << 'EOF'
net.ipv4.ip_unprivileged_port_start = 80
EOF
sudo sysctl --system > /dev/null || true

# ==============================================================================
# FIN
# ==============================================================================
echo "Seguridad avanzada configurada."
echo "Verifica con: sudo ufw status verbose | sudo fail2ban-client status"
