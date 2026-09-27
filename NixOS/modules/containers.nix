{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # CONTENEDORES Y PODMAN ROOTLESS (modules/containers.nix)
  # =============================================================================

  # 1. SOPORTE DE CONTENEDORES Y REGISTRIES
  virtualisation.containers = {
    enable = true;
    registries.search = [
      "docker.io"
      "quay.io"
      "ghcr.io"
      "registry.fedoraproject.org"
    ];
  };

  # 2. MOTOR PODMAN ROOTLESS Y COMPATIBILIDAD CON DOCKER
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # 3. PAQUETES DEL ECOSISTEMA DE CONTENEDORES
  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    podman-tui
    buildah
    skopeo
    dive
    fuse-overlayfs
  ];

  # 4. VARIABLE DE ENTORNO DOCKER_HOST PARA ROOTLESS
  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" ] && [ -e "/run/user/$UID/podman/podman.sock" ]; then
      export DOCKER_HOST="unix:///run/user/$UID/podman/podman.sock"
    fi
  '';
}
