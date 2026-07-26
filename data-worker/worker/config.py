from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class WorkerSettings(BaseSettings):
    sync_database_url: str = "postgresql://seungyo:seungyo_password@localhost:5432/seungyo"
    data_source_mode: str = "mock"
    kbo_base_url: str = "https://www.koreabaseball.com"
    kbo_event_url_template: str = (
        "{base_url}/Schedule/GameCenter/Main.aspx?"
        "gameDate={game_date}&gameId={game_id}&section=REVIEW"
    )
    chrome_binary: str | None = None
    chrome_user_data_dir: str | None = None
    chrome_headless: bool = True
    chrome_keep_open: bool = False
    chrome_page_timeout_seconds: int = 30
    chrome_page_settle_seconds: float = 1.5
    chrome_boxscore_settle_seconds: float = 0.2
    chrome_cache_ttl_seconds: int = 30
    startup_backfill_days: int = 30
    startup_future_schedule_days: int = 30

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> WorkerSettings:
    return WorkerSettings()


settings = get_settings()
