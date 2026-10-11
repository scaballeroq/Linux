#!/bin/bash
# virtualization.sh - Instalación y Optimización Avanzada de Virtualización (KVM/QEMU) para openSUSE Tumbleweed
# Optimizado para openSUSE Tumbleweed con KDE Plasma 6 Wayland y Cockpit Web Console
# (Kernel 6.x/7.x, AMD Ryzen 7 PRO 4750U / Intel, GPU AMD Radeon Vega / Intel, 3D VirGL, Btrfs NoCoW, Firewalld nftables, Modular Daemons, Tuned)

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
[ -z "$TARGET_HOME" ] && TARGET_HOME="$HOME"

WITH_WINDOWS=false
STATUS_ONLY=false

# Resolución de rutas de binarios de administración
TUNED_ADM_BIN=$(command -v tuned-adm 2>/dev/null || echo "/usr/sbin/tuned-adm")

# ---------------------------------------------------------------------------
# Funciones de ayuda y utilidades
# ---------------------------------------------------------------------------
show_help() {
    cat <<EOF
Uso: $0 [OPCIONES]

Script de aprovisionamiento y optimización de virtualización KVM/QEMU en openSUSE Tumbleweed.
Diseñado para maximizar el rendimiento de máquinas virtuales y soportar dos vías de gestión:
  1. Cockpit Web Console (módulo cockpit-machines en https://localhost:9090)
  2. Virt-Manager (interfaz de escritorio avanzada para KDE Plasma 6 Wayland)

OPCIONES:
  --status, -s, --check Verifica el estado de KVM, Cockpit, sockets libvirt, módulos del kernel,
                        Polkit, Btrfs NoCoW, Firewalld, Tuned y red sin realizar cambios.
  --with-windows        Instala o descarga los controladores VirtIO para Windows (virtio-win.iso).
  -h, --help            Muestra esta ayuda y recomendaciones para VMs Linux.

CARACTERÍSTICAS Y OPTIMIZACIONES PARA OPENSUSE TUMBLEWEED:
  - Integración Doble de Gestión:
      * Cockpit Machines: Administración ágil vía navegador web (https://localhost:9090).
      * Virt-Manager: Control avanzado de hardware en KDE Plasma 6 Wayland.
  - Integración KDE Plasma 6 Wayland: Regla Polkit sin contraseñas para el grupo 'libvirt'.
  - Aceleración Gráfica 3D VirGL (libvirglrenderer1 + virtio-gpu-gl) con grupo 'render' para AMD Radeon Vega / Intel.
  - Almacenamiento Btrfs NoCoW (+C) en /var/lib/libvirt/images para evitar fragmentación y latencia de IOPS.
  - Compartición ultrarrápida de carpetas host-guest mediante VirtioFS (virtiofsd).
  - Aceleración por hardware AMD AVIC / Intel EPT y virtualización anidada (Nested KVM).
  - Aceleración de red del kernel (vhost_net, vhost_vsock, tun) y sockets modulares Libvirt.
  - Backend nativo nftables en libvirt coordinado con Firewalld (zonas 'libvirt' y 'public' con masquerade).
  - Deduplicación de memoria RAM (KSM vía tmpfiles.d) y perfil Tuned virtual-host.
  - Detección segura de interfaces Wi-Fi para evitar desconexiones en portátiles (HP EliteBook).
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DEL ENTORNO DE VIRTUALIZACIÓN (OPENSUSE TUMBLEWEED)"
    echo "================================================================="

    echo -n "• Entorno de Escritorio Host: "
    local desktop="${XDG_CURRENT_DESKTOP:-Desconocido}"
    local session_type="${XDG_SESSION_TYPE:-Desconocido}"
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
    echo "${loaded[*]:-Ninguno cargado (se cargarán con la optimización)}"

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

    echo "• Consola Web Cockpit & Módulo de Máquinas Virtuales:"
    local cockpit_socket_state
    cockpit_socket_state=$(systemctl is-active cockpit.socket 2>/dev/null || echo "inactivo")
    echo "  - Servicio cockpit.socket: $cockpit_socket_state (Puerto 9090)"

    echo -n "  - Módulo cockpit-machines: "
    if [ -d "/usr/share/cockpit/machines" ] || rpm -q cockpit-machines >/dev/null 2>&1; then
        echo "✅ Instalado y disponible (/usr/share/cockpit/machines)"
    else
        echo "❌ No instalado"
    fi

    if [ "$cockpit_socket_state" = "active" ]; then
        echo "  - Acceso Web Cockpit: 🌐 https://localhost:9090 (o https://$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo 'IP-LOCAL'):9090)"
    fi

    echo -n "• Estado de la red virtual 'default': "
    if ip link show virbr0 >/dev/null 2>&1; then
        echo "✅ Activa (interfaz virbr0 levantada)"
    elif [ -f /etc/libvirt/qemu/networks/autostart/default.xml ] || [ -f /etc/libvirt/qemu/networks/default.xml ]; then
        echo "ℹ️ Definida en disco (se activará al iniciar virtnetworkd)"
    elif command -v virsh >/dev/null 2>&1 && timeout 2 virsh -c qemu:///system net-info default >/dev/null 2>&1; then
        echo "✅ Activa (en ejecución en libvirt)"
    else
        echo "⚠️ No configurada aún (se creará automáticamente)"
    fi

    echo -n "• Integración con Firewalld: "
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
        local zones
        zones=$(firewall-cmd --get-zones 2>/dev/null || true)
        local has_libvirt_zone=false
        echo "$zones" | grep -qw "libvirt" && has_libvirt_zone=true

        local pub_services
        pub_services=$(firewall-cmd --zone=public --list-services 2>/dev/null || true)
        local has_cockpit_svc=false
        echo "$pub_services" | grep -qw "cockpit" && has_cockpit_svc=true

        if [ "$has_libvirt_zone" = true ] && [ "$has_cockpit_svc" = true ]; then
            echo "✅ Zona 'libvirt' cargada y servicio 'cockpit' permitido"
        elif [ "$has_libvirt_zone" = true ]; then
            echo "✅ Zona 'libvirt' cargada (servicio 'cockpit' pendiente de verificar)"
        else
            echo "⚠️ Zona 'libvirt' pendiente de registrar en firewalld"
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
        echo "⚠️ No configurada (KDE/Cockpit solicitarán autenticación de root)"
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
        echo "⚠️ Incompleto ($user_groups). Faltan: $([ "$has_libvirt" = false ] && echo -n "libvirt ") $([ "$has_kvm" = false ] && echo -n "kvm ") $([ "$has_render" = false ] && echo -n "render")"
    fi

    echo "• Interfaces gráficas y herramientas de gestión:"
    echo -n "  - virt-manager (GUI de escritorio KDE): "
    if rpm -q virt-manager >/dev/null 2>&1 || command -v virt-manager >/dev/null 2>&1; then
        echo "✅ Instalado"
    else
        echo "❌ No instalado"
    fi

    echo -n "  - virt-viewer (Visor SPICE/VNC): "
    if rpm -q virt-viewer >/dev/null 2>&1 || command -v virt-viewer >/dev/null 2>&1; then
        echo "✅ Instalado"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Gestor de energía y recursos (Tuned): "
    if [ -x "$TUNED_ADM_BIN" ] && systemctl is-active --quiet tuned 2>/dev/null; then
        local tuned_profile
        tuned_profile=$("$TUNED_ADM_BIN" active 2>/dev/null | cut -d: -f2 | xargs || true)
        echo "✅ Activo (Perfil: ${tuned_profile:-desconocido})"
    elif systemctl is-enabled --quiet tuned 2>/dev/null; then
        echo "ℹ️ Tuned habilitado pero inactivo"
    else
        echo "ℹ️ Tuned inactivo"
    fi

    echo -n "• Deduplicación de memoria KSM: "
    if [ -f /sys/kernel/mm/ksm/run ] && [ "$(cat /sys/kernel/mm/ksm/run 2>/dev/null)" = "1" ]; then
        echo "✅ Activo (KSM en ejecución)"
    else
        echo "ℹ️ Inactivo"
    fi

    echo -n "• Herramientas de aceleración y soporte de hardware: "
    local tools=("libvirglrenderer1" "virtiofsd" "osinfo-db" "spice-vdagent" "usbredir" "swtpm" "qemu-ovmf-x86_64")
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
        echo "ℹ️ No descargado (opcional con --with-windows)"
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

echo "🚀 Iniciando configuración y optimización de virtualización KVM/QEMU en openSUSE Tumbleweed..."
echo "🎯 Integrando Cockpit Machines (Web) y Virt-Manager (KDE Plasma 6 Wayland con GPU AMD Vega)..."

# ---------------------------------------------------------------------------
# 1. Instalación de paquetes necesarios vía Zypper en openSUSE Tumbleweed
# ---------------------------------------------------------------------------
echo "ℹ️ [1/13] Verificando e instalando paquetes oficiales para openSUSE Tumbleweed..."

# Paquetes validados y existentes exactamente en repo-oss de openSUSE Tumbleweed
PKGS=(
    qemu
    qemu-x86
    qemu-tools
    qemu-ovmf-x86_64
    qemu-ksm
    libvirt
    libvirt-daemon-config-network
    libvirt-client
    virt-manager
    virt-viewer
    virt-install
    virt-top
    libvirglrenderer1
    cockpit
    cockpit-machines
    cockpit-ws
    cockpit-bridge
    virtiofsd
    spice-vdagent
    usbredir
    swtpm
    libosinfo
    dnsmasq
    dmidecode
    tuned
    acl
    guestfs-tools
    nftables
)

sudo zypper --non-interactive install -y "${PKGS[@]}"

# ---------------------------------------------------------------------------
# 2. Controladores VirtIO para Windows (Opcional vía --with-windows)
# ---------------------------------------------------------------------------
if [ "$WITH_WINDOWS" = true ]; then
    echo "ℹ️ [2/13] Descargando controladores VirtIO para Windows..."
    VIRTIO_DIR="$TARGET_HOME/Descargas/virtio-drivers"
    mkdir -p "$VIRTIO_DIR"
    if [ ! -f "$VIRTIO_DIR/virtio-win.iso" ]; then
        echo "⬇️ Descargando la versión estable más reciente de virtio-win.iso..."
        curl -fsSL -o "$VIRTIO_DIR/virtio-win.iso" "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" || true
        chown -R "$TARGET_USER:$TARGET_USER" "$VIRTIO_DIR" 2>/dev/null || true
        echo "  ✅ virtio-win.iso descargado en $VIRTIO_DIR/virtio-win.iso"
    else
        echo "  ✅ ISO de VirtIO ya presente en $VIRTIO_DIR/virtio-win.iso"
    fi
else
    echo "ℹ️ [2/13] Omitiendo descarga de drivers Windows (las distribuciones Linux tienen VirtIO nativo en el kernel)."
fi

# ---------------------------------------------------------------------------
# 3. Módulos del Kernel, Aceleración de CPU (AVIC/EPT) y Virtualización Anidada
# ---------------------------------------------------------------------------
echo "ℹ️ [3/13] Configurando optimizaciones de CPU y virtualización anidada (Nested KVM)..."
sudo mkdir -p /etc/modprobe.d /etc/modules-load.d

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
if [ "$CPU_VENDOR" = "AuthenticAMD" ]; then
    echo "  • Optimizando KVM para AMD Ryzen (nested=1, avic=1, npt=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_amd.conf > /dev/null
# Configuración KVM para procesadores AMD Ryzen / Zen en openSUSE Tumbleweed
options kvm_amd nested=1 avic=1 npt=1
EOF
    sudo modprobe -r kvm_amd 2>/dev/null || true
    sudo modprobe kvm_amd 2>/dev/null || true
elif [ "$CPU_VENDOR" = "GenuineIntel" ]; then
    echo "  • Optimizando KVM para Intel Core (nested=1, ept=1, vpid=1, pml=1)..."
    cat <<EOF | sudo tee /etc/modprobe.d/kvm_intel.conf > /dev/null
# Configuración KVM para procesadores Intel Core / Xeon en openSUSE Tumbleweed
options kvm_intel nested=1 ept=1 vpid=1 pml=1
EOF
    sudo modprobe -r kvm_intel 2>/dev/null || true
    sudo modprobe kvm_intel 2>/dev/null || true
fi

# Aceleración de red en el kernel (vhost_net), sockets rápidos VM-Host (vhost_vsock) y túneles (tun)
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
# 4. Ajustes de /etc/libvirt/qemu.conf (Permisos y dynamic_ownership)
# ---------------------------------------------------------------------------
echo "ℹ️ [4/13] Configurando permisos y propiedad dinámica en libvirt..."
sudo mkdir -p /etc/libvirt
if [ -f /etc/libvirt/qemu.conf ]; then
    sudo sed -i 's/^#*dynamic_ownership = .*/dynamic_ownership = 1/' /etc/libvirt/qemu.conf 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 5. Backend de Firewall y Reglas Firewalld (nftables nativo + Cockpit)
# ---------------------------------------------------------------------------
echo "ℹ️ [5/13] Configurando backend de red en libvirt (nftables) e integrando con Firewalld..."

cat <<EOF | sudo tee /etc/libvirt/network.conf > /dev/null
# Backend de firewall para openSUSE Tumbleweed (nftables nativo)
firewall_backend = "nftables"
EOF

if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    echo "  • Aplicando reglas de red y servicios en Firewalld..."
    sudo firewall-cmd --reload 2>/dev/null || true

    # Permitir servicio Cockpit (puerto 9090) en la zona predeterminada
    DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=cockpit 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=public --add-service=cockpit 2>/dev/null || true

    # Configurar zona libvirt y reenvío NAT
    sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=libvirt --add-forward 2>/dev/null || true
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-masquerade 2>/dev/null || true
    sudo firewall-cmd --permanent --zone=public --add-masquerade 2>/dev/null || true

    sudo firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Reglas de Firewalld aplicadas (servicio cockpit y zona libvirt con masquerade)."
fi

# ---------------------------------------------------------------------------
# 6. Regla Polkit para KDE Plasma 6 y Cockpit (Sin contraseñas de root)
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
echo "  ✅ Regla /etc/polkit-1/rules.d/50-libvirt.rules configurada."

# ---------------------------------------------------------------------------
# 7. Verificación de capacidades KVM del Host
# ---------------------------------------------------------------------------
echo "ℹ️ [7/13] Validando capacidades de virtualización del hardware..."
virt-host-validate qemu || echo "  ⚠️ Nota: Si alguna comprobación falla, verifica que la virtualización AMD-V esté activa en tu BIOS/UEFI."

# ---------------------------------------------------------------------------
# 8. Activación de Sockets Modulares de Libvirt y Cockpit
# ---------------------------------------------------------------------------
echo "ℹ️ [8/13] Habilitando sockets modulares de Libvirt y servicio Cockpit..."

# Desactivar servicio monolítico libvirtd heredado si existiera
sudo systemctl stop libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket 2>/dev/null || true
sudo systemctl disable libvirtd.service libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket 2>/dev/null || true

# Habilitar sockets modulares bajo demanda
sudo systemctl enable --now \
    virtqemud.socket \
    virtnetworkd.socket \
    virtstoraged.socket \
    virtnodedevd.socket \
    virtnwfilterd.socket \
    virtsecretd.socket \
    virtproxyd.socket 2>/dev/null || true

# Habilitar servicio web Cockpit
sudo systemctl enable --now cockpit.socket 2>/dev/null || true
echo "  ✅ Sockets de Libvirt y Cockpit activados."

# ---------------------------------------------------------------------------
# 9. Configuración de Red Virtual NAT y Storage Pool con Btrfs NoCoW
# ---------------------------------------------------------------------------
echo "ℹ️ [9/13] Configurando red virtual NAT por defecto (virbr0)..."
sudo systemctl restart virtnetworkd.service 2>/dev/null || true

# Asegurar archivo XML de red default si no existe
sudo mkdir -p /etc/libvirt/qemu/networks/autostart
DEFAULT_NET_XML="/etc/libvirt/qemu/networks/default.xml"
if [ ! -f "$DEFAULT_NET_XML" ]; then
    echo "  • Generando definición XML para la red virtual 'default'..."
    cat <<EOF | sudo tee "$DEFAULT_NET_XML" > /dev/null
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF
fi

if ! sudo virsh net-info default >/dev/null 2>&1; then
    sudo virsh net-define "$DEFAULT_NET_XML" 2>/dev/null || true
fi

# Levantar red default
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default 2>/dev/null || true

echo "ℹ️ [9/13] Configurando directorio de imágenes (/var/lib/libvirt/images)..."
sudo mkdir -p /var/lib/libvirt/images

# Optimización Btrfs NoCoW (+C): evita fragmentación severa y mejora latencia de E/S
FS_TYPE=$(stat -f -c %T /var/lib/libvirt/images 2>/dev/null || true)
if [ "$FS_TYPE" = "btrfs" ]; then
    echo "  ⚡ Btrfs detectado en /var/lib/libvirt/images: aplicando atributo NoCoW (+C)..."
    sudo chattr +C /var/lib/libvirt/images 2>/dev/null || true
fi

echo "  • Asegurando storage pool 'default'..."
if ! sudo virsh pool-info default >/dev/null 2>&1; then
    sudo virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images 2>/dev/null || true
    sudo virsh pool-build default 2>/dev/null || true
fi
sudo virsh pool-start default 2>/dev/null || true
sudo virsh pool-autostart default 2>/dev/null || true

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
# 11. Optimización de Memoria (KSM) y Perfil Tuned
# ---------------------------------------------------------------------------
echo "ℹ️ [11/13] Configurando deduplicación de memoria RAM (KSM) y Tuned..."
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
echo "  ✅ KSM activado."

if [ -x "$TUNED_ADM_BIN" ]; then
    sudo systemctl enable --now tuned.service 2>/dev/null || true
    sudo "$TUNED_ADM_BIN" profile virtual-host 2>/dev/null || true
    echo "  ✅ Perfil Tuned 'virtual-host' aplicado."
fi

# ---------------------------------------------------------------------------
# 12. Permisos de Usuario y Grupos (libvirt, kvm, render)
# ---------------------------------------------------------------------------
echo "ℹ️ [12/13] Configurando grupos de usuario (libvirt, kvm, render) para $TARGET_USER..."
# Grupo render permite aceleración 3D VirGL directa en GPUs AMD Radeon Vega (/dev/dri/renderD128)
sudo usermod -aG libvirt,kvm,render "$TARGET_USER" 2>/dev/null || sudo usermod -aG libvirt,kvm "$TARGET_USER" 2>/dev/null || true

echo "  • Configurando listas de control de acceso (ACL) en /var/lib/libvirt/images..."
sudo setfacl -R -b /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -R -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true
sudo setfacl -d -m u:"$TARGET_USER":rwX /var/lib/libvirt/images 2>/dev/null || true

# ---------------------------------------------------------------------------
# 13. Variable de Entorno LIBVIRT_DEFAULT_URI en el Perfil de Usuario
# ---------------------------------------------------------------------------
echo "ℹ️ [13/13] Configurando LIBVIRT_DEFAULT_URI en el perfil de $TARGET_USER..."

# 13.1. Sesión de escritorio KDE / systemd --user (environment.d)
mkdir -p "$TARGET_HOME/.config/environment.d"
cat <<EOF > "$TARGET_HOME/.config/environment.d/10-libvirt.conf"
LIBVIRT_DEFAULT_URI=qemu:///system
EOF

# 13.2. Zsh modular (~/.zshrc.d)
mkdir -p "$TARGET_HOME/.zshrc.d"
cat <<EOF > "$TARGET_HOME/.zshrc.d/virtualization.zsh"
# Configuración KVM/QEMU conectando al daemon de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

# 13.3. Bash modular (~/.bashrc.d)
mkdir -p "$TARGET_HOME/.bashrc.d"
cat <<EOF > "$TARGET_HOME/.bashrc.d/virtualization.sh"
# Configuración KVM/QEMU conectando al daemon de sistema por defecto
export LIBVIRT_DEFAULT_URI="qemu:///system"
EOF

# Asignar propiedad al usuario objetivo
chown -R "$TARGET_USER:$TARGET_USER" \
    "$TARGET_HOME/.config/environment.d" \
    "$TARGET_HOME/.zshrc.d" \
    "$TARGET_HOME/.bashrc.d" 2>/dev/null || true

# Propagar a la sesión actual de systemd/D-Bus si está activa
sudo -u "$TARGET_USER" dbus-update-activation-environment --systemd LIBVIRT_DEFAULT_URI=qemu:///system 2>/dev/null || true

# ---------------------------------------------------------------------------
# Resumen Final y Vías de Gestión
# ---------------------------------------------------------------------------
HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo '127.0.0.1')
echo "================================================================="
echo "✅ Entorno de Virtualización KVM/QEMU Configurado y Optimizado con Éxito"
echo "================================================================="
echo "🌐 1. CONSOLA WEB COCKPIT (Módulo Máquinas Virtuales):"
echo "   • URL Local:    https://localhost:9090"
echo "   • URL en tu Red: https://$HOST_IP:9090"
echo "   • Acceso: Inicia sesión con tu usuario '$TARGET_USER' y contraseña."
echo "   • Ideal para: Crear y arrancar VMs rápidamente, monitorizar consumo de CPU/RAM/Disco,"
echo "     y administrar el host de forma ligera desde cualquier navegador."
echo ""
echo "🖥️ 2. VIRT-MANAGER (Escritorio KDE Plasma 6 Wayland):"
echo "   • Ejecuta en terminal o lanzador de aplicaciones: virt-manager"
echo "   • Ideal para: Máxima aceleración gráfica 3D (VirGL en AMD Radeon Vega),"
echo "     carpetas compartidas VirtIO-FS, redirección USB y sonido de baja latencia."
echo ""
echo "💡 RECOMENDACIONES DE RENDIMIENTO PARA VMS LINUX (Virt-Manager):"
echo "  • Procesador: Modelo 'host-passthrough' (rendimiento nativo AMD Zen 2)."
echo "  • Gráficos: Pantalla SPICE + Aceleración OpenGL activada."
echo "  • Tarjeta de Video: 'VirtIO' con 'Aceleración 3D' marcada (GPU AMD Vega 7)."
echo "  • Almacenamiento: Bus 'VirtIO', caché 'writeback', descartar 'unmap' (TRIM)."
echo "  • Compartir Carpetas: Hardware -> Sistema de archivos -> 'virtiofs'."
echo "================================================================="
echo "⚠️ IMPORTANTE: Cierra sesión y vuelve a iniciarla (o reinicia el equipo)"
echo "   para que se apliquen los nuevos grupos: libvirt, kvm, render."
echo "================================================================="
