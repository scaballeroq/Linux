#!/bin/bash
# seguridad.sh - Configuración de Firewall (UFW) para Omarchy (Laptop)

set -e

echo "🔒 Configurando Firewall (UFW) para Omarchy..."

# 1. Instalar UFW y GUFW (interfaz gráfica) si no están presentes
echo "ℹ️ Verificando instalación de UFW y GUFW..."
sudo pacman -S --needed --noconfirm ufw gufw

# 2. Resetear reglas previas para garantizar un estado limpio
sudo ufw --force reset

# 3. Políticas por defecto: denegar tráfico entrante, permitir tráfico saliente
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 4. Tráfico interno (Loopback / Localhost para desarrollo local y contenedores)
sudo ufw allow in on lo
sudo ufw deny in from 127.0.0.0/8
sudo ufw deny in from ::1

# 5. SSH: Permitido con limitación de intentos (Anti fuerza bruta) desde redes privadas
sudo ufw allow from 10.0.0.0/8 to any port 22 proto tcp comment "SSH LAN 10.x"
sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment "SSH LAN 172.x"
sudo ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment "SSH LAN 192.168.x"
sudo ufw limit 22/tcp comment "SSH rate limit"

# 6. mDNS y DHCP (Descubrimiento en red local, impresoras y asignación de IP)
sudo ufw allow in 5353/udp comment "mDNS/Avahi"
sudo ufw allow in 67/udp comment "DHCP"
sudo ufw allow in 68/udp comment "DHCP"

# 7. Habilitar y persistir UFW en systemd para arranques futuros
sudo ufw --force enable
sudo ufw logging low
sudo systemctl enable --now ufw.service

echo ""
echo "✅ Firewall UFW configurado, habilitado y persistido en systemd."
echo ""
echo "📋 Estado actual del Firewall:"
sudo ufw status verbose

