#!/usr/bin/env bash
# ==============================================================================
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU)
# Sistema: Ubuntu Linux (24.04 / 24.10 / 26.10) | Escritorio: GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3 / Barcelo-R, 8C/16T)
# GPU: AMD Radeon Graphics (Vega 8 / 3D VirGL / VA-API) | Memoria: 32 GB RAM DDR4
# Almacenamiento: SSD NVMe Kioxia 512 GB (Btrfs NoCoW / Ext4) | Firewall: Firewalld
# ==============================================================================

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
[ -z "$TARGET_HOME" ] && TARGET_HOME="$HOME"

WITH_WINDOWS=false
STATUS_ONLY=false
SETUP_BRIDGE=false

TUNED_ADM_BIN=$(command -v tuned-adm 2>/dev/null || echo "/usr/sbin/tuned-adm")

# ---------------------------------------------------------------------------
# Funciones de ayuda y utilidades
# ---------------------------------------------------------------------------
show_help() {
    cat <<EOF
Uso: $0 [OPCIONES]

Script de aprovisionamiento y optimización de virtualización KVM/QEMU en Ubuntu Linux.
Optimizado para portátiles HP ProBook 455 G10 (AMD Ryzen 7 7730U Zen 3 + Radeon Vega 8).
Proporciona dos vías de gestión completas para desarrollo y producción:
  1. Cockpit Web Console (módulo cockpit-machines en https://localhost:9090)
  2. Virt-Manager (interfaz gráfica de escritorio nativa para GNOME Shell Wayland)

OPCIONES:
  --status, -s, --check Verifica el estado de KVM, Cockpit, libvirt, módulos del kernel,
                        AMD AVIC, VirGL, Polkit, Btrfs NoCoW, Firewalld, KSM y red.
  --with-windows        Descarga los controladores VirtIO para Windows (virtio-win.iso).
  --setup-bridge        Crea un puente de red br0 enlazado a la interfaz Ethernet activa
                        (Opcional; por defecto se mantiene la red NAT virbr0 segura para portátiles).
  -h, --help            Muestra esta ayuda y recomendaciones para VMs Linux/Windows.

CARACTERÍSTICAS Y OPTIMIZACIONES:
  - Doble interfaz de gestión: Cockpit Machines (Web) y Virt-Manager (GNOME Wayland).
  - Aceleración CPU AMD Zen 3: AVIC (Advanced Virtual Interrupt Controller) y Nested KVM.
  - Aceleración Gráfica 3D VirGL: Acceso directo a /dev/dri/renderD128 para usuario y libvirt-qemu.
  - Redirección SPICE USB: Integración completa de spice-client-gtk y gir1.2-spiceclientgtk.
  - Red Virtual NAT limpia: dnsmasq-base integrado en libvirt sin conflicto con systemd-resolved.
  - Firewalld nativo: virbr0/virbr+ en zona 'trusted', Cockpit en zona activa con masquerade.
  - Almacenamiento NVMe Btrfs NoCoW (+C): Elimina fragmentación de imágenes en /var/lib/libvirt/images.
  - VirtioFS ultrarrápido: Compartición de carpetas host-guest mediante demonio virtiofsd.
  - Deduplicación KSM calibrada: sleep_millisecs=2000 para balancear ahorro de RAM y batería.
  - Regla Polkit sin contraseñas para miembros del grupo 'libvirt'.
  - Conexión por defecto unificada con LIBVIRT_DEFAULT_URI="qemu:///system".

EJEMPLO DE CREACIÓN DE VM LINUX CON ACELERACIÓN 3D (virt-install):
  virt-install \\
    --name ubuntu-test \\
    --memory 4096 \\
    --vcpus 4 \\
    --cpu host-passthrough \\
    --disk size=25,format=qcow2,bus=virtio \\
    --network network=default,model=virtio \\
    --graphics spice,gl=on,listen=none \\
    --video virtio,accel3d=on \\
    --boot uefi \\
    --os-variant ubuntu24.04
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DEL ENTORNO DE VIRTUALIZACIÓN (UBUNTU GNOME)"
    echo "================================================================="

    echo -n "• Entorno de Escritorio Host: "
    local desktop="${XDG_CURRENT_DESKTOP:-GNOME}"
    local session_type="${XDG_SESSION_TYPE:-wayland}"
    echo "✅ $desktop ($session_type)"

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
            echo "⚠️ Presente pero sin permisos de escritura (requiere pertenecer al grupo kvm)"
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
            echo "ℹ️ Inactiva en AMD (parámetro nested=$nested_amd)"
        fi
    elif [ -f /sys/module/kvm_intel/parameters/nested ]; then
        local nested_intel
        nested_intel=$(cat /sys/module/kvm_intel/parameters/nested 2>/dev/null || echo "0")
        if [ "$nested_intel" = "1" ] || [ "$nested_intel" = "Y" ]; then
            echo "✅ Activa en Intel (nested=1)"
        else
            echo "ℹ️ Inactiva en Intel (parámetro nested=$nested_intel)"
        fi
    else
        echo "ℹ️ Módulos KVM no cargados en este momento"
    fi

    if [ -f /sys/module/kvm_amd/parameters/avic ]; then
        echo -n "• Aceleración de Interrupciones AMD AVIC: "
        local avic_amd
        avic_amd=$(cat /sys/module/kvm_amd/parameters/avic 2>/dev/null || echo "N")
        if [ "$avic_amd" = "1" ] || [ "$avic_amd" = "Y" ]; then
            echo "✅ Activa en AMD (baja latencia para VMs)"
        else
            echo "ℹ️ Inactiva (parámetro avic=$avic_amd; se activará con kvm_amd.conf)"
        fi
    fi

    echo -n "• Módulos de aceleración de red/kernel: "
    local modules=("vhost_net" "vhost_vsock" "tun")
    local loaded=()
    for mod in "${modules[@]}"; do
        if lsmod | grep -q "^$mod "; then
            loaded+=("$mod")
        fi
    done
    echo "${loaded[*]:-Ninguno cargado}"

    echo "• Estado de servicios de Libvirt:"
    local libvirt_state="inactivo"
    if systemctl is-active --quiet libvirtd 2>/dev/null; then
        libvirt_state="activo (libvirtd)"
    elif systemctl is-active --quiet virtqemud 2>/dev/null; then
        libvirt_state="activo (virtqemud modular)"
    fi
    echo "  - Servicio libvirt: $libvirt_state"

    echo "• Consola Web Cockpit & Módulo de Máquinas Virtuales:"
    local cockpit_socket_state="inactivo"
    if systemctl is-active --quiet cockpit.socket 2>/dev/null; then
        cockpit_socket_state="activo"
    fi
    echo "  - Servicio cockpit.socket: $cockpit_socket_state (Puerto 9090)"

    echo -n "  - Módulo cockpit-machines: "
    if [ -d "/usr/share/cockpit/machines" ] || dpkg -s cockpit-machines >/dev/null 2>&1; then
        echo "✅ Instalado y disponible (/usr/share/cockpit/machines)"
    else
        echo "❌ No instalado"
    fi

    if [ "$cockpit_socket_state" = "activo" ]; then
        echo "  - Acceso Web Cockpit: 🌐 https://localhost:9090"
    fi

    echo -n "• Aceleración Gráfica 3D VirGL (/dev/dri/renderD128): "
    if [ -e /dev/dri/renderD128 ]; then
        echo "✅ Disponible (AMD Radeon Vega 8 - Nodo DRM render)"
    else
        echo "ℹ️ No disponible"
    fi

    if id libvirt-qemu >/dev/null 2>&1; then
        echo -n "• Permisos de GPU del daemon QEMU (libvirt-qemu): "
        local qemu_groups
        qemu_groups=$(id -Gn libvirt-qemu 2>/dev/null || true)
        if [[ "$qemu_groups" =~ (^|[[:space:]])render($|[[:space:]]) ]] && [[ "$qemu_groups" =~ (^|[[:space:]])kvm($|[[:space:]]) ]]; then
            echo "✅ render, kvm (aceleración 3D habilitada)"
        else
            echo "⚠️ Incompleto ($qemu_groups) - requiere pertenencia a 'render' y 'kvm'"
        fi
    fi

    echo -n "• Estado de la red virtual 'default': "
    if ip link show virbr0 >/dev/null 2>&1; then
        echo "✅ Activa (interfaz virbr0 levantada)"
    elif command -v virsh >/dev/null 2>&1 && timeout 2 virsh -c qemu:///system net-info default >/dev/null 2>&1; then
        echo "✅ Activa (registrada en libvirt)"
    else
        echo "⚠️ No configurada aún (se creará automáticamente)"
    fi

    echo -n "• Integración con Firewalld: "
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        local fw_zone
        fw_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        local virbr_trusted="no"
        if firewall-cmd --zone=trusted --list-interfaces 2>/dev/null | grep -q 'virbr0'; then
            virbr_trusted="sí"
        fi
        echo "✅ Activo (Zona por defecto: $fw_zone | virbr0 en trusted: $virbr_trusted)"
    else
        echo "ℹ️ Firewalld no activo o no disponible"
    fi

    echo -n "• Deduplicación de Memoria (KSM): "
    if [ -f /sys/kernel/mm/ksm/run ]; then
        local ksm_val
        ksm_val=$(cat /sys/kernel/mm/ksm/run 2>/dev/null || echo "0")
        if [ "$ksm_val" = "1" ]; then
            local ksm_sleep
            ksm_sleep=$(cat /sys/kernel/mm/ksm/sleep_millisecs 2>/dev/null || echo "2000")
            echo "✅ Activa (sleep_millisecs=${ksm_sleep}ms, optimizada para batería)"
        else
            echo "ℹ️ Inactiva (/sys/kernel/mm/ksm/run=$ksm_val)"
        fi
    else
        echo "ℹ️ No soportado por el kernel"
    fi

    echo -n "• Almacenamiento VM (/var/lib/libvirt/images): "
    if [ -d /var/lib/libvirt/images ]; then
        local fs_type
        fs_type=$(stat -f -c %T /var/lib/libvirt/images 2>/dev/null || true)
        if [ "$fs_type" = "btrfs" ]; then
            if lsattr -d /var/lib/libvirt/images 2>/dev/null | grep -q 'C'; then
                echo "✅ Btrfs NoCoW (+C activo, optimizado para IOPS NVMe)"
            else
                echo "⚠️ Btrfs con Copy-on-Write activo (se recomienda aplicar chattr +C)"
            fi
        else
            echo "✅ Presente ($fs_type)"
        fi
    else
        echo "ℹ️ Pendiente de creación"
    fi

    echo -n "• Regla Polkit sin contraseñas para libvirt: "
    if [ -f /etc/polkit-1/rules.d/50-libvirt.rules ]; then
        echo "✅ Presente (/etc/polkit-1/rules.d/50-libvirt.rules)"
    else
        echo "⚠️ No configurada"
    fi

    echo -n "• Pertenencia a grupos requeridos ($TARGET_USER): "
    local user_groups
    user_groups=$(id -Gn "$TARGET_USER" 2>/dev/null || true)
    local has_libvirt=false
    local has_kvm=false
    local has_render=false
    [[ "$user_groups" =~ (^|[[:space:]])libvirt($|[[:space:]]) ]] && has_libvirt=true
    [[ "$user_groups" =~ (^|[[:space:]])kvm($|[[:space:]]) ]] && has_kvm=true
    [[ "$user_groups" =~ (^|[[:space:]])render($|[[:space:]]) ]] && has_render=true

    if [ "$has_libvirt" = true ] && [ "$has_kvm" = true ] && [ "$has_render" = true ]; then
        echo "✅ libvirt, kvm, render"
    else
        echo "⚠️ Incompleto ($user_groups)."
    fi

    echo "================================================================="
}

for arg in "$@"; do
    case "$arg" in
        --status|-s|--check)
            STATUS_ONLY=true
            ;;
        --with-windows)
            WITH_WINDOWS=true
            ;;
        --setup-bridge)
            SETUP_BRIDGE=true
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Opción desconocida: $arg"
            show_help
            exit 1
            ;;
    esac
done

if [ "$STATUS_ONLY" = true ]; then
    check_status
    exit 0
fi

echo "🚀 Iniciando configuración y optimización de virtualización KVM/QEMU en Ubuntu Linux..."
echo "🎯 Integrando Cockpit Machines (Web) y Virt-Manager (GNOME Shell Wayland)..."

# ---------------------------------------------------------------------------
# 1. Instalación de paquetes vía APT
# ---------------------------------------------------------------------------
echo "ℹ️ [1/13] Verificando e instalando paquetes oficiales para Ubuntu..."
sudo apt-get update -qq

PKGS_TO_INSTALL=(
    # Hipervisor base y emulación
    qemu-system-x86
    qemu-utils
    # Daemons de libvirt y herramientas CLI
    libvirt-daemon-system
    libvirt-clients
    # Interfaces gráficas y gestión
    virt-manager
    virt-viewer
    virtinst
    virt-top
    # Consola Web Cockpit y gestión de VMs
    cockpit
    cockpit-machines
    cockpit-bridge
    # Firmware UEFI y emulación TPM 2.0 (Windows 11 / Linux Secure Boot)
    ovmf
    swtpm
    swtpm-tools
    # Herramientas de inspección de discos y metadatos de SO
    libguestfs-tools
    guestfs-tools
    libosinfo-bin
    # Compartición ultrarrápida host-guest mediante virtio-fs
    virtiofsd
    # Integración SPICE y redirección USB para Virt-Manager
    spice-vdagent
    spice-client-gtk
    gir1.2-spiceclientgtk-3.0
    # Red virtual Libvirt (dnsmasq-base evita conflictos con systemd-resolved)
    dnsmasq-base
    iptables
    nftables
    # Afinamiento de rendimiento y ACLs
    tuned
    acl
)

sudo apt-get install -y "${PKGS_TO_INSTALL[@]}"

# ---------------------------------------------------------------------------
# 2. Controladores VirtIO para Windows (Opcional)
# ---------------------------------------------------------------------------
if [ "$WITH_WINDOWS" = true ]; then
    echo "ℹ️ [2/13] Descargando controladores VirtIO para Windows..."
    VIRTIO_DIR="$TARGET_HOME/Descargas/virtio-drivers"
    mkdir -p "$VIRTIO_DIR"
    if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
        echo "⬇️ Descargando virtio-win.iso..."
        curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" || true
        chown -R "$TARGET_USER:$TARGET_USER" "$VIRTIO_DIR" 2>/dev/null || true
        echo "  ✅ virtio-win.iso descargado en $VIRTIO_DIR/virtio-win.iso"
    fi
else
    echo "ℹ️ [2/13] Omitiendo descarga de drivers Windows (usar --with-windows para activarla)."
fi

# ---------------------------------------------------------------------------
# 3. Módulos del Kernel y Virtualización Anidada (Nested KVM + AVIC)
# ---------------------------------------------------------------------------
echo "ℹ️ [3/13] Configurando optimizaciones de CPU y virtualización anidada..."
sudo mkdir -p /etc/modprobe.d /etc/modules-load.d

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    echo "  • Optimizando KVM para AMD Ryzen Zen 3 (nested=1, avic=1, npt=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_amd.conf > /dev/null
# Configuración KVM para procesadores AMD Ryzen / Zen 3 (HP ProBook 455 G10)
options kvm_amd nested=1 avic=1 npt=1
EOF
    # Intentar recargar kvm_amd de forma segura si no hay VMs activas
    if lsmod | grep -q '^kvm_amd '; then
        if sudo modprobe -r kvm_amd kvm 2>/dev/null; then
            sudo modprobe kvm_amd 2>/dev/null || true
            echo "  ✅ Módulo kvm_amd recargado con AVIC activo."
        else
            echo "  ℹ️ kvm_amd está en uso; los nuevos parámetros (AVIC) se activarán al reiniciar."
        fi
    else
        sudo modprobe kvm_amd 2>/dev/null || true
    fi
elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo "  • Optimizando KVM para Intel Core (nested=1, ept=1, vpid=1, pml=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
# Configuración KVM para procesadores Intel Core / Xeon
options kvm_intel nested=1 ept=1 vpid=1 pml=1
EOF
    if lsmod | grep -q '^kvm_intel '; then
        if sudo modprobe -r kvm_intel kvm 2>/dev/null; then
            sudo modprobe kvm_intel 2>/dev/null || true
            echo "  ✅ Módulo kvm_intel recargado."
        fi
    else
        sudo modprobe kvm_intel 2>/dev/null || true
    fi
fi

echo "  • Habilitando módulos de aceleración en el kernel (vhost_net, vhost_vsock, tun)..."
cat <<EOF | sudo tee /etc/modules-load.d/kvm-vhost.conf > /dev/null
vhost_net
vhost_vsock
tun
EOF
sudo modprobe vhost_net 2>/dev/null || true
sudo modprobe vhost_vsock 2>/dev/null || true
sudo modprobe tun 2>/dev/null || true

# ---------------------------------------------------------------------------
# 4. Ajustes de /etc/libvirt/qemu.conf y Permisos de GPU (3D VirGL)
# ---------------------------------------------------------------------------
echo "ℹ️ [4/13] Configurando permisos, propiedad dinámica y aceleración GPU 3D en libvirt..."
sudo mkdir -p /etc/libvirt
if [ -f /etc/libvirt/qemu.conf ]; then
    sudo sed -i 's/^#*dynamic_ownership = .*/dynamic_ownership = 1/' /etc/libvirt/qemu.conf 2>/dev/null || true
    sudo sed -i 's/^#*remember_owner = .*/remember_owner = 1/' /etc/libvirt/qemu.conf 2>/dev/null || true
fi

# Añadir el usuario daemon libvirt-qemu al grupo render para permitir VirGL 3D
if id libvirt-qemu >/dev/null 2>&1; then
    sudo usermod -aG render,kvm libvirt-qemu 2>/dev/null || true
    echo "  ✅ libvirt-qemu añadido a los grupos 'render' y 'kvm' para aceleración VirGL."
fi

# ---------------------------------------------------------------------------
# 5. Backend de Firewall y Reglas Firewalld (nftables + Cockpit)
# ---------------------------------------------------------------------------
echo "ℹ️ [5/13] Configurando backend de red en libvirt e integrando con Firewalld..."

cat <<EOF | sudo tee /etc/libvirt/network.conf > /dev/null
# Backend de firewall (nftables nativo)
firewall_backend = "nftables"
EOF

if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=cockpit 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=trusted --add-interface=virbr+ 2>/dev/null || true
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-masquerade 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Reglas de Firewalld aplicadas (cockpit en $DEFAULT_ZONE, virbr0/virbr+ en trusted)."
fi

# ---------------------------------------------------------------------------
# 6. Regla Polkit sin contraseñas para el grupo 'libvirt'
# ---------------------------------------------------------------------------
echo "ℹ️ [6/13] Configurando regla Polkit para administración local sin contraseña..."
sudo mkdir -p /etc/polkit-1/rules.d
cat <<EOF | sudo tee /etc/polkit-1/rules.d/50-libvirt.rules > /dev/null
/* Permitir a usuarios en el grupo libvirt gestionar la virtualización sin pedir contraseña */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF
sudo chmod 644 /etc/polkit-1/rules.d/50-libvirt.rules

# ---------------------------------------------------------------------------
# 7. Verificación de capacidades KVM del Host
# ---------------------------------------------------------------------------
echo "ℹ️ [7/13] Validando capacidades de virtualización del hardware..."
virt-host-validate qemu || echo "  ⚠️ Nota: Si alguna comprobación falla, verifica que la virtualización esté activa en tu BIOS/UEFI."

# ---------------------------------------------------------------------------
# 8. Activación de Servicios de Libvirt y Cockpit
# ---------------------------------------------------------------------------
echo "ℹ️ [8/13] Habilitando servicios de Libvirt y Cockpit..."
sudo systemctl enable --now libvirtd 2>/dev/null || true
sudo systemctl enable --now cockpit.socket 2>/dev/null || true

# ---------------------------------------------------------------------------
# 9. Configuración de Red Virtual NAT y Storage Pool (/var/lib/libvirt/images)
# ---------------------------------------------------------------------------
echo "ℹ️ [9/13] Configurando red virtual NAT por defecto (virbr0)..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ [9/13] Configurando almacenamiento de imágenes en NVMe (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images

FS_TYPE=$(stat -f -c %T /var/lib/libvirt/images 2>/dev/null || true)
if [ "$FS_TYPE" = "btrfs" ]; then
    echo "  ⚡ Btrfs detectado en /var/lib/libvirt/images: aplicando atributo NoCoW (+C)..."
    sudo chattr +C /var/lib/libvirt/images 2>/dev/null || true
fi

# Asegurar que el pool de almacenamiento 'default' está definido y activo en libvirt
if command -v virsh >/dev/null 2>&1; then
    if ! sudo virsh pool-info default >/dev/null 2>&1; then
        sudo virsh pool-define-as default dir --target /var/lib/libvirt/images 2>/dev/null || true
        sudo virsh pool-build default 2>/dev/null || true
        sudo virsh pool-start default 2>/dev/null || true
        sudo virsh pool-autostart default 2>/dev/null || true
        echo "  ✅ Pool de almacenamiento 'default' configurado en /var/lib/libvirt/images."
    fi
fi

# ---------------------------------------------------------------------------
# 10. Configuración de Red: Detección Segura de Interfaz (Cableada vs Wi-Fi)
# ---------------------------------------------------------------------------
echo "ℹ️ [10/13] Analizando conectividad de red del host..."
PHYS_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1 || true)

is_wireless() {
    local iface="$1"
    [ -z "$iface" ] && return 1
    [[ "$iface" =~ ^wl ]] && return 0
    [ -d "/sys/class/net/$iface/wireless" ] && return 0
    if command -v iw >/dev/null 2>&1; then
        iw dev "$iface" info >/dev/null 2>&1 && return 0
    fi
    return 1
}

if [ "$SETUP_BRIDGE" = true ]; then
    if [ -n "$PHYS_IFACE" ]; then
        if is_wireless "$PHYS_IFACE"; then
            echo "  ⚠️ Interfaz inalámbrica detectada ('$PHYS_IFACE'). Los puentes br0 directos no son compatibles con Wi-Fi estándar 802.11."
            echo "  🛡️ Se mantiene la red virtual NAT 'virbr0' recomendada."
        elif [ "$PHYS_IFACE" != "br0" ]; then
            echo "  • Configurando bridge br0 sobre interfaz Ethernet $PHYS_IFACE..."
            if command -v nmcli >/dev/null 2>&1; then
                if ! nmcli con show br0 >/dev/null 2>&1; then
                    sudo nmcli con add type bridge ifname br0 con-name br0 2>/dev/null || true
                    sudo nmcli con add type bridge-slave ifname "$PHYS_IFACE" con-name br0-port master br0 2>/dev/null || true
                    sudo nmcli con modify br0 ipv4.method auto 2>/dev/null || true

                    cat <<EOF > /tmp/host-bridge.xml
<network>
  <name>host-bridge</name>
  <forward mode='bridge'/>
  <bridge name='br0'/>
</network>
EOF
                    sudo virsh net-define /tmp/host-bridge.xml 2>/dev/null || true
                    sudo virsh net-start host-bridge 2>/dev/null || true
                    sudo virsh net-autostart host-bridge 2>/dev/null || true
                    rm -f /tmp/host-bridge.xml
                    echo "  ✅ Bridge br0 creado y registrado en libvirt como 'host-bridge'."
                else
                    echo "  ℹ️ Bridge br0 ya existente en NetworkManager."
                fi
            fi
        fi
    fi
else
    echo "  🛡️ Modo portátil seguro: Se mantiene la red NAT virtual 'virbr0' (utiliza '--setup-bridge' si requieres bridge directo en la interfaz Ethernet)."
fi

# ---------------------------------------------------------------------------
# 11. Optimización de Memoria (KSM) y Perfiles de Energía
# ---------------------------------------------------------------------------
echo "ℹ️ [11/13] Configurando deduplicación de memoria RAM (KSM) y gestión de energía..."
sudo mkdir -p /etc/tmpfiles.d

cat <<EOF | sudo tee /etc/tmpfiles.d/ksm.conf > /dev/null
# Deduplicación de páginas de memoria RAM compartidas entre VMs KVM
# sleep_millisecs=2000 optimizado para preservar batería en portátiles
w /sys/kernel/mm/ksm/run - - - - 1
w /sys/kernel/mm/ksm/sleep_millisecs - - - - 2000
w /sys/kernel/mm/ksm/pages_to_scan - - - - 100
EOF

if [ -d /sys/kernel/mm/ksm ]; then
    echo 1 | sudo tee /sys/kernel/mm/ksm/run > /dev/null 2>&1 || true
    echo 2000 | sudo tee /sys/kernel/mm/ksm/sleep_millisecs > /dev/null 2>&1 || true
fi

if systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then
    echo "  ⚡ power-profiles-daemon activo: preservando batería del portátil."
elif [ -x "$TUNED_ADM_BIN" ]; then
    sudo systemctl enable --now tuned.service 2>/dev/null || true
    sudo "$TUNED_ADM_BIN" profile virtual-host 2>/dev/null || true
    echo "  ✅ Perfil Tuned 'virtual-host' aplicado."
fi

# ---------------------------------------------------------------------------
# 12. Permisos de Usuario y Grupos (libvirt, kvm, render)
# ---------------------------------------------------------------------------
echo "ℹ️ [12/13] Configurando grupos de usuario (libvirt, kvm, render) para $TARGET_USER..."
sudo usermod -aG libvirt,kvm,render "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || true

sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# ---------------------------------------------------------------------------
# 13. Variable de Entorno LIBVIRT_DEFAULT_URI
# ---------------------------------------------------------------------------
echo "ℹ️ [13/13] Configurando LIBVIRT_DEFAULT_URI en el perfil de $TARGET_USER..."

mkdir -p "$TARGET_HOME/.config/environment.d"
cat <<EOF > "$TARGET_HOME/.config/environment.d/10-libvirt.conf"
LIBVIRT_DEFAULT_URI=qemu:///system
EOF

mkdir -p "$TARGET_HOME/.bashrc.d"
cat <<EOF > "$TARGET_HOME/.bashrc.d/virtualization.sh"
# Configuración KVM/QEMU conectando al daemon de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

if [ -f "$TARGET_HOME/.zshrc" ] || [ -d "$TARGET_HOME/.zshrc.d" ]; then
    mkdir -p "$TARGET_HOME/.zshrc.d"
    cat <<EOF > "$TARGET_HOME/.zshrc.d/virtualization.zsh"
# Configuración KVM/QEMU conectando al daemon de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
fi

chown -R "$TARGET_USER:$TARGET_USER" \
    "$TARGET_HOME/.config/environment.d" \
    "$TARGET_HOME/.bashrc.d" 2>/dev/null || true

[ -d "$TARGET_HOME/.zshrc.d" ] && chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.zshrc.d" 2>/dev/null || true

HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo '127.0.0.1')
echo "================================================================="
echo "✅ Entorno de Virtualización KVM/QEMU Configurado con Éxito"
echo "================================================================="
echo "🌐 1. CONSOLA WEB COCKPIT: https://$HOST_IP:9090 (o https://localhost:9090)"
echo "🖥️ 2. VIRT-MANAGER: Ejecuta 'virt-manager' en terminal o lanzador GNOME."
echo "================================================================="
echo "⚠️ IMPORTANTE: Si es la primera vez que añades los grupos, cierra sesión"
echo "   y vuelve a iniciarla (o ejecuta 'newgrp libvirt') para aplicarlos."
echo "================================================================="
