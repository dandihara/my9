from datetime import date, time

from pydantic import BaseModel


class GameRead(BaseModel):
    id: int
    season_year: int
    game_date: date
    game_time: time | None = None
    home_team_id: int
    home_team_name: str | None = None
    away_team_id: int
    away_team_name: str | None = None
    stadium_id: int | None = None
    stadium_name: str | None = None
    status: str
    home_score: int | None = None
    away_score: int | None = None
    external_game_id: str | None = None

    model_config = {"from_attributes": True}


class BattingStatRead(BaseModel):
    player_id: int
    player_name: str
    team_id: int
    team_name: str
    batting_order: int | None = None
    position: str | None = None
    ab: int
    r: int
    h: int
    hr: int
    rbi: int
    bb: int
    so: int
    avg_after_game: float | None = None
    decisive_hit: bool = False
    walkoff_home_run: bool = False


class PitchingStatRead(BaseModel):
    player_id: int
    player_name: str
    team_id: int
    team_name: str
    innings_pitched: float | None = None
    hits: int
    runs: int
    earned_runs: int
    walks: int
    strikeouts: int
    pitches: int | None = None
    era_after_game: float | None = None


class PlateAppearanceRead(BaseModel):
    sequence_no: int
    inning: int
    inning_half: str
    batting_team_id: int | None = None
    batter_id: int | None = None
    batter_name: str | None = None
    event_type: str
    description: str | None = None
    runs_scored: int = 0


class GameStatsRead(BaseModel):
    batting: list[BattingStatRead]
    pitching: list[PitchingStatRead]
    plate_appearances: list[PlateAppearanceRead] = []


class LiveGameRead(BaseModel):
    game: GameRead
    inning: int | None = None
    inning_half: str | None = None
    outs: int | None = None
    base_state: str | None = None
    description: str | None = None
