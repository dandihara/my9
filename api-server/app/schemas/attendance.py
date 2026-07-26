from datetime import date

from pydantic import BaseModel, Field


class AttendanceCreate(BaseModel):
    game_id: int
    attend_type: str = "stadium"
    is_neutral: bool = False
    my_team_id: int | None = None
    seat_section: str | None = None
    seat_row: str | None = None
    seat_number: str | None = None
    memo: str | None = None
    rating: int | None = Field(default=None, ge=1, le=5)


class AttendanceUpdate(BaseModel):
    my_team_id: int | None = None
    seat_section: str | None = None
    seat_row: str | None = None
    seat_number: str | None = None
    memo: str | None = None
    rating: int | None = Field(default=None, ge=1, le=5)


class AttendanceRead(BaseModel):
    id: int
    user_id: int
    game_id: int
    attend_type: str
    my_team_id: int | None = None
    result_for_my_team: str | None = None
    seat_section: str | None = None
    seat_row: str | None = None
    seat_number: str | None = None
    memo: str | None = None
    rating: int | None = None
    game_date: date | None = None
    away_team_name: str | None = None
    home_team_name: str | None = None

    model_config = {"from_attributes": True}


class AttendanceBattingLeader(BaseModel):
    player_id: int
    player_name: str
    team_id: int
    team_name: str
    games: int
    pa: int
    h: int
    hr: int
    rbi: int
    bb: int
    obp: float
    slg: float
    ops: float


class AttendancePitchingLeader(BaseModel):
    player_id: int
    player_name: str
    team_id: int
    team_name: str
    games: int
    wins: int
    innings_pitched: float
    strikeouts: int
    era: float
    whip: float
    k_per_nine: float
    batting_average_against: float


class AttendanceDecisiveHitByGame(BaseModel):
    game_id: int
    game_date: date
    player_id: int | None = None
    player_name: str | None = None
    team_name: str | None = None


class AttendanceDecisiveHitLeader(BaseModel):
    player_id: int
    player_name: str
    team_name: str
    count: int


class AttendanceBreakdown(BaseModel):
    label: str
    games: int
    wins: int
    draws: int
    losses: int
    win_rate: float


class AttendanceSummaryRead(BaseModel):
    total_records: int
    qualified_games: int
    wins: int
    losses: int
    draws: int
    win_rate: float
    top_batting_players: list[AttendanceBattingLeader]
    top_pitchers: list[AttendancePitchingLeader]
    decisive_hit_leaders: list[AttendanceDecisiveHitLeader]
    decisive_hits: list[AttendanceDecisiveHitByGame]
    weekday_records: list[AttendanceBreakdown]
    stadium_records: list[AttendanceBreakdown]
