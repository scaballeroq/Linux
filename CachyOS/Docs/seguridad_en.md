---
sidebar_position: 1
---

# CachyOS Security Hardening

This guide details the security hardening process applied to a **CachyOS** system with **GNOME** for a development workstation, as automated in the `Setup/seguridad.sh` script.

The process covers exclusive firewall configuration (**Firewalld**), Podman and KVM integration, DNS privacy, MAC Randomization, and kernel hardening.

## 1. Firewall Configuration (Firewalld)

**Firewalld** is used exclusively with the default `home` zone, integrating isolated zones for containers and virtual machines. UFW is uninstalled and purged.

1. Disable and remove UFW if it came pre-installed with CachyOS, then install/enable Firewalld:
   ```bash
   sudo systemctl disable --now ufw 2>/dev/null || true
   sudo pacman -Rns --noconfirm ufw 2>/dev/null || true
   sudo pacman -S --needed --noconfirm firewalld
   sudo systemctl enable --now firewalld
   ```

2. Configure default `home` zone and services for development:
   ```bash
   # Default zone: home
   sudo firewall-cmd --set-default-zone=home
   sudo firewall-cmd --permanent --zone=home --add-service=mdns
   sudo firewall-cmd --permanent --zone=home --add-service=ssh

   # Isolated zone for Podman Rootless
   sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true

   # Zone for KVM / libvirt virtual network
   sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true

   sudo firewall-cmd --reload
   ```

3. Verify status:
   ```bash
   sudo firewall-cmd --state
   sudo firewall-cmd --get-default-zone
   sudo firewall-cmd --zone=home --list-all
   ```

## 2. DNS Privacy (DNS-over-TLS)

To prevent ISPs from spying on your web queries, DNS traffic is encrypted via `systemd-resolved`.

1. Configure DNS-over-TLS by creating `/etc/systemd/resolved.conf.d/dot.conf`:
   ```bash
   sudo mkdir -p /etc/systemd/resolved.conf.d/
   sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
   [Resolve]
   DNSOverTLS=opportunistic
   DNSSEC=allow-downgrade
   EOF
   ```

2. Restart the service:
   ```bash
   sudo systemctl restart systemd-resolved
   ```

3. Verify status:
   ```bash
   resolvectl status
   ```

## 3. Network Privacy (MAC Randomization)

Randomizes Wi-Fi MAC address to prevent tracking on public networks.

1. Configure NetworkManager by creating `/etc/NetworkManager/conf.d/00-macrandomize.conf`:
   ```bash
   sudo mkdir -p /etc/NetworkManager/conf.d
   sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf > /dev/null <<'EOF'
   [device]
   wifi.scan-rand-mac-address=yes

   [connection]
   wifi.cloned-mac-address=stable
   EOF
   ```

2. Reload NetworkManager:
   ```bash
   sudo systemctl reload NetworkManager
   ```

## 4. Kernel Hardening (sysctl)

Applies security restrictions to the kernel compatible with Podman rootless.

Configuration in `/etc/sysctl.d/99-security.conf`:
```ini
# Kernel restrictions
kernel.dmesg_restrict=1
kernel.kptr_restrict=2

# Network protection
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Rootless container support (Podman)
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=28633
net.ipv4.ip_unprivileged_port_start=80
```

Apply changes:
```bash
sudo sysctl --system
```

## 5. Critical Permissions Auditing

Restricts permissions for vital OS files and folders.

```bash
sudo chmod 700 /root
```

## Verification

To verify the security configuration:

```bash
# Firewall
sudo firewall-cmd --state

# DNS-over-TLS
resolvectl status

# MAC Randomization
cat /etc/NetworkManager/conf.d/00-macrandomize.conf

# Kernel sysctl
sysctl kernel.dmesg_restrict kernel.kptr_restrict net.ipv4.tcp_syncookies user.max_user_namespaces
```
