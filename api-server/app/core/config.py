from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "seungyo-app"
    env: str = "local"
    database_url: str = "postgresql+asyncpg://seungyo:seungyo_password@localhost:5432/seungyo"
    secret_key: str = "change-this-secret-key"
    access_token_expire_minutes: int = 43200
    cors_origins: list[str] = ["*"]
    seed_test_user: bool = True

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def alembic_database_url(self) -> str:
        # Alembic runs migrations with a synchronous SQLAlchemy engine.
        # The application uses asyncpg at runtime, so switch Alembic to psycopg3 here.
        return self.database_url.replace("+asyncpg", "+psycopg", 1)


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
