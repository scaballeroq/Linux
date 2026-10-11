{ config, pkgs, ... }:

{
  # =============================================================================
  # CONFIGURACIÓN HOME MANAGER (home/home.nix)
  # =============================================================================

  home.username = "caballero";
  home.homeDirectory = "/home/caballero";
  home.stateVersion = "24.11";

  # 1. GESTIÓN DE HOME-MANAGER
  programs.home-manager.enable = true;

  # 2. GIT
  programs.git = {
    enable = true;
    userName = "Tu Nombre";
    userEmail = "tu_email@ejemplo.com";
    extraConfig = {
      init.defaultBranch = "develop";
      pull.rebase = false;
      core.editor = "nano";
    };
  };

  # 3. STARSHIP PROMPT
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # 4. TERMINAL KITTY
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      background_opacity = "0.92";
      background_blur = "30";
      enable_audio_bell = "no";
      window_padding_width = "8";
      cursor_shape = "beam";
      cursor_blink_interval = "0.5";
      confirm_os_window_close = 0;
    };
  };

  # 5. INTEGRACIÓN BASH
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      # Cargar modularmente configuración desde ~/.bashrc.d si existe
      if [ -d "$HOME/.bashrc.d" ]; then
        for file in "$HOME"/.bashrc.d/*.sh; do
          [ -r "$file" ] && source "$file"
        done
      fi
    '';
  };
}
