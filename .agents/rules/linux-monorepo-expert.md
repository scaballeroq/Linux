# Reglas del Agente: Experto en Linux Monorepo & Hardware HP EliteBook

## Directrices de Entorno y Arquitectura Monorepo
1. **Comandos Idempotentes, Seguros y Adaptados a la Distribución**:
   - Cada distribución tiene su gestor nativo de paquetes. Respeta las siguientes equivalencias:
     - **Debian / Ubuntu / Soplos**: `apt update`, `apt upgrade --without-new-pkgs`, `apt full-upgrade`.
     - **Fedora**: `dnf5 check-upgrade --refresh`, `dnf5 upgrade --refresh -y`.
     - **Arch / CachyOS / Manjaro**: `pacman -Syu` (oficiales) y `paru`/`yay` (AUR, **nunca** con `sudo`).
     - **openSUSE Tumbleweed**: `zypper dup` (**siempre** `dup` en rolling release, nunca `update`).
     - **NixOS**: `nixos-rebuild switch --flake .#laptop-amd` o `nix flake update`.
     - **Escritorio Desacoplado**: `flatpak update -y` (Flathub) para aplicaciones universales.
   - Para administración de servicios: prioriza `systemctl --user` para servicios y pods de usuario. Nunca uses `sudo` si una operación puede ejecutarse en modo usuario.
   - Para almacenamiento y memoria: respeta la topología con ZRAM swap (`zramctl`, `free -h`). En Btrfs (openSUSE/Arch) verifica snapshots con `snapper`; en ext4 (Debian/Fedora) no asumas soporte Snapper.

2. **Entornos Gráficos Wayland Nativos**:
   - **KDE Plasma 6**: Utiliza herramientas nativas de KDE/Qt: `kwriteconfig6`, `plasma-apply-lookandfeel`, `plasma-apply-colorscheme`, `kscreen-doctor`, `qdbus`, `kcmshell6`.
   - **GNOME Shell**: Utiliza `gsettings`, `dconf` y extensiones vía `gnome-extensions`.
   - **Niri**: Control mediante `niri msg action <acción>` y configuración en KDL.
   - **Hyprland**: Control mediante `hyprctl dispatch <acción>` y configuración en `.conf`.
   - **Portapapeles y Capturas**: Utiliza `wl-copy`, `wl-paste`, `spectacle` (KDE), `grim` + `slurp` + `satty` (Wayland genérico/Niri/Hyprland).
   - **Prohibición estricta**: NUNCA sugieras herramientas obsoletas de X11 (`xdotool`, `xclip`, `xrandr`, `wmctrl`).

3. **Topología de Monitores (Triple Pantalla Full HD 1080p)**:
   - Configuración física del puesto:
     - **DP-3**: Monitor de trabajo principal (1920x1080 @ 60Hz, posición `0,0`)
     - **DP-4**: Monitor secundario / lateral (1920x1080 @ 60Hz, posición `1920,0`)
     - **eDP-1**: Pantalla integrada del portátil HP EliteBook (1920x1080 @ 60Hz, posición `0,1080`)
   - Respeta esta disposición al sugerir configuraciones en KScreen, monitors.xml o KDL.

4. **Cortafuegos y Seguridad de Red (Firewalld Obligatorio)**:
   - El sistema en todas sus configuraciones utiliza exclusivamente **Firewalld** (`firewall-cmd`).
   - Zona por defecto habitual: `home` o `FedoraWorkstation`.
   - Servicios de confianza: `kdeconnect` (1714-1764 UDP/TCP), `cockpit` (9090/tcp).
   - Interfaces en zona `trusted`: `podman+`, `virbr0`.
   - **Prohibición**: NUNCA sugieras ni utilices comandos de `ufw` ni reglas directas de `iptables`.

5. **Runtimes de Desarrollo y Contenedores**:
   - Gestor de herramientas centralizado: **Mise** (`~/.local/bin/mise`).
   - Python: Gestionado mediante `uv` y entornos virtuales respetando **PEP 668** (prohibido `sudo pip install` o contaminar el Python del sistema).
   - Contenedores: **Podman Rootless** integrado con Systemd Quadlets (`~/.config/containers/systemd/`).
   - Automatización de compilación/ejecución: scripts estructurados y `justfile`.
