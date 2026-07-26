from pydantic import BaseModel


class GameState(BaseModel):
    inning: int
    inning_half: str
    outs: int
    base_state: str
    score_diff: int


class GameEvent(BaseModel):
    id: int
    before: GameState
    after: GameState
    batter_id: int | None = None
    pitcher_id: int | None = None
    description: str | None = None


class WpaResult(BaseModel):
    event_id: int
    we_before: float
    we_after: float
    wpa: float
    batter_id: int | None = None
    pitcher_id: int | None = None
