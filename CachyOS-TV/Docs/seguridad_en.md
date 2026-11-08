---
sidebar_position: 1
---

# Security Hardening and Firewall Configuration in CachyOS TV

This guide details the security, firewall, and network optimization process applied to the **CachyOS (Arch Linux)** system on the **HP Z230 SFF Workstation (Sony TV)** media center, as automated in [`Setup/seguridad.sh`](file:///home/televisor/Proyectos/Linux/CachyOS-TV/Setup/seguridad.sh).

The setup covers an exclusive firewall (**Firewalld** using the `nftables` backend), essential service access for home streaming (NAS, Kodi, Stremio, GSConnect, Cockpit), **DNS-over-TLS (DoT)** privacy, and kernel TCP buffer tuning for stutter-free 1080p video playback.

---

## 1. Exclusive Firewall Configuration (Firewalld)

**Firewalld** is used exclusively with the default `home` zone, ensuring that UFW and conflicting legacy `iptables` rules are uninstalled and purged.

### 1.1 UFW Removal and Firewalld Installation
```bash
sudo systemctl disable --now ufw 2>/dev/null || true
sudo pacman -Rns --noconfirm ufw 2>/dev/null || true
sudo pacman -S --needed --noconfirm firewalld
sudo systemctl enable --now firewalld.service
```

### 1.2 Custom Multimedia Service Definitions
The script provisions two custom service XML files under `/etc/firewalld/services/`:
- **Kodi Media Center (`kodi.xml`)**: Port `8080/tcp` (HTTP API and mobile remotes like Kore/Yatse) and `9777/udp` (Kodi EventServer).
- **Stremio Engine (`stremio.xml`)**: Port `11470/tcp` (local streaming server and Web API).

### 1.3 Setting the `home` Zone and Authorizing Services
```bash
# Set default zone to home
sudo firewall-cmd --set-default-zone=home

# Media & local network services
sudo firewall-cmd --permanent --zone=home --add-service=samba-client
sudo firewall-cmd --permanent --zone=home --add-service=nfs
sudo firewall-cmd --permanent --zone=home --add-service=mdns
sudo firewall-cmd --permanent --zone=home --add-service=upnp-client
sudo firewall-cmd --permanent --zone=home --add-service=kdeconnect
sudo firewall-cmd --permanent --zone=home --add-service=ssh
sudo firewall-cmd --permanent --zone=home --add-service=cockpit
sudo firewall-cmd --permanent --zone=home --add-service=kodi
sudo firewall-cmd --permanent --zone=home --add-service=stremio

# Reload rules
sudo firewall-cmd --reload
```

---

## 2. DNS Privacy (DNS-over-TLS)

To protect streaming queries from ISP snooping and ensure fast resolution, traffic is encrypted via **Systemd-resolved** with **Quad9** (malware protection) and **Cloudflare** (low latency).

File `/etc/systemd/resolved.conf.d/dot.conf`:
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

Restart service:
```bash
sudo systemctl enable --now systemd-resolved.service
sudo systemctl restart systemd-resolved
```

---

## 3. Kernel Hardening & Streaming Buffers (Sysctl)

Optimized for the HP Z230 SFF's Intel I217-LM Gigabit adapter and 8 GB RAM.

File `/etc/sysctl.d/99-tv-security.conf`:
```ini
# Anti-spoofing & SYN protection
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1

# Ignore broadcast ICMP & bogus error responses
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# Socket buffers optimized for HD streaming
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=1048576
net.core.wmem_default=1048576
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192

# Keepalive optimization for continuous NAS playback
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_fin_timeout=15

# Security restrictions
net.ipv4.ip_unprivileged_port_start=80
user.max_user_namespaces=65536
kernel.dmesg_restrict=1
kernel.kptr_restrict=1
fs.protected_hardlinks=1
fs.protected_symlinks=1
```

Apply immediately:
```bash
sudo sysctl --system
```

---

## 4. File Permissions Auditing

Strict restriction on `/root`:
```bash
sudo chmod 700 /root
```

---

## 5. Usage & Verification CLI

The [`Setup/seguridad.sh`](file:///home/televisor/Proyectos/Linux/CachyOS-TV/Setup/seguridad.sh) script provides a complete CLI interface:

```bash
# View comprehensive status
./Setup/seguridad.sh --status
# or via just
just security-status

# Apply full security configuration
sudo ./Setup/seguridad.sh
# or via just
just security

# Open custom port (e.g., 8000/tcp)
sudo ./Setup/seguridad.sh --add-port 8000/tcp

# Close custom port
sudo ./Setup/seguridad.sh --remove-port 8000/tcp

# Reset to media center defaults
sudo ./Setup/seguridad.sh --reset
```
