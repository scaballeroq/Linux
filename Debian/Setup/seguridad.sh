#!/bin/bash
# ==============================================================================
# MANUAL PASO A PASO: ENDURECIMIENTO DE SEGURIDAD (Debian 13)
# ==============================================================================
# Este script aplica una serie de configuraciones para mejorar la seguridad
# de una instalación de Debian 13. A continuación se detalla cada paso.
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

# 1.3 Permitir y limitar el acceso por SSH (Secure Shell)
# SSH permite conectarnos al servidor de forma remota.
# Para máxima seguridad, restringimos quién puede conectarse:
# - 'from 192.168.1.0/24': Solo los equipos que estén en la misma red local (casa/oficina)
#   podrán intentar conectarse. NINGÚN equipo desde Internet podrá acceder.
#   (NOTA: Ajusta esta IP según la configuración de tu red local, ej: 10.0.0.0/8).
# - 'limit': Además de permitir la conexión, UFW vigilará que no se hagan demasiados
#   intentos seguidos. Si alguien en la red local intenta adivinar la contraseña
#   equivocándose más de 6 veces en 30 segundos, será bloqueado.
sudo ufw limit from 192.168.1.0/24 to any port ssh

# 1.4 Activar el Firewall
# Una vez definidas las reglas, encendemos el firewall. 
# El parámetro '--force' evita que el comando nos pida confirmación manual,
# lo que es ideal para scripts automáticos.
sudo ufw --force enable


# ==============================================================================
# PASO 2: PROTECCIÓN CONTRA ATAQUES DE FUERZA BRUTA (FAIL2BAN)
# ==============================================================================
# Fail2Ban es un "perro guardián" que lee constantemente los archivos de registro
# (logs) del sistema. Si detecta que alguien intenta iniciar sesión repetidas 
# veces y falla (posible ataque de diccionario o fuerza bruta), añade una regla
# temporal en el firewall para bloquear la IP del atacante.
# ==============================================================================
echo "ℹ️ Paso 2: Instalando y configurando Fail2Ban..."

# 2.1 Comprobar e instalar Fail2Ban si no está presente
if ! command -v fail2ban-client &> /dev/null; then
    echo "   - Fail2Ban no detectado. Procediendo a la instalación..."
    sudo apt install -y fail2ban
fi

# 2.2 Habilitar y arrancar el servicio
# Usamos systemctl para asegurar que el guardián de Fail2Ban:
# - Se arranque en este preciso momento ('--now')
# - Se configure para encenderse automáticamente cada vez que reiniciemos el PC ('enable')
sudo systemctl enable --now fail2ban


# ==============================================================================
# PASO 3: PRIVACIDAD EN INTERNET (DNS-OVER-TLS CON SYSTEMD-RESOLVED)
# ==============================================================================
# Cada vez que escribes 'google.com', tu PC le pregunta a un servidor DNS qué IP
# le corresponde. Normalmente, esta pregunta viaja en texto plano (sin cifrar),
# por lo que tu proveedor de internet o cualquier espía puede ver qué webs visitas.
# DNS-over-TLS (DoT) soluciona esto cifrando las consultas DNS.
# ==============================================================================
echo "ℹ️ Paso 3: Configurando DNS cifrado y seguro (DNS-over-TLS)..."

# 3.1 Instalar el gestor de red systemd-resolved (en Debian no siempre viene por defecto)
if ! systemctl list-unit-files | grep -q systemd-resolved; then
    echo "   - systemd-resolved no detectado. Procediendo a la instalación..."
    sudo apt install -y systemd-resolved
fi

# 3.2 Crear archivo de configuración para DNS-over-TLS
# Creamos una carpeta para añadir nuestra configuración personalizada
sudo mkdir -p /etc/systemd/resolved.conf.d/

# Escribimos las reglas de conexión:
# - DNS: Usaremos los servidores rápidos y privados de Cloudflare (1.1.1.1)
# - DNSSEC=yes: Activa una validación extra para asegurar que el DNS no fue manipulado.
# - DNSOverTLS=yes: ¡La magia! Cifra todo el tráfico DNS.
# - FallbackDNS: Si Cloudflare falla, usamos los de Google como respaldo temporal.
sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSSEC=yes
DNSOverTLS=yes
FallbackDNS=8.8.8.8
EOF

# 3.3 Habilitar, arrancar y reiniciar el servicio de red para aplicar los cambios
sudo systemctl enable --now systemd-resolved
sudo systemctl restart systemd-resolved

# 3.4 Configurar el sistema para usar este nuevo DNS interno
# Para que todos los programas usen nuestro DNS cifrado, necesitamos que 
# el archivo maestro (/etc/resolv.conf) apunte a systemd-resolved (127.0.0.53).
# Verificamos si ya apunta ahí. Si no, forzamos un enlace simbólico (ln -sf).
# El "|| echo" al final evita que el script falle y aborte si estamos en un
# entorno raro (como Docker o WSL en Windows) donde este archivo no se puede tocar.
if ! grep -q "127.0.0.53" /etc/resolv.conf 2>/dev/null; then
    echo "   - Redirigiendo el tráfico local al DNS cifrado..."
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || echo "⚠️ No se pudo enlazar resolv.conf (Ignorar si estás en WSL o Docker)"
fi


# ==============================================================================
# PASO 4: AUDITORÍA Y PROTECCIÓN DE PERMISOS DE ARCHIVOS CRÍTICOS
# ==============================================================================
# Linux guarda las contraseñas cifradas y los usuarios en archivos específicos.
# Si los permisos de estos archivos son incorrectos, un usuario normal o un 
# programa malicioso podría leerlos o modificarlos.
# ==============================================================================
echo "ℹ️ Paso 4: Verificando permisos de archivos críticos del sistema..."

# 4.1 Proteger el directorio del superusuario (root)
# chmod 700: Solo el propio usuario 'root' tiene acceso total (leer, escribir, ejecutar).
# Nadie más puede asomarse a su carpeta personal.
sudo chmod 700 /root

# 4.2 Proteger lista de usuarios y grupos
# /etc/passwd: Lista todos los usuarios del sistema.
# /etc/group: Lista todos los grupos del sistema.
# chmod 644: El dueño (root) puede modificarlo. El resto del mundo solo puede LEERLO.
# (Es necesario que el resto pueda leerlo para saber quién es dueño de los archivos).
sudo chmod 644 /etc/passwd
sudo chmod 644 /etc/group

# 4.3 Proteger las contraseñas cifradas
# /etc/shadow: Contiene las contraseñas cifradas de los usuarios.
# /etc/gshadow: Contiene las contraseñas cifradas de los grupos.
# chmod 600: ABSOLUTAMENTE NADIE salvo el superusuario (root) puede leer o modificar
# estos archivos. Así se evitan ataques de extracción de contraseñas.
sudo chmod 600 /etc/shadow
sudo chmod 600 /etc/gshadow

# ==============================================================================
# FIN DEL PROCESO
# ==============================================================================
echo "✅ Configuración de seguridad completada con éxito."
echo "💡 Nota: Tu tráfico DNS ahora está cifrado vía Cloudflare (1.1.1.1)."
echo "   Puedes verificar que está funcionando correctamente ejecutando: 'resolvectl status'."
