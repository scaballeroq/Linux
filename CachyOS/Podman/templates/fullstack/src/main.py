from fastapi import FastAPI

app = FastAPI(title="__PROJECT_UPPER__")


@app.get("/")
def root():
    return {"message": "Hello from __PROJECT_UPPER__!"}


@app.get("/health")
def health():
    return {"status": "ok"}
