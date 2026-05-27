from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "medflow-appointment-service"
    environment: str = "local"
    log_level: str = "INFO"
    database_url: str = "sqlite:///./appointment.db"

    class Config:
        env_file = ".env"

settings = Settings()
