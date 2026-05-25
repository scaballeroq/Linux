---
sidebar_position: 1
---

# Debian 13 Security Hardening

This guide details the security hardening process applied to a Debian 13 system, as automated in the security setup script.

The process covers firewall configuration, brute-force protection, DNS privacy, and critical permissions auditing.

## 1. Firewall Configuration (UFW)

Uncomplicated Firewall (UFW) is used to define strict network policies.

1. Install UFW if it's not present:
   ```bash
   sudo apt update
   sudo apt install -y ufw
   ```

2. Set default policies (deny incoming, allow outgoing):
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   ```

3. Allow SSH connections **only** from the local network and limit attempts to prevent brute-force attacks:
   ```bash
   sudo ufw limit from 192.168.1.0/24 to any port ssh
   ```
   *(Note: Adjust `192.168.1.0/24` according to your local network setup.)*

4. Enable the firewall:
   ```bash
   sudo ufw --force enable
   ```

## 2. Brute-Force Protection (Fail2Ban)

Fail2Ban monitors system logs and automatically blocks IP addresses that exhibit malicious behaviors.

1. Install Fail2Ban:
   ```bash
   sudo apt install -y fail2ban
   ```

2. Enable and start the service to run continuously:
   ```bash
   sudo systemctl enable --now fail2ban
   ```

## 3. DNS Privacy (DNS-over-TLS)

To prevent ISPs from spying on your web queries, DNS traffic is encrypted via `systemd-resolved` using Cloudflare.

1. Install `systemd-resolved`:
   ```bash
   sudo apt install -y systemd-resolved
   ```

2. Configure Cloudflare servers with DNS-over-TLS by creating the `/etc/systemd/resolved.conf.d/dot.conf` file:
   ```bash
   sudo mkdir -p /etc/systemd/resolved.conf.d/
   sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
   [Resolve]
   DNS=1.1.1.1 1.0.0.1
   DNSSEC=yes
   DNSOverTLS=yes
   FallbackDNS=8.8.8.8
   EOF
   ```

3. Restart the service to apply changes:
   ```bash
   sudo systemctl enable --now systemd-resolved
   sudo systemctl restart systemd-resolved
   ```

4. Redirect local traffic to the encrypted DNS:
   ```bash
   sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
   ```

## 4. Critical Permissions Auditing

Permissions for vital OS files and folders are restricted to prevent unprivileged programs or users from modifying them.

1. Protect the administrator's folder and password files:
   ```bash
   sudo chmod 700 /root
   sudo chmod 644 /etc/passwd
   sudo chmod 644 /etc/group
   sudo chmod 600 /etc/shadow
   sudo chmod 600 /etc/gshadow
   ```

## Verification

To verify that the encrypted DNS is working properly, run:
```bash
resolvectl status
```
