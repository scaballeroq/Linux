---
sidebar_position: 10
---

# Rootless Podman & Systemd Quadlets in OpenSUSE Tumbleweed

This guide describes the **Rootless Podman** container setup and **Systemd Quadlets** integration on **OpenSUSE Tumbleweed**.

---

## 1. Architecture

- **Security**: 100% rootless daemonless containers.
- **Networking**: Netavark + Aardvark-DNS for inter-container DNS resolution.
- **Orchestration**: Systemd Quadlets managed under `~/.config/containers/systemd/`.
- **Docker API**: Active socket at `$XDG_RUNTIME_DIR/podman/podman.sock`.

---

## 2. Installation

```bash
just podman-base
just podman-quadlets
```
