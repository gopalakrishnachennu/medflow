from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "medflow-notification-service"
    environment: str = "local"
    log_level: str = "INFO"
    database_url: str = "sqlite:///./notification.db"

    class Config:
        env_file = ".env"

settings = Settings()
