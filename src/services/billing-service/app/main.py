from contextlib import asynccontextmanager
from time import perf_counter

from fastapi import Request
from fastapi import FastAPI

from app.logging_config import configure_logging
from app.metrics import REQUEST_COUNT, REQUEST_LATENCY
from app.routes import init_db, router


@asynccontextmanager
async def lifespan(app: FastAPI):
    configure_logging()
    init_db()
    yield


app = FastAPI(title="MedFlow Auth Service", version="0.1.0", lifespan=lifespan)
app.include_router(router)


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = perf_counter()
    response = await call_next(request)
    path = request.url.path
    REQUEST_COUNT.labels(request.method, path, str(response.status_code)).inc()
    REQUEST_LATENCY.labels(request.method, path).observe(perf_counter() - start)
    return response
