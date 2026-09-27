{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # SEGURIDAD, CORTAFUEGOS Y PAM (modules/security.nix)
  # =============================================================================

  # 1. CORTAFUEGOS DE RED (NETWORKING FIREWALL)
  networking.firewall = {
    enable = true;

    # Puertos TCP permitidos:
    # 22: SSH
    # 1714-1764: KDE Connect
    # 9090: Cockpit Web Console
    allowedTCPPorts = [ 22 9090 ];
    allowedTCPPortRanges = [
      { from = 1714; to = 1764; }
    ];

    # Puertos UDP permitidos:
    # 1714-1764: KDE Connect
    # 5353: mDNS / Avahi
    allowedUDPPorts = [ 5353 ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; }
    ];

    # Interfaces de confianza (KVM / Libvirt y Podman)
    trustedInterfaces = [
      "virbr0"
      "virbr+"
      "podman+"
      "docker+"
      "vnet+"
    ];

    checkReversePath = "loose";
  };

  # 2. POLKIT Y PRIVILEGIOS DE SISTEMA
  security.polkit.enable = true;

  # 3. ENDURECIMIENTO DE SUDO
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    execWheelOnly = true;
    extraConfig = ''
      Defaults env_keep += "EDITOR VISUAL"
    '';
  };

  # 4. CONFIGURACIÓN PAM PARA HUELLA DACTILAR (FPRINTD)
  # Se permite fprintd en sudo y bloqueo de pantalla (kscreenlocker),
  # pero se desactiva en SDDM para evitar bloqueos y retardos al iniciar sesión.
  security.pam.services = {
    sddm.fprintAuth = false;
    login.fprintAuth = true;
    sudo.fprintAuth = true;
  };
}
