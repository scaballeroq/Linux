---
sidebar_position: 2
---

# System Setup on Debian 13

This guide details the base setup, automatic workspace mounting, native `x86_64-v3` kernel compilation, 3D screensavers, GNOME extensions, terminal enhancements, and web administration panel for Debian 13 (Trixie).

All configurations are automated through scripts located in the `Setup` folder.

---

## 1. Base Post-Installation (`post-install.sh`)

Prepares the base system by enabling additional official repositories, installing essential software, and configuring hardware acceleration.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt-add-repository -y contrib non-free non-free-firmware
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)
echo "deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt update
```

Installs `zram-tools`, `build-essential`, `flatpak`, `vlc`, `gimp`, `ffmpeg`, and Mesa 3D drivers.

---

## 2. Workspace Partition Automount (`mount-workspace.sh`)

Automatically mounts `/home/caballero/Workspace` via `/etc/fstab` using UUID `3d81e6d2-6011-484a-8123-6bcf68f365ba` with `defaults,noatime,nofail` flags.

```bash
./Setup/mount-workspace.sh
```

---

## 3. Custom NATIVE x86_64-v3 Kernel Builder (`build-custom-kernel.sh`)

Queries `kernel.org` API (`https://www.kernel.org/releases.json`) for the latest stable Linux kernel version, trims unused drivers with `make localmodconfig`, and builds native `.deb` packages tuned for `x86_64-v3`, **1000Hz** timer frequency, and **Dynamic Preemption**.

```bash
./Setup/build-custom-kernel.sh
# Or using just:
just build-kernel
```

---

## 4. Clean GNOME Extensions Installer (`gnome-extensions.sh`)

Installs `gnome-browser-connector`, `extension-manager`, and downloads 17 custom extensions using native DBus installer `gnome-extensions install --force` and automatic GSettings schema compilation (`glib-compile-schemas`).

```bash
./Setup/gnome-extensions.sh
# Or using just:
just extensions
```

---

## 5. 3D Screensaver & Lock Screen (`screensaver-setup.sh`)

Installs XScreenSaver 3D OpenGL effects (Matrix, Pipes, Flurry), registers the GNOME autostart daemon, and binds `Super + L` to lock screen with 3D animations.

```bash
./Setup/screensaver-setup.sh
```

---

## 6. Web Administration Panel Cockpit (`cockpit.sh`)

Installs Cockpit with modules for Podman (`cockpit-podman`), KVM VMs (`cockpit-machines`), Storage (`cockpit-storaged`), Networking (`cockpit-networkmanager`), and Hardware Sensors (`lm-sensors`).

Configures UFW rate-limiting (`sudo ufw limit 9090/tcp`) and uses systemd socket activation (`cockpit.socket`). Access at [https://localhost:9090](https://localhost:9090).
