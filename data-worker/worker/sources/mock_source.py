from datetime import date, time
from typing import Any

from worker.sources.base import BaseballDataSource


class MockBaseballDataSource(BaseballDataSource):
    async def fetch_schedule(self, target_date: date) -> list[dict[str, Any]]:
        return [
            {
                "external_source": "mock",
                "external_game_id": f"mock-{target_date.isoformat()}-lg-ob",
                "season_year": target_date.year,
                "game_date": target_date,
                "game_time": time(18, 30),
                "home_team_code": "LG",
                "away_team_code": "OB",
                "stadium_name": "잠실야구장",
                "status": "scheduled",
            }
        ]

    async def fetch_live_games(self, target_date: date) -> list[dict[str, Any]]:
        return [
            {
                "external_source": "mock",
                "external_game_id": f"mock-{target_date.isoformat()}-lg-ob",
                "status": "in_progress",
                "home_score": 3,
                "away_score": 2,
                "inning": 7,
                "inning_half": "top",
                "outs": 1,
                "base_state": "100",
                "description": "7회초 1사 1루",
            }
        ]

    async def fetch_boxscore(self, external_game_id: str) -> dict[str, Any]:
        return {"external_game_id": external_game_id, "batting": [], "pitching": []}

    async def fetch_game_events(self, external_game_id: str) -> list[dict[str, Any]]:
        return []
