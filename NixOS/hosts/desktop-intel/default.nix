{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # PERFIL DE HOST: SOBREMESA INTEL CORE / MEDIA CENTER
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

  networking.hostName = "nixos-desktop";

  # 1. OPTIMIZACIONES GRÁFICAS PARA INTEL HD GRAPHICS / HASWELL
  hardware.cpu.intel.updateMicrocode = true;
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
  };

  # 2. CENTRO MULTIMEDIA (KODI Y COMPLEMENTOS)
  environment.systemPackages = with pkgs; [
    kodi
    kodiPackages.inputstream-adaptive
    kodiPackages.inputstream-rtmp
    kodiPackages.pvr-iptvsimple
  ];
}
