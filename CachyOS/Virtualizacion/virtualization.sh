#!/bin/bash
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU) para CachyOS
# Optimizado para virtualizar distribuciones Linux (Kernel 7.x, AMD Ryzen/Intel, KDE Plasma 6 Wayland, 3D VirGL, VirtioFS, Modular Daemons)

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
WITH_WINDOWS=false
STATUS_ONLY=false

# ---------------------------------------------------------------------------
# Funciones de ayuda y utilidades
# ---------------------------------------------------------------------------
show_help() {
    cat <<EOF
Uso: $0 [OPCIONES]

Script de aprovisionamiento y optimización de virtualización KVM/QEMU en CachyOS,
diseñado para maximizar el rendimiento y la integración de distribuciones Linux invitadas.

OPCIONES:
  --status, --check     Verifica el estado de KVM, sockets libvirt, módulos del kernel y red sin realizar cambios.
  --with-windows        Descarga también la ISO de controladores VirtIO para Windows (virtio-win.iso).
  -h, --help            Muestra esta ayuda y recomendaciones para VMs Linux.

CARACTERÍSTICAS PARA LINUX GUESTS:
  - Soporte 3D VirGL (virglrenderer + virtio-gpu-gl) para escritorios Wayland/X11 fluidos.
  - Compartición ultrarrápida de carpetas mediante VirtioFS (virtiofsd en Rust).
  - Aceleración por hardware AMD AVIC / Intel EPT y virtualización anidada (Nested KVM).
  - Aceleración de red del kernel (vhost_net, vhost_vsock) y sockets modulares Libvirt 12+.
  - Deduplicación de memoria RAM entre VMs con KSM del kernel y perfil Tuned 'virtual-host'.
  - Protección de interfaces Wi-Fi para evitar pérdida de conexión.
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DEL ENTORNO DE VIRTUALIZACIÓN (CachyOS)"
    echo "================================================================="

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
    local sockets=("virtqemud.socket" "virtnetworkd.socket" "virtstoraged.socket" "virtnodedevd.socket" "virtproxyd.socket")
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

    echo -n "• Pertenencia a grupos requeridos ($TARGET_USER): "
    local user_groups
    user_groups=$(id -Gn "$TARGET_USER" 2>/dev/null || true)
    local has_libvirt=false
    local has_kvm=false
    [[ "$user_groups" =~ (^|[[:space:]])libvirt($|[[:space:]]) ]] && has_libvirt=true
    [[ "$user_groups" =~ (^|[[:space:]])kvm($|[[:space:]]) ]] && has_kvm=true

    if [ "$has_libvirt" = true ] && [ "$has_kvm" = true ]; then
        echo "✅ libvirt, kvm"
    else
        echo "⚠️ Incompleto (Grupos actuales: $user_groups). Se requiere libvirt y kvm."
    fi

    echo -n "• Interfaz gráfica (virt-manager): "
    if pacman -Q virt-manager >/dev/null 2>&1; then
        echo "✅ Instalado"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Herramientas de optimización Linux Guest: "
    local tools=("virglrenderer" "virtiofsd" "osinfo-db" "tuned" "swtpm")
    local found_tools=()
    for t in "${tools[@]}"; do
        if pacman -Q "$t" >/dev/null 2>&1; then
            found_tools+=("$t")
        fi
    done
    echo "${found_tools[*]:-Ninguna instalada}"

    echo "================================================================="
}

# ---------------------------------------------------------------------------
# Procesamiento de argumentos
# ---------------------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --status|--check)
            STATUS_ONLY=true
            ;;
        --with-windows)
            WITH_WINDOWS=true
            ;;
        -h|--help)
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

echo "🚀 Configurando entorno de virtualización de alto rendimiento (KVM/QEMU) en CachyOS..."
echo "🎯 Optimizado para distribuciones Linux invitadas (Arch, Fedora, Ubuntu, Debian, openSUSE)..."

# ---------------------------------------------------------------------------
# 1. Instalación de paquetes necesarios vía Pacman
# ---------------------------------------------------------------------------
echo "ℹ️ Instalando QEMU, libvirt, virt-manager, virglrenderer, virtiofsd y herramientas auxiliares..."
sudo pacman -S --needed --noconfirm \
    qemu-desktop \
    libvirt \
    virt-manager \
    virt-viewer \
    dnsmasq \
    dmidecode \
    bridge-utils \
    openbsd-netcat \
    iptables-nft \
    nftables \
    edk2-ovmf \
    swtpm \
    tuned \
    acl \
    libosinfo \
    osinfo-db \
    osinfo-db-tools \
    virglrenderer \
    virtiofsd \
    spice-vdagent \
    qemu-guest-agent

# Herramientas opcionales de inspección de discos VM
sudo pacman -S --needed --noconfirm guestfs-tools 2>/dev/null || true

# ---------------------------------------------------------------------------
# 2. Controladores VirtIO para Windows (Opcional)
# ---------------------------------------------------------------------------
if [ "$WITH_WINDOWS" = true ]; then
    echo "ℹ️ Opción --with-windows activada: Descargando controladores VirtIO para Windows..."
    VIRTIO_DIR="$HOME/Descargas/virtio-drivers"
    mkdir -p "$VIRTIO_DIR"
    if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
        echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso..."
        curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" 2>/dev/null || true
    else
        echo "✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
    fi
else
    echo "ℹ️ Omitiendo descarga de drivers Windows (las distribuciones Linux tienen VirtIO nativo en el kernel)."
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
    # npt: Nested Page Tables para paginación por hardware
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_amd.conf > /dev/null
# Configuración KVM para procesadores AMD Ryzen / Zen
options kvm_amd nested=1 avic=1 npt=1
EOF
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd 2>/dev/null || true
elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo "• Optimizando KVM para Intel Core (nested=1, ept=1, vpid=1, pml=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
# Configuración KVM para procesadores Intel Core / Xeon
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
fi

# ---------------------------------------------------------------------------
# 5. Backend de Firewall y Red Libvirt (/etc/libvirt/network.conf y Firewalld)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando backend de firewall e integración de red en libvirt..."

# Resolver conflicto de múltiples firewalls (UFW vs Firewalld)
if systemctl is-active --quiet firewalld && systemctl is-active --quiet ufw; then
    echo "⚠️ Detectados firewalld y ufw activos simultáneamente. UFW bloquea virbr0/vnet por defecto."
    echo "ℹ️ Desactivando UFW para evitar colisiones con Firewalld..."
    sudo systemctl disable --now ufw 2>/dev/null || true
fi

# Con Firewalld activo, el backend recomendado en Arch/CachyOS es "iptables" (mediante iptables-nft)
# para evitar que virtnetworkd cree cadenas nftables independientes que colisionen con las zonas de firewalld.
if [ -f /etc/libvirt/network.conf ]; then
    if systemctl is-active --quiet firewalld || systemctl is-enabled --quiet firewalld; then
        echo "ℹ️ Firewalld detectado: configurando firewall_backend = \"iptables\" (iptables-nft)..."
        sudo sed -i 's/^#*firewall_backend = .*/firewall_backend = "iptables"/' /etc/libvirt/network.conf 2>/dev/null || true
    else
        echo "ℹ️ Firewalld no detectado: manteniendo firewall_backend = \"nftables\"..."
        sudo sed -i 's/^#*firewall_backend = .*/firewall_backend = "nftables"/' /etc/libvirt/network.conf 2>/dev/null || true
    fi
fi

# Configuración de reglas en Firewalld para NAT y puente virtual (virbr0)
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
    echo "ℹ️ Configurando zonas y reenvío NAT en Firewalld para libvirt..."
    sudo firewall-cmd --permanent --zone=libvirt --add-forward 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=public --add-masquerade 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Reglas de reenvío y masquerade aplicadas en Firewalld."
fi

# Si solo se usa UFW (sin firewalld), permitir reenvío y tráfico en virbr0
if command -v ufw >/dev/null 2>&1 && systemctl is-active --quiet ufw && ! systemctl is-active --quiet firewalld; then
    echo "ℹ️ UFW detectado: configurando política de reenvío y permisos para virbr0..."
    if [ -f /etc/default/ufw ]; then
        sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw 2>/dev/null || true
    fi
    sudo ufw route allow in on virbr0 2>/dev/null || true
    sudo ufw allow in on virbr0 2>/dev/null || true
    sudo ufw reload 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 6. Verificación de capacidades KVM del Host
# ---------------------------------------------------------------------------
echo "ℹ️ Verificando capacidades de virtualización del hardware con virt-host-validate..."
virt-host-validate qemu || echo "⚠️ Advertencia: Revisa que la virtualización VT-x / AMD-V esté habilitada en tu BIOS/UEFI."

# ---------------------------------------------------------------------------
# 7. Configuración de Sockets Modulares de Libvirt (Eliminando conflictos)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando daemons modulares de Libvirt (Systemd Socket Activation)..."
# En Arch/CachyOS con libvirt moderno, libvirtd.service monolítico entra en conflicto con los sockets modulares.
# Desactivamos el demonio monolítico heredado:
sudo systemctl stop libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket 2>/dev/null || true
sudo systemctl disable libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket 2>/dev/null || true

# Habilitamos los sockets modulares bajo demanda:
# virtproxyd.socket expone /run/libvirt/libvirt-sock para compatibilidad con virt-manager, virsh y cockpit
sudo systemctl enable --now \
    virtqemud.socket \
    virtnetworkd.socket \
    virtstoraged.socket \
    virtnodedevd.socket \
    virtproxyd.socket 2>/dev/null || true

# ---------------------------------------------------------------------------
# 8. Configuración de Red Virtual NAT y Storage Pool por Defecto
# ---------------------------------------------------------------------------
echo "ℹ️ Asegurando red virtual NAT por defecto (virbr0)..."
sudo systemctl restart virtnetworkd.service 2>/dev/null || true
# Si la red default ya estaba activa, la recargamos para aplicar cambios de backend/firewall
if sudo virsh net-info default 2>/dev/null | grep -q "Activo:.*sí"; then
    sudo virsh net-destroy default 2>/dev/null || true
fi
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Asegurando storage pool por defecto (/var/lib/libvirt/images)..."
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

# ---------------------------------------------------------------------------
# 9. Configuración de Red: Detección segura de Interfaz (Cableada vs Wi-Fi)
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
# 10. Perfil de Rendimiento Tuned (virtual-host) y Deduplicación de Memoria (KSM)
# ---------------------------------------------------------------------------
echo "ℹ️ Aplicando optimizaciones de rendimiento con tuned (virtual-host) y KSM..."
if [ -d /sys/kernel/mm/ksm ]; then
    echo 1 | sudo tee /sys/kernel/mm/ksm/run > /dev/null 2>&1 || true
fi
sudo systemctl enable --now tuned.service 2>/dev/null || true
sudo tuned-adm profile virtual-host 2>/dev/null || true

# ---------------------------------------------------------------------------
# 11. Permisos de Usuario y Listas de Control de Acceso (ACL)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando grupos de usuario (libvirt, kvm) para $TARGET_USER..."
sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt "$TARGET_USER"

echo "ℹ️ Configurando permisos ACL en el directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# ---------------------------------------------------------------------------
# 12. Variable de Entorno LIBVIRT_DEFAULT_URI
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI en el entorno del usuario..."
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p "$HOME/.bashrc.d"
    cat <<EOF > "$HOME/.bashrc.d/virtualization.sh"
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
    echo "✅ Configuración de Virtualización creada en ~/.bashrc.d/virtualization.sh"
else
    if ! grep -q "LIBVIRT_DEFAULT_URI" "$HOME/.bashrc" 2>/dev/null; then
        echo '' >> "$HOME/.bashrc"
        echo '# Configuración KVM/QEMU conectando al modo de sistema por defecto' >> "$HOME/.bashrc"
        echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> "$HOME/.bashrc"
    fi
fi

# ---------------------------------------------------------------------------
# Resumen y Recomendaciones para VMs Linux
# ---------------------------------------------------------------------------
echo "================================================================="
echo "✅ Entorno KVM/QEMU en CachyOS configurado y optimizado con éxito."
echo "================================================================="
echo "💡 GUÍA RÁPIDA DE CONFIGURACIÓN PARA LINUX GUESTS EN VIRT-MANAGER:"
echo "  1. Procesador (CPU):"
echo "     - Modelo: 'host-passthrough' (rendimiento nativo de CPU e instrucciones AVX2/Zen)."
echo "  2. Gráficos y Pantalla (KDE Plasma / GNOME / Wayland fluído):"
echo "     - Pantalla: 'SPICE', Tipo de escucha: 'Ninguno' (socket local Unix)."
echo "     - Activar: 'Aceleración OpenGL'."
echo "     - Video: 'VirtIO' con casilla 'Aceleración 3D' marcada (VirGL)."
echo "  3. Almacenamiento (Disco):"
echo "     - Bus: 'VirtIO' o 'SCSI' con controlador VirtIO SCSI."
echo "     - Rendimiento: Modo de caché 'writeback', Motor de E/S 'io_uring', Descarte 'unmap' (TRIM)."
echo "  4. Compartir Carpetas (Host <-> Guest):"
echo "     - Añadir Hardware -> Sistema de archivos -> Modo de acceso: 'virtiofs' (requiere memoria compartida)."
echo "  5. Dentro de la distribución Linux invitada, instala:"
echo "     - Arch/CachyOS : sudo pacman -S spice-vdagent qemu-guest-agent"
echo "     - Fedora       : sudo dnf install spice-vdagent qemu-guest-agent"
echo "     - Ubuntu/Debian: sudo apt install spice-vdagent qemu-guest-agent"
echo "================================================================="
echo "💡 Recuerda reiniciar o cerrar sesión para aplicar los cambios de grupo (libvirt, kvm)."
echo "================================================================="
