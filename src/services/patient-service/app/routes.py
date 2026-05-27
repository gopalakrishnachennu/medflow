from fastapi import APIRouter
from app.config import settings
from app.metrics import metrics_response
from sqlalchemy import create_engine
from app.models import Base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

engine_options = {}
if settings.database_url.startswith("sqlite"):
    engine_options = {
        "connect_args": {"check_same_thread": False},
        "poolclass": StaticPool,
    }

engine = create_engine(settings.database_url, **engine_options)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

router = APIRouter()

def init_db() -> None:
    if settings.environment in {"local", "test"}:
        Base.metadata.create_all(bind=engine)

@router.get("/health")
def health():
    return {"status": "ok", "service": settings.app_name, "environment": settings.environment}

@router.get("/metrics", include_in_schema=False)
def metrics():
    return metrics_response()
