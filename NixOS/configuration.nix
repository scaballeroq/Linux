{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # CONFIGURACIÓN MAESTRA DE NIXOS (configuration.nix)
  # =============================================================================
  # Este archivo importa de forma modular todos los componentes del sistema.
  # Puede utilizarse tanto con 'nixos-rebuild' tradicional como mediante Flakes.

  imports = [
    # Importar la configuración de hardware generada por el instalador
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then /etc/nixos/hardware-configuration.nix
     else ./hosts/laptop-amd/hardware-configuration.nix)

    # Módulos del sistema
    ./modules/core.nix
    ./modules/desktop-kde.nix
    ./modules/hardware.nix
    ./modules/virtualization.nix
    ./modules/containers.nix
    ./modules/development.nix
    ./modules/security.nix
    ./modules/gaming.nix
    ./modules/flatpak.nix
  ];

  networking.hostName = lib.mkDefault "nixos";
}
