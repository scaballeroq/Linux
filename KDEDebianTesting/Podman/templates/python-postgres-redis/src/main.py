from fastapi import FastAPI

app = FastAPI(title="__PROJECT__ API")

@app.get("/")
def read_root():
    return {"message": "Hola desde __PROJECT__ con Redis!"}

@app.get("/health")
def health_check():
    return {"status": "ok"}
