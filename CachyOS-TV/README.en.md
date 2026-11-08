# 📺 CachyOS TV & Multimedia Center (HP Z230 SFF / Sony TV)

Automated, modular, and high-performance configuration to turn the **HP Z230 SFF Workstation** into a state-of-the-art living room media center using **CachyOS (Arch Linux)** with **GNOME Shell (Wayland)** connected to a **Sony TV**.

---

## 💻 Hardware Specifications (HP Z230 SFF)

Based on hardware telemetry from the actual device:

| Component | Technical Specification | CachyOS Optimization |
| :--- | :--- | :--- |
| **Model** | HP Z230 SFF Workstation | Compact and quiet form factor for living room setups |
| **Processor (CPU)** | Intel® Core™ i7-4790 (4C / 8T @ 3.60 GHz - 4.00 GHz Turbo) | Haswell architecture fully compatible with CachyOS `x86-64-v3` repositories |
| **Graphics (GPU)** | Intel® HD Graphics 4600 (HSW GT2) | Mesa Crocus driver + VA-API hardware driver `i965` (`LIBVA_DRIVER_NAME=i965`) |
| **RAM Memory** | 8.0 GiB DDR3 | Compressed ZRAM swap with `zstd` algorithm at 50% (4 GB) via `zram-generator` |
| **Storage** | 256.1 GB SSD | Periodic TRIM enabled (`fstrim.timer`) and automatic cache cleaning |
| **Display** | Sony TV (Full HD 1920x1080 @ 60Hz) | HDMI/DisplayPort connection, 1.15 visual text scale, sleep prevention |
| **Audio** | Digital HDMI Output to Sony TV Speakers | PipeWire + WirePlumber with safe quantum 1024 and stereo downmix normalization |
| **Network & NAS** | Gigabit Ethernet / Wi-Fi | Seamless integration with domestic NAS for movie and TV series streaming in Kodi |

---

## 🍿 Core Multimedia Stack

The system is configured for an effortless living room TV experience:

### 1. 🌐 Google Chrome with Widevine DRM (Web Streaming)
Native access to DRM-protected platforms with hardware-accelerated 1080p playback:
- **YouTube** (`https://www.youtube.com`)
- **Netflix** (`https://www.netflix.com`)
- **Amazon Prime Video** (`https://www.primevideo.com`)
- **Pluto TV** (`https://pluto.tv`)
- **RTVE Play** (`https://www.rtve.es/play/`)
- **Orange TV** (`https://orangetv.orange.es`)

Each service has an independent WebApp launcher (`.desktop` with `--app=URL`) and high-definition SVG vector icons pinned to the GNOME Shell favorites dock.

### 2. 📺 Kodi Media Center (Native Pacman)
- Native installation via `pacman` for full integration with the Haswell `i965` VA-API driver and PipeWire audio backend.
- Network integration with the home **NAS** to browse and stream movies and TV series over SMB/CIFS, NFS, and Avahi (mDNS) auto-discovery.
- Preconfigured mount points at `/mnt/nas/peliculas` and `/mnt/nas/series`.

### 3. 🎬 Stremio (Flatpak Flathub)
- Runs in an isolated container with specific permissions and overrides for Intel Haswell (`--env=GSK_RENDERER=gl`, `--env=LIBVA_DRIVER_NAME=i965`).
- Custom `mpv.conf` profile to eliminate clipping and audio artifacts on TV stereo speakers (`ao=pulse`, `audio-channels=stereo`, `audio-normalize-downmix=yes`).

### 4. 🎞️ VLC Media Player (Flatpak Flathub)
- Secondary video player for local files and removable drives.

---

## ⚡ Automation with Justfile

Manage the multimedia center declaratively using `just`:

```bash
# Complete unattended media center setup
just setup-tv

# Full health check of system, VA-API, HDMI audio, NAS, and apps
just status

# --- Apps & Streaming ---
just kodi              # Launch Kodi Media Center with Haswell VA-API and PipeWire
just stremio           # Launch Stremio
just vlc               # Launch VLC
just tv-webapps        # Install/update WebApp launchers and SVG icons
just tv-dock           # Configure GNOME Shell favorites dock for TV

# --- NAS Storage & Network ---
just nas-setup         # Configure SMB/NFS clients, Avahi, and /mnt/nas folders
just nas-status        # Verify NAS connection and mount status

# --- TV Audio & Browser ---
just audio             # Apply HDMI audio quantum and normalization for Sony TV
just audio-status      # PipeWire / WirePlumber diagnosis
just chrome            # Install and optimize Google Chrome for Wayland & VA-API

# --- System & Maintenance ---
just tuning-status     # View ZRAM, Sysctl, and governor metrics
just security-status   # View Firewalld status (NAS, Samba, SSH ports)
just update            # Update complete system (Pacman, AUR, and Flatpak)
just clean             # Clean package caches and unused Flatpak runtimes
```

---

## 📂 Directory Structure

```text
CachyOS-TV/
├── .agents/                    # AI profiles and specialized skills
│   ├── AGENTS.md               # Technical rules for HP Z230 SFF and CachyOS TV
│   └── skills/
│       └── cachyos-tv-multimedia/ # Skill for Kodi NAS, Stremio, Chrome, and VA-API
├── Bash.Setup/                 # Shell configuration, aliases, and environment
│   ├── aliases.sh              # Terminal shortcuts (cachy, kodi, stremio, nas)
│   └── environment.sh          # VA-API and Wayland environment variables
├── Setup/                      # Modular provisioning scripts
│   ├── chrome.sh               # Google Chrome installer and optimizer
│   ├── tv-streaming.sh         # WebApps generator and SVG icons for dock
│   ├── nas-setup.sh            # NAS storage integrator for Kodi
│   ├── multimedia.sh           # Codecs suite, media players, and HDMI TV audio
│   ├── post-install-intel.sh   # Haswell post-install, VA-API i965, and ZRAM
│   ├── flatpak.sh              # Flatpak manager and hardware overrides
│   ├── gnome-settings.sh       # HTPC living room mode, dark theme, scaling
│   ├── cachyos-tuning.sh       # Kernel sysctl performance and limits
│   ├── seguridad.sh            # Firewalld network hardening (Samba, NFS, mDNS)
│   └── icons/                  # SVG vector icons for streaming platforms
│       ├── netflix.svg
│       ├── prime-video.svg
│       ├── rtve-play.svg
│       ├── pluto-tv.svg
│       ├── youtube.svg
│       └── orange-tv.svg
└── justfile                    # Declarative task runner
```

---

## 🛡️ Security & Firewall Rules

- **Firewalld Mandatory:** All ports are strictly managed using `firewall-cmd` in the `home` zone.
- **Enabled Services:** `samba-client`, `nfs`, `mdns` (Avahi), `ssh`, and `kdeconnect` (GSConnect for smartphone remote control).
- **Prohibited:** `ufw` and raw `iptables` rules.

---

## 🚀 Getting Started on HP Z230 SFF

1. Clone the repository on your HP Z230 SFF running CachyOS:
   ```bash
   git clone -b feature/CachyOS-TV https://github.com/scaballeroq/Linux.git ~/Proyectos/Linux
   cd ~/Proyectos/Linux/CachyOS-TV
   ```
2. Run the complete setup:
   ```bash
   just setup-tv
   ```
3. Reboot the machine:
   ```bash
   sudo reboot
   ```
4. Enjoy your CachyOS TV multimedia center on your Sony TV!
