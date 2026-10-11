---
sidebar_position: 1
---

# Security Configuration on Manjaro Linux

This guide details the security hardening process tailored for a developer lpacmanop running KVM and Podman, as automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Manjaro/Setup/seguridad.sh).

---

## 1. Firewall (UFW), KVM/Podman Routing & Fail2ban

Configures UFW without breaking KVM virtual machines (`virbr0`) or Podman containers:

1. **Package Installation**:
   ```bash
   sudo pacman -Syu
   sudo pacman -S -y ufw fail2ban
   ```

2. **KVM & Podman Packet Forwarding Fix**:
   Sets `DEFAULT_FORWARD_POLICY="ACCEPT"` in `/etc/default/ufw` and allows forwarding on `virbr0`:
   ```bash
   sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
   sudo ufw route allow in on virbr0
   ```

3. **Rate-Limiting Rules**:
   - `sudo ufw default deny incoming`
   - `sudo ufw default allow outgoing`
   - `sudo ufw limit ssh` (Allows roaming Wi-Fi SSH logins while rate-limiting brute force attacks).
   - `sudo ufw limit 9090/tcp` (Protects Cockpit Web Console).

4. **Fail2ban**:
   `sudo systemctl enable --now fail2ban.service`

---

## 2. DNS Privacy (DNS-over-TLS) (`seguridad-dot.sh`)

Encrypted DNS queries using Cloudflare and `systemd-resolved`:

```bash
./Setup/seguridad-dot.sh
```
