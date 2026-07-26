from datetime import datetime

from pydantic import BaseModel, Field


class LeagueCreate(BaseModel):
    name: str = Field(min_length=2, max_length=60)


class LeagueJoin(BaseModel):
    invite_code: str = Field(min_length=6, max_length=20)


class LeagueRead(BaseModel):
    id: int
    name: str
    owner_id: int
    invite_code: str
    member_count: int
    created_at: datetime


class LeagueRankingRead(BaseModel):
    rank: int
    user_id: int
    username: str
    nickname: str | None
    games: int
    wins: int
    draws: int
    losses: int
    win_rate: float


class LeagueDetailRead(LeagueRead):
    rankings: list[LeagueRankingRead]
