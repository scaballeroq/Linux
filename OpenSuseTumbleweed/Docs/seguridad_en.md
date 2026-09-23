---
sidebar_position: 1
---

# Security Hardening & Firewall in openSUSE Tumbleweed (KDE Plasma 6)

This guide details the security, networking, and system hardening process automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Setup/seguridad.sh), specifically optimized for a development workstation with **openSUSE Tumbleweed** and **KDE Plasma 6 (Wayland)**.

---

## 1. Native Firewall (Firewalld)

Configures Firewalld to safeguard the system against unauthorized connections while maintaining seamless integration with development tools (Podman, KVM), KDE Plasma, KDE Connect, and the local network:

1. **Service Activation**:
   ```bash
   sudo systemctl enable --now firewalld
   ```

2. **Rules for KDE Plasma, KDE Connect & Development**:
   - **KDE Connect (`kdeconnect`)**: Syncs notifications, media controls, shared clipboard, and file transfer between mobile and PC.
   - **Local Discovery (`mdns`)**: Enables printer (HP LaserJet) and local network device discovery.
   - **Remote Access (`ssh`)**: Maintains secure SSH access.
   - **Virtual Machines & Containers**:
     - Podman Rootless subnets (`podman+` and `cni-podman+`) assigned to the `trusted` zone.
     - KVM virtual bridge (`virbr0`) assigned to the `trusted` zone with active IP Masquerade.

---

## 2. Kernel & Network Optimization (Sysctl) for Development

Applies kernel parameters in `/etc/sysctl.d/99-development-network.conf` to guarantee full compatibility with rootless Podman containers and KVM virtual machines without requiring root execution:

```ini
# /etc/sysctl.d/99-development-network.conf

# Packet forwarding for containers and VMs
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Allow Podman Rootless to bind standard HTTP/HTTPS ports (>=80) without root
net.ipv4.ip_unprivileged_port_start = 80

# Allow ICMP ping inside unprivileged containers
net.ipv4.ping_group_range = 0 2147483647

# User namespaces support
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 65536

# Standard network protection (reverse path filtering and SYN cookies)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
```

---

## 3. Home Local Network Sanitation

For a home development workstation, unnecessary overhead and configurations that cause friction are eliminated:

- **DHCP Stability & IP Reservations**: Removes MAC address randomization (`00-macrandomize.conf`) so the router maintains static DHCP IP reservations.
- **No Fail2ban Overhead**: Disables Fail2ban on private LANs where ports are not directly exposed to the public Internet.
- **Native Router DNS**: Keeps the local router's DNS resolution active, allowing `.local` and `.lan` hostnames to resolve smoothly.

---

## 4. Critical Permissions Audit

Ensures sensitive system directories cannot be accessed by unauthorized users:
```bash
sudo chmod 700 /root
```

---

## 5. Execution & Status Diagnostics via Just

```bash
# Apply security and network configurations
just security

# Inspect status of firewall, interfaces, and sysctl parameters
just security-status
```
