from pydantic import BaseModel


class RecentBattingGameRead(BaseModel):
    game_id: int
    game_date: str
    opponent_name: str
    ab: int
    h: int
    hr: int
    rbi: int
    r: int
    bb: int
    so: int
    sb: int
    avg_after_game: float | None = None


class RecentPitchingGameRead(BaseModel):
    game_id: int
    game_date: str
    opponent_name: str
    innings_pitched: float
    earned_runs: int
    runs: int
    hits: int
    walks: int
    strikeouts: int
    decision: str | None = None
    era_after_game: float | None = None


class SeasonBattingPlayerRead(BaseModel):
    player_id: int
    player_name: str
    team_id: int
    team_name: str
    games: int
    pa: int
    ab: int
    r: int
    h: int
    doubles: int
    triples: int
    hr: int
    rbi: int
    bb: int
    hbp: int
    sf: int
    sh: int
    ci: int
    so: int
    sb: int
    avg: float
    obp: float
    slg: float
    ops: float
    estimated_woba: float
    estimated_wrc: float
    estimated_wrc_plus: float
    qualification_pa: int
    is_qualified: bool
    batting_wpa: float = 0
    pitching_wpa: float = 0
    total_wpa: float = 0
    recent_games: list[RecentBattingGameRead] = []


class SeasonBattingRead(BaseModel):
    season_year: int
    as_of_date: str | None = None
    methodology: str
    players: list[SeasonBattingPlayerRead]


class SeasonPitchingPlayerRead(BaseModel):
    player_id: int
    player_name: str
    team_id: int
    team_name: str
    games: int
    wins: int = 0
    losses: int = 0
    holds: int = 0
    saves: int = 0
    innings_pitched: float
    hits: int
    home_runs: int
    batters_faced: int
    runs: int
    earned_runs: int
    walks: int
    strikeouts: int
    pitches: int
    era: float
    whip: float
    k_per_nine: float
    bb_per_nine: float
    k_bb: float
    fip: float
    k_bb_percent: float
    qualification_innings: int
    is_qualified: bool
    batting_wpa: float = 0
    pitching_wpa: float = 0
    total_wpa: float = 0
    recent_games: list[RecentPitchingGameRead] = []


class SeasonPitchingRead(BaseModel):
    season_year: int
    as_of_date: str | None = None
    methodology: str
    players: list[SeasonPitchingPlayerRead]


class SeasonWpaPlayerRead(BaseModel):
    player_id: int
    player_name: str
    team_id: int
    team_name: str
    games: int
    batting_wpa: float
    pitching_wpa: float
    total_wpa: float


class SeasonWpaRead(BaseModel):
    season_year: int
    as_of_date: str | None = None
    players: list[SeasonWpaPlayerRead]
