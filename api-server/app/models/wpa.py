from sqlalchemy import ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class GameEvent(Base, TimestampMixin):
    __tablename__ = "game_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    game_id: Mapped[int] = mapped_column(ForeignKey("games.id"), index=True)
    sequence_no: Mapped[int] = mapped_column(Integer)
    inning: Mapped[int] = mapped_column(Integer)
    inning_half: Mapped[str] = mapped_column(String(10))
    batting_team_id: Mapped[int | None] = mapped_column(ForeignKey("teams.id"), nullable=True)
    fielding_team_id: Mapped[int | None] = mapped_column(ForeignKey("teams.id"), nullable=True)
    batter_id: Mapped[int | None] = mapped_column(ForeignKey("players.id"), nullable=True)
    pitcher_id: Mapped[int | None] = mapped_column(ForeignKey("players.id"), nullable=True)
    outs_before: Mapped[int] = mapped_column(Integer)
    base_state_before: Mapped[str] = mapped_column(String(3), default="000")
    score_diff_before: Mapped[int] = mapped_column(Integer)
    event_type: Mapped[str] = mapped_column(String(50))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    runs_scored: Mapped[int] = mapped_column(Integer, default=0)
    outs_after: Mapped[int] = mapped_column(Integer)
    base_state_after: Mapped[str] = mapped_column(String(3), default="000")
    score_diff_after: Mapped[int] = mapped_column(Integer)


class WinExpectancy(Base, TimestampMixin):
    __tablename__ = "win_expectancy_table"

    id: Mapped[int] = mapped_column(primary_key=True)
    season_year: Mapped[int] = mapped_column(Integer)
    inning: Mapped[int] = mapped_column(Integer)
    inning_half: Mapped[str] = mapped_column(String(10))
    outs: Mapped[int] = mapped_column(Integer)
    base_state: Mapped[str] = mapped_column(String(3))
    score_diff: Mapped[int] = mapped_column(Integer)
    win_expectancy: Mapped[float] = mapped_column(Numeric(6, 5))


class WpaEvent(Base, TimestampMixin):
    __tablename__ = "wpa_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    game_event_id: Mapped[int] = mapped_column(ForeignKey("game_events.id"), unique=True)
    batter_id: Mapped[int | None] = mapped_column(ForeignKey("players.id"), nullable=True)
    pitcher_id: Mapped[int | None] = mapped_column(ForeignKey("players.id"), nullable=True)
    we_before: Mapped[float] = mapped_column(Numeric(6, 5))
    we_after: Mapped[float] = mapped_column(Numeric(6, 5))
    wpa: Mapped[float] = mapped_column(Numeric(7, 5))


class PlayerGameWpa(Base, TimestampMixin):
    __tablename__ = "player_game_wpa"

    id: Mapped[int] = mapped_column(primary_key=True)
    game_id: Mapped[int] = mapped_column(ForeignKey("games.id"), index=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id"), index=True)
    team_id: Mapped[int | None] = mapped_column(ForeignKey("teams.id"), nullable=True)
    batting_wpa: Mapped[float] = mapped_column(Numeric(7, 5), default=0)
    pitching_wpa: Mapped[float] = mapped_column(Numeric(7, 5), default=0)
    total_wpa: Mapped[float] = mapped_column(Numeric(7, 5), default=0)
