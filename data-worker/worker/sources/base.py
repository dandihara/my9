from abc import ABC, abstractmethod
from datetime import date
from typing import Any


class BaseballDataSource(ABC):
    @abstractmethod
    async def fetch_schedule(self, target_date: date) -> list[dict[str, Any]]:
        raise NotImplementedError

    @abstractmethod
    async def fetch_live_games(self, target_date: date) -> list[dict[str, Any]]:
        raise NotImplementedError

    @abstractmethod
    async def fetch_boxscore(self, external_game_id: str) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    async def fetch_game_events(self, external_game_id: str) -> list[dict[str, Any]]:
        """Return ordered play-by-play events for a completed game."""
        raise NotImplementedError
