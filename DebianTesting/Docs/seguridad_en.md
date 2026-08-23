---
sidebar_position: 1
---

# Security Configuration on Debian 13

This guide details the security hardening process tailored for a developer laptop running KVM and Podman, as automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Debian/Setup/seguridad.sh).

---

## 1. Firewall (UFW) & KVM/Podman Routing
 
Configures UFW tailored for developer laptops without breaking KVM virtual machines (`virbr0`) or Podman containers:
 
1. **Package Installation (UFW & GUFW GUI)**:
   ```bash
   sudo apt update
   sudo apt install -y ufw gufw
   ```
 
2. **KVM & Podman Packet Forwarding Fix**:
   Sets `DEFAULT_FORWARD_POLICY="ACCEPT"` in `/etc/default/ufw` and allows forwarding on `virbr0`:
   ```bash
   sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
   sudo ufw route allow in on virbr0
   ```
 
3. **Security Policies**:
   - `sudo ufw default deny incoming` (Blocks all unsolicited incoming traffic on public Wi-Fi).
   - `sudo ufw default allow outgoing` (Full outbound Internet connectivity).
   - Lightweight and battery-friendly (no unnecessary background daemons like Fail2ban).
