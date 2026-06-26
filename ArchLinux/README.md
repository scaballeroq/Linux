# Arch Linux + GNOME Configuration Scripts

Colección de scripts de configuración modular para **Arch Linux** con **GNOME**.

## Estructura

| Carpeta | Propósito |
|---------|-----------|
| `Setup/` | Post-install, seguridad, shell, terminal, fuentes, Cockpit, GNOME |
| `Bash.Setup/` | Aliases, funciones, entorno, historial, opciones de shell |
| `Podman/` | Configuración de Podman y contenedores de desarrollo |
| `Virtualizacion/` | KVM/QEMU/Libvirt virtualization stack |
| `IDE/` | Instalación de VS Code, Neovim, Antigravity |
| `Git/` | Git, Delta, Lazygit, GitHub CLI |
| `AI/` | Herramientas de IA (Antigravity CLI, Gemini) |
| `Apps/` | Aplicaciones adicionales (Meld) |
| `ProgrammingLanguages/` | Mise, Node.js, Python, Rust, .NET, Angular |

## Uso

### Post-Install

```bash
cd Setup/
chmod +x post-install.sh
./post-install.sh
```

### Setup Modular

```bash
cd Setup/
chmod +x *.sh
./shell.sh       # Utilidades de terminal
./fonts.sh       # Nerd Fonts
./terminal.sh    # Kitty Terminal
./fastfetch.sh   # Fastfetch config
./seguridad.sh   # Hardening
./gnome-settings.sh  # Personalización GNOME
./cockpit.sh     # Cockpit Web Admin
./yt-dlp-setup.sh    # yt-dlp + ffmpeg
```

### Bash Setup

Crear enlaces simbólicos en `~/.bashrc.d/`:

```bash
mkdir -p ~/.bashrc.d
ln -s $(pwd)/Bash.Setup/*.sh ~/.bashrc.d/
```

Añadir en `~/.bashrc`:

```bash
if [ -d ~/.bashrc.d ]; then
    for f in ~/.bashrc.d/*.sh; do
        [ -r "$f" ] && source "$f"
    done
    unset f
fi
```

### Podman

```bash
cd Podman/
chmod +x *.sh
./podman.sh           # Setup principal
./podman-redis.sh     # Redis container
./podman-postgres.sh  # PostgreSQL container
```

### Virtualización

```bash
cd Virtualizacion/
chmod +x virtualization.sh
./virtualization.sh
```

### IDE y Lenguajes

```bash
cd IDE/
chmod +x *.sh
./vscode.sh
./neovim.sh

cd ../ProgrammingLanguages/
chmod +x *.sh
./mise.sh
./nodejs.sh
./python.sh
./rust.sh
```

## Diferencias con Fedora

| Fedora | Arch Linux |
|--------|------------|
| `dnf5 install` | `pacman -S` |
| `@development-tools` | `base-devel` |
| `kernel-devel` | `linux-headers` |
| COPR repos | AUR (yay/paru) |
| RPM Fusion | No necesario (todo en repos/AUR) |
| `mesa-va-drivers-freeworld` | `libva-mesa-driver` |
| `fd-find` | `fd` |
| `git-delta` | `delta` |
| `wl-copy` | `wl-clipboard` |
| KDE settings | GNOME settings (gsettings) |
| Modular libvirt sockets | `libvirtd.service` |

## Licencia

GPL-3.0
