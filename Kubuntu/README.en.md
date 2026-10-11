# Kubuntu Environment Configuration (KDE Plasma 6)

Modular and automated collection of configuration scripts for **Kubuntu** systems (KDE Plasma 6 and 5 across Kubuntu 24.04 LTS, 24.10, and 26.04 LTS).

Automates the complete setup of a professional, fast, secure, and aesthetically refined development environment.

---

## Repository Structure

### Bash.Setup
Modular Bash terminal core loaded via `~/.bashrc.d/`:
- **`aliases.sh`**: Shortcuts for common commands, Git, APT, kernel-check, VM, Podman.
- **`desktop_settings.sh`**: KDE Plasma optimizations and shortcuts.
- **`environment.sh`**: Global environment variables (`EDITOR`, `PATH`, Wayland/Qt flags).
- **`functions.sh`**: Utility functions (backups, extract, multimedia).
- **`history.sh`**: Optimized persistent history (10k/20k lines, no duplicates).
- **`options.sh`**: Advanced shell behaviors (`autocd`, `globstar`).
- **`podman-functions.sh`**: Podman container + Quadlets management functions.
- **`rclone_aliases.sh`**: Google Drive and OneDrive sync shortcuts.
- **`yt-dlp_aliases.sh`**: Multimedia downloads with Deno JS engine.

### Setup
System, hardware, customization, and hardening scripts:
- **`post-install.sh`**: Dispatcher with auto-detection of CPU (AMD/Intel).
- **`post-install-amd.sh`**: Post-install optimized for AMD Ryzen.
- **`post-install-intel.sh`**: Post-install optimized for Intel Core.
- **`zram-setup.sh`**: ZRAM with ZSTD compression at 50% RAM.
- **`kubuntu-tuning.sh`**: Performance tuning (sysctl, limits, Baloo, systemd).
- **`kde-settings.sh`**: KDE Plasma customization (Breeze Dark, Night Color).
- **`kde-widgets.sh`**: Widgets, Klipper, KWin tiling, global shortcuts.
- **`kde-plasma-customization.sh`**: Material You Colors, official plasmoids.
- **`konsole.sh`**: Translucent Konsole (85% opacity + blur).
- **`kitty.sh`**: Kitty terminal with GPU, Catppuccin theme, configurable opacity.
- **`laptop-setup.sh`**: Laptop optimizations (VRR, HiDPI, touchpad, power).
- **`seguridad.sh`**: UFW + Fail2ban + sysctl hardening.
- **`seguridad-dot.sh`**: DNS-over-TLS (Quad9 + Cloudflare).
- **`screensaver-setup.sh`**: KScreenLocker (auto-lock).
- **`shell.sh`** / **`starship.toml`**: Modern CLI tools + Starship prompt.
- **`apariencia.sh`**: Papirus and Breeze themes/icons.
- **`fonts.sh`**: Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack).
- **`fastfetch.sh`** / **`config.jsonc`**: Aesthetic system summary.
- **`firefox.sh`**: Native .deb Firefox from Mozilla APT (no Snap).
- **`cockpit.sh`**: Web administration panel.
- **`yt-dlp-setup.sh`**: yt-dlp, ffmpeg, Deno.
- **`fingerprint-setup.sh`**: Fingerprint authentication.
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w printer.
- **`mount-workspace.sh`**: Workspace partition automount.

### Virtualizacion
- **`virtualization.sh`**: KVM/QEMU with Libvirt, Virt-Manager, `br0` bridge, VirtIO.
- **`notas_virtualizacion_kubuntu.md`**: Virtualization guide.

### IDE
- **`git.sh`**: Git, Delta, Lazygit.
- **`github-cli.sh`**: GitHub CLI (`gh`).
- **`neovim.sh`**: Neovim + LazyVim.
- **`vscode.sh`**: Visual Studio Code.
- **`antigravity.sh`**: Google Antigravity Desktop.
- **`antigravity-cli.sh`**: Google Antigravity CLI.
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine.
- **`opencode.sh`**: OpenCode AI CLI/Editor.

### ProgrammingLanguages
Runtime management via **Mise**:
- **`mise.sh`**: Mise version manager.
- **`nodejs.sh`**: Node.js LTS + pnpm.
- **`python.sh`**: Python 3.12 + pip.
- **`rust.sh`**: Rust + cargo-binstall.
- **`dotnet.sh`**: .NET SDK.
- **`java.sh`**: OpenJDK.
- **`angular.sh`**: Angular CLI.
- **`gemini.sh`**: Gemini CLI.

### Podman
Rootless container ecosystem with Quadlets:
- **`install/`**: `podman-install.sh`, `quadlets-setup.sh`
- **`lib/`**: `podman-utils.sh` (project management CLI)
- **`services-shared/`**: Global services (PostgreSQL, Redis, Traefik, Keycloak)
- **`templates/`**: Project templates (python-postgres, python-postgres-redis, fullstack)
- **`projects/`**: Active projects (gitignored)

### Apps & Juegos
- **`Apps/meld.sh`**: Visual diff and merge tool.
- **`Juegos/steam.sh`**: Steam + Proton-GE via Flatpak.

---

## Usage with Justfile

### Full profiles
```bash
just setup-all            # Auto-detect CPU
just setup-laptop-amd     # AMD Ryzen laptop
just setup-laptop-intel   # Intel Core laptop
just setup-desktop-amd    # AMD desktop
just setup-desktop-intel  # Intel desktop
```

### Individual tasks
```bash
just post-install         # Base system (auto-detect CPU)
just post-install-amd     # AMD post-install
just post-install-intel   # Intel post-install
just zram                 # ZRAM with ZSTD
just kde                  # KDE Plasma settings
just widgets              # Widgets, Klipper, shortcuts
just kde-custom           # Material You, plasmoids
just konsole              # Translucent Konsole
just kitty                # Kitty GPU terminal
just shell                # Modern terminal + Starship
just security             # UFW + Fail2ban
just security-dot         # DNS-over-TLS
just tuning               # Performance tuning
just tuning-status        # Tuning status
just virtualization       # KVM/QEMU
just firefox              # Firefox .deb
just ides                 # All IDEs
just languages            # Node, Python, Rust, .NET, Java
just podman-setup         # Podman rootless + Quadlets
just podman-status        # Podman status
```

---

## Manual Shell Setup

```bash
mkdir -p ~/.bashrc.d
ln -s $(pwd)/Bash.Setup/*.sh ~/.bashrc.d/
```

Add to `~/.bashrc`:
```bash
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

*Maintained by [caballero](https://github.com/scaballeroq)*
