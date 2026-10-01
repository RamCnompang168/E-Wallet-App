from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    database_url: str = 'postgresql+asyncpg://novapay:novapay@localhost:5432/novapay'
    jwt_secret: str = 'replace-me-with-a-32-byte-secret'
    jwt_algorithm: str = 'HS256'
    model_config = SettingsConfigDict(env_file='.env', extra='ignore')

settings = Settings()
