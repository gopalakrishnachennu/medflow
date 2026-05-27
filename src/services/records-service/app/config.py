from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "medflow-records-service"
    environment: str = "local"
    log_level: str = "INFO"
    database_url: str = "sqlite:///./records.db"

    class Config:
        env_file = ".env"

settings = Settings()
