from fastapi import FastAPI
import os

app = FastAPI(
    title="__PROJECT__ API",
    description="API FastAPI con PostgreSQL y Redis en Docker (Omarchy)",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "message": "¡Hola desde __PROJECT__ con Postgres y Redis en Docker!",
        "status": "online"
    }

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "redis_configured": bool(os.getenv("REDIS_URL")),
        "database_configured": bool(os.getenv("DATABASE_URL"))
    }
