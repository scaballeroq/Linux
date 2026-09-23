#!/bin/bash
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU) para openSUSE Tumbleweed
# Optimizado para openSUSE Tumbleweed con KDE Plasma 6 Wayland (Kernel 6.x/7.x, AMD Ryzen/Intel, GPU Vega/Radeon/Intel, 3D VirGL, Btrfs NoCoW, Firewalld, Modular Daemons, Tuned)

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
[ -z "$TARGET_HOME" ] && TARGET_HOME="$HOME"

WITH_WINDOWS=false
STATUS_ONLY=false

# ---------------------------------------------------------------------------
# Funciones de ayuda y utilidades
# ---------------------------------------------------------------------------
show_help() {
    cat <<EOF
Uso: $0 [OPCIONES]

Script de aprovisionamiento y optimización de virtualización KVM/QEMU en openSUSE Tumbleweed,
diseñado para maximizar el rendimiento y la integración de distribuciones Linux invitadas bajo entornos
KDE Plasma 6 (Wayland) y el ecosistema openSUSE.

OPCIONES:
  --status, -s, --check Verifica el estado de KVM, sockets libvirt, módulos del kernel,
                        Polkit, Btrfs NoCoW, Firewalld, Tuned y red sin realizar cambios.
  --with-windows        Instala o descarga los controladores VirtIO para Windows (virtio-win).
  -h, --help            Muestra esta ayuda y recomendaciones para VMs Linux.

CARACTERÍSTICAS Y OPTIMIZACIONES PARA OPENSUSE TUMBLEWEED + KDE PLASMA 6:
  - Integración KDE Plasma 6 Wayland: Regla Polkit sin contraseñas, virt-manager,
    spice-vdagent y usbredir para portapapeles y USB compartido bidireccional.
  - Soporte 3D VirGL (virglrenderer + virtio-gpu-gl) con grupo 'render' para AMD Radeon / Intel.
  - Almacenamiento Btrfs NoCoW (+C) en /var/lib/libvirt/images para evitar fragmentación e IOPS lentos.
  - Compartición ultrarrápida de carpetas mediante VirtioFS (virtiofsd).
  - Aceleración por hardware AMD AVIC / Intel EPT y virtualización anidada (Nested KVM).
  - Aceleración de red del kernel (vhost_net, vhost_vsock, tun) y sockets modulares Libvirt.
  - Deduplicación de memoria RAM (KSM vía tmpfiles.d) y perfil Tuned virtual-host.
  - Integración nativa con Firewalld (zona 'libvirt', backend iptables-nft/nftables y masquerade).
  - Detección segura de interfaces Wi-Fi para evitar desconexiones en portátiles (HP EliteBook).
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DEL ENTORNO DE VIRTUALIZACIÓN (OPENSUSE + KDE PLASMA 6)"
    echo "================================================================="

    echo -n "• Entorno de Escritorio Host: "
    local desktop="${XDG_CURRENT_DESKTOP:-Desconocido}"
    local session_type="${XDG_SESSION_TYPE:-Desconocido}"
    echo "✅ $desktop ($session_type)"

    echo -n "• Soporte de Virtualización Hardware: "
    if grep -E -q '(vmx|svm)' /proc/cpuinfo; then
        echo "✅ Detectado ($(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs))"
    else
        echo "❌ No detectado o deshabilitado en BIOS/UEFI."
    fi

    echo -n "• Dispositivo /dev/kvm: "
    if [ -e /dev/kvm ]; then
        if [ -w /dev/kvm ]; then
            echo "✅ Accesible con permisos de escritura"
        else
            echo "⚠️ Presente pero sin permisos de escritura (requiere pertenecer al grupo kvm)"
        fi
    else
        echo "❌ No encontrado."
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

    echo "• Estado de sockets modulares de Libvirt:"
    local sockets=(
        "virtqemud.socket"
        "virtnetworkd.socket"
        "virtstoraged.socket"
        "virtnodedevd.socket"
        "virtnwfilterd.socket"
        "virtsecretd.socket"
        "virtproxyd.socket"
    )
    for s in "${sockets[@]}"; do
        local state
        state=$(systemctl is-active "$s" 2>/dev/null || true)
        [ -z "$state" ] && state="inactivo"
        echo "  - $s: $state"
    done

    echo -n "• Estado de la red virtual 'default': "
    if ip link show virbr0 >/dev/null 2>&1; then
        echo "✅ Activa (interfaz virbr0 levantada)"
    elif command -v virsh >/dev/null 2>&1 && virsh -c qemu:///system net-info default >/dev/null 2>&1; then
        echo "✅ Activa (iniciada en libvirt)"
    elif [ -f /etc/libvirt/qemu/networks/autostart/default.xml ] || [ -f /etc/libvirt/qemu/networks/default.xml ]; then
        echo "ℹ️ Definida pero inactiva (se activará al iniciar los sockets de libvirt)"
    else
        echo "⚠️ No iniciada o pendiente de configuración inicial"
    fi

    echo -n "• Zona 'libvirt' en Firewalld: "
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        local zones
        zones=$(firewall-cmd --get-zones 2>/dev/null || true)
        if echo "$zones" | grep -qw "libvirt"; then
            echo "✅ Zona 'libvirt' cargada y disponible"
        else
            echo "⚠️ Zona 'libvirt' no cargada aún (se activará al instalar libvirt y recargar firewalld)"
        fi
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
                echo "⚠️ Btrfs con Copy-on-Write activo (se recomienda chattr +C)"
            fi
        else
            echo "✅ Presente ($fs_type)"
        fi
    else
        echo "ℹ️ Pendiente de creación"
    fi

    echo -n "• Regla Polkit sin contraseñas para KDE Plasma: "
    if [ -f /etc/polkit-1/rules.d/50-libvirt.rules ]; then
        echo "✅ Presente (/etc/polkit-1/rules.d/50-libvirt.rules)"
    else
        echo "⚠️ No configurada (KDE solicitará contraseña de root para virt-manager)"
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
        echo "⚠️ Incompleto ($user_groups). Recomendados: libvirt, kvm, render."
    fi

    echo "• Interfaces gráficas y herramientas:"
    echo -n "  - virt-manager (Avanzado): "
    if rpm -q virt-manager >/dev/null 2>&1 || command -v virt-manager >/dev/null 2>&1; then
        echo "✅ Instalado"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Gestor de energía y recursos (Tuned): "
    if command -v tuned-adm >/dev/null 2>&1 && systemctl is-active --quiet tuned 2>/dev/null; then
        local tuned_profile
        tuned_profile=$(tuned-adm active 2>/dev/null | cut -d: -f2 | xargs || true)
        echo "✅ Tuned activo (Perfil: $tuned_profile)"
    else
        echo "ℹ️ Tuned estándar / no activo"
    fi

    echo -n "• Deduplicación de memoria KSM: "
    if [ -f /sys/kernel/mm/ksm/run ] && [ "$(cat /sys/kernel/mm/ksm/run 2>/dev/null)" = "1" ]; then
        echo "✅ Activo (KSM en ejecución)"
    else
        echo "ℹ️ Inactivo o desactivado"
    fi

    echo -n "• Herramientas de optimización y aceleración: "
    local tools=("virglrenderer" "virtiofsd" "osinfo-db" "spice-gtk" "usbredir" "swtpm")
    local found_tools=()
    for t in "${tools[@]}"; do
        if rpm -q "$t" >/dev/null 2>&1 || command -v "$t" >/dev/null 2>&1; then
            found_tools+=("$t")
        fi
    done
    echo "${found_tools[*]:-Ninguna instalada}"

    echo -n "• VirtIO Drivers (Windows): "
    if [ -f "/usr/share/virtio-win/virtio-win.iso" ]; then
        echo "✅ Presente en /usr/share/virtio-win/virtio-win.iso"
    elif [ -f "$TARGET_HOME/Descargas/virtio-drivers/virtio-win.iso" ]; then
        echo "✅ Presente en $TARGET_HOME/Descargas/virtio-drivers/virtio-win.iso"
    else
        echo "ℹ️ No instalado (disponible con opción --with-windows)"
    fi

    echo "================================================================="
}

# ---------------------------------------------------------------------------
# Procesamiento de argumentos
# ---------------------------------------------------------------------------
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

echo "🚀 Configurando entorno de virtualización de alto rendimiento (KVM/QEMU) en openSUSE Tumbleweed..."
echo "🎯 Optimizado para openSUSE Tumbleweed con KDE Plasma 6 Wayland y distribuciones Linux invitadas..."

# ---------------------------------------------------------------------------
# 1. Instalación de paquetes necesarios vía Zypper
# ---------------------------------------------------------------------------
echo "ℹ️ Instalando QEMU, libvirt, virt-manager, virglrenderer, virtiofsd y herramientas auxiliares vía Zypper..."
sudo zypper --non-interactive install -y -t pattern kvm_server kvm_tools 2>/dev/null || true

sudo zypper --non-interactive install -y \
    qemu-kvm \
    qemu-tools \
    libvirt \
    libvirt-daemon-driver-qemu \
    libvirt-daemon-driver-network \
    libvirt-daemon-driver-storage \
    libvirt-client \
    virt-manager \
    virt-viewer \
    virt-install \
    virt-top \
    virglrenderer \
    spice-vdagent \
    usbredir \
    ovmf \
    swtpm \
    libosinfo \
    dnsmasq \
    dmidecode \
    bridge-utils \
    tuned \
    acl \
    guestfs-tools \
    iptables \
    nftables 2>/dev/null || true

# Paquete virtiofsd (disponible de forma independiente o en qemu)
sudo zypper --non-interactive install -y virtiofsd 2>/dev/null || true

# ---------------------------------------------------------------------------
# 2. Controladores VirtIO para Windows (Opcional vía --with-windows)
# ---------------------------------------------------------------------------
if [ "$WITH_WINDOWS" = true ]; then
    echo "ℹ️ Opción --with-windows activada: Asegurando controladores VirtIO para Windows..."
    VIRTIO_DIR="$TARGET_HOME/Descargas/virtio-drivers"
    mkdir -p "$VIRTIO_DIR"
    if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
        echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso desde fedorapeople..."
        curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" 2>/dev/null || true
        chown -R "$TARGET_USER:$TARGET_USER" "$VIRTIO_DIR" 2>/dev/null || true
        echo "✅ virtio-win.iso descargado en $VIRTIO_DIR/virtio-win.iso"
    else
        echo "✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
    fi
else
    echo "ℹ️ Omitiendo instalación de drivers Windows (las distribuciones Linux tienen VirtIO nativo en el kernel)."
    echo "💡 Si requieres Windows en el futuro, ejecuta: $0 --with-windows"
fi

# ---------------------------------------------------------------------------
# 3. Módulos del Kernel, Aceleración de CPU (AVIC/EPT) y Virtualización Anidada
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando optimizaciones del procesador y virtualización anidada (Nested KVM)..."
sudo mkdir -p /etc/modprobe.d /etc/modules-load.d

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    echo "• Optimizando KVM para AMD Ryzen (nested=1, avic=1, npt=1)..."
    # avic: Advanced Virtual Interrupt Controller para menor latencia de interrupciones
    # npt: Nested Page Tables para paginación por hardware nativa
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_amd.conf > /dev/null
# Configuración KVM para procesadores AMD Ryzen / Zen en openSUSE Tumbleweed
options kvm_amd nested=1 avic=1 npt=1
EOF
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd 2>/dev/null || true
elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo "• Optimizando KVM para Intel Core (nested=1, ept=1, vpid=1, pml=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
# Configuración KVM para procesadores Intel Core / Xeon en openSUSE Tumbleweed
options kvm_intel nested=1 ept=1 vpid=1 pml=1
EOF
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel 2>/dev/null || true
fi

# Aceleración de red en el kernel (vhost_net), sockets rápidos VM-Host (vhost_vsock) y túneles (tun)
echo "ℹ️ Habilitando aceleración en el kernel (vhost_net, vhost_vsock, tun)..."
cat <<EOF | sudo tee /etc/modules-load.d/kvm-vhost.conf > /dev/null
vhost_net
vhost_vsock
tun
EOF
sudo modprobe vhost_net 2>/dev/null || true
sudo modprobe vhost_vsock 2>/dev/null || true
sudo modprobe tun 2>/dev/null || true

# ---------------------------------------------------------------------------
# 4. Ajustes de /etc/libvirt/qemu.conf (Audio PipeWire nativo y permisos de usuario)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando usuario y grupo en /etc/libvirt/qemu.conf para audio PipeWire e integración de sesión..."
if [ -f /etc/libvirt/qemu.conf ]; then
    sudo sed -i "s/^#*user = .*/user = \"$TARGET_USER\"/" /etc/libvirt/qemu.conf 2>/dev/null || true
    sudo sed -i "s/^#*group = .*/group = \"kvm\"/" /etc/libvirt/qemu.conf 2>/dev/null || true
    sudo sed -i "s/^#*dynamic_ownership = .*/dynamic_ownership = 1/" /etc/libvirt/qemu.conf 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 5. Backend de Firewall y Red Libvirt (/etc/libvirt/network.conf y Firewalld)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando backend de firewall e integración de red en libvirt..."

sudo mkdir -p /etc/libvirt
if [ -f /etc/libvirt/network.conf ]; then
    if systemctl is-active --quiet firewalld 2>/dev/null || systemctl is-enabled --quiet firewalld 2>/dev/null; then
        sudo sed -i 's/^#*firewall_backend = .*/firewall_backend = "iptables"/' /etc/libvirt/network.conf 2>/dev/null || true
    else
        sudo sed -i 's/^#*firewall_backend = .*/firewall_backend = "nftables"/' /etc/libvirt/network.conf 2>/dev/null || true
    fi
else
    cat <<EOF | sudo tee /etc/libvirt/network.conf > /dev/null
# Backend de firewall para openSUSE Tumbleweed
firewall_backend = "iptables"
EOF
fi

# Configuración de reglas en Firewalld para NAT y puente virtual (virbr0)
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    echo "ℹ️ Recargando definiciones de zonas de Firewalld para asegurar zona 'libvirt'..."
    sudo firewall-cmd --reload 2>/dev/null || true

    echo "ℹ️ Configurando zonas y reenvío NAT en Firewalld para libvirt..."
    sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=libvirt --add-forward 2>/dev/null || true

    DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-masquerade 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=public --add-masquerade 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Reglas de reenvío y masquerade aplicadas en Firewalld (zonas libvirt y $DEFAULT_ZONE)."
fi

# ---------------------------------------------------------------------------
# 6. Regla Polkit para KDE Plasma 6 (Evita petición de contraseñas continuas)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando regla Polkit para gestión sin contraseña en KDE Plasma..."
sudo mkdir -p /etc/polkit-1/rules.d
cat <<EOF | sudo tee /etc/polkit-1/rules.d/50-libvirt.rules > /dev/null
/* Permitir a usuarios en el grupo libvirt gestionar la virtualización sin pedir contraseña en KDE Plasma */
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.libvirt") === 0 && subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF
sudo chmod 644 /etc/polkit-1/rules.d/50-libvirt.rules
echo "  ✅ Regla Polkit /etc/polkit-1/rules.d/50-libvirt.rules configurada."

# ---------------------------------------------------------------------------
# 7. Verificación de capacidades KVM del Host
# ---------------------------------------------------------------------------
echo "ℹ️ Verificando capacidades de virtualización del hardware con virt-host-validate..."
virt-host-validate qemu || echo "⚠️ Advertencia: Revisa que la virtualización VT-x / AMD-V esté habilitada en tu BIOS/UEFI."

# ---------------------------------------------------------------------------
# 8. Configuración de Sockets Modulares de Libvirt (Eliminando conflictos)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando daemons modulares de Libvirt (Systemd Socket Activation)..."
if systemctl list-unit-files | grep -q "virtqemud.socket"; then
    sudo systemctl stop libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket 2>/dev/null || true
    sudo systemctl disable libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket 2>/dev/null || true

    sudo systemctl enable --now \
        virtqemud.socket \
        virtnetworkd.socket \
        virtstoraged.socket \
        virtnodedevd.socket \
        virtnwfilterd.socket \
        virtsecretd.socket \
        virtproxyd.socket 2>/dev/null || true
else
    # Fallback si los sockets modulares no están empaquetados por separado
    sudo systemctl enable --now libvirtd.service 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 9. Configuración de Red Virtual NAT y Storage Pool con Btrfs NoCoW
# ---------------------------------------------------------------------------
echo "ℹ️ Asegurando red virtual NAT por defecto (virbr0)..."
sudo systemctl restart virtnetworkd.service 2>/dev/null || sudo systemctl restart libvirtd.service 2>/dev/null || true

if ! sudo virsh net-info default >/dev/null 2>&1; then
    if [ -f /etc/libvirt/qemu/networks/default.xml ]; then
        sudo virsh net-define /etc/libvirt/qemu/networks/default.xml 2>/dev/null || true
    fi
fi

if sudo virsh net-info default 2>/dev/null | grep -q "Activo:.*sí"; then
    sudo virsh net-destroy default 2>/dev/null || true
fi
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Configurando directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images

# Optimización Btrfs NoCoW (+C): evita fragmentación severa y mejora latencia de E/S en openSUSE
FS_TYPE=$(stat -f -c %T /var/lib/libvirt/images 2>/dev/null || true)
if [ "$FS_TYPE" = "btrfs" ]; then
    echo "  ⚡ Btrfs detectado en /var/lib/libvirt/images: desactivando Copy-on-Write (+C)..."
    sudo chattr +C /var/lib/libvirt/images 2>/dev/null || true
fi

echo "ℹ️ Asegurando storage pool por defecto..."
if ! sudo virsh pool-info default >/dev/null 2>&1; then
    sudo virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images 2>/dev/null || true
    sudo virsh pool-build default 2>/dev/null || true
fi
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

# ---------------------------------------------------------------------------
# 10. Configuración de Red: Detección segura de Interfaz (Cableada vs Wi-Fi)
# ---------------------------------------------------------------------------
echo "ℹ️ Comprobando interfaz de red principal para conectividad de VMs..."
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
        echo "ℹ️ Interfaz activa inalámbrica detectada: '$PHYS_IFACE'."
        echo "🛡️ Por restricciones del estándar 802.11 (Wi-Fi), no se crea un bridge directo para evitar desconexiones."
        echo "✅ La red NAT por defecto ('default' con virbr0 y vhost_net) ofrece máximo rendimiento y acceso a internet transparente."
    elif [ "$PHYS_IFACE" != "br0" ]; then
        echo "ℹ️ Interfaz activa cableada detectada: '$PHYS_IFACE'."
        if command -v nmcli >/dev/null 2>&1; then
            if ! nmcli con show br0 >/dev/null 2>&1; then
                echo "Creando bridge br0 sobre interfaz Ethernet $PHYS_IFACE..."
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
                echo "✅ Bridge br0 creado y registrado en libvirt como 'host-bridge'."
            else
                echo "✅ El bridge br0 ya existe, omitiendo creación."
            fi
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 11. Optimización de Memoria (KSM) y Coexistencia con Tuned
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando deduplicación de memoria RAM (KSM) en openSUSE..."
sudo mkdir -p /etc/tmpfiles.d
cat <<EOF | sudo tee /etc/tmpfiles.d/ksm.conf > /dev/null
# Deduplicación de páginas de memoria RAM compartidas entre VMs KVM
w /sys/kernel/mm/ksm/run - - - - 1
w /sys/kernel/mm/ksm/sleep_millisecs - - - - 100
EOF

if [ -d /sys/kernel/mm/ksm ]; then
    echo 1 | sudo tee /sys/kernel/mm/ksm/run > /dev/null 2>&1 || true
    echo 100 | sudo tee /sys/kernel/mm/ksm/sleep_millisecs > /dev/null 2>&1 || true
fi
echo "  ✅ KSM habilitado en el kernel de forma persistente."

if command -v tuned-adm >/dev/null 2>&1; then
    sudo systemctl enable --now tuned.service 2>/dev/null || true
    sudo tuned-adm profile virtual-host 2>/dev/null || true
    echo "  ✅ Perfil Tuned virtual-host aplicado."
fi

# ---------------------------------------------------------------------------
# 12. Permisos de Usuario y Grupos (libvirt, kvm, render)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando grupos de usuario (libvirt, kvm, render) para $TARGET_USER..."
# Grupo render permite aceleración 3D VirGL directa en GPUs AMD/Intel (/dev/dri/renderD128)
sudo usermod -aG libvirt,kvm,render "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt "$TARGET_USER" 2>/dev/null || true

echo "ℹ️ Configurando permisos ACL en el directorio de imágenes (/var/lib/libvirt/images)..."
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# ---------------------------------------------------------------------------
# 13. Variable de Entorno LIBVIRT_DEFAULT_URI en el Perfil de Usuario Real
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI para el usuario $TARGET_USER ($TARGET_HOME)..."

# 13.1. Sesión de escritorio KDE / systemd --user (environment.d)
mkdir -p "$TARGET_HOME/.config/environment.d"
cat <<EOF > "$TARGET_HOME/.config/environment.d/10-libvirt.conf"
LIBVIRT_DEFAULT_URI=qemu:///system
EOF

# 13.2. Zsh modular (~/.zshrc.d)
mkdir -p "$TARGET_HOME/.zshrc.d"
cat <<EOF > "$TARGET_HOME/.zshrc.d/virtualization.zsh"
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

# 13.3. Bash modular (~/.bashrc.d)
mkdir -p "$TARGET_HOME/.bashrc.d"
cat <<EOF > "$TARGET_HOME/.bashrc.d/virtualization.sh"
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

# Fallback en ~/.bashrc si no se usa carga modular
if ! grep -q "LIBVIRT_DEFAULT_URI" "$TARGET_HOME/.bashrc" 2>/dev/null; then
    echo '' >> "$TARGET_HOME/.bashrc"
    echo '# Configuración KVM/QEMU conectando al modo de sistema por defecto' >> "$TARGET_HOME/.bashrc"
    echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> "$TARGET_HOME/.bashrc"
fi

# Asignar propiedad correcta de los archivos creados al usuario objetivo
chown -R "$TARGET_USER:$TARGET_USER" \
    "$TARGET_HOME/.config/environment.d" \
    "$TARGET_HOME/.zshrc.d" \
    "$TARGET_HOME/.bashrc.d" 2>/dev/null || true

# Propagar inmediatamente al entorno de activación de systemd/D-Bus del usuario si hay sesión activa
sudo -u "$TARGET_USER" dbus-update-activation-environment --systemd LIBVIRT_DEFAULT_URI=qemu:///system 2>/dev/null || true

echo "✅ Configuración de Virtualización creada con éxito en el perfil de $TARGET_USER."

# ---------------------------------------------------------------------------
# Resumen y Recomendaciones para VMs Linux en KDE Plasma 6 Wayland
# ---------------------------------------------------------------------------
echo "================================================================="
echo "✅ Entorno KVM/QEMU en openSUSE Tumbleweed con KDE Plasma 6 configurado y optimizado."
echo "================================================================="
echo "💡 INTERFAZ GRÁFICA DISPONIBLE:"
echo "  • Virt-Manager: Interfaz avanzada de control total de máquinas virtuales."
echo ""
echo "💡 GUÍA RÁPIDA DE CONFIGURACIÓN PARA LINUX GUESTS EN VIRT-MANAGER:"
echo "  1. Procesador (CPU):"
echo "     - Modelo: 'host-passthrough' (rendimiento nativo de CPU e instrucciones AVX2/Zen)."
echo "  2. Gráficos y Pantalla (KDE Wayland 60+ FPS):"
echo "     - Pantalla: 'SPICE', Tipo de escucha: 'Ninguno' (socket local Unix)."
echo "     - Activar: 'Aceleración OpenGL'."
echo "     - Video: 'VirtIO' con casilla 'Aceleración 3D' marcada (VirGL en AMD Radeon / Intel)."
echo "  3. Almacenamiento (Disco):"
echo "     - Bus: 'VirtIO' o 'SCSI' con controlador VirtIO SCSI."
echo "     - Rendimiento: Modo de caché 'writeback', Motor de E/S 'io_uring', Descarte 'unmap' (TRIM)."
echo "  4. Compartir Carpetas (Host <-> Guest):"
echo "     - Añadir Hardware -> Sistema de archivos -> Modo de acceso: 'virtiofs' (requiere memoria compartida memfd)."
echo "  5. Integración de Portapapeles y Resolución Dinámica:"
echo "     - En la VM invitada instala: spice-vdagent y qemu-guest-agent"
echo "       * openSUSE     : sudo zypper install spice-vdagent qemu-guest-agent"
echo "       * Fedora       : sudo dnf install spice-vdagent qemu-guest-agent"
echo "       * Arch/CachyOS : sudo pacman -S spice-vdagent qemu-guest-agent"
echo "       * Ubuntu/Debian: sudo apt install spice-vdagent qemu-guest-agent"
echo "================================================================="
echo "💡 Recuerda reiniciar o cerrar sesión para aplicar los cambios de grupo (libvirt, kvm, render)."
echo "================================================================="
