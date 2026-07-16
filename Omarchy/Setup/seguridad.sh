#!/bin/bash
# seguridad.sh - Configuración de UFW para Arch Linux (Laptop Desarrollador)

set -e

echo "🔒 Configurando UFW..."

# Instalar ufw si no está presente
if ! command -v ufw &>/dev/null; then
    echo "📦 Instalando ufw..."
    sudo pacman -S --noconfirm ufw
fi

# Detener y deshabilitar firewalld si está activo
if systemctl is-active --quiet firewalld; then
    echo "🔄 Deshabilitando firewalld..."
    sudo systemctl disable --now firewalld
fi

# Resetear reglas existentes
sudo ufw --force reset

# Políticas por defecto: denegar entrada, permitir salida
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Loopback esencial
sudo ufw allow in on lo
sudo ufw deny in from 127.0.0.0/8
sudo ufw deny in from ::1

# SSH: solo desde redes locales (trabajo remoto seguro)
sudo ufw allow from 10.0.0.0/8 to any port 22 proto tcp
sudo ufw allow from 172.16.0.0/12 to any port 22 proto tcp
sudo ufw allow from 192.168.0.0/16 to any port 22 proto tcp

# mDNS/Bonjour (impresoras, descubrimiento de dispositivos en red local)
sudo ufw allow in 5353/udp

# DHCP para WiFi/Ethernet
sudo ufw allow in 67/udp
sudo ufw allow in 68/udp

# Desarrollo web local (solo loopback ya cubierto, pero por si usa red local)
# sudo ufw allow from 192.168.0.0/16 to any port 3000 proto tcp  # React/Next.js
# sudo ufw allow from 192.168.0.0/16 to any port 5173 proto tcp  # Vite
# sudo ufw allow from 192.168.0.0/16 to any port 8080 proto tcp  # Servidores dev

# SSH rate limiting (protección contra fuerza bruta)
sudo ufw limit 22/tcp comment "SSH rate limit"

# Habilitar UFW con logging bajo
sudo ufw --force enable
sudo ufw logging low

echo ""
echo "✅ UFW habilitado y activo"
echo ""
echo "📋 Estado actual:"
sudo ufw status verbose
