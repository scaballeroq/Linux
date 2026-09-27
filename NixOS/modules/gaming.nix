{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # VIDEOJUEGOS Y STEAM (modules/gaming.nix)
  # =============================================================================

  # 1. STEAM Y COMPATIBILIDAD CON VULKAN 32-BIT
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };

  # 2. GAMEMODE (OPTIMIZACIÓN DE PROCESOS EN JUEGOS)
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Modo Juego activado'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Modo Juego finalizado'";
      };
    };
  };

  # 3. HERRAMIENTAS ADICIONALES DE GAMING
  environment.systemPackages = with pkgs; [
    mangohud
    gamescope
    protonup-qt
    libnotify
  ];
}
