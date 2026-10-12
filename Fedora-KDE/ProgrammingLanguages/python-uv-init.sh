#!/usr/bin/env bash
# ==============================================================================
# python-uv-init.sh - Creador rápido de proyectos Python aislados con 'uv'
# Optimizado para Fedora 44 (Zero interferencia con el sistema / Btrfs copy mode)
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

# 5. Crear el entorno virtual .venv (Copy mode para Btrfs)
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
    description="Proyecto Python aislado creado con uv en Fedora 44",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "status": "success",
        "message": "¡Hola desde FastAPI gestionado por uv!",
        "system": "Fedora 44 Linux (KDE Plasma 6)"
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

app = typer.Typer(help="CLI moderna creada con uv y Typer")
console = Console()

@app.command()
def hello(name: str = "Desarrollador"):
    """Saluda al usuario con estilo Rich"""
    console.print(f"[bold green]¡Hola {name}![/bold green] Bienvenido a tu CLI en Fedora 44.")

if __name__ == "__main__":
    app()
EOF
        ;;
    4)
        echo -e "${BLUE}📦 Instalando dependencias de Data Science...${NC}"
        UV_LINK_MODE=copy uv add numpy pandas matplotlib
        cat << 'EOF' > main.py
import numpy as np
import pandas as pd

def main():
    print("📊 Entorno de Ciencia de Datos inicializado con 'uv'")
    data = {
        "x": np.arange(1, 6),
        "y": np.random.randint(10, 100, size=5)
    }
    df = pd.DataFrame(data)
    print("\nDataFrame de prueba:")
    print(df)

if __name__ == "__main__":
    main()
EOF
        ;;
    *)
        cat << 'EOF' > main.py
def main():
    print("🚀 Proyecto Python gestionado con 'uv' en Fedora 44 (KDE Plasma 6)")

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

echo -e "\n${BOLD}${GREEN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}✅ Proyecto '${PROJECT_NAME}' creado exitosamente con uv${NC}"
echo -e "${BOLD}${GREEN}=================================================================${NC}"
echo -e "Para comenzar a trabajar:"
echo -e "  1) Entra en la carpeta:   ${CYAN}cd ${PROJECT_NAME}${NC}"
echo -e "  2) Ejecuta la app:        ${CYAN}uv run python main.py${NC} (o ${CYAN}./run.sh${NC})"
echo -e "  3) Añade librerías:       ${CYAN}uv add <libreria>${NC}"
echo -e "  4) Ejecuta tests:         ${CYAN}uv run pytest${NC}"
echo -e "${BOLD}${GREEN}=================================================================${NC}"
