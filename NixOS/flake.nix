{
  description = "❄️ NixOS Environment Configuration (KDE Plasma 6 Wayland, Flakes & System Modules) - AMD Ryzen & Intel Core";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      # Configuraciones de Sistema NixOS
      nixosConfigurations = {
        # Portátil de desarrollo (AMD Ryzen + KDE Plasma 6 + KVM + Podman)
        "laptop-amd" = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/laptop-amd/default.nix
          ];
        };

        # Sobremesa Centro Multimedia (Intel Core / Haswell + Kodi)
        "desktop-intel" = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/desktop-intel/default.nix
          ];
        };

        # Alias por defecto
        default = self.nixosConfigurations."laptop-amd";
      };

      # Devshell para desarrollo y administración del flake
      devShells.${system}.default = pkgs.mkShell {
        name = "nixos-admin-shell";
        packages = with pkgs; [
          just
          git
          nix-output-monitor
          nvd
          nh
          nixpkgs-fmt
        ];
        shellHook = ''
          echo "❄️ Entorno de administración de NixOS cargado."
          echo "Comandos disponibles:"
          echo "  just switch         -> Aplica la configuración en vivo"
          echo "  just test           -> Prueba la configuración sin agregarla al bootloader"
          echo "  just update         -> Actualiza inputs de Nix flake"
          echo "  just clean          -> Limpia generaciones antiguas y optimiza /nix/store"
        '';
      };

      # Formateador oficial
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
