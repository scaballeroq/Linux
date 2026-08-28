---
sidebar_position: 1
---

# Security Hardening & Firewall on Fedora 44 (KDE Plasma 6)

This guide details the security, privacy, and system hardening process automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Setup/seguridad.sh), tailored for developer laptops and workstations running **Fedora 44** with **KDE Plasma 6**.

---

## 1. Native Firewall (Firewalld - `FedoraWorkstation` Zone)

Configures Firewalld to safeguard the machine from unauthorized incoming connections while ensuring full support for local development, KDE Plasma tools, and home networks:

1. **Service Activation**:
   ```bash
   sudo systemctl enable --now firewalld
   ```

2. **Cleaning Unnecessary Services**:
   Removes legacy or unnecessary services from the default zone:
   ```bash
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=samba-client
   ```

3. **KDE Plasma & Developer Rules**:
   - **KDE Connect (`kdeconnect`)**: Enables phone-to-PC syncing, notifications, media control, and file sharing.
   - **Local Discovery (`mdns`)**: Enables printer (HP LaserJet), media device, and local service discovery.
   - **Remote Access (`ssh`)**: Maintains secure incoming SSH access.
   ```bash
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=mdns
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=ssh
   sudo firewall-cmd --reload
   ```

---

## 2. DNS Privacy (DNS-over-TLS via `systemd-resolved`)

Encrypts DNS lookups across public and Wi-Fi networks using `systemd-resolved`:

```ini
# /etc/systemd/resolved.conf.d/dot.conf
[Resolve]
DNSOverTLS=opportunity
DNSSEC=allow-downgrade
```

Restart to activate:
```bash
sudo systemctl restart systemd-resolved
```

---

## 3. Wi-Fi Privacy (MAC Randomization)

Configures NetworkManager to randomize MAC addresses when scanning and associating with Wi-Fi networks:

```ini
# /etc/NetworkManager/conf.d/00-macrandomize.conf
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
```

---

## 4. Kernel Hardening (Sysctl) & Rootless Podman

Applies defensive kernel parameters while granting required user namespaces for rootless Podman containers:

```ini
# /etc/sysctl.d/99-security.conf
# Kernel restrictions
kernel.dmesg_restrict=1
kernel.kptr_restrict=2

# Network protections (Anti-spoofing & TCP SYN Cookies)
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Essential support for Rootless Podman / Quadlets
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=28633
```

---

## 5. Critical Permissions Audit

Ensures that sensitive system directories remain restricted:
```bash
sudo chmod 700 /root
```

---

## 6. Automation with Just

```bash
just security
# or ./Setup/seguridad.sh
```

---

## Verification

The script automatically displays the status of all security components:
- **Firewalld**: `sudo firewall-cmd --state`
- **DNS-over-TLS**: Checks directive in `systemd-resolved`.
- **MAC Randomization**: Checks configuration in NetworkManager.
- **User Namespaces**: `sysctl user.max_user_namespaces`.
