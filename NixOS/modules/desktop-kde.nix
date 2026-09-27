{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # ENTORNO DE ESCRITORIO KDE PLASMA 6 WAYLAND (modules/desktop-kde.nix)
  # =============================================================================

  # 1. SERVICIOS DE VENTANAS Y ESCRITORIO
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  # 2. GESTOR DE SESIÓN (SDDM WAYLAND)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.defaultSession = "plasma";

  # 3. SISTEMA DE AUDIO PIPEWIRE + WIREPLUMBER
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # 4. PORTALES XDG WAYLAND
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  # 5. INTEGRACIÓN KDECONNECT
  programs.kdeconnect.enable = true;

  # 6. FUENTES DEL SISTEMA (NERD FONTS & SISTEMA)
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.cascadia-code
      nerd-fonts.meslo-lg
      nerd-fonts.hack
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      corefonts
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "Noto Sans Mono" ];
        sansSerif = [ "Noto Sans" "DejaVu Sans" ];
        serif = [ "Noto Serif" "DejaVu Serif" ];
      };
    };
  };

  # 7. APLICACIONES Y UTILIDADES DE KDE PLASMA 6
  environment.systemPackages = with pkgs; [
    # KDE Gear Apps
    kdePackages.dolphin
    kdePackages.kate
    kdePackages.kwrite
    kdePackages.spectacle
    kdePackages.ark
    kdePackages.gwenview
    kdePackages.okular
    kdePackages.kcalc
    kdePackages.kinfocenter
    kdePackages.plasma-systemmonitor
    kdePackages.partitionmanager
    kdePackages.kio-extras
    kdePackages.kio-gdrive
    kdePackages.ffmpegthumbnailer

    # Portapapeles y Utilidades Wayland
    wl-clipboard
    wtype
    wayland-utils

    # Temas e Iconos
    papirus-icon-theme
    kdePackages.breeze-icons
    kdePackages.breeze-gtk
  ];

  # 8. VARIABLES DE ENTORNO GRÁFICAS
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    GDK_BACKEND = "wayland,x11,*";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
}
