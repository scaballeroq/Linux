{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # PERFIL DE HOST: PORTÁTIL AMD RYZEN (HP EliteBook 855 G7)
  # =============================================================================

  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop-kde.nix
    ../../modules/hardware.nix
    ../../modules/virtualization.nix
    ../../modules/containers.nix
    ../../modules/development.nix
    ../../modules/security.nix
    ../../modules/gaming.nix
    ../../modules/flatpak.nix
  ];

  networking.hostName = "nixos-laptop";

  # 1. OPTIMIZACIONES ESPECÍFICAS PARA AMD RYZEN & RADEON GRAPHICS
  hardware.cpu.amd.updateMicrocode = true;
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libvulkan_radeon
      vaapiVdpau
    ];
  };

  # 2. GESTIÓN DE ENERGÍA Y BATERÍA AVANZADA PARA PORTÁTIL
  services.power-profiles-daemon.enable = true;

  # 3. CONTROL DE TOUCHPAD EN WAYLAND
  # Configurado vía KWin en Plasma 6
}
