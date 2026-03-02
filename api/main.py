from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Routers
from routers import auth
from routers import eventos
from routers import catalogo
from routers import home

app = FastAPI(title="EventControl API")

# CORS

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ROTAS

app.include_router(
    auth.router,
    prefix="/auth",
    tags=["Auth"]
)

app.include_router(
    home.router,
    prefix="/home",
    tags=["Home"]
)


app.include_router(
    catalogo.router,
    prefix="/catalogo",
    tags=["Catálogo"]
)

app.include_router(
    eventos.router,
    prefix="/eventos",
    tags=["Eventos"]
)

# ROOT

@app.get("/")
def root():
    return {"status": "EventControl API online"}
