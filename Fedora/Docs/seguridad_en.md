---
sidebar_position: 1
---

# Security Configuration on Fedora 44

This guide details the security hardening process tailored for a developer ldnf5op running KVM and Podman, as automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Setup/seguridad.sh).

---

## 1. Firewall (Firewalld), KVM/Podman Routing & Fail2ban

Configures Firewalld without breaking KVM virtual machines (`virbr0`) or Podman containers:

1. **Package Installation**:
   ```bash
   sudo dnf5 update
   sudo dnf5 install -y firewalld fail2ban
   ```

2. **KVM & Podman Packet Forwarding Fix**:
   Sets `DEFAULT_FORWARD_POLICY="ACCEPT"` in `/etc/default/firewalld` and allows forwarding on `virbr0`:
   ```bash
   sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/firewalld
   sudo firewalld route allow in on virbr0
   ```

3. **Rate-Limiting Rules**:
   - `sudo firewalld default deny incoming`
   - `sudo firewalld default allow outgoing`
   - `sudo firewalld limit ssh` (Allows roaming Wi-Fi SSH logins while rate-limiting brute force attacks).
   - `sudo firewalld limit 9090/tcp` (Protects Cockpit Web Console).

4. **Fail2ban**:
   `sudo systemctl enable --now fail2ban.service`

---

## 2. DNS Privacy (DNS-over-TLS) (`seguridad-dot.sh`)

Encrypted DNS queries using Cloudflare and `systemd-resolved`:

```bash
./Setup/seguridad-dot.sh
```
