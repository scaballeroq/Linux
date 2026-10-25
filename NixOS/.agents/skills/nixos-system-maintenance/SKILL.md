---
name: nixos-system-maintenance
description: >-
  Use this skill when rebuilding NixOS systems with Flakes (nixos-rebuild), updating flake inputs, running garbage collection, checking generation history, or inspecting hardware telemetry.
---

# NixOS System Maintenance & Flakes Skill

Procedimientos y operaciones declarativas para NixOS en HP ProBook 455 G10.

## 1. Reconstrucción y Flakes
```bash
# Reconstruir y activar el sistema con el perfil laptop-amd
sudo nixos-rebuild switch --flake /home/caballero/Workspace/Repositorios/Linux/NixOS#laptop-amd

# Probar la configuración sin persistir en el bootloader
sudo nixos-rebuild test --flake /home/caballero/Workspace/Repositorios/Linux/NixOS#laptop-amd

# Actualizar inputs del flake
nix flake update --flake /home/caballero/Workspace/Repositorios/Linux/NixOS

# Comprobar estado de los flakes
nix flake check /home/caballero/Workspace/Repositorios/Linux/NixOS
```

## 2. Limpieza de Generaciones y Recolección de Basura
```bash
# Limpiar generaciones antiguas de usuario y root
nix-collect-garbage -d
sudo nix-collect-garbage -d

# Optimizar el almacén /nix/store deduplicando hardlinks
nix-store --optimise
```

## 3. Telemetría y Salud
```bash
df -h /nix/store /boot
free -h
sensors
```
