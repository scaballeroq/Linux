#!/usr/bin/env bash
# ==============================================================================
# DIAGNÓSTICO Y HABILITACIÓN DE MICROARQUITECTURA x86-64-v3 EN DEBIAN
# ==============================================================================
# Comprueba la compatibilidad de la CPU con x86-64-v3 (AVX, AVX2, BMI1, BMI2, FMA)
# y la aceleración nativa mediante glibc-hwcaps y variantes de APT en Debian.
# ==============================================================================

set -euo pipefail

APT_CONF_FILE="/etc/apt/apt.conf.d/99enable-amd64v3"

# Función de ayuda
show_help() {
    cat << 'EOF'
Uso: ./Setup/amd64v3.sh [OPCIÓN]

Opciones:
  --status, -s        Comprueba compatibilidad de CPU, soporte glibc-hwcaps y estado de APT (Por defecto).
  --enable, -e        Configura la variante amd64v3 en APT para repositorios compatibles.
  --disable, -d       Deshabilita la variante amd64v3 eliminando la configuración de APT.
  --no-upgrade        Configura APT y actualiza índices sin ejecutar 'dist-upgrade'.
  --help, -h          Muestra este mensaje de ayuda.

Arquitectura:
  - CPU: AMD Ryzen 7 7730U (Zen 3 / Barcelo-R) compatible con x86-64-v3.
  - Debian utiliza glibc-hwcaps (/usr/lib/x86_64-linux-gnu/glibc-hwcaps/x86-64-v3/)
    de manera transparente para bibliotecas optimizadas con AVX2/FMA.
EOF
}

# Comprobación de compatibilidad de CPU
check_cpu_support() {
    local supported=false

    if [ -x /lib64/ld-linux-x86-64.so.2 ]; then
        if /lib64/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q "x86-64-v3 (supported"; then
            supported=true
        fi
    fi

    # Fallback / verificación mediante flags del procesador
    if [ "$supported" = false ] && [ -f /proc/cpuinfo ]; then
        if grep -m1 -E 'avx2' /proc/cpuinfo | grep -q 'bmi2' && grep -m1 -E 'fma' /proc/cpuinfo >/dev/null; then
            supported=true
        fi
    fi

    if [ "$supported" = true ]; then
        echo "✅ CPU compatible con la microarquitectura x86-64-v3 (AVX2, BMI2, FMA soportados)."
        return 0
    else
        echo "❌ ERROR: Este procesador no soporta el conjunto de instrucciones x86-64-v3." >&2
        return 1
    fi
}

# Comprobación de versión de Debian
check_debian_version() {
    if [ ! -f /etc/os-release ]; then
        echo "❌ ERROR: No se puede determinar la distribución (/etc/os-release no encontrado)." >&2
        return 1
    fi

    . /etc/os-release
    echo "ℹ️ Distribución detectada: ${PRETTY_NAME:-Debian}"
}

# Ver estado actual
show_status() {
    echo "=========================================================="
    echo "🔍 ESTADO DE MICROARQUITECTURA x86-64-v3 (DEBIAN)"
    echo "=========================================================="
    
    # 1. Hardware
    echo -n "1. Compatibilidad CPU:   "
    if check_cpu_support >/dev/null 2>&1; then
        echo "Compatible (AVX2 / BMI2 / FMA detectados)"
    else
        echo "NO compatible"
    fi

    # 2. Soporte glibc-hwcaps
    echo -n "2. glibc-hwcaps:         "
    if [ -x /lib64/ld-linux-x86-64.so.2 ] && /lib64/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q "x86-64-v3 (supported"; then
        echo "✅ Activo (Carga transparente de rutas x86-64-v3)"
    else
        echo "ℹ️ No reportado explícitamente por el enlazador dinámico"
    fi

    # 3. Configuración APT
    echo -n "3. Configuración APT:    "
    if [ -f "$APT_CONF_FILE" ] && grep -q 'amd64v3' "$APT_CONF_FILE"; then
        echo "Habilitada ($APT_CONF_FILE)"
    else
        echo "Deshabilitada / No configurada (Estándar en Debian)"
    fi

    # 4. Paquetes instalados
    echo -n "4. Paquetes con v3:      "
    local total_v3
    total_v3=$(dpkg-query -W -f='${Package} ${Architecture} ${Architecture-Variant}\n' 2>/dev/null | grep -c ' amd64v3$' || true)
    echo "$total_v3 paquetes instalados con la variante amd64v3"
    echo "=========================================================="
}

# Deshabilitar amd64v3
disable_amd64v3() {
    echo "ℹ️ Deshabilitando variante amd64v3 en APT..."
    if [ -f "$APT_CONF_FILE" ]; then
        sudo rm -f "$APT_CONF_FILE"
        echo "✅ Archivo $APT_CONF_FILE eliminado."
    else
        echo "ℹ️ El archivo de configuración no existe o ya estaba deshabilitado."
    fi

    echo "ℹ️ Actualizando índices de repositorios..."
    sudo apt update
    echo "✅ amd64v3 deshabilitado."
}

# Habilitar amd64v3
enable_amd64v3() {
    local run_upgrade="${1:-true}"

    echo "🚀 Preparando activación de amd64v3 en Debian..."

    # Validar CPU y versión
    check_cpu_support
    check_debian_version

    # Escribir configuración de APT
    echo "ℹ️ Configurando APT para solicitar variantes 'amd64v3'..."
    echo 'APT::Architecture-Variants "amd64v3";' | sudo tee "$APT_CONF_FILE" > /dev/null
    echo "✅ Archivo generado: $APT_CONF_FILE"

    # Actualizar listas de APT
    echo "ℹ️ Actualizando índices de paquetes..."
    sudo apt update

    if [ "$run_upgrade" = true ]; then
        echo "ℹ️ Comprobando paquetes optimizados para amd64v3 (dist-upgrade)..."
        sudo apt dist-upgrade -y
        echo "✅ Proceso completado."
    else
        echo "ℹ️ Se omitió la actualización automática (--no-upgrade)."
    fi

    echo ""
    show_status
}

# Punto de entrada
main() {
    local action="status"
    local run_upgrade=true

    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --status|-s)
                action="status"
                shift
                ;;
            --disable|-d)
                action="disable"
                shift
                ;;
            --enable|-e)
                action="enable"
                shift
                ;;
            --no-upgrade)
                run_upgrade=false
                shift
                ;;
            *)
                echo "❌ Opción desconocida: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done

    case "$action" in
        status)
            show_status
            ;;
        disable)
            disable_amd64v3
            ;;
        enable)
            enable_amd64v3 "$run_upgrade"
            ;;
    esac
}

main "$@"
