---
sidebar_position: 7
---

# Security & Hardening in OpenSUSE Tumbleweed

This guide details the security setup applied via `Setup/seguridad.sh` and `Setup/seguridad-dot.sh` in **OpenSUSE Tumbleweed + GNOME**.

---

## 1. Firewall (Firewalld)

Managed via **Firewalld** (`firewall-cmd`), configured to:
- Allow SSH with rate limiting.
- Trust KVM (`virbr0`) and Podman container interfaces.
- Protect Cockpit web console (port 9090).

```bash
just security
```

---

## 2. Fail2ban Protection

Protects against brute-force attacks via `fail2ban.service`.

---

## 3. Wi-Fi Privacy (MAC Randomization)

Configured in NetworkManager (`/etc/NetworkManager/conf.d/00-macrandomize.conf`) for random MAC address scanning.

---

## 4. DNS-over-TLS (`seguridad-dot.sh`)

Encrypted DNS queries via `systemd-resolved` (1.1.1.1).

```bash
just security-dot
```
