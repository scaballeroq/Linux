#!/bin/bash
# ==============================================================================
# python-uv-init.sh - Creador rápido de proyectos Python aislados con 'uv'
# Optimizado para Fedora 44 Workstation (Zero interferencia con el sistema)
# ==============================================================================

set -euo pipefail

# Colores para salida visual
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Sin color

# Verificar que 'uv' esté instalado
if ! command -v uv &>/dev/null; then
    echo -e "${YELLOW}⚠️ 'uv' no está instalado o no se encuentra en el PATH.${NC}"
    echo "Instálalo vía Mise ('mise use -g uv@latest') o con DNF5 ('sudo dnf5 install -y uv')."
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
    echo -e "${YELLOW}❌ Error: El nombre del proyecto no puede estar vacío.${NC}"
    exit 1
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
        fastapi|api) TEMPLATE_OPT=2 ;;
        cli|terminal) TEMPLATE_OPT=3 ;;
        data|datascience) TEMPLATE_OPT=4 ;;
        *) TEMPLATE_OPT=1 ;;
    esac
fi

# 4. Crear e inicializar proyecto con uv
echo -e "\n${BLUE}ℹ️ Inicializando proyecto en ./${PROJECT_NAME} con Python ${PYTHON_VERSION}...${NC}"
uv init --python "$PYTHON_VERSION" --app "$PROJECT_NAME"

cd "$PROJECT_NAME"

# 5. Crear el entorno virtual .venv
echo -e "${BLUE}ℹ️ Creando entorno virtual aislado (.venv)...${NC}"
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
    description="Proyecto Python aislado creado con uv en Fedora 44 Workstation",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "status": "success",
        "message": "¡Hola desde FastAPI gestionado por uv!",
        "system": "Fedora 44 Workstation Linux"
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
        title="[bold yellow]Fedora 44 Workstation Python CLI[/bold yellow]"
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
        "Métrica": ["CPU (Ryzen 7)", "RAM (32 GB)", "GPU (Vega 7)"],
        "Estado": ["Óptimo", "Disponible", "Acelerada"]
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
