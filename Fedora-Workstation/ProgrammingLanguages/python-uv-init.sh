#!/usr/bin/env bash
# ==============================================================================
# python-uv-init.sh - Generador Profesional de Proyectos Python Aislados con 'uv'
# Optimizado para Fedora 45 Workstation (GNOME Shell Wayland / PEP 668)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM | NVMe
# ==============================================================================
# Principios de Diseño:
# - Cero interferencia con el Python nativo del sistema (/usr/bin/python3).
# - Creación ultrarrápida de entornos virtuales aislados (.venv) mediante 'uv'.
# - Optimizado con UV_LINK_MODE="copy" para compatibilidad con snapshots Btrfs y NVMe.
# - Plantillas modernas listas para producción:
#     1) Basic: Aplicación / Script estructurado con tipado y pruebas
#     2) FastAPI: API REST asíncrona moderna con Uvicorn, Pydantic v2 y CORS
#     3) CLI: Herramienta de terminal profesional con Typer y Rich
#     4) Data Science: Análisis de datos con NumPy, Pandas, Polars y Matplotlib
#     5) Worker / Scraper: Cliente HTTP asíncrono con HTTPX, Tenacity y Rich
# - Integración automática con linters (Ruff) y suite de pruebas (Pytest).
# - Soporte interactivo y mediante banderas CLI (--name, --python, --template, --help).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y ESTILOS VISUALES
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}ℹ️  [INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}✅ [OK]${NC}   $1"; }
log_warn()  { echo -e "${YELLOW}⚠️  [WARN]${NC} $1"; }
log_error() { echo -e "${RED}❌ [ERR]${NC}  $1"; }
log_step()  { echo -e "${CYAN}>> [PASO]${NC} $1"; }

# Entorno de rendimiento uv
export UV_LINK_MODE="copy"
export PYTHONUNBUFFERED=1

# ------------------------------------------------------------------------------
# 2. LOCALIZACIÓN DE BINARIO 'uv' Y DETECCIÓN DE PYTHON
# ------------------------------------------------------------------------------
USER_HOME="${HOME:-/home/${USER:-$(id -un)}}"
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH"

get_uv_cmd() {
    if command -v uv &>/dev/null; then
        command -v uv
    elif [ -x "$USER_HOME/.local/share/mise/shims/uv" ]; then
        echo "$USER_HOME/.local/share/mise/shims/uv"
    elif [ -x "$USER_HOME/.local/bin/uv" ]; then
        echo "$USER_HOME/.local/bin/uv"
    else
        echo ""
    fi
}

UV_CMD=$(get_uv_cmd)

# Detección inteligente de versión sugerida de Python
DETECTED_SYS_PY=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "")
if [[ "$DETECTED_SYS_PY" =~ ^3\.(1[0-4])$ ]]; then
    SUGGESTED_PYTHON="$DETECTED_SYS_PY"
else
    # Si el sistema es bleeding edge (ej. 3.15), sugerir 3.13 LTS para máxima compatibilidad PyPI
    SUGGESTED_PYTHON="3.13"
fi

# ------------------------------------------------------------------------------
# 3. AYUDA, ESTADO Y LISTADO DE PLANTILLAS
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🚀 Inicializador de Proyectos Python con 'uv' - Fedora Workstation
   Hardware: AMD Ryzen 7 7730U (16T) | 32GB RAM | NVMe Kioxia | Wayland

Uso:
  $0 [OPCIONES] [NOMBRE_PROYECTO] [VERSION_PYTHON] [PLANTILLA]

Opciones:
  -n, --name <nombre>        Nombre del proyecto y directorio destino.
  -p, --python <versión>     Versión de Python a utilizar (ej: 3.12, 3.13, 3.14).
                             (Por defecto sugerida: $SUGGESTED_PYTHON)
  -t, --template <tipo>      Plantilla inicial (basic, fastapi, cli, data, worker).
  -l, --list                 Muestra la lista descriptiva de plantillas disponibles.
  -s, --status               Diagnostica el gestor 'uv' y el estado del entorno.
  -h, --help                 Muestra esta ayuda.

Plantillas disponibles:
  1) basic   - Aplicación modular estándar con tipado estricto y Pytest
  2) fastapi - API REST moderna asíncrona con Uvicorn, Pydantic v2 y CORS
  3) cli     - Herramienta de terminal moderna con Typer y paneles Rich
  4) data    - Ciencia de datos y análisis (NumPy, Pandas, Polars, Matplotlib)
  5) worker  - Automatización y scraping con HTTPX async y reintentos Tenacity

Ejemplos:
  $0 mi-servicio-api 3.13 fastapi
  $0 --name monitor-cli --template cli
  $0 (Modo interactivo con asistente guiado)
EOF
}

list_templates() {
    cat <<EOF
📋 Plantillas de Proyectos Disponibles:
-----------------------------------------------------------------
  1. basic (app, script)
     • Aplicación estándar con estructura profesional.
     • Dependencias dev: Ruff (linter/formatter) y Pytest.

  2. fastapi (api, rest)
     • Servicio web REST asíncrono de alto rendimiento.
     • Dependencias: FastAPI, Uvicorn (standard), Pydantic v2.
     • Dev: HTTPX (TestClient), Ruff, Pytest.
     • Endpoints incluidos: '/', '/health' y OpenAPI docs automáticos.

  3. cli (terminal, console)
     • Aplicación interactiva por línea de comandos.
     • Dependencias: Typer (CLI parsing) y Rich (estilos y tablas ANSI).
     • Dev: Pytest y Ruff.

  4. data (datascience, analytics)
     • Entorno de análisis numérico y manipulación de datos.
     • Dependencias: NumPy, Pandas, Polars, Matplotlib.
     • Dev: Ruff y Pytest.

  5. worker (scraper, http)
     • Cliente HTTP asíncrono con reintentos y tolerancia a fallos.
     • Dependencias: HTTPX, Tenacity (reintentos), Rich (progreso).
     • Dev: Ruff y Pytest.
-----------------------------------------------------------------
EOF
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE INICIALIZADOR UV (FEDORA WORKSTATION)${NC}"
    echo -e "${CYAN}=================================================================${NC}"
    if [ -n "$UV_CMD" ] && [ -x "$UV_CMD" ]; then
        local uv_ver
        uv_ver=$("$UV_CMD" --version 2>/dev/null || echo "Presente")
        echo -e "• ${BOLD}Binario 'uv':${NC}          ${GREEN}✅ $uv_ver ($UV_CMD)${NC}"
    else
        echo -e "• ${BOLD}Binario 'uv':${NC}          ${RED}❌ No disponible en PATH${NC}"
        echo -e "  Ejecuta './ProgrammingLanguages/python.sh' para aprovisionarlo vía Mise."
    fi

    echo -e "• ${BOLD}Python nativo:${NC}         $(python3 --version 2>/dev/null || echo "No disponible")"
    echo -e "• ${BOLD}Versión sugerida:${NC}      ${CYAN}Python $SUGGESTED_PYTHON${NC}"
    echo -e "• ${BOLD}Modo de enlace:${NC}        ${GREEN}UV_LINK_MODE=$UV_LINK_MODE${NC} (Seguro para Btrfs/NVMe)"
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. PARSEO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
PROJECT_NAME=""
PYTHON_VERSION=""
PROJECT_TYPE=""
TEMPLATE_OPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--status)
            show_status
            exit 0
            ;;
        -l|--list|--list-templates)
            list_templates
            exit 0
            ;;
        -n|--name)
            PROJECT_NAME="${2:-}"
            shift 2
            ;;
        -p|--python)
            PYTHON_VERSION="${2:-}"
            shift 2
            ;;
        -t|--template)
            PROJECT_TYPE="${2:-}"
            shift 2
            ;;
        -*)
            log_error "Opción no reconocida: $1"
            echo "Ejecuta '$0 --help' para ver la sintaxis."
            exit 1
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            elif [ -z "$PYTHON_VERSION" ]; then
                PYTHON_VERSION="$1"
            elif [ -z "$PROJECT_TYPE" ]; then
                PROJECT_TYPE="$1"
            fi
            shift
            ;;
    esac
done

# ------------------------------------------------------------------------------
# 5. VERIFICAR QUE 'uv' ESTÉ DISPONIBLE
# ------------------------------------------------------------------------------
if [ -z "$UV_CMD" ] || [ ! -x "$UV_CMD" ]; then
    log_warn "'uv' no está disponible en el entorno actual."
    echo -e "Intentando localizar en Mise o aprovisionar..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/python.sh" ]; then
        bash "$SCRIPT_DIR/python.sh"
        UV_CMD=$(get_uv_cmd)
    fi

    if [ -z "$UV_CMD" ] || [ ! -x "$UV_CMD" ]; then
        log_error "No se pudo encontrar el gestor 'uv'."
        echo "Asegúrate de instalarlo con: ./ProgrammingLanguages/python.sh"
        exit 1
    fi
fi

echo -e "${CYAN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}🚀 Generador de Proyectos Python Aislados con 'uv'${NC}"
echo -e "   Fedora Workstation | AMD Ryzen 7 7730U | NVMe Kioxia"
echo -e "${CYAN}=================================================================${NC}"

# ------------------------------------------------------------------------------
# 6. ASISTENTE INTERACTIVO / VALIDACIONES
# ------------------------------------------------------------------------------
# 6.1. Nombre del Proyecto
if [ -z "$PROJECT_NAME" ]; then
    echo -e "\n${BOLD}1. Nombre del proyecto:${NC}"
    read -rp "📦 Introduce el nombre (ej: api-servicios, cli-herramienta): " PROJECT_NAME
fi

# Sanitizar y validar nombre
PROJECT_NAME="$(echo "$PROJECT_NAME" | tr -d ' ')"
if [ -z "$PROJECT_NAME" ]; then
    log_error "El nombre del proyecto no puede estar vacío."
    exit 1
fi

if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_error "El nombre contiene caracteres inválidos. Usa solo letras, números, guiones y guiones bajos."
    exit 1
fi

if [ -d "$PROJECT_NAME" ] && [ "$(ls -A "$PROJECT_NAME" 2>/dev/null)" ]; then
    log_error "El directorio '$PROJECT_NAME' ya existe y no está vacío."
    echo "Elige un directorio nuevo o limpia el existente antes de continuar."
    exit 1
fi

# 6.2. Versión de Python
if [ -z "$PYTHON_VERSION" ]; then
    echo -e "\n${BOLD}2. Versión de Python para el proyecto:${NC}"
    echo -e "   (Sugerida: ${CYAN}$SUGGESTED_PYTHON${NC} | También puedes usar 3.12, 3.13, 3.14 o 'system')"
    read -rp "🐍 Versión de Python [$SUGGESTED_PYTHON]: " INPUT_PY
    PYTHON_VERSION="${INPUT_PY:-$SUGGESTED_PYTHON}"
fi

# 6.3. Plantilla del Proyecto
if [ -z "$PROJECT_TYPE" ]; then
    echo -e "\n${BOLD}3. Selecciona la plantilla inicial:${NC}"
    echo "  1) Básico / Minimalista (Script / Aplicación estándar con Pytest & Ruff)"
    echo "  2) FastAPI (API REST asíncrona moderna con Uvicorn, Pydantic v2 y CORS)"
    echo "  3) CLI Tool (Herramienta de terminal interactiva con Typer y Rich)"
    echo "  4) Data Science (Análisis con NumPy, Pandas, Polars y Matplotlib)"
    echo "  5) Worker / Scraper (Automatización y HTTP asíncrono con HTTPX y Tenacity)"
    read -rp "Opción [1]: " INPUT_OPT
    TEMPLATE_OPT="${INPUT_OPT:-1}"
else
    case "${PROJECT_TYPE,,}" in
        2|fastapi|api|rest) TEMPLATE_OPT=2 ;;
        3|cli|terminal|typer) TEMPLATE_OPT=3 ;;
        4|data|datascience|pandas) TEMPLATE_OPT=4 ;;
        5|worker|scraper|http) TEMPLATE_OPT=5 ;;
        1|basic|app|script|*) TEMPLATE_OPT=1 ;;
    esac
fi

# ------------------------------------------------------------------------------
# 7. CREACIÓN E INICIALIZACIÓN CON UV
# ------------------------------------------------------------------------------
log_step "Inicializando proyecto en './${PROJECT_NAME}' con Python ${PYTHON_VERSION}..."
"$UV_CMD" init --python "$PYTHON_VERSION" --app "$PROJECT_NAME"

cd "$PROJECT_NAME"

log_step "Creando entorno virtual aislado (.venv) con UV_LINK_MODE=copy..."
"$UV_CMD" venv --python "$PYTHON_VERSION"

# Asegurar directorios de soporte estándar
mkdir -p tests

# ------------------------------------------------------------------------------
# 8. CONFIGURACIÓN SEGÚN LA PLANTILLA SELECCIONADA
# ------------------------------------------------------------------------------
TEMPLATE_NAME=""
case "$TEMPLATE_OPT" in
    2)
        TEMPLATE_NAME="FastAPI (REST API Moderna)"
        log_step "Instalando dependencias de FastAPI y Pydantic..."
        "$UV_CMD" add fastapi "uvicorn[standard]" pydantic
        log_step "Instalando herramientas de pruebas y calidad (HTTPX, Pytest, Ruff)..."
        "$UV_CMD" add --dev httpx pytest ruff

        cat << 'EOF' > main.py
"""API REST moderna construida con FastAPI y uv en Fedora Workstation."""

import os
import platform
from typing import Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

app = FastAPI(
    title="API REST Aislada con uv",
    description="Microservicio desarrollado sobre Fedora Workstation Linux.",
    version="1.0.0",
)

# Configuración básica de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class MensajeEntrada(BaseModel):
    titulo: str = Field(..., min_length=2, max_length=100, description="Título del mensaje")
    contenido: str = Field(..., description="Cuerpo del mensaje")

@app.get("/")
def raiz() -> Dict[str, Any]:
    """Endpoint principal de bienvenida."""
    return {
        "status": "success",
        "mensaje": "¡Bienvenido a tu API con FastAPI gestionada por uv!",
        "entorno": "Fedora Linux Workstation",
    }

@app.get("/health")
def health_check() -> Dict[str, Any]:
    """Chequeo de salud del servicio y telemetría básica."""
    return {
        "status": "healthy",
        "python_version": platform.python_version(),
        "sistema": platform.system(),
        "release": platform.release(),
        "cpu_count": os.cpu_count(),
    }

@app.post("/eco")
def eco_mensaje(datos: MensajeEntrada) -> Dict[str, Any]:
    """Endpoint que valida y replica la carga de datos recibida."""
    return {
        "procesado": True,
        "eco": datos.model_dump(),
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
EOF

        cat << 'EOF' > tests/test_api.py
from fastapi.testclient import TestClient
from main import app

cliente = TestClient(app)

def test_raiz():
    respuesta = cliente.get("/")
    assert respuesta.status_code == 200
    assert respuesta.json()["status"] == "success"

def test_health():
    respuesta = cliente.get("/health")
    assert respuesta.status_code == 200
    assert respuesta.json()["status"] == "healthy"

def test_eco():
    payload = {"titulo": "Prueba", "contenido": "Contenido de test"}
    respuesta = cliente.post("/eco", json=payload)
    assert respuesta.status_code == 200
    assert respuesta.json()["eco"]["titulo"] == "Prueba"
EOF
        ;;

    3)
        TEMPLATE_NAME="CLI Tool (Typer + Rich)"
        log_step "Instalando dependencias de CLI (Typer & Rich)..."
        "$UV_CMD" add typer rich
        log_step "Instalando herramientas de desarrollo..."
        "$UV_CMD" add --dev pytest ruff

        cat << 'EOF' > main.py
"""Herramienta de terminal moderna construida con Typer y Rich."""

import os
import platform
import typer
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

app = typer.Typer(
    help="CLI moderna creada con Typer y uv en Fedora Workstation",
    add_completion=False,
)
console = Console()

@app.command()
def saludo(
    nombre: str = typer.Option("Desarrollador", "--nombre", "-n", help="Nombre a saludar")
):
    """Muestra un saludo estilizado en la terminal."""
    console.print(Panel.fit(
        f"[bold green]¡Hola, {nombre}![/bold green]\n"
        "[cyan]Tu entorno aislado con 'uv' en Fedora Workstation está listo para producción.[/cyan]",
        title="[bold yellow]Fedora Linux CLI[/bold yellow]",
        border_style="bright_blue",
    ))

@app.command()
def sysinfo():
    """Muestra un resumen de telemetría y especificaciones de la estación."""
    tabla = Table(title="Telemetría de la Estación de Trabajo", border_style="cyan")
    tabla.add_column("Propiedad", style="bold yellow")
    tabla.add_column("Detalle", style="white")

    tabla.add_row("Sistema Operativo", f"{platform.system()} {platform.release()}")
    tabla.add_row("Versión de Python", platform.python_version())
    tabla.add_row("Núcleos de CPU", str(os.cpu_count() or "Desconocido"))
    tabla.add_row("Arquitectura", platform.machine())

    console.print(tabla)

if __name__ == "__main__":
    app()
EOF

        cat << 'EOF' > tests/test_cli.py
from typer.testing import CliRunner
from main import app

runner = CliRunner()

def test_saludo():
    resultado = runner.invoke(app, ["saludo", "--nombre", "Ada"])
    assert resultado.exit_code == 0
    assert "Ada" in resultado.stdout

def test_sysinfo():
    resultado = runner.invoke(app, ["sysinfo"])
    assert resultado.exit_code == 0
    assert "Telemetría" in resultado.stdout
EOF
        ;;

    4)
        TEMPLATE_NAME="Data Science & Analytics (NumPy + Pandas + Polars + Matplotlib)"
        log_step "Instalando librerías científicas y de análisis..."
        "$UV_CMD" add numpy pandas polars matplotlib
        log_step "Instalando herramientas de desarrollo..."
        "$UV_CMD" add --dev pytest ruff

        cat << 'EOF' > main.py
"""Pipeline de demostración y análisis con Pandas y Polars."""

import os
import platform
import numpy as np
import pandas as pd
import polars as pl

def ejecutar_analisis():
    print("=" * 60)
    print("📊 Pipeline de Análisis de Datos (Fedora Workstation)")
    print("=" * 60)

    # 1. Creación de datos con NumPy
    rng = np.random.default_rng(seed=42)
    datos_cpu = rng.normal(loc=45.0, scale=5.0, size=100)

    # 2. Manipulación con Polars (rápido en multihilo)
    df_polars = pl.DataFrame({
        "Muestra": range(1, 101),
        "Temperatura_C": datos_cpu,
    })

    resumen = df_polars.select([
        pl.col("Temperatura_C").mean().alias("Media_C"),
        pl.col("Temperatura_C").min().alias("Min_C"),
        pl.col("Temperatura_C").max().alias("Max_C"),
    ])

    print("\nResumen Estadístico con Polars:")
    print(resumen)

    # 3. Manipulación con Pandas
    df_pandas = df_polars.to_pandas()
    print(f"\nTotal registros analizados: {len(df_pandas)}")
    print(f"Python: {platform.python_version()} | Hilos de CPU: {os.cpu_count()}")
    print("=" * 60)

def main():
    ejecutar_analisis()

if __name__ == "__main__":
    main()
EOF

        cat << 'EOF' > tests/test_data.py
import numpy as np
import polars as pl

def test_dataframe_creation():
    df = pl.DataFrame({"a": [1, 2, 3], "b": [10.0, 20.0, 30.0]})
    assert df.shape == (3, 2)
    assert df["a"].sum() == 6
EOF
        ;;

    5)
        TEMPLATE_NAME="Worker / Scraper (Async HTTPX + Tenacity + Rich)"
        log_step "Instalando dependencias de HTTPX y Tenacity..."
        "$UV_CMD" add httpx tenacity rich
        log_step "Instalando herramientas de desarrollo..."
        "$UV_CMD" add --dev pytest ruff

        cat << 'EOF' > main.py
"""Worker HTTP asíncrono robusto con HTTPX y reintentos Tenacity."""

import asyncio
import httpx
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from tenacity import retry, stop_after_attempt, wait_exponential

console = Console()

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=5))
async def consultar_endpoint(cliente: httpx.AsyncClient, url: str) -> dict:
    """Realiza una petición HTTP con política de reintentos."""
    respuesta = await cliente.get(url, timeout=5.0)
    respuesta.raise_for_status()
    return respuesta.json()

async def tarea_principal():
    console.print("[bold cyan]Iniciando Worker Asíncrono en Fedora Workstation...[/bold cyan]")
    url_test = "https://httpbin.org/get"

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console,
    ) as progress:
        task = progress.add_task(f"Consultando {url_test}...", total=None)

        async with httpx.AsyncClient() as cliente:
            try:
                datos = await consultar_endpoint(cliente, url_test)
                progress.update(task, completed=True)
                console.print(f"[bold green]✅ Petición exitosa.[/bold green] IP detectada: {datos.get('origin')}")
            except Exception as error:
                console.print(f"[bold red]❌ Error durante la petición:[/bold red] {error}")

def main():
    asyncio.run(tarea_principal())

if __name__ == "__main__":
    main()
EOF

        cat << 'EOF' > tests/test_worker.py
import pytest
import httpx

@pytest.mark.asyncio
async def test_dummy_client():
    async with httpx.AsyncClient() as cliente:
        assert cliente is not None
EOF
        ;;

    *)
        TEMPLATE_NAME="Básica / Modular"
        log_step "Configurando plantilla básica modular..."
        "$UV_CMD" add --dev pytest ruff

        cat << 'EOF' > main.py
"""Aplicación Python estándar aislada con uv en Fedora Workstation."""

import os
import platform
import sys

def main() -> None:
    """Punto de entrada principal de la aplicación."""
    print("=" * 60)
    print("🚀 Proyecto Python Aislado con 'uv'")
    print("=" * 60)
    print(f"• Intérprete:    {sys.executable}")
    print(f"• Versión:       {platform.python_version()}")
    print(f"• Plataforma:    {platform.system()} {platform.release()}")
    print(f"• CPU Núcleos:   {os.cpu_count()}")
    print(f"• Cumplimiento:  PEP 668 Aislamiento Absoluto")
    print("=" * 60)
    print("El sistema operativo Fedora permanece 100% limpio y protegido.")

if __name__ == "__main__":
    main()
EOF

        cat << 'EOF' > tests/test_main.py
def test_dummy():
    assert True
EOF
        ;;
esac

# ------------------------------------------------------------------------------
# 9. GENERAR ARCHIVOS DE CONFIGURACIÓN Y CALIDAD (GITIGNORE, RUFF, README)
# ------------------------------------------------------------------------------
log_step "Generando archivos de configuración estándar (.gitignore, .env.example, README.md)..."

cat << 'EOF' > .gitignore
# Entornos virtuales de Python
.venv/
env/
venv/
ENV/

# Byte-compiled / optimizados
__pycache__/
*.py[cod]
*$py.class

# Herramientas de calidad y pruebas
.pytest_cache/
.ruff_cache/
.coverage
htmlcov/
dist/
build/
*.egg-info/

# Variables de entorno secretas
.env
.env.local

# IDEs
.idea/
.vscode/
*.swp
*.swo
EOF

cat << 'EOF' > .env.example
# Variables de entorno del proyecto
APP_ENV=development
APP_DEBUG=true
PORT=8000
EOF

cat << EOF > README.md
# ${PROJECT_NAME}

Proyecto Python aislado desarrollado con **\`uv\`** en **Fedora Workstation**.

- **Plantilla:** ${TEMPLATE_NAME}
- **Python:** ${PYTHON_VERSION}
- **Modo de Enlace:** \`UV_LINK_MODE=copy\` (Optimizado para Btrfs / NVMe)

---

## 🛠️ Flujo de Trabajo con \`uv\`

### 1. Ejecutar la aplicación:
\`\`\`bash
uv run main.py
\`\`\`

### 2. Ejecutar la suite de pruebas:
\`\`\`bash
uv run pytest
\`\`\`

### 3. Verificar calidad y formato con Ruff:
\`\`\`bash
uv run ruff check .
uv run ruff format .
\`\`\`

### 4. Añadir nuevas dependencias:
\`\`\`bash
# Dependencias de producción
uv add <nombre-paquete>

# Dependencias de desarrollo
uv add --dev <nombre-paquete>
\`\`\`

### 5. Activar el entorno virtual manualmente (opcional):
\`\`\`bash
source .venv/bin/activate
\`\`\`
EOF

# Añadir configuración de Ruff y Pytest al pyproject.toml si no está presente
if [ -f pyproject.toml ] && ! grep -q "\[tool.ruff\]" pyproject.toml; then
    cat << 'EOF' >> pyproject.toml

[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
EOF
fi

# ------------------------------------------------------------------------------
# 10. RESUMEN FINAL
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}✅ Proyecto '${PROJECT_NAME}' creado con éxito.${NC}"
echo -e "${CYAN}=================================================================${NC}"
echo -e "  • ${BOLD}Directorio:${NC}      ./${PROJECT_NAME}"
echo -e "  • ${BOLD}Plantilla:${NC}       ${CYAN}${TEMPLATE_NAME}${NC}"
echo -e "  • ${BOLD}Python:${NC}          ${GREEN}${PYTHON_VERSION}${NC} (Aislado en .venv)"
echo -e "  • ${BOLD}Herramientas:${NC}    uv, Ruff, Pytest"
echo -e "-----------------------------------------------------------------"
echo -e "${BOLD}Comandos para comenzar:${NC}"
echo -e "  1. Acceder al directorio:"
echo -e "     ${CYAN}cd ${PROJECT_NAME}${NC}"
echo -e "  2. Ejecutar la aplicación:"
echo -e "     ${CYAN}uv run main.py${NC}"
echo -e "  3. Ejecutar pruebas unitarias:"
echo -e "     ${CYAN}uv run pytest${NC}"
echo -e "  4. Analizar código con Ruff:"
echo -e "     ${CYAN}uv run ruff check .${NC}"
echo -e "${CYAN}=================================================================${NC}\n"
