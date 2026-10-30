#!/usr/bin/env bash
# ==============================================================================
# HABILITACIÓN DE ARQUITECTURA amd64v3 (x86-64-v3) EN UBUNTU (>= 26.04)
# ==============================================================================
# Permite descargar y ejecutar binarios y librerías compilados específicamente
# para la microarquitectura x86-64-v3 (instrucciones AVX2, FMA, BMI1, BMI2).
# ==============================================================================

set -euo pipefail

APT_CONF_FILE="/etc/apt/apt.conf.d/99enable-amd64v3"

# Función de ayuda
show_help() {
    cat << 'EOF'
Uso: ./Setup/amd64v3.sh [OPCIÓN]

Opciones:
  --enable, -e        Habilita la variante amd64v3, actualiza los índices y migra los paquetes (Por defecto).
  --status, -s        Comprueba la compatibilidad de la CPU, estado de APT y paquetes amd64v3 instalados.
  --disable, -d       Deshabilita la variante amd64v3 eliminando la configuración de APT.
  --no-upgrade        Configura APT y actualiza índices sin ejecutar 'dist-upgrade'.
  --help, -h          Muestra este mensaje de ayuda.

Requisitos:
  - CPU compatible con x86-64-v3 (AVX, AVX2, BMI1, BMI2, FMA).
  - Ubuntu 26.04 LTS (resolute) o superior (ej. 26.10 stonking).
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

# Comprobación de versión de Ubuntu
check_ubuntu_version() {
    if [ ! -f /etc/os-release ]; then
        echo "❌ ERROR: No se puede determinar la distribución (/etc/os-release no encontrado)." >&2
        return 1
    fi

    . /etc/os-release
    if [ "${ID:-}" != "ubuntu" ]; then
        echo "⚠️ ADVERTENCIA: Esta distribución no es Ubuntu ($ID). La variante amd64v3 oficial de Canonical requiere Ubuntu." >&2
    fi

    local version_id="${VERSION_ID:-0}"
    # Se requiere Ubuntu 26.04 o superior
    local major=$(echo "$version_id" | cut -d. -f1)
    if [ "$major" -lt 26 ] 2>/dev/null; then
        echo "⚠️ ADVERTENCIA: La paquetería nativa 'amd64v3' requiere Ubuntu 26.04 LTS o posterior. Tu versión detectada es $version_id." >&2
    fi
}

# Ver estado actual
show_status() {
    echo "=========================================================="
    echo "🔍 ESTADO DE ARQUITECTURA amd64v3"
    echo "=========================================================="
    
    # 1. Hardware
    echo -n "1. Compatibilidad CPU: "
    if check_cpu_support >/dev/null 2>&1; then
        echo "Compatible (AVX2 / BMI2 / FMA detectados)"
    else
        echo "NO compatible"
    fi

    # 2. Configuración APT
    echo -n "2. Configuración APT:  "
    if [ -f "$APT_CONF_FILE" ] && grep -q 'amd64v3' "$APT_CONF_FILE"; then
        echo "Habilitada ($APT_CONF_FILE)"
    else
        echo "Deshabilitada / No configurada"
    fi

    # 3. Paquetes instalados
    echo -n "3. Paquetes amd64v3:   "
    local total_v3
    total_v3=$(dpkg-query -W -f='${Package} ${Architecture} ${Architecture-Variant}\n' 2>/dev/null | grep -c ' amd64v3$' || true)
    echo "$total_v3 paquetes instalados con la variante amd64v3"

    if [ "$total_v3" -gt 0 ]; then
        echo ""
        echo "📦 Muestra de paquetes amd64v3 instalados:"
        (dpkg-query -W -f=' - ${Package} (${Architecture-Variant})\n' 2>/dev/null | grep 'amd64v3' || true) | head -n 10 || true
        if [ "$total_v3" -gt 10 ]; then
            echo "   ... y $((total_v3 - 10)) paquetes más."
        fi
    fi
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
    echo "✅ amd64v3 deshabilitado. (Los paquetes ya instalados se mantendrán hasta su próxima actualización a la rama genérica)."
}

# Habilitar amd64v3
enable_amd64v3() {
    local run_upgrade="${1:-true}"

    echo "🚀 Preparando activación de amd64v3 en Ubuntu..."

    # Validar CPU y versión
    check_cpu_support
    check_ubuntu_version

    # Escribir configuración de APT
    echo "ℹ️ Configurando APT para solicitar variantes 'amd64v3'..."
    echo 'APT::Architecture-Variants "amd64v3";' | sudo tee "$APT_CONF_FILE" > /dev/null
    echo "✅ Archivo generado: $APT_CONF_FILE"

    # Actualizar listas de APT
    echo "ℹ️ Actualizando índices de paquetes desde el archivo oficial de Ubuntu..."
    sudo apt update

    if [ "$run_upgrade" = true ]; then
        echo "ℹ️ Descargando e instalando paquetes optimizados para amd64v3 (dist-upgrade)..."
        sudo apt dist-upgrade -y
        echo "✅ Migración a amd64v3 completada."
    else
        echo "ℹ️ Se omitió la actualización automática (--no-upgrade)."
        echo "   Ejecuta 'sudo apt dist-upgrade' cuando desees aplicar los paquetes v3."
    fi

    echo ""
    show_status
}

# Punto de entrada
main() {
    local action="enable"
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
