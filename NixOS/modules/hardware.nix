{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # HARDWARE, DRIVERS Y PERIFÉRICOS (modules/hardware.nix)
  # =============================================================================

  # 1. ACELERACIÓN GRÁFICA Y MESA (OPENGL / VULKAN / VA-API)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva
      libva-utils
      vulkan-tools
      vulkan-loader
      libvdpau-va-gl
    ];
  };

  # 2. FIRMWARE REDISTRIBUIBLE Y ACTUALIZACIONES DE MICROCÓDIGO
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # 3. BLUETOOTH (OPTIMIZADO PARA BLUEZ Y KDEVIL EN PLASMA 6)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
      Policy = {
        AutoEnable = "true";
      };
    };
  };

  # 4. GESTIÓN DE ENERGÍA Y PERFILES PARA PORTÁTIL (power-profiles-daemon)
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # 5. SENSOR DE HUELLA DACTILAR (fprintd + PAM)
  services.fprintd = {
    enable = true;
    tod.enable = false;
  };

  # 6. SERVICIO DE IMPRESIÓN (CUPS + HPLIP) Y DESCUBRIMIENTO AVAHI/MDNS
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      hplip
      hplipWithPlugin
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # 7. CIERRE DE TAPA INTELIGENTE (LOGIND)
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    lidSwitchDocked = "ignore";
    extraConfig = ''
      HandlePowerKey=poweroff
      HandleLidSwitchDocked=ignore
      HandleLidSwitchExternalPower=lock
    '';
  };

  # 8. PAQUETES DE DIAGNÓSTICO DE HARDWARE
  environment.systemPackages = with pkgs; [
    inxi
    glxinfo
    vulkan-tools
    clinfo
    radeontop
    powertop
    brightnessctl
    usbutils
    pciutils
  ];
}
