{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # INTEGRACIÓN FLATPAK & FLATHUB (modules/flatpak.nix)
  # =============================================================================

  # 1. SERVICIO FLATPAK
  services.flatpak.enable = true;

  # 2. INTEGRACIÓN CON KDE DISCOVER
  environment.systemPackages = with pkgs; [
    flatpak
    kdePackages.discover
  ];

  # 3. REGLAS XDG PARA RUTAS FLATPAK
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };
}
