from fastapi import APIRouter
from app.config import settings
from app.metrics import metrics_response

router = APIRouter()

def init_db() -> None:
    pass

@router.get("/health")
def health():
    return {"status": "ok", "service": settings.app_name, "environment": settings.environment}

@router.get("/metrics", include_in_schema=False)
def metrics():
    return metrics_response()
