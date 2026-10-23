---
sidebar_position: 1
---

# Security Hardening and Firewall in Ubuntu Linux (GNOME Shell)

This guide details the security, network, and system hardening automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Ubuntu/Setup/seguridad.sh), specifically optimized for a local development workstation on **Ubuntu Linux** with **GNOME Shell (Wayland)**.

---

## 1. Mandatory Native Firewall (Firewalld)

Per monorepo master rules, **UFW is permanently disabled** and **Firewalld** (`firewall-cmd`) is strictly enforced:

1. **Disabling UFW & Starting Firewalld**:
   ```bash
   sudo ufw disable
   sudo systemctl disable --now ufw
   sudo systemctl mask ufw
   sudo systemctl enable --now firewalld
   ```

2. **Rules for GNOME Shell, GSConnect, and Development**:
   - **GSConnect (`kdeconnect` service in Firewalld)**: Enables notification sync, media controls, shared clipboard, and file transfer without any KDE/Qt libraries.
   - **Local Discovery (`mdns`)**: Enables printer discovery (HP LaserJet) and local network services.
   - **Remote Access (`ssh`)**: Maintains secure SSH access.
   - **Virtual Machines & Containers**:
     - Rootless Podman subnets (`podman+` and `cni-podman+`) in the `trusted` zone.
     - KVM virtualization bridge (`virbr0` and `virbr+`) in the `trusted` zone with active IP Masquerade.

---

## 2. Network and Kernel Tuning (Sysctl) for Development

Applies Kernel settings in `/etc/sysctl.d/99-development-network.conf` to guarantee full compatibility with rootless Podman and KVM virtual machines:

```ini
# /etc/sysctl.d/99-development-network.conf

# Packet forwarding for containers and VMs
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Preserve IPv6 Router Advertisements (SLAAC) with forwarding enabled
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2

# Allow Rootless Podman to bind standard HTTP/HTTPS ports (>=80) without root
net.ipv4.ip_unprivileged_port_start = 80

# Allow ICMP (ping) in unprivileged containers
net.ipv4.ping_group_range = 0 2147483647

# Full support for user namespaces
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 262144
```

---

## 3. Home LAN Optimization

For a development workstation on a private home network:
- **DHCP Stability**: Avoid MAC randomization to prevent changing the machine's local IP address and breaking static DHCP reservations.
- **No Fail2ban Overhead**: Kept inactive on home LANs where ports are not publicly exposed to the internet.

---

## 4. Execution and Diagnostics with Just

```bash
# Apply security and network setup
just security

# Inspect firewall, network interfaces, and sysctl parameters
just security-status
```
