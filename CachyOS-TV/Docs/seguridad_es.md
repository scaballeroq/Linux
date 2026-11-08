---
sidebar_position: 1
---

# Endurecimiento de Seguridad y Cortafuegos en CachyOS TV

Esta guía detalla el proceso de seguridad, cortafuegos y optimización de red aplicado al sistema **CachyOS (Arch Linux)** en el centro multimedia **HP Z230 SFF Workstation (Sony TV)**, tal y como se automatiza en el script [`Setup/seguridad.sh`](file:///home/televisor/Proyectos/Linux/CachyOS-TV/Setup/seguridad.sh).

El proceso cubre el cortafuegos exclusivo (**Firewalld** con backend `nftables`), apertura de servicios para streaming doméstico (NAS, Kodi, Stremio, GSConnect, Cockpit), privacidad mediante **DNS-over-TLS (DoT)** y optimización de buffers TCP del kernel para reproducción 1080p sin cortes.

---

## 1. Configuración del Cortafuegos Exclusivo (Firewalld)

Se utiliza **Firewalld** exclusivamente con la zona por defecto `home`, asegurando la eliminación y purga total de UFW o reglas conflictivas de `iptables`.

### 1.1 Desinstalación de UFW e Instalación de Firewalld
```bash
sudo systemctl disable --now ufw 2>/dev/null || true
sudo pacman -Rns --noconfirm ufw 2>/dev/null || true
sudo pacman -S --needed --noconfirm firewalld
sudo systemctl enable --now firewalld.service
```

### 1.2 Definición de Servicios Multimedia Personalizados
El script registra dos definiciones nativas en `/etc/firewalld/services/`:
- **Kodi Media Center (`kodi.xml`)**: Puerto `8080/tcp` (interfaz HTTP y control remoto con aplicaciones como Kore/Yatse) y `9777/udp` (Kodi EventServer).
- **Stremio Engine (`stremio.xml`)**: Puerto `11470/tcp` (servidor local de streaming y Web API).

### 1.3 Asignación de Zona `home` y Apertura de Servicios
```bash
# Establecer zona predeterminada 'home'
sudo firewall-cmd --set-default-zone=home

# Servicios de red y streaming
sudo firewall-cmd --permanent --zone=home --add-service=samba-client
sudo firewall-cmd --permanent --zone=home --add-service=nfs
sudo firewall-cmd --permanent --zone=home --add-service=mdns
sudo firewall-cmd --permanent --zone=home --add-service=upnp-client
sudo firewall-cmd --permanent --zone=home --add-service=kdeconnect
sudo firewall-cmd --permanent --zone=home --add-service=ssh
sudo firewall-cmd --permanent --zone=home --add-service=cockpit
sudo firewall-cmd --permanent --zone=home --add-service=kodi
sudo firewall-cmd --permanent --zone=home --add-service=stremio

# Recargar reglas
sudo firewall-cmd --reload
```

---

## 2. Privacidad DNS (DNS-over-TLS)

Para evitar la interceptación de consultas DNS por parte del proveedor de internet (ISP) y acelerar la resolución de nombres en streaming, se cifra el tráfico mediante **Systemd-resolved** con servidores **Quad9** (con bloqueo de malware) y **Cloudflare** (baja latencia).

Archivo `/etc/systemd/resolved.conf.d/dot.conf`:
```ini
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=8.8.8.8#dns.google 8.8.4.4#dns.google
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
MulticastDNS=resolve
LLMNR=no
Cache=yes
CacheTimeSecMax=86400
```

Reinicio del servicio:
```bash
sudo systemctl enable --now systemd-resolved.service
sudo systemctl restart systemd-resolved
```

---

## 3. Endurecimiento del Kernel y Buffers de Streaming (Sysctl)

Optimizado específicamente para el adaptador Gigabit Intel I217-LM y los 8 GB de RAM del HP Z230 SFF.

Archivo `/etc/sysctl.d/99-tv-security.conf`:
```ini
# Protección contra spoofing y ataques SYN
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1

# Ignorar ICMP broadcast y respuestas erróneas
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# Buffers de red optimizados para streaming continuo 1080p
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=1048576
net.core.wmem_default=1048576
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192

# Persistencia Keepalive para conexiones ininterrumpidas con el NAS
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_fin_timeout=15

# Permisos seguros y namespaces
net.ipv4.ip_unprivileged_port_start=80
user.max_user_namespaces=65536
kernel.dmesg_restrict=1
kernel.kptr_restrict=1
fs.protected_hardlinks=1
fs.protected_symlinks=1
```

Aplicar cambios en caliente:
```bash
sudo sysctl --system
```

---

## 4. Auditoría y Permisos

Protección estricta del directorio `/root`:
```bash
sudo chmod 700 /root
```

---

## 5. Comandos y Verificación con el Script

El script `Setup/seguridad.sh` proporciona una interfaz CLI completa para verificar y operar el cortafuegos:

```bash
# Ver diagnóstico detallado del cortafuegos, servicios multimedia y sysctl
./Setup/seguridad.sh --status
# o con just
just security-status

# Aprovisionar y aplicar todas las optimizaciones de seguridad
sudo ./Setup/seguridad.sh
# o con just
just security

# Abrir un puerto adicional en zona 'home' (ej: 8000/tcp)
sudo ./Setup/seguridad.sh --add-port 8000/tcp

# Cerrar un puerto en zona 'home'
sudo ./Setup/seguridad.sh --remove-port 8000/tcp

# Restaurar configuración estándar multimedia de Firewalld
sudo ./Setup/seguridad.sh --reset
```
