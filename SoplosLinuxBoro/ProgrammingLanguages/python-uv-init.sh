#!/bin/bash
# ==============================================================================
# python-uv-init.sh - Creador rápido de proyectos Python aislados con 'uv'
# Optimizado para Soplos Linux Boro Workstation (GNOME Shell Wayland)
# Hardware: AMD Ryzen 7 7730U | 32 GB RAM | SSD NVMe Kioxia 512GB
# ==============================================================================

set -euo pipefail

# Asegurar rutas de usuario y shims de Mise en PATH
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:/usr/bin:$PATH"
export UV_LINK_MODE="${UV_LINK_MODE:-hardlink}"

# Colores para salida visual
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Sin color

show_help() {
    cat <<EOF
🚀 Generador de Proyectos Python Aislados con 'uv' - Soplos Linux Boro Workstation

Uso:
  $0 [NOMBRE_PROYECTO] [VERSION_PYTHON] [TIPO_PLANTILLA]

Argumentos opcionales:
  NOMBRE_PROYECTO     Nombre del directorio/proyecto a crear (ej: mi-api)
  VERSION_PYTHON      Versión de Python a aislar (ej: 3.12, 3.13, 3.11; por defecto: 3.12)
  TIPO_PLANTILLA      Plantilla inicial:
                        - basic (o 1): Script o aplicación minimalista
                        - fastapi (o 2): API REST moderna con FastAPI y Uvicorn
                        - cli (o 3): Herramienta de terminal con Typer y Rich
                        - data (o 4): Ciencia de datos (NumPy, Pandas, Matplotlib)

Opciones:
  -h, --help          Muestra esta ayuda.

Ejemplos:
  $0 mi-api 3.12 fastapi
  $0 mi-cli 3.12 cli
  $0                  # Modo interactivo asistido
EOF
}

# Procesar solicitud de ayuda
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "help" ]; then
    show_help
    exit 0
fi

# Verificar que 'uv' esté instalado
if ! command -v uv &>/dev/null; then
    echo -e "${YELLOW}⚠️ 'uv' no está instalado o no se encuentra en el PATH.${NC}"
    echo "Instálalo vía Mise ('mise use -g uv@latest') o ejecutando ./ProgrammingLanguages/python.sh"
    exit 1
fi

echo -e "${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}🚀 Generador de Proyectos Python con 'uv' (Aislado & Rápido)${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}"

# 1. Obtener nombre del proyecto
PROJECT_NAME="${1:-}"
if [ -z "$PROJECT_NAME" ]; then
    read -rp "📦 Nombre del proyecto (ej: mi-api): " PROJECT_NAME
fi

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Error: El nombre del proyecto no puede estar vacío.${NC}"
    exit 1
fi

if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}⚠️ Advertencia: El directorio './${PROJECT_NAME}' ya existe.${NC}"
    read -rp "¿Deseas continuar en este directorio? (s/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
        echo -e "${RED}Operación cancelada.${NC}"
        exit 0
    fi
fi

# 2. Versión de Python
PYTHON_VERSION="${2:-}"
if [ -z "$PYTHON_VERSION" ]; then
    read -rp "🐍 Versión de Python [3.12]: " PYTHON_VERSION
    PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
fi

# 3. Tipo de proyecto / plantilla
PROJECT_TYPE="${3:-}"
if [ -z "$PROJECT_TYPE" ]; then
    echo -e "\n${BOLD}Selecciona la plantilla inicial:${NC}"
    echo "  1) Básico / Minimalista (Script / App estándar)"
    echo "  2) FastAPI (API REST moderna con Uvicorn)"
    echo "  3) CLI Tool (Herramienta de terminal con Typer y Rich)"
    echo "  4) Data Science / Análisis (Numpy, Pandas, Matplotlib)"
    read -rp "Opción [1]: " TEMPLATE_OPT
    TEMPLATE_OPT="${TEMPLATE_OPT:-1}"
else
    case "$PROJECT_TYPE" in
        fastapi|api|2) TEMPLATE_OPT=2 ;;
        cli|terminal|3) TEMPLATE_OPT=3 ;;
        data|datascience|4) TEMPLATE_OPT=4 ;;
        *) TEMPLATE_OPT=1 ;;
    esac
fi

# 4. Crear e inicializar proyecto con uv
echo -e "\n${BLUE}ℹ️ Inicializando proyecto en ./${PROJECT_NAME} con Python ${PYTHON_VERSION}...${NC}"
if [ ! -d "$PROJECT_NAME" ]; then
    uv init --python "$PYTHON_VERSION" --app "$PROJECT_NAME"
fi

cd "$PROJECT_NAME"

# 5. Crear el entorno virtual .venv (usando enlaces rápidos UV_LINK_MODE)
echo -e "${BLUE}ℹ️ Creando entorno virtual aislado (.venv) con enlace ${UV_LINK_MODE}...${NC}"
uv venv --python "$PYTHON_VERSION"

# 6. Añadir dependencias y generar archivo principal según plantilla
case "$TEMPLATE_OPT" in
    2)
        echo -e "${BLUE}📦 Instalando dependencias de FastAPI...${NC}"
        uv add fastapi "uvicorn[standard]" pydantic
        cat << 'EOF' > main.py
from fastapi import FastAPI

app = FastAPI(
    title="API con FastAPI & uv",
    description="Proyecto Python aislado creado con uv en Soplos Linux Boro",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "status": "success",
        "message": "¡Hola desde FastAPI gestionado por uv!",
        "system": "Soplos Linux Boro (GNOME Shell)"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
EOF
        ;;
    3)
        echo -e "${BLUE}📦 Instalando dependencias de CLI (Typer + Rich)...${NC}"
        uv add typer rich
        cat << 'EOF' > main.py
import typer
from rich.console import Console
from rich.panel import Panel

app = typer.Typer(help="CLI moderna creada con Typer y uv")
console = Console()

@app.command()
def saludo(nombre: str = "Usuario"):
    """Saluda al usuario con estilo."""
    console.print(Panel.fit(
        f"[bold green]¡Bienvenido, {nombre}![/bold green]\n"
        "[cyan]Tu CLI en Python aislado con uv está lista para desarrollo.[/cyan]",
        title="[bold yellow]Soplos Linux Boro Python CLI[/bold yellow]"
    ))

if __name__ == "__main__":
    app()
EOF
        ;;
    4)
        echo -e "${BLUE}📦 Instalando librerías de Ciencia de Datos...${NC}"
        uv add numpy pandas matplotlib
        cat << 'EOF' > main.py
import numpy as np
import pandas as pd

def main():
    print("📊 Inicializando análisis con Pandas y NumPy...")
    datos = {
        "Métrica": ["CPU (AMD Ryzen 7 7730U)", "RAM (32 GB)", "GPU (Radeon Vega 8)"],
        "Estado": ["16 Hilos Activos", "Disponible", "Aceleración VA-API"]
    }
    df = pd.DataFrame(datos)
    print("\nResumen del Sistema:")
    print(df.to_string(index=False))

if __name__ == "__main__":
    main()
EOF
        ;;
    *)
        cat << 'EOF' > main.py
def main():
    print("🚀 Proyecto Python aislado con uv inicializado correctamente.")
    print("   El sistema operativo permanece 100% limpio y protegido.")

if __name__ == "__main__":
    main()
EOF
        ;;
esac

echo -e "\n${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}✅ Proyecto '${PROJECT_NAME}' creado con éxito.${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}Para comenzar a trabajar:${NC}"
echo -e "  1. Entra al proyecto:"
echo -e "     ${CYAN}cd ${PROJECT_NAME}${NC}"
echo -e "  2. Ejecuta tu código (uv gestiona el entorno automáticamente):"
echo -e "     ${CYAN}uv run main.py${NC}"
echo -e "  3. O activa el entorno virtual si prefieres el flujo clásico:"
echo -e "     ${CYAN}source .venv/bin/activate${NC}"
echo -e "  4. Añadir más paquetes en cualquier momento:"
echo -e "     ${CYAN}uv add <nombre-paquete>${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}\n"
