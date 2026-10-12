#!/usr/bin/env bash
# ==============================================================================
# python-uv-init.sh - Creador rápido de proyectos Python aislados con 'uv'
# Optimizado para Fedora 44 (Zero interferencia con el sistema / Btrfs copy mode)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Vega 7 / 32 GB RAM)
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

# 5. Crear el entorno virtual .venv (Copy mode para compatibilidad con Btrfs en NVMe)
echo -e "${BLUE}ℹ️ Creando entorno virtual aislado (.venv) con UV_LINK_MODE=copy...${NC}"
UV_LINK_MODE=copy uv venv --python "$PYTHON_VERSION"

# 6. Añadir dependencias y generar archivo principal según plantilla
case "$TEMPLATE_OPT" in
    2)
        echo -e "${BLUE}📦 Instalando dependencias de FastAPI...${NC}"
        UV_LINK_MODE=copy uv add fastapi "uvicorn[standard]" pydantic
        cat << 'EOF' > main.py
from fastapi import FastAPI

app = FastAPI(
    title="API con FastAPI & uv",
    description="Proyecto Python aislado creado con uv en Fedora 44 (KDE Plasma 6)",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "status": "success",
        "message": "¡Hola desde FastAPI gestionado por uv!",
        "system": "Fedora 44 Workstation Linux (KDE Plasma 6 Wayland)"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
EOF
        ;;
    3)
        echo -e "${BLUE}📦 Instalando dependencias de CLI (Typer & Rich)...${NC}"
        UV_LINK_MODE=copy uv add typer rich
        cat << 'EOF' > main.py
import typer
from rich.console import Console
from rich.panel import Panel

app = typer.Typer(help="CLI moderna creada con uv y Typer")
console = Console()

@app.command()
def saludo(nombre: str = "Desarrollador"):
    """Saluda al usuario con estilo Rich."""
    console.print(Panel.fit(
        f"[bold green]¡Bienvenido, {nombre}![/bold green]\n"
        "[cyan]Tu CLI en Python aislado con uv está lista para desarrollo.[/cyan]",
        title="[bold yellow]Fedora 44 KDE Plasma 6 Python CLI[/bold yellow]"
    ))

if __name__ == "__main__":
    app()
EOF
        ;;
    4)
        echo -e "${BLUE}📦 Instalando librerías de Ciencia de Datos...${NC}"
        UV_LINK_MODE=copy uv add numpy pandas matplotlib
        cat << 'EOF' > main.py
import numpy as np
import pandas as pd

def main():
    print("📊 Inicializando análisis con Pandas y NumPy en Fedora 44...")
    datos = {
        "Componente": ["CPU (AMD Ryzen 7 PRO 4750U)", "RAM (32 GB DDR4)", "GPU (AMD Radeon Vega 7)", "Almacenamiento (NVMe Btrfs)"],
        "Topología": ["8 Núcleos / 16 Hilos", "Doble Canal Activo", "Vulkan RADV / VA-API", "UV_LINK_MODE=copy"],
        "Estado": ["Óptimo", "Disponible", "Acelerada por hardware", "Sin reflinks cruzados"]
    }
    df = pd.DataFrame(datos)
    print("\nResumen de la Estación de Trabajo:")
    print(df.to_string(index=False))

if __name__ == "__main__":
    main()
EOF
        ;;
    *)
        cat << 'EOF' > main.py
def main():
    print("🚀 Proyecto Python aislado con uv inicializado correctamente en Fedora 44.")
    print("   El sistema operativo permanece 100% limpio y protegido.")

if __name__ == "__main__":
    main()
EOF
        ;;
esac

# 7. Crear script de conveniencia para ejecutar
cat << 'EOF' > run.sh
#!/bin/bash
set -euo pipefail
# Ejecuta el proyecto usando el entorno virtual gestionado por uv
uv run python main.py "$@"
EOF
chmod +x run.sh

echo -e "\n${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}✅ Proyecto '${PROJECT_NAME}' creado exitosamente con uv.${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}"
echo -e "${BOLD}Para comenzar a trabajar:${NC}"
echo -e "  1. Entra al proyecto:"
echo -e "     ${CYAN}cd ${PROJECT_NAME}${NC}"
echo -e "  2. Ejecuta tu código (uv gestiona el entorno automáticamente):"
echo -e "     ${CYAN}uv run python main.py${NC} (o ${CYAN}./run.sh${NC})"
echo -e "  3. O activa el entorno virtual si prefieres el flujo clásico:"
echo -e "     ${CYAN}source .venv/bin/activate${NC}"
echo -e "  4. Añadir más paquetes en cualquier momento:"
echo -e "     ${CYAN}uv add <nombre-paquete>${NC}"
echo -e "${BOLD}${CYAN}=================================================================${NC}\n"
