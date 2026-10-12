---
name: linux-multi-distro-package-management
description: >-
  Use this skill when comparing, diagnosing, installing, updating, or cleaning packages across different Linux distributions (APT for Debian/Ubuntu, DNF5 for Fedora, Pacman/Paru for Arch/CachyOS/Manjaro, Zypper for openSUSE, Nix for NixOS, and Flatpak).
---

# Multi-Distribution Linux Package Management Skill

Esta skill proporciona las operaciones de mantenimiento, actualización, limpieza y diagnóstico para cada familia de gestor de paquetes representada en el monorepo Linux.

---

## 1. Familia Debian / Ubuntu / Soplos (APT & dpkg)

Aplica a: `Debian`, `DebianTesting`, `KDEDebian`, `KDEDebianTesting`, `Kubuntu`, `Ubuntu`, `SoplosLinuxTyson`.

```bash
# 1. Actualizar repositorios e índices
sudo apt update

# 2. Ver actualizaciones disponibles
apt list --upgradable

# 3. Actualización estándar segura
sudo apt upgrade --without-new-pkgs

# 4. Actualización completa resolviendo transiciones (requerido en Testing)
sudo apt full-upgrade

# 5. Limpieza de huérfanos y paquetes temporales
sudo apt autoremove --purge -y
sudo apt autoclean

# 6. Diagnóstico y reparación de dependencias rotas
sudo dpkg --configure -a
sudo apt --fix-broken install
```

---

## 2. Familia Fedora / Red Hat (DNF5)

Aplica a: `Fedora-KDE`, `Fedora-Workstation`.

```bash
# 1. Comprobar actualizaciones refrescando metadatos
sudo dnf5 check-upgrade --refresh

# 2. Actualización completa del sistema
sudo dnf5 upgrade --refresh -y

# 3. Limpieza de paquetes huérfanos y dependencias residuales
sudo dnf5 autoremove -y

# 4. Limpieza de caché de metadatos y paquetes descargados
sudo dnf5 clean all

# 5. Buscar paquete o información de proveedor
dnf5 search <termino>
dnf5 info <paquete>
```

---

## 3. Familia Arch Linux / CachyOS / Manjaro (Pacman & AUR)

Aplica a: `ArchLinux`, `ArchLinux-Niri-DMS`, `CachyOS`, `CachyOS-Niri-DMS`, `CachyOS_Niri_Noctalia`, `Manjaro`, `Omarchy`.

```bash
# 1. Actualización completa del sistema y bases de datos oficiales
sudo pacman -Syu

# 2. Actualización de paquetes oficiales y AUR (vía paru/yay sin sudo)
paru -Syu --noconfirm 2>/dev/null || yay -Syu --noconfirm

# 3. Limpiar paquetes huérfanos no requeridos
sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || true

# 4. Limpieza de caché de paquetes (manteniendo últimas 2 versiones)
sudo paccache -r 2>/dev/null || sudo pacman -Sc --noconfirm

# 5. Consultar paquetes modificados o verificar integridad
pacman -Qk
```

---

## 4. Familia openSUSE Tumbleweed (Zypper)

Aplica a: `OpenSuseTumbleweed`.

```bash
# 1. Actualización completa rolling release (SIEMPRE con dup)
sudo zypper dup

# 2. Refrescar repositorios manualmente
sudo zypper refresh

# 3. Limpieza de paquetes huérfanos
sudo zypper packages --orphaned
sudo zypper rm -u $(zypper packages --orphaned | awk '{print $5}' | grep -v "S |" | grep -v "^$") 2>/dev/null || true

# 4. Limpiar caché de Zypper
sudo zypper clean --all
```

---

## 5. Familia NixOS (Nix Flakes)

Aplica a: `NixOS`.

```bash
# 1. Reconstruir y activar el sistema desde el flake local
sudo nixos-rebuild switch --flake /home/caballero/Workspace/Repositorios/Linux/NixOS#laptop-amd

# 2. Actualizar las entradas del flake (nixpkgs, home-manager)
nix flake update --flake /home/caballero/Workspace/Repositorios/Linux/NixOS

# 3. Recolector de basura (liberar espacio de generaciones antiguas)
nix-collect-garbage -d
sudo nix-collect-garbage -d
```

---

## 6. Aplicaciones Universales Flatpak (Flathub)

Aplica universalmente a todas las distribuciones:

```bash
# 1. Actualizar todas las aplicaciones y runtimes
flatpak update -y

# 2. Desinstalar runtimes huérfanos sin aplicaciones asociadas
flatpak uninstall --unused -y

# 3. Listar aplicaciones instaladas
flatpak list --app
```
