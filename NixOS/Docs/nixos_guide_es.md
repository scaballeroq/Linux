# ❄️ Guía de Administración y Despliegue de NixOS con Flakes

Esta guía proporciona una referencia integral sobre la gestión del sistema operativo **NixOS** mediante **Flakes** y módulos declarativos.

---

## 📂 1. Estructura de la Configuración

- **`flake.nix`**: Entrada principal del sistema que define los inputs (`nixpkgs`, `home-manager`) y los hosts configurados.
- **`hosts/`**:
  - `laptop-amd/`: Perfil para portátil AMD Ryzen (HP EliteBook 855 G7) con KVM, Podman y KDE Plasma 6.
  - `desktop-intel/`: Perfil para sobremesa Intel Core con Kodi Media Center.
- **`modules/`**: Módulos funcionales desacoplados:
  - `core.nix`: Bootloader, Kernel, ZRAM, Locale, Usuarios.
  - `desktop-kde.nix`: KDE Plasma 6 Wayland, SDDM, PipeWire, Fuentes.
  - `hardware.nix`: GPU Mesa/RADV, Bluetooth, Power Profiles, Huella dactilar, CUPS.
  - `virtualization.nix`: KVM/QEMU, Libvirtd, Virt-Manager, VirtioFS, Polkit.
  - `containers.nix`: Podman rootless, dockerCompat, registros OCI.
  - `development.nix`: nix-ld, Git, compiladores, Mise, uv, terminal Kitty.
  - `security.nix`: Firewall (KDE Connect, SSH, Cockpit), PAM.
  - `gaming.nix`: Steam, GameMode, MangoHud.
  - `flatpak.nix`: Soporte Flatpak y Flathub para aplicaciones de escritorio.

---

## 🚀 2. Flujo de Trabajo y Comandos Esenciales

| Acción | Comando con Just | Comando Nativo de NixOS |
|---|---|---|
| **Aplicar cambios en vivo** | `just switch` | `sudo nixos-rebuild switch --flake .#` |
| **Probar configuración** | `just test` | `sudo nixos-rebuild test --flake .#` |
| **Registrar para el próximo arranque** | `just boot` | `sudo nixos-rebuild boot --flake .#` |
| **Actualizar paquetes (Flake)** | `just update` | `nix flake update` |
| **Limpiar paquetes antiguos (GC)** | `just clean` | `sudo nix-collect-garbage -d && sudo nix-store --optimise` |
| **Listar generaciones del sistema** | `just generations` | `sudo nix-env --list-generations --profile /nix/var/nix/profiles/system` |
| **Revertir a generación anterior** | `just rollback` | `sudo nixos-rebuild --rollback switch` |

---

## ⚡ 3. Entorno de Desarrollo Efímero (DevShell)

Para iniciar un entorno de administración con todas las herramientas necesarias sin instalarlas permanentemente:

```bash
nix develop
```

Esto proporciona acceso inmediato a `just`, `git`, `nix-output-monitor` y `nh`.
