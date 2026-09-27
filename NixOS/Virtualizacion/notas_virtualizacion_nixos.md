# 🖥️ Guía de Virtualización KVM / QEMU en NixOS

Esta guía documenta la arquitectura de virtualización implementada en **NixOS** mediante configuración declarativa (`modules/virtualization.nix`), optimizada para **KDE Plasma 6 (Wayland)**.

---

## 🏗️ 1. Arquitectura Declarativa en NixOS

En NixOS, el soporte completo para KVM/QEMU, Libvirt y Virt-Manager se declara en `modules/virtualization.nix`:

```nix
# Módulos del kernel y virtualización anidada
boot.kernelModules = [ "kvm-amd" "kvm-intel" "vhost_net" "vhost_vsock" "tun" ];
boot.extraModprobeConfig = ''
  options kvm_amd nested=1
  options kvm_intel nested=1
'';

# Hipervisor Libvirt con soporte UEFI (OVMF) y emulador TPM (swtpm)
virtualisation.libvirtd = {
  enable = true;
  qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
    swtpm.enable = true;
    ovmf.enable = true;
  };
};

# Interfaz gráfica
programs.virt-manager.enable = true;

# Acceso sin contraseña para usuarios del grupo 'libvirtd'
security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirtd")) {
      return polkit.Result.YES;
    }
  });
'';
```

---

## ⚡ 2. Optimizaciones Recomendadas para Máquinas Virtuales

1. **Tipo de Disco**: VirtIO SCSI o VirtIO Block (`vda` en lugar de SATA/IDE).
2. **Controlador de Red**: VirtIO (`virtio-net`) con aceleración `vhost_net`.
3. **Controlador Gráfico en Wayland**: `virtio-gpu` con aceleración 3D habilitada.
4. **Compartición de Carpetas Host <-> Guest**: Usar **VirtioFS** (`virtiofsd`) para máximo rendimiento.
5. **Deduplicación de Memoria**: KSM (Kernel Samepage Merging) optimiza el uso de RAM cuando se ejecutan varias VMs.
