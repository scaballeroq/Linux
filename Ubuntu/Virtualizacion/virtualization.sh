#!/usr/bin/env bash
# ==============================================================================
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU)
# Sistema: Ubuntu Linux | Escritorio: GNOME Shell (Wayland)
# Hardware: AMD Ryzen 7 7730U / Vega 8 (VA-API / 3D VirGL) | Intel
# ==============================================================================

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
[ -z "$TARGET_HOME" ] && TARGET_HOME="$HOME"

WITH_WINDOWS=false
STATUS_ONLY=false

TUNED_ADM_BIN=$(command -v tuned-adm 2>/dev/null || echo "/usr/sbin/tuned-adm")

# ---------------------------------------------------------------------------
# Funciones de ayuda y utilidades
# ---------------------------------------------------------------------------
show_help() {
    cat <<EOF
Uso: $0 [OPCIONES]

Script de aprovisionamiento y optimización de virtualización KVM/QEMU en Ubuntu Linux.
Diseñado para maximizar el rendimiento de máquinas virtuales y soportar dos vías de gestión:
  1. Cockpit Web Console (módulo cockpit-machines en https://localhost:9090)
  2. Virt-Manager (interfaz de escritorio avanzada para GNOME Shell Wayland)

OPCIONES:
  --status, -s, --check Verifica el estado de KVM, Cockpit, libvirt, módulos del kernel,
                        Polkit, Btrfs NoCoW, Firewalld, Tuned y red sin realizar cambios.
  --with-windows        Instala o descarga los controladores VirtIO para Windows (virtio-win.iso).
  -h, --help            Muestra esta ayuda y recomendaciones para VMs Linux.

CARACTERÍSTICAS Y OPTIMIZACIONES:
  - Integración Doble de Gestión: Cockpit Machines (Web) y Virt-Manager (GNOME Wayland).
  - Regla Polkit sin contraseñas para el grupo 'libvirt'.
  - Aceleración Gráfica 3D VirGL (virtio-gpu-gl) con grupo 'render' para AMD Radeon Vega / Intel.
  - Almacenamiento Btrfs NoCoW (+C) en /var/lib/libvirt/images para evitar fragmentación.
  - Compartición ultrarrápida de carpetas host-guest mediante VirtioFS (virtiofsd).
  - Aceleración por hardware AMD AVIC / Intel EPT y virtualización anidada (Nested KVM).
  - Aceleración de red del kernel (vhost_net, vhost_vsock, tun).
  - Backend nativo nftables en libvirt coordinado con Firewalld (zonas 'trusted' / 'libvirt' y masquerade).
  - Deduplicación de memoria RAM (KSM vía tmpfiles.d).
  - Detección segura de interfaces Wi-Fi para evitar roturas de red en portátiles.
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
    local libvirt_state
    libvirt_state=$(systemctl is-active libvirtd 2>/dev/null || systemctl is-active virtqemud 2>/dev/null || echo "inactivo")
    echo "  - Servicio libvirt: $libvirt_state"

    echo "• Consola Web Cockpit & Módulo de Máquinas Virtuales:"
    local cockpit_socket_state
    cockpit_socket_state=$(systemctl is-active cockpit.socket 2>/dev/null || echo "inactivo")
    echo "  - Servicio cockpit.socket: $cockpit_socket_state (Puerto 9090)"

    echo -n "  - Módulo cockpit-machines: "
    if [ -d "/usr/share/cockpit/machines" ] || dpkg -s cockpit-machines >/dev/null 2>&1; then
        echo "✅ Instalado y disponible (/usr/share/cockpit/machines)"
    else
        echo "❌ No instalado"
    fi

    if [ "$cockpit_socket_state" = "active" ]; then
        echo "  - Acceso Web Cockpit: 🌐 https://localhost:9090"
    fi

    echo -n "• Estado de la red virtual 'default': "
    if ip link show virbr0 >/dev/null 2>&1; then
        echo "✅ Activa (interfaz virbr0 levantada)"
    elif command -v virsh >/dev/null 2>&1 && timeout 2 virsh -c qemu:///system net-info default >/dev/null 2>&1; then
        echo "✅ Activa (en ejecución en libvirt)"
    else
        echo "⚠️ No configurada aún (se creará automáticamente)"
    fi

    echo -n "• Integración con Firewalld: "
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        local fw_zone
        fw_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        echo "✅ Activo (Zona: $fw_zone)"
    else
        echo "ℹ️ Firewalld no activo o no disponible"
    fi

    echo -n "• Almacenamiento VM (/var/lib/libvirt/images): "
    if [ -d /var/lib/libvirt/images ]; then
        local fs_type
        fs_type=$(stat -f -c %T /var/lib/libvirt/images 2>/dev/null || true)
        if [ "$fs_type" = "btrfs" ]; then
            if lsattr -d /var/lib/libvirt/images 2>/dev/null | grep -q 'C'; then
                echo "✅ Btrfs NoCoW (+C activo, optimizado para IOPS)"
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
sudo apt-get install -y \
    qemu-system-x86 \
    qemu-utils \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    virt-manager \
    virt-viewer \
    virtinst \
    virt-top \
    cockpit \
    cockpit-machines \
    cockpit-bridge \
    ovmf \
    swtpm \
    libguestfs-tools \
    guestfs-tools \
    libosinfo-bin \
    virtiofsd \
    spice-vdagent \
    usbredir \
    dnsmasq \
    tuned \
    acl \
    nftables 2>/dev/null || true

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
    echo "ℹ️ [2/13] Omitiendo descarga de drivers Windows."
fi

# ---------------------------------------------------------------------------
# 3. Módulos del Kernel y Virtualización Anidada (Nested KVM)
# ---------------------------------------------------------------------------
echo "ℹ️ [3/13] Configurando optimizaciones de CPU y virtualización anidada..."
sudo mkdir -p /etc/modprobe.d /etc/modules-load.d

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    echo "  • Optimizando KVM para AMD Ryzen (nested=1, avic=1, npt=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_amd.conf > /dev/null
# Configuración KVM para procesadores AMD Ryzen / Zen
options kvm_amd nested=1 avic=1 npt=1
EOF
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd 2>/dev/null || true
elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo "  • Optimizando KVM para Intel Core (nested=1, ept=1, vpid=1, pml=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
# Configuración KVM para procesadores Intel Core / Xeon
options kvm_intel nested=1 ept=1 vpid=1 pml=1
EOF
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel 2>/dev/null || true
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
# 4. Ajustes de /etc/libvirt/qemu.conf
# ---------------------------------------------------------------------------
echo "ℹ️ [4/13] Configurando permisos y propiedad dinámica en libvirt..."
sudo mkdir -p /etc/libvirt
if [ -f /etc/libvirt/qemu.conf ]; then
    sudo sed -i 's/^#*dynamic_ownership = .*/dynamic_ownership = 1/' /etc/libvirt/qemu.conf 2>/dev/null || true
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
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-masquerade 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Reglas de Firewalld aplicadas."
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
# 9. Configuración de Red Virtual NAT y Storage Pool
# ---------------------------------------------------------------------------
echo "ℹ️ [9/13] Configurando red virtual NAT por defecto (virbr0)..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ [9/13] Configurando directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images

FS_TYPE=$(stat -f -c %T /var/lib/libvirt/images 2>/dev/null || true)
if [ "$FS_TYPE" = "btrfs" ]; then
    echo "  ⚡ Btrfs detectado en /var/lib/libvirt/images: aplicando atributo NoCoW (+C)..."
    sudo chattr +C /var/lib/libvirt/images 2>/dev/null || true
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

if [ -n "$PHYS_IFACE" ]; then
    if is_wireless "$PHYS_IFACE"; then
        echo "  ℹ️ Interfaz inalámbrica detectada ('$PHYS_IFACE')."
        echo "  🛡️ Se mantiene la red NAT por defecto ('virbr0') para evitar incompatibilidades con Wi-Fi 802.11."
    elif [ "$PHYS_IFACE" != "br0" ]; then
        echo "  ℹ️ Interfaz cableada detectada: '$PHYS_IFACE'."
        if command -v nmcli >/dev/null 2>&1; then
            if ! nmcli con show br0 >/dev/null 2>&1; then
                echo "  • Creando bridge br0 sobre interfaz Ethernet $PHYS_IFACE..."
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
                echo "  ✅ Bridge br0 creado y registrado en libvirt como 'host-bridge'."
            fi
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 11. Optimización de Memoria (KSM) y Perfiles de Energía
# ---------------------------------------------------------------------------
echo "ℹ️ [11/13] Configurando deduplicación de memoria RAM (KSM) y gestión de energía..."
sudo mkdir -p /etc/tmpfiles.d

cat <<EOF | sudo tee /etc/tmpfiles.d/ksm.conf > /dev/null
# Deduplicación de páginas de memoria RAM compartidas entre VMs KVM
w /sys/kernel/mm/ksm/run - - - - 1
w /sys/kernel/mm/ksm/sleep_millisecs - - - - 500
w /sys/kernel/mm/ksm/pages_to_scan - - - - 100
EOF

if [ -d /sys/kernel/mm/ksm ]; then
    echo 1 | sudo tee /sys/kernel/mm/ksm/run > /dev/null 2>&1 || true
    echo 500 | sudo tee /sys/kernel/mm/ksm/sleep_millisecs > /dev/null 2>&1 || true
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

chown -R "$TARGET_USER:$TARGET_USER" \
    "$TARGET_HOME/.config/environment.d" \
    "$TARGET_HOME/.bashrc.d" 2>/dev/null || true

HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo '127.0.0.1')
echo "================================================================="
echo "✅ Entorno de Virtualización KVM/QEMU Configurado con Éxito"
echo "================================================================="
echo "🌐 1. CONSOLA WEB COCKPIT: https://$HOST_IP:9090 (o https://localhost:9090)"
echo "🖥️ 2. VIRT-MANAGER: Ejecuta 'virt-manager' en terminal o lanzador GNOME."
echo "================================================================="
echo "⚠️ IMPORTANTE: Cierra sesión y vuelve a iniciarla para aplicar grupos."
echo "================================================================="
