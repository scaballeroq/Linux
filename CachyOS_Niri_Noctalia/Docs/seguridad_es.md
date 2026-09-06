---
sidebar_position: 1
---

# Configuración de Seguridad en CachyOS

Esta guía detalla el proceso de endurecimiento de seguridad (hardening) aplicado a un sistema **CachyOS** con **KDE Plasma 6**, tal y como se automatiza en el script de seguridad.

El proceso cubre la configuración del firewall (Firewalld), privacidad DNS, MAC Randomization y endurecimiento del kernel.

## 1. Configuración de Firewall (Firewalld)

Se utiliza Firewalld para definir políticas estrictas de red con zonas dinámicas.

1. Desactiva UFW si vino preinstalado en CachyOS, e instala/habilita Firewalld:
   ```bash
   sudo systemctl disable --now ufw 2>/dev/null || true
   sudo pacman -S --needed --noconfirm firewalld
   sudo systemctl enable --now firewalld
   ```

2. Configura servicios útiles para desarrollo y KDE Plasma:
   ```bash
   sudo firewall-cmd --permanent --add-service=kdeconnect
   sudo firewall-cmd --permanent --add-service=mdns
   sudo firewall-cmd --permanent --add-service=ssh
   sudo firewall-cmd --reload
   ```

3. Verifica el estado:
   ```bash
   sudo firewall-cmd --state
   sudo firewall-cmd --list-all
   ```

## 2. Privacidad DNS (DNS-over-TLS)

Para evitar que tu proveedor de internet espíe tus consultas web, se cifra el tráfico DNS mediante `systemd-resolved`.

1. Configura DNS-over-TLS creando `/etc/systemd/resolved.conf.d/dot.conf`:
   ```bash
   sudo mkdir -p /etc/systemd/resolved.conf.d/
   sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
   [Resolve]
   DNSOverTLS=opportunistic
   DNSSEC=allow-downgrade
   EOF
   ```

2. Reinicia el servicio:
   ```bash
   sudo systemctl restart systemd-resolved
   ```

3. Verifica el estado:
   ```bash
   resolvectl status
   ```

## 3. Privacidad en Redes (MAC Randomization)

Randomiza la dirección MAC de Wi-Fi para evitar tracking en redes públicas.

1. Configura NetworkManager creando `/etc/NetworkManager/conf.d/00-macrandomize.conf`:
   ```bash
   sudo mkdir -p /etc/NetworkManager/conf.d
   sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf > /dev/null <<'EOF'
   [device]
   wifi.scan-rand-mac-address=yes

   [connection]
   wifi.cloned-mac-address=stable
   EOF
   ```

2. Recarga NetworkManager:
   ```bash
   sudo systemctl reload NetworkManager
   ```

## 4. Endurecimiento del Kernel (sysctl)

Aplica restricciones de seguridad al kernel compatibles con Podman rootless.

Configuración en `/etc/sysctl.d/99-security.conf`:
```ini
# Restricciones de kernel
kernel.dmesg_restrict=1
kernel.kptr_restrict=2

# Proteccion de red
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Soporte para contenedores rootless (Podman)
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=28633
```

Aplicar cambios:
```bash
sudo sysctl --system
```

## 5. Auditoría de Permisos Críticos

Se restringen los permisos de archivos y carpetas vitales del sistema.

```bash
sudo chmod 700 /root
```

## Verificación

Para comprobar la configuración de seguridad:

```bash
# Firewall
sudo firewall-cmd --state

# DNS-over-TLS
resolvectl status

# MAC Randomization
cat /etc/NetworkManager/conf.d/00-macrandomize.conf

# Kernel sysctl
sysctl kernel.dmesg_restrict kernel.kptr_restrict net.ipv4.tcp_syncookies user.max_user_namespaces
```
