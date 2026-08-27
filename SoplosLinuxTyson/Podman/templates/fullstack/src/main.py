import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

PROJECT_NAME = os.getenv("PROJECT_NAME", "__PROJECT__")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

app = FastAPI(
    title=f"{PROJECT_NAME} API (Fullstack)",
    description=f"API Backend para {PROJECT_NAME} con Traefik y Keycloak sobre Podman + Quadlets en Soplos Linux Tyson",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {
        "project": PROJECT_NAME,
        "environment": ENVIRONMENT,
        "status": "running",
        "message": f"¡API Fullstack de {PROJECT_NAME} activa con Traefik!",
    }

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": PROJECT_NAME,
    }
