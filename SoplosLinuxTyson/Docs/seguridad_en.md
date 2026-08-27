---
sidebar_position: 1
---

# Security Configuration in Soplos Linux Tyson

This guide details security hardening tailored for a developer laptop running **Soplos Linux Tyson**, as automated in [Setup/seguridad.sh](file:///home/caballero/Workspace/Repositorios/Linux/SoplosLinuxTyson/Setup/seguridad.sh).

The setup configures a firewall compatible with Podman, KVM, KDE Connect, Fail2ban, and local development services.

---

## 1. Firewall Configuration (UFW) for Laptop & Podman

Uncomplicated Firewall (UFW) is configured to protect the machine without breaking local container or development traffic:

1. **UFW and Fail2ban Installation**:
   ```bash
   sudo apt update
   sudo apt install -y ufw fail2ban
   ```

2. **Podman and KVM Compatibility (`DEFAULT_FORWARD_POLICY`)**:
   Enables forwarding for Podman (netavark/pasta) and KVM (`virbr0`):
   ```bash
   sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
   sudo ufw allow in on podman+
   sudo ufw route allow in on podman+
   sudo ufw route allow out on podman+
   sudo ufw allow in on virbr0
   sudo ufw route allow in on virbr0
   ```

3. **Localhost Development & KDE Integrations**:
   - Full traffic allowed on loopback `lo` for testing web servers (`localhost`, `127.0.0.1`).
   - Rules for **KDE Connect** (`1714:1764` TCP/UDP).
   - Printer discovery and mDNS Avahi (`5353/udp`, `631/udp`).

4. **Security Policies and Rate-Limiting**:
   - Deny unsolicited incoming traffic (`sudo ufw default deny incoming`).
   - Allow outgoing traffic (`sudo ufw default allow outgoing`).
   - **SSH Rate Limiting**: `sudo ufw limit ssh`.
   - **Cockpit Web Console (Port 9090)**: `sudo ufw limit 9090/tcp`.

5. **Fail2ban with systemd**:
   Enabled and supervised via systemd:
   ```bash
   sudo systemctl enable --now fail2ban.service
   ```
