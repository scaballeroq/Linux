#!/usr/bin/env bash
# ==============================================================================
# virtualization.sh - Instalación y Diagnóstico de Virtualización (KVM/QEMU) en NixOS
# ==============================================================================

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"

show_help() {
    cat <<EOF
🖥️ Gestor y Diagnóstico de Virtualización KVM/QEMU - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica el estado del hipervisor KVM y componentes de virtualización.
  --status, -s        Comprueba el estado de KVM, libvirtd, virt-manager y red virtual.
  --with-windows      Información y preparación para controladores VirtIO de Windows.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  En este repositorio, la virtualización se declara de forma inmutable en:
    modules/virtualization.nix
  (virtualisation.libvirtd.enable = true, programs.virt-manager.enable = true, nested KVM, Polkit)
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE VIRTUALIZACIÓN KVM/QEMU - NIXOS"
    echo "================================================================="

    echo -n "• Soporte de Virtualización Hardware (CPU): "
    if grep -E -q '(vmx|svm)' /proc/cpuinfo; then
        local cpu_model
        cpu_model=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
        echo "✅ Detectado ($cpu_model)"
    else
        echo "❌ No detectado o deshabilitado en BIOS/UEFI."
    fi

    echo -n "• Dispositivo /dev/kvm: "
    if [ -e /dev/kvm ]; then
        if [ -w /dev/kvm ]; then
            echo "✅ Accesible con permisos de lectura/escritura"
        else
            echo "⚠️ Presente pero sin permisos de escritura (requiere grupo kvm)"
        fi
    else
        echo "❌ No encontrado."
    fi

    echo -n "• Virtualización Anidada (Nested KVM): "
    if [ -f /sys/module/kvm_amd/parameters/nested ]; then
        local nested_amd
        nested_amd=$(cat /sys/module/kvm_amd/parameters/nested 2>/dev/null || echo "0")
        if [ "$nested_amd" = "1" ] || [ "$nested_amd" = "Y" ]; then
            echo "✅ Activa en AMD (nested=1)"
        else
            echo "ℹ️ Inactiva en AMD"
        fi
    elif [ -f /sys/module/kvm_intel/parameters/nested ]; then
        local nested_intel
        nested_intel=$(cat /sys/module/kvm_intel/parameters/nested 2>/dev/null || echo "0")
        if [ "$nested_intel" = "1" ] || [ "$nested_intel" = "Y" ]; then
            echo "✅ Activa en Intel (nested=1)"
        else
            echo "ℹ️ Inactiva en Intel"
        fi
    fi

    echo -n "• Servicio Libvirtd: "
    if systemctl is-active --quiet libvirtd.service 2>/dev/null; then
        echo "✅ Activo (running)"
    else
        echo "ℹ️ En espera o inactivo"
    fi

    echo -n "• Virt-Manager: "
    if command -v virt-manager &>/dev/null; then
        echo "✅ Instalado"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Red Virtual por Defecto (virbr0): "
    if ip link show virbr0 &>/dev/null; then
        echo "✅ Activa"
    else
        echo "ℹ️ No activa en este momento"
    fi

    echo -n "• Pertenencia a grupos (kvm, libvirtd): "
    local in_kvm=0 in_lib=0
    groups "$TARGET_USER" 2>/dev/null | grep -qw "kvm" && in_kvm=1 || true
    groups "$TARGET_USER" 2>/dev/null | grep -qw "libvirtd" && in_lib=1 || true
    if [ "$in_kvm" -eq 1 ] && [ "$in_lib" -eq 1 ]; then
        echo "✅ Usuario '$TARGET_USER' pertenece a kvm y libvirtd"
    else
        echo "⚠️ Faltan grupos (kvm=$in_kvm, libvirtd=$in_lib)"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --with-windows)
        echo "💡 Para descargar drivers VirtIO para Windows en NixOS:"
        echo "   Descarga la ISO oficial de Fedora VirtIO:"
        echo "   https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso"
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        check_status
        ;;
esac
