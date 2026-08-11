# 🔧 Debian Environment Configuration (GNOME Desktop)

This repository contains an organized and modular collection of setup scripts for **Debian** systems (Debian 12 Bookworm / Debian 13 Trixie) with the **GNOME** desktop environment (optimized for workstation PCs and development laptops).

---

## 📂 Repository Structure

The configuration is modularly structured for ease of maintenance and readability:

### 🐚 [Bash.Setup](./Bash.Setup/)
Core Bash shell configuration.
- **`aliases.sh`**: Common command shortcuts.
- **`environment.sh`**: Global environment variables.
- **`functions.sh`**: Advanced helper functions and utilities.
- **`gnome_settings.sh`**: GNOME environment settings, touchpad, power, and HiDPI.
- **`history.sh`**: History behavior settings.
- **`options.sh`**: Internal Bash behavior options (`shopt` / `bind`).
- **`podman-functions.sh`**: Helper functions for container management.
- **`rclone_aliases.sh`**: Cloud sync shortcuts.
- **`yt-dlp_aliases.sh`**: Optimized media download aliases.

### 🐳 [Podman](./Podman/)
Isolated container service deployment scripts:
- **Core**: `podman.sh` (Main installation on Debian)
- **Databases**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Management & Monitoring**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-dozzle.sh`, `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`
- **Infrastructure**: `podman-nginx.sh`, `podman-keycloak.sh`, `podman-rabbitmq.sh`, `podman-minio.sh`, `podman-mailhog.sh`, `podman-browserless.sh`
- **Frameworks/CMS**: `podman-wordpress.sh`, `podman-storybook.sh`

### 🖥️ [Virtualization](./Virtualizacion/)
- **`virtualization.sh`**: High-performance KVM/QEMU virtualization setup (libvirt modular sockets, VirtIO stable ISO, Nested KVM, vhost_net acceleration).
- **`notas_virtualizacion_debian.md`**: Detailed KVM/QEMU guide for Debian.

### ⚙️ [Setup](./Setup/)
OS configuration, customization, and hardening scripts:
- **`post-install.sh`**: Master post-install script (Enables `contrib`, `non-free`, `non-free-firmware`, and `backports`).
- **`laptop-setup.sh`**: Development laptop optimization (Touchpad, Bluetooth, `power-profiles-daemon`, `switcheroo-control`, HiDPI, VRR).
- **`fingerprint-setup.sh`**: Fingerprint unlock & admin authentication (`fprintd`, PAM `sudo`, `polkit-1`, `pam-auth-update`).
- **`debian-tuning.sh`**: Kernel tuning (`sysctl`) and `distrobox`.
- **`gnome-extensions.sh`**: Automated setup of `gnome-browser-connector`, `extension-manager`, and clean installation of 17 custom GNOME extensions.
- **`apariencia.sh`**: Theme and icon installation.
- **`cockpit.sh`**: Cockpit web admin installation and setup.
- **`fastfetch.sh`**: System summary info on terminal launch (Fastfetch).
- **`firefox.sh`**: Mozilla Firefox installation.
- **`fonts.sh`**: Automated developer fonts installation (Nerd Fonts).
- **`ptyxis.sh`**: Ptyxis terminal emulator setup.
- **`seguridad.sh`**: Hardening and UFW firewall setup.
- **`shell.sh`**: Modern CLI utilities (`eza`, `bat`, `fd`, `zoxide`, `ripgrep`) and Starship prompt.
- **`yt-dlp-setup.sh`**: Media dependencies (yt-dlp, ffmpeg).

---

## 🚀 Getting Started

```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/Debian
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/*.sh Git/*.sh Apps/*.sh Juegos/*.sh
just setup-all
```

---
*Maintained by [caballero](https://github.com/scaballeroq)*
