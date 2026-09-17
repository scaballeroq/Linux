#!/bin/bash
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU) para CachyOS
# Optimizado para virtualizar distribuciones Linux (Kernel 7.x, AMD Ryzen/Intel, Niri / Wayland, 3D VirGL, VirtioFS, Modular Daemons)

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
TARGET_HOME="${TARGET_HOME:-$HOME}"
VM_STORAGE_DIR="${VM_STORAGE_DIR:-$TARGET_HOME/Workspace/MaquinasVirtuales}"
WITH_WINDOWS=false
STATUS_ONLY=false
CREATE_BRIDGE=false

# ---------------------------------------------------------------------------
# Funciones de ayuda y utilidades
# ---------------------------------------------------------------------------
show_help() {
    cat <<EOF
Uso: $0 [OPCIONES]

Script de aprovisionamiento y optimización de virtualización KVM/QEMU en CachyOS,
diseñado para maximizar el rendimiento y la integración de distribuciones Linux invitadas.
Optimizado para portátiles AMD Ryzen (HP EliteBook), Niri Compositor y Dank Material Shell.

OPCIONES:
  --status, --check     Verifica el estado de KVM, sockets libvirt, módulos del kernel y red sin realizar cambios.
  --storage-dir=RUTA    Ruta personalizada para imágenes de VMs (por defecto: ~/Workspace/MaquinasVirtuales).
  --with-windows        Descarga también la ISO de controladores VirtIO para Windows (virtio-win.iso).
  --bridge              Crea un puente de red L2 físico (br0) sobre la interfaz Ethernet cableada (opcional).
  -h, --help            Muestra esta ayuda y recomendaciones para VMs Linux.

CARACTERÍSTICAS Y OPTIMIZACIONES:
  - Optimización Btrfs (NOCOW / +C) automática para evitar fragmentación y latencia en discos qcow2/raw.
  - Creación y arranque automático del Storage Pool 'MaquinasVirtuales' de Libvirt en el espacio de trabajo.
  - Soporte 3D VirGL (virglrenderer + virtio-gpu-gl) para escritorios Wayland/X11 fluidos en GPU AMD Vega.
  - Compartición ultrarrápida de carpetas mediante VirtioFS (virtiofsd en Rust).
  - Aceleración por hardware AMD AVIC / Intel EPT y virtualización anidada (Nested KVM).
  - Aceleración de red del kernel (vhost_net, vhost_vsock) y sockets modulares Libvirt 12+ (ahorro de batería).
  - Integración nativa con Firewalld (zonas libvirt y home, sin conflictos de firewall).
  - Respeto a la gestión térmica y de batería en portátiles (coexistencia con power-profiles-daemon y ananicy-cpp).
  - Protección de interfaces Wi-Fi y Ethernet para evitar caídas de red accidentales.
  - Reglas de Polkit para gestionar máquinas virtuales sin solicitudes de contraseña (grupo libvirt).
  - Integración nativa con Niri Compositor (reglas para virt-manager y visores sin recorte de esquinas).
  - Entorno de terminal configurado para Zsh (Dank Material Shell), Wayland y Bash (LIBVIRT_DEFAULT_URI).
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
        if grep -q "^$mod " /proc/modules 2>/dev/null; then
            loaded+=("$mod")
        fi
    done
    echo "${loaded[*]:-Ninguno cargado}"

    echo "• Estado de sockets modulares de Libvirt:"
    local sockets=("virtqemud.socket" "virtnetworkd.socket" "virtstoraged.socket" "virtnodedevd.socket" "virtsecretd.socket" "virtnwfilterd.socket" "virtinterfaced.socket" "virtproxyd.socket")
    for s in "${sockets[@]}"; do
        local state
        state=$(systemctl is-active "$s" 2>/dev/null || true)
        [ -z "$state" ] && state="inactivo"
        echo "  - $s: $state"
    done

    echo -n "• Estado de la red virtual 'default': "
    if command -v virsh >/dev/null 2>&1 && virsh -c qemu:///system net-list --name 2>/dev/null | grep -qx "default"; then
        echo "✅ Activa (iniciada en libvirt con virbr0)"
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
    local tools=("virglrenderer" "virtiofsd" "osinfo-db" "swtpm" "spice-gtk")
    local found_tools=()
    for t in "${tools[@]}"; do
        if pacman -Q "$t" >/dev/null 2>&1; then
            found_tools+=("$t")
        fi
    done
    echo "${found_tools[*]:-Ninguna instalada}"

    echo -n "• Directorio de almacenamiento de VMs ($VM_STORAGE_DIR): "
    if [ -d "$VM_STORAGE_DIR" ]; then
        local fs_type
        fs_type=$(findmnt -n -o FSTYPE -T "$VM_STORAGE_DIR" 2>/dev/null || stat -f -c %T "$VM_STORAGE_DIR" 2>/dev/null || echo "desconocido")
        local is_nocow=false
        if lsattr -d "$VM_STORAGE_DIR" 2>/dev/null | cut -d' ' -f1 | grep -q 'C'; then
            is_nocow=true
        fi

        if [ "$fs_type" = "btrfs" ]; then
            if [ "$is_nocow" = true ]; then
                echo "✅ Btrfs con atributo NOCOW (+C) activo (Óptimo)"
            else
                echo "⚠️ Btrfs detectado SIN NOCOW (Riesgo de fragmentación y sobrecarga de CPU)"
            fi
        else
            echo "✅ Presente (FS: $fs_type)"
        fi
    else
        echo "ℹ️ No creado aún (se aprovisionará al ejecutar el script)"
    fi

    echo -n "• Storage Pool Libvirt 'MaquinasVirtuales': "
    if command -v virsh >/dev/null 2>&1 && virsh -c qemu:///system pool-list --name 2>/dev/null | grep -qx "MaquinasVirtuales"; then
        echo "✅ Activo y registrado"
    else
        echo "ℹ️ No registrado o inactivo"
    fi

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
        --storage-dir=*)
            VM_STORAGE_DIR="${arg#*=}"
            ;;
        --with-windows)
            WITH_WINDOWS=true
            ;;
        --bridge)
            CREATE_BRIDGE=true
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
    iptables \
    nftables \
    edk2-ovmf \
    swtpm \
    acl \
    libosinfo \
    osinfo-db \
    osinfo-db-tools \
    virglrenderer \
    virtiofsd \
    spice-vdagent \
    spice-gtk \
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

# 1. Evitar que NetworkManager interfiera con puentes virtuales de libvirt (virbr*, vnet*)
if [ -d /etc/NetworkManager/conf.d ]; then
    echo "ℹ️ Configurando NetworkManager para excluir interfaces virtuales (virbr*, vnet*)..."
    cat <<EOF | sudo tee /etc/NetworkManager/conf.d/10-libvirt-unmanaged.conf > /dev/null
# Excluir puentes de virtualización para que sean gestionados exclusivamente por libvirt
[keyfile]
unmanaged-devices=interface-name:virbr*;interface-name:vnet*
EOF
    # Eliminar perfiles automáticos huérfanos que NetworkManager haya podido registrar
    nmcli con delete virbr0 2>/dev/null || true
    nmcli general reload 2>/dev/null || true
fi

# 2. Resolver conflicto de múltiples firewalls (UFW vs Firewalld)
if systemctl is-active --quiet firewalld && systemctl is-active --quiet ufw; then
    echo "⚠️ Detectados firewalld y ufw activos simultáneamente. UFW bloquea virbr0/vnet por defecto."
    echo "ℹ️ Desactivando UFW para evitar colisiones con Firewalld..."
    sudo systemctl disable --now ufw 2>/dev/null || true
fi

# 3. Con Firewalld activo, el backend recomendado en CachyOS es "iptables" (mediante iptables-nft)
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

# 4. Configuración de reglas en Firewalld para NAT y puente virtual (virbr0)
if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld; then
    echo "ℹ️ Configurando zonas y reenvío NAT en Firewalld para libvirt..."
    sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=libvirt --add-forward 2>/dev/null || true
    ACTIVE_ZONE=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")
    sudo firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-masquerade 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Reglas de zona libvirt, reenvío y masquerade aplicadas en Firewalld (zona: $ACTIVE_ZONE)."
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
# En CachyOS con libvirt moderno, libvirtd.service monolítico entra en conflicto con los sockets modulares.
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
    virtsecretd.socket \
    virtnwfilterd.socket \
    virtinterfaced.socket \
    virtproxyd.socket 2>/dev/null || true

# ---------------------------------------------------------------------------
# 8. Configuración de Red Virtual NAT, Optimización Btrfs y Storage Pools
# ---------------------------------------------------------------------------
echo "ℹ️ Asegurando red virtual NAT por defecto (virbr0)..."
sudo systemctl restart virtnetworkd.service 2>/dev/null || true

# Definir red default si aún no está registrada en libvirt
if ! virsh -c qemu:///system net-list --all --name 2>/dev/null | grep -qx "default"; then
    if [ -f /etc/libvirt/qemu/networks/default.xml ]; then
        sudo virsh net-define /etc/libvirt/qemu/networks/default.xml 2>/dev/null || true
    fi
fi

# Si la red default ya estaba activa, la reiniciamos para aplicar cambios de backend/firewall
if virsh -c qemu:///system net-list --name 2>/dev/null | grep -qx "default"; then
    sudo virsh net-destroy default 2>/dev/null || true
fi

# Limpieza preventiva de interfaz huérfana virbr0 en el host para evitar "ya está siendo utilizada"
if ip link show virbr0 >/dev/null 2>&1; then
    nmcli con down virbr0 2>/dev/null || true
    nmcli con delete virbr0 2>/dev/null || true
    sudo ip link delete virbr0 2>/dev/null || true
fi

sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ Asegurando storage pool por defecto (/var/lib/libvirt/images)..."
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

echo "ℹ️ Configurando directorio de almacenamiento de VMs: $VM_STORAGE_DIR..."
sudo mkdir -p "$VM_STORAGE_DIR"
sudo chown "$TARGET_USER":kvm "$VM_STORAGE_DIR" 2>/dev/null || sudo chown "$TARGET_USER":"$TARGET_USER" "$VM_STORAGE_DIR"
sudo chmod 775 "$VM_STORAGE_DIR" 2>/dev/null || true

# Detección de Btrfs y aplicación de NOCOW (+C)
FS_TYPE=$(findmnt -n -o FSTYPE -T "$VM_STORAGE_DIR" 2>/dev/null || stat -f -c %T "$VM_STORAGE_DIR" 2>/dev/null || true)
if [ "$FS_TYPE" = "btrfs" ]; then
    echo "• Sistema de archivos Btrfs detectado en $VM_STORAGE_DIR."
    if lsattr -d "$VM_STORAGE_DIR" 2>/dev/null | cut -d' ' -f1 | grep -q 'C'; then
        echo "  ✅ Atributo NOCOW (+C) ya activo en el directorio."
    else
        echo "  ⚙️ Aplicando atributo NOCOW (+C) para evitar fragmentación y compresión innecesaria..."
        sudo chattr +C "$VM_STORAGE_DIR" 2>/dev/null || true
        echo "  ✅ Atributo NOCOW (+C) aplicado con éxito."
    fi

    # Comprobar si existen archivos de disco (.qcow2, .raw, .img) creados con CoW previo
    shopt -s nullglob
    for disk in "$VM_STORAGE_DIR"/*.qcow2 "$VM_STORAGE_DIR"/*.raw "$VM_STORAGE_DIR"/*.img; do
        [ -f "$disk" ] || continue
        if ! lsattr "$disk" 2>/dev/null | cut -d' ' -f1 | grep -q 'C'; then
            local_disk_name=$(basename "$disk")
            echo "  ⚠️ Archivo con CoW activo detectado: $local_disk_name"
            echo "  🔄 Recreando $local_disk_name sin CoW ni compresión (--reflink=never)..."
            cp --reflink=never "$disk" "${disk}.nocow.tmp"
            mv -f "${disk}.nocow.tmp" "$disk"
            sudo chown "$TARGET_USER":kvm "$disk" 2>/dev/null || sudo chown "$TARGET_USER":"$TARGET_USER" "$disk"
            echo "  ✅ $local_disk_name optimizado con NOCOW (+C)."
        fi
    done
    shopt -u nullglob
fi

echo "ℹ️ Configurando y registrando Storage Pool 'MaquinasVirtuales' en Libvirt..."
if ! virsh -c qemu:///system pool-list --all --name 2>/dev/null | grep -qx "MaquinasVirtuales"; then
    echo "• Definiendo pool 'MaquinasVirtuales' en libvirt..."
    sudo virsh pool-define-as MaquinasVirtuales dir --target "$VM_STORAGE_DIR" 2>/dev/null || true
    sudo virsh pool-build MaquinasVirtuales 2>/dev/null || true
fi
sudo virsh pool-start MaquinasVirtuales 2>/dev/null || true
sudo virsh pool-autostart MaquinasVirtuales 2>/dev/null || true
echo "✅ Storage Pool 'MaquinasVirtuales' activo y con inicio automático."

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
        if [ "$CREATE_BRIDGE" = true ]; then
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
        else
            echo "🛡️ Portátil detectado: Para evitar caídas de red o desconfiguración de DHCP al desconectar cables/docks,"
            echo "   la interfaz física permanece intacta. La red NAT ('default' con virbr0) gestiona el tráfico"
            echo "   de forma transparente y segura en cualquier red (Wi-Fi o cable)."
            echo "💡 Si requieres explícitamente un bridge físico L2 para exponer VMs en la LAN, ejecuta: $0 --bridge"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 10. Optimización de Rendimiento y Sysctl (Diseñado para Portátil con CachyOS)
# ---------------------------------------------------------------------------
echo "ℹ️ Aplicando optimizaciones de rendimiento y energía para portátil (CachyOS + DMS)..."
# En un portátil con CachyOS y Dank Material Shell, el perfil térmico y de batería
# es gobernado de forma óptima por power-profiles-daemon y ananicy-cpp. 'tuned' entra
# en conflicto directo con estos servicios, desactiva estados de reposo y degrada la batería.
#
# Con 32 GB de RAM, KSM (Kernel Samepage Merging) se mantiene apagado para no gastar
# ciclos continuos de CPU escaneando páginas de memoria en segundo plano.
if [ -d /sys/kernel/mm/ksm ]; then
    echo 0 | sudo tee /sys/kernel/mm/ksm/run > /dev/null 2>&1 || true
fi

# Asegurar persistencia del reenvío de paquetes IPv4 para conectividad fiable de las VMs
echo "ℹ️ Asegurando persistencia de reenvío de paquetes IPv4 (net.ipv4.ip_forward = 1)..."
cat <<EOF | sudo tee /etc/sysctl.d/99-ipforward.conf > /dev/null
net.ipv4.ip_forward = 1
EOF
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# 11. Permisos de Usuario y Listas de Control de Acceso (ACL)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando grupos de usuario (libvirt, kvm) para $TARGET_USER..."
sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt "$TARGET_USER"

echo "ℹ️ Configurando permisos ACL en directorios de libvirt (/var/lib/libvirt)..."
sudo mkdir -p /var/lib/libvirt/images /var/lib/libvirt/qemu/nvram /var/lib/libvirt/boot
sudo setfacl -R -b /var/lib/libvirt/images /var/lib/libvirt/qemu 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images /var/lib/libvirt/qemu 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images /var/lib/libvirt/qemu 2>/dev/null || true

echo "ℹ️ Configurando permisos ACL para acceso del hipervisor a $VM_STORAGE_DIR..."
sudo setfacl -m u:nobody:rx "$TARGET_HOME" 2>/dev/null || true
if [ -d "$TARGET_HOME/Workspace" ]; then
    sudo setfacl -m u:nobody:rx "$TARGET_HOME/Workspace" 2>/dev/null || true
fi
sudo setfacl -R -m u:nobody:rwX,u:"$TARGET_USER":rwX,g:kvm:rwX "$VM_STORAGE_DIR" 2>/dev/null || true
sudo setfacl -R -d -m u:nobody:rwX,u:"$TARGET_USER":rwX,g:kvm:rwX "$VM_STORAGE_DIR" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 12. Regla de Polkit para Gestión sin Contraseña (Grupo libvirt)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando regla de Polkit para grupo libvirt (acceso sin contraseñas)..."
sudo mkdir -p /etc/polkit-1/rules.d
cat <<'EOF' | sudo tee /etc/polkit-1/rules.d/50-libvirt.rules > /dev/null
/* Permitir a usuarios en grupo libvirt gestionar hipervisores sin solicitar clave */
polkit.addRule(function(action, subject) {
    if ((action.id == "org.libvirt.unix.manage" || action.id.indexOf("org.libvirt") == 0) &&
        subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF

# ---------------------------------------------------------------------------
# 13. Variable de Entorno LIBVIRT_DEFAULT_URI (Wayland, Zsh y Bash)
# ---------------------------------------------------------------------------
echo "ℹ️ Configurando LIBVIRT_DEFAULT_URI para el entorno global, Zsh y Bash..."

# 1. Sesión global del sistema / Wayland / DMS (systemd environment generator)
sudo mkdir -p /etc/environment.d
cat <<EOF | sudo tee /etc/environment.d/10-libvirt.conf > /dev/null
# Configuración KVM/QEMU conectando al modo de sistema por defecto
LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

# 2. Configuración para Zsh (shell predeterminada en CachyOS + DMS)
if [ -d "$HOME/.zshrc.d" ]; then
    cat <<EOF > "$HOME/.zshrc.d/virtualization.zsh"
# Configuración KVM/QEMU conectando al modo de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF
    echo "✅ Configuración de Virtualización creada en ~/.zshrc.d/virtualization.zsh"
elif [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "LIBVIRT_DEFAULT_URI" "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo '# Configuración KVM/QEMU conectando al modo de sistema por defecto' >> "$HOME/.zshrc"
        echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> "$HOME/.zshrc"
    fi
fi

# 3. Configuración para Bash (compatibilidad)
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
# 14. Reglas de Ventana para Niri Compositor (virt-manager y visores de VM)
# ---------------------------------------------------------------------------
NIRI_CONFIG=""
if [ -f "$HOME/.config/niri/config.kdl" ]; then
    NIRI_CONFIG="$HOME/.config/niri/config.kdl"
elif [ -f "$HOME/.config/niri/cfg/rules.kdl" ]; then
    NIRI_CONFIG="$HOME/.config/niri/cfg/rules.kdl"
fi

if [ -n "$NIRI_CONFIG" ]; then
    echo "ℹ️ Niri Compositor detectado ($NIRI_CONFIG): asegurando reglas de ventana para virt-manager y visores..."
    if ! grep -q "virt-manager" "$NIRI_CONFIG" 2>/dev/null; then
        cat <<'EOF' >> "$NIRI_CONFIG"

// Reglas para Gestor de Máquinas Virtuales (virt-manager)
window-rule {
    match app-id=r#"^virt-manager$"# title=r#"^Virtual Machine Manager|Gestor de máquinas virtuales$"#
    default-column-width { proportion 0.5; }
}

window-rule {
    match app-id=r#"^virt-manager$"#
    exclude title=r#"^Virtual Machine Manager|Gestor de máquinas virtuales$"#
    open-floating true
}

// Visor de VM (remote-viewer / virt-viewer): flotante, tamaño inicial y sin esquinas cortadas
window-rule {
    match app-id=r#"^remote-viewer$"#
    match app-id=r#"^virt-viewer$"#
    open-floating true
    default-column-width { fixed 1280; }
    default-window-height { fixed 800; }
    geometry-corner-radius 0
    clip-to-geometry false
}
EOF
        echo "✅ Reglas de ventana añadidas a $NIRI_CONFIG"
        if command -v niri &>/dev/null; then
            niri msg action reload-config 2>/dev/null || true
        fi
    else
        echo "✅ Las reglas para virt-manager ya están presentes en Niri ($NIRI_CONFIG)."
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
echo "  2. Gráficos y Pantalla (Wayland / Niri / GNOME fluido):"
echo "     - Pantalla: 'SPICE', Tipo de escucha: 'Ninguno' (socket local Unix)."
echo "     - Activar: 'Aceleración OpenGL'."
echo "     - Video: 'VirtIO' con casilla 'Aceleración 3D' marcada (VirGL)."
echo "  3. Almacenamiento (Disco):
     - Bus: 'VirtIO' o 'SCSI' con controlador VirtIO SCSI.
     - Storage Pool: 'MaquinasVirtuales' ($VM_STORAGE_DIR) optimizado con Btrfs NOCOW (+C).
     - Rendimiento: Modo de caché 'none' (recomendado en Btrfs NOCOW con O_DIRECT) o 'writeback', Motor de E/S 'io_uring', Descarte 'unmap' (TRIM)."
echo "  4. Compartir Carpetas (Host <-> Guest):"
echo "     - Añadir Hardware -> Sistema de archivos -> Modo de acceso: 'virtiofs' (requiere memoria compartida)."
echo "  5. Dentro de la distribución Linux invitada, instala:"
echo "     - Arch Linux : sudo pacman -S spice-vdagent qemu-guest-agent"
echo "     - Fedora       : sudo dnf install spice-vdagent qemu-guest-agent"
echo "     - Ubuntu/Debian: sudo apt install spice-vdagent qemu-guest-agent"
echo "================================================================="
echo "💡 Recuerda reiniciar o cerrar sesión para aplicar los cambios de grupo (libvirt, kvm)."
echo "💡 NOTA VIRT-MANAGER: Al abrir la interfaz gráfica por primera vez tras reiniciar, asegúrate de"
echo "   que la fila 'QEMU/KVM' muestre estado conectado antes de pulsar 'Crear una nueva máquina virtual'."
echo "================================================================="
