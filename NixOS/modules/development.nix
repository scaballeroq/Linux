{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # ENTORNO DE DESARROLLO, HERRAMIENTAS Y NIX-LD (modules/development.nix)
  # =============================================================================

  # 1. NIX-LD: COMPATIBILIDAD CON BINARIOS PRECOMPILADOS DINÁMICOS
  # Permite ejecutar binarios estándar de Linux (VS Code, Google Antigravity, OpenCode, npm, uv)
  # sin necesidad de patchelf manual.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      glib
      glibc
      openssl
      libxml2
      icu
      libpulseaudio
      alsa-lib
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      xorg.libXext
      xorg.libXfixes
      xorg.libXrender
      xorg.libxcb
      xorg.libXcomposite
      xorg.libXdamage
      libGL
      nss
      nspr
      dbus
      expat
      udev
      systemd
      fontconfig
      freetype
      pango
      cairo
      atk
      gtk3
    ];
  };

  # 2. DIRENV CON CACHÉ NATIVO DE NIX (NIX-DIRENV)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # 3. CONTROL DE VERSIONES Y HERRAMIENTAS GIT
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  # 4. TERMINAL KITTY Y PROMPTS
  programs.bash.completion.enable = true;

  # 5. PAQUETES DE DESARROLLO Y LENGUAJES BASE
  environment.systemPackages = with pkgs; [
    # Control de versiones
    git
    gh
    git-delta
    lazygit

    # Compiladores y herramientas de construcción
    gcc
    clang
    gnumake
    cmake
    pkg-config
    ninja

    # Runtimes y gestores modernos
    mise
    uv
    python3
    nodejs_22
    corepack_22
    rustup

    # Terminal moderna y utilidades Rust
    kitty
    starship
    eza
    bat
    fzf
    zoxide
    ripgrep
    fd
    duf
    dust
    jq
    yq-go

    # Herramientas de red y diagnóstico
    curl
    wget
    httpie
    dnsutils
    netcat-gnu
    nmap

    # Utilidades para Nix
    nix-output-monitor
    nvd
    nh
  ];

  # 6. VARIABLES DE ENTORNO PARA DESARROLLO
  environment.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
  };
}
