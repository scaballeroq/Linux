{ config, pkgs, lib, ... }:

{
  # =============================================================================
  # VIRTUALIZACIÓN (KVM/QEMU, LIBVIRT Y VIRT-MANAGER) (modules/virtualization.nix)
  # =============================================================================

  # 1. MÓDULOS DE KERNEL Y VIRTUALIZACIÓN ANIDADA (NESTED KVM)
  boot.kernelModules = [ "kvm-amd" "kvm-intel" "vhost_net" "vhost_vsock" "tun" ];
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
    options kvm_intel nested=1
  '';

  # 2. SERVICIO LIBVIRTD CON SOPORTE MODULAR Y TPM EMULADO
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
      vhostUserPackages = [ pkgs.virtiofsd ];
    };
  };

  # 3. INTERFAZ GRÁFICA VIRT-MANAGER
  programs.virt-manager.enable = true;

  # 4. REGLA POLKIT PARA ACCESO SIN CONTRASEÑA A MIEMBROS DE LIBVIRTD
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  # 5. PAQUETES ADICIONALES DE VIRTUALIZACIÓN
  environment.systemPackages = with pkgs; [
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtiofsd
    bridge-utils
    dnsmasq
    iptables
  ];

  # 6. VARIABLE DE ENTORNO LIBVIRT
  environment.sessionVariables = {
    LIBVIRT_DEFAULT_URI = "qemu:///system";
  };
}
