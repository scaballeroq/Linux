from fastapi import FastAPI

app = FastAPI(
    title="__PROJECT__ API",
    description="API de desarrollo para __PROJECT__ en Omarchy",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {
        "message": "¡Hola desde __PROJECT__ en Docker (Omarchy)!",
        "status": "online"
    }

@app.get("/health")
def health_check():
    return {"status": "ok"}
