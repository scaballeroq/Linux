---
sidebar_position: 1
---

# Configuración de Seguridad en Debian 13

Esta guía detalla el proceso de endurecimiento de seguridad (hardening) aplicado a un sistema Debian 13, tal y como se automatiza en el script de seguridad.

El proceso cubre la configuración del firewall, protección contra fuerza bruta, privacidad DNS y auditoría de permisos.

## 1. Configuración de Firewall (UFW)

Se utiliza Uncomplicated Firewall (UFW) para definir políticas estrictas de red.

1. Instala UFW si no está presente:
   ```bash
   sudo apt update
   sudo apt install -y ufw
   ```

2. Establece las políticas por defecto (bloquear entrada, permitir salida):
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   ```

3. Permite conexiones SSH **solo** desde la red local y con límite de intentos para prevenir ataques de fuerza bruta:
   ```bash
   sudo ufw limit from 192.168.1.0/24 to any port ssh
   ```
   *(Nota: Ajusta `192.168.1.0/24` según la configuración de tu red local.)*

4. Activa el firewall:
   ```bash
   sudo ufw --force enable
   ```

## 2. Protección contra Fuerza Bruta (Fail2Ban)

Fail2Ban monitoriza los registros del sistema y bloquea automáticamente las direcciones IP que muestran comportamientos maliciosos.

1. Instala Fail2Ban:
   ```bash
   sudo apt install -y fail2ban
   ```

2. Habilita y arranca el servicio para que funcione continuamente:
   ```bash
   sudo systemctl enable --now fail2ban
   ```

## 3. Privacidad DNS (DNS-over-TLS)

Para evitar que tu proveedor de internet espíe tus consultas web, se cifra el tráfico DNS mediante `systemd-resolved` utilizando Cloudflare.

1. Instala `systemd-resolved`:
   ```bash
   sudo apt install -y systemd-resolved
   ```

2. Configura los servidores de Cloudflare con DNS-over-TLS creando el archivo `/etc/systemd/resolved.conf.d/dot.conf`:
   ```bash
   sudo mkdir -p /etc/systemd/resolved.conf.d/
   sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
   [Resolve]
   DNS=1.1.1.1 1.0.0.1
   DNSSEC=yes
   DNSOverTLS=yes
   FallbackDNS=8.8.8.8
   EOF
   ```

3. Reinicia el servicio para aplicar los cambios:
   ```bash
   sudo systemctl enable --now systemd-resolved
   sudo systemctl restart systemd-resolved
   ```

4. Redirige el tráfico local al DNS cifrado:
   ```bash
   sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
   ```

## 4. Auditoría de Permisos Críticos

Se restringen los permisos de archivos y carpetas vitales del sistema operativo para evitar que programas o usuarios sin privilegios los modifiquen.

1. Protege la carpeta del administrador y los archivos de contraseñas:
   ```bash
   sudo chmod 700 /root
   sudo chmod 644 /etc/passwd
   sudo chmod 644 /etc/group
   sudo chmod 600 /etc/shadow
   sudo chmod 600 /etc/gshadow
   ```

## Verificación

Para comprobar que el DNS cifrado funciona correctamente, ejecuta:
```bash
resolvectl status
```
