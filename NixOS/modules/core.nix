{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # CONFIGURACIÓN BÁSICA DEL SISTEMA NIXOS (modules/core.nix)
  # =============================================================================

  # 1. GESTOR DE ARRANQUE (BOOTLOADER)
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.loader.timeout = lib.mkDefault 5;

  # 2. KERNEL LINUX Y MÓDULOS DEL SISTEMA
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 8192;
    "fs.file-max" = 2097152;
  };

  # 3. COMPRESIÓN DE MEMORIA ZRAM
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # 4. POLÍTICAS DE NIX Y GESTIÓN DE PAQUETES
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      trusted-users = [ "root" "caballero" "@wheel" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # 5. ZONA HORARIA Y LOCALIZACIÓN (ESPAÑA)
  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "es_ES.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };
  console.keyMap = "es";

  # 6. GESTIÓN DE RED
  networking.networkmanager.enable = true;

  # 7. USUARIO PRINCIPAL (caballero)
  users.users.caballero = {
    isNormalUser = true;
    description = "Usuario Principal";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "kvm"
      "libvirtd"
      "input"
      "render"
      "disk"
    ];
    shell = pkgs.bash;
  };

  # 8. PAQUETES BASE DEL SISTEMA
  environment.systemPackages = with pkgs; [
    curl
    wget
    git
    vim
    nano
    htop
    btop
    fastfetch
    just
    pciutils
    usbutils
    lsof
    which
    tree
    zip
    unzip
    p7zip
    bzip2
    xz
    zstd
    rsync
    efibootmgr
  ];

  system.stateVersion = "24.11";
}
