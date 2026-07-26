from datetime import date, datetime, time

from pydantic import BaseModel


class TeamRead(BaseModel):
    id: int
    code: str
    name: str
    short_name: str | None = None
    logo_url: str | None = None

    model_config = {"from_attributes": True}


class TeamSeasonSummaryRead(BaseModel):
    season_year: int
    team_id: int
    team_name: str
    rank: int
    games: int
    wins: int
    losses: int
    draws: int
    win_rate: float
    runs_scored: int
    runs_allowed: int
    run_difference: int
    recent_10_wins: int
    recent_10_draws: int
    recent_10_losses: int
    team_batting_average: float = 0
    team_on_base_percentage: float = 0
    team_slugging_percentage: float = 0
    team_ops: float = 0
    team_hits: int = 0
    team_home_runs: int = 0
    team_era: float = 0
    team_whip: float = 0
    team_strikeouts: int = 0


class TeamStandingsRead(BaseModel):
    season_year: int
    as_of_date: date | None = None
    standings: list[TeamSeasonSummaryRead]


class TeamDashboardGameRead(BaseModel):
    game_id: int
    game_date: date
    game_time: time | None = None
    opponent_name: str
    is_home: bool
    stadium_name: str | None = None
    my_score: int | None = None
    opponent_score: int | None = None
    result: str | None = None


class StadiumWeatherRead(BaseModel):
    condition: str
    temperature_c: float | None = None
    weather_code: int | None = None
    is_day: bool = True
    stadium_name: str
    game_id: int
    source: str = "Open-Meteo"
    fetched_at: datetime


class TeamDashboardRead(BaseModel):
    summary: TeamSeasonSummaryRead
    recent_games: list[TeamDashboardGameRead]
    next_game: TeamDashboardGameRead | None = None
    stadium_weather: StadiumWeatherRead | None = None
