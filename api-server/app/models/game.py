from datetime import date, datetime, time

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Time, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class Game(Base, TimestampMixin):
    __tablename__ = "games"
    __table_args__ = (UniqueConstraint("external_source", "external_game_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    season_year: Mapped[int] = mapped_column(Integer, index=True)
    game_date: Mapped[date] = mapped_column(Date, index=True)
    game_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    home_team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"))
    away_team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"))
    stadium_id: Mapped[int | None] = mapped_column(ForeignKey("stadiums.id"), nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="scheduled")
    home_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    away_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    external_source: Mapped[str | None] = mapped_column(String(50), nullable=True)
    external_game_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    boxscore_finalized_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    events_synced_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )


class GameLiveState(Base, TimestampMixin):
    __tablename__ = "game_live_states"

    id: Mapped[int] = mapped_column(primary_key=True)
    game_id: Mapped[int] = mapped_column(ForeignKey("games.id"), unique=True)
    inning: Mapped[int | None] = mapped_column(Integer, nullable=True)
    inning_half: Mapped[str | None] = mapped_column(String(10), nullable=True)
    outs: Mapped[int | None] = mapped_column(Integer, nullable=True)
    base_state: Mapped[str | None] = mapped_column(String(10), nullable=True)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    last_source_updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class GameScoreByInning(Base, TimestampMixin):
    __tablename__ = "game_scores_by_inning"

    id: Mapped[int] = mapped_column(primary_key=True)
    game_id: Mapped[int] = mapped_column(ForeignKey("games.id"), index=True)
    inning: Mapped[int] = mapped_column(Integer)
    home_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    away_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
