---
sidebar_position: 1
---

# Security Hardening & Firewall in openSUSE Tumbleweed (KDE Plasma 6)

This guide details the security, privacy, and system hardening automated in [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Setup/seguridad.sh), optimized for a development workstation and laptop running **openSUSE Tumbleweed** and **KDE Plasma 6 (Wayland)**.

---

## 1. Native Firewall (Firewalld)

Configures Firewalld to safeguard the system against unauthorized connections while maintaining seamless integration with development tools, KDE Plasma, KDE Connect, and local networks:

1. **Service Activation**:
   ```bash
   sudo systemctl enable --now firewalld
   ```

2. **Removing Unnecessary Services**:
   Removes obsolete or insecure services on public/home networks:
   ```bash
   sudo firewall-cmd --permanent --zone=public --remove-service=samba-client 2>/dev/null || true
   ```

3. **Rules for KDE Plasma, KDE Connect & Development**:
   - **KDE Connect (`kdeconnect`)**: Syncs notifications, media controls, shared clipboard, and file transfer between mobile and PC.
   - **Local Discovery (`mdns`)**: Enables printer (HP LaserJet) and local network device discovery.
   - **Remote Access (`ssh`)**: Maintains secure SSH access.
   - **Virtual Machines & Containers**: `virbr0` interface in `libvirt` zone, and `podman+` subnets in `trusted` zone.
   ```bash
   sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect
   sudo firewall-cmd --permanent --zone=public --add-service=mdns
   sudo firewall-cmd --permanent --zone=public --add-service=ssh
   sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
   sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
   sudo firewall-cmd --reload
   ```

---

## 2. DNS Privacy (DNS-over-TLS with `systemd-resolved`)

Encrypts system DNS queries to protect traffic against eavesdropping on public Wi-Fi networks:

```ini
# /etc/systemd/resolved.conf.d/dot.conf
[Resolve]
DNSOverTLS=opportunity
DNSSEC=allow-downgrade
```

Immediate activation:
```bash
sudo systemctl restart systemd-resolved
```

---

## 3. Wi-Fi Privacy (MAC Randomization)

Configures NetworkManager to randomize MAC addresses when scanning and connecting to Wi-Fi networks, preventing physical tracking of the HP EliteBook laptop:

```ini
# /etc/NetworkManager/conf.d/00-macrandomize.conf
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
```

---

## 4. Kernel Hardening (Sysctl) & Rootless Podman

Applies kernel-level protections while maintaining compatibility with rootless Podman containers:

```ini
# /etc/sysctl.d/99-security.conf
# Kernel restrictions
kernel.dmesg_restrict=1
kernel.kptr_restrict=2

# Network protection (Anti-spoofing and SYN Cookies)
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Unprivileged ports and Rootless Podman
net.ipv4.ip_unprivileged_port_start=80
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=28633
```

---

## 5. Critical Permissions Audit

Ensures sensitive system directories cannot be accessed by unauthorized users:
```bash
sudo chmod 700 /root
```

---

## 6. Automation via Just

```bash
just security
# or ./Setup/seguridad.sh
```

---

## Verification

The script automatically reports component status upon completion:
- **Firewalld**: `sudo firewall-cmd --state`
- **DNS-over-TLS**: Checks directive in `systemd-resolved`.
- **MAC Randomization**: Checks directive in NetworkManager.
- **User Namespaces**: `sysctl user.max_user_namespaces`.
