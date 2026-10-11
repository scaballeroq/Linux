---
sidebar_position: 1
---

# Security Hardening and Firewall on Debian Testing (KDE Plasma 6)

This guide details the security, network, and system hardening process automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/Setup/seguridad.sh), optimized for a local developer workstation running **Debian Testing (Trixie/Sid)** and **KDE Plasma 6 (Wayland)**.

---

## 1. Native Firewall (Firewalld / UFW)

Configures the firewall to safeguard the machine while maintaining seamless local development (Podman, KVM), KDE Plasma, KDE Connect, and local LAN discovery:

1. **Firewall Manager**:
   Detects and configures **Firewalld** (preferred on KDE) or **UFW** depending on your system setup.

2. **Rules for KDE Plasma, KDE Connect, and Development**:
   - **KDE Connect (`kdeconnect`)**: Enables phone-PC notifications, media controls, shared clipboard, and file transfer.
   - **Local Discovery (`mdns`)**: Discovers network printers (HP LaserJet), media renderers, and LAN services.
   - **Remote Access (`ssh`)**: Secure SSH connectivity.
   - **Cockpit Web Console**: Port `9090/tcp` for web administration.
   - **Virtual Machines & Containers**:
     - Rootless Podman subnets (`podman+` and `cni-podman+`) in `trusted` zone.
     - KVM virtualization bridge (`virbr0`) in `trusted` zone with IP Masquerade.

---

## 2. Kernel & Network Sysctl Tuning for Development

Applies kernel settings in `/etc/sysctl.d/99-development-network.conf`:

```ini
# /etc/sysctl.d/99-development-network.conf

# IP forwarding for containers and VMs
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Allow Rootless Podman to bind standard HTTP/HTTPS ports (>=80) without root
net.ipv4.ip_unprivileged_port_start = 80

# Allow ICMP ping operations in unprivileged containers
net.ipv4.ping_group_range = 0 2147483647

# Full user namespace support
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 65536

# Local network protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
```

---

## 3. Domestic Local Network Sanity

Removes friction for home developer workstations:
- **DHCP Stability & IP Reservations**: Removes NetworkManager MAC randomization to ensure steady IP leases from your router.
- **No Fail2ban Overhead**: Avoids unnecessary resource consumption on trusted private subnets.
- **Native DNS**: Resolves local `.local` and `.lan` domains via your router.

---

## 4. Critical Permissions Audit

Ensures sensitive directories have restricted permissions:
```bash
sudo chmod 700 /root
```

---

## 5. Execution and Diagnostics via Just

```bash
# Apply security and network hardening
just security

# Diagnose firewall and sysctl settings
just security-status
```
