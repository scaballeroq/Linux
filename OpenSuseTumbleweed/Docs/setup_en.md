---
sidebar_position: 2
---

# System Setup in OpenSUSE Tumbleweed

This guide details the base setup, Packman & OPI repositories, Snapper/Btrfs snapshots, workspace automounting, native `x86_64-v3` kernel compilation, GNOME customization, Ptyxis/Kitty terminals, GNOME Shell extensions, and Cockpit web console on **OpenSUSE Tumbleweed** with **GNOME**.

All tasks are automated via scripts in `Setup/` and `justfile`.

---

## 1. Post-Installation Base (`post-install.sh`, `post-install-amd.sh`, `post-install-intel.sh`)

Configures Packman repository (priority 90), full multimedia codecs, ZRAM, PipeWire, GNOME suite, and hardware acceleration:

```bash
just post-install-amd    # AMD Ryzen + Radeon
just post-install-intel  # Intel Core + Media Center
```

---

## 2. Workspace Partition Automount (`mount-workspace.sh`)

Auto-mounts `/home/caballero/Workspace` via `/etc/fstab` using UUID with `defaults,noatime,nofail`.

```bash
just workspace
```

---

## 3. System & Snapper Tuning (`tumbleweed-tuning.sh`)

Configures sysctl (`inotify`, `max_map_count`) and Snapper retention policies on Btrfs to avoid storage exhaustion.

```bash
just tuning
```

---

## 4. Native Linux Kernel Compiler (`build-custom-kernel.sh`)

Compiles an optimized kernel for `x86_64-v3`, **1000Hz** timer, and dynamic preemption.

```bash
just build-kernel
```

---

## 5. Clean GNOME Extensions Installation (`gnome-extensions.sh`)

Installs GNOME Shell extensions via DBus and compiles GSettings schemas (`glib-compile-schemas`).

```bash
just extensions
```

---

## 6. Development Laptop Setup (`laptop-setup.sh`)

- **Automatic 95% brightness**: Systemd service + GNOME autostart.
- **Power management**: `power-profiles-daemon`, `switcheroo-control`.
- **Touchpad & Display**: Tap-to-click, natural scrolling, VRR.

```bash
just laptop
```

---

## 7. Web Management with Cockpit (`cockpit.sh`)

Access Cockpit at [https://localhost:9090](https://localhost:9090) with Podman and KVM support.

```bash
just cockpit
```
