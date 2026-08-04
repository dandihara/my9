from sqlalchemy import JSON, ForeignKey, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class BattingGameStat(Base, TimestampMixin):
    __tablename__ = "batting_game_stats"

    id: Mapped[int] = mapped_column(primary_key=True)
    game_id: Mapped[int] = mapped_column(ForeignKey("games.id"), index=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id"), index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"))
    batting_order: Mapped[int | None] = mapped_column(Integer, nullable=True)
    position: Mapped[str | None] = mapped_column(String(20), nullable=True)
    ab: Mapped[int] = mapped_column(Integer, default=0)
    r: Mapped[int] = mapped_column(Integer, default=0)
    h: Mapped[int] = mapped_column(Integer, default=0)
    hr: Mapped[int] = mapped_column(Integer, default=0)
    doubles: Mapped[int] = mapped_column(Integer, default=0)
    triples: Mapped[int] = mapped_column(Integer, default=0)
    rbi: Mapped[int] = mapped_column(Integer, default=0)
    bb: Mapped[int] = mapped_column(Integer, default=0)
    hbp: Mapped[int] = mapped_column(Integer, default=0)
    sf: Mapped[int] = mapped_column(Integer, default=0)
    sh: Mapped[int] = mapped_column(Integer, default=0)
    ci: Mapped[int] = mapped_column(Integer, default=0)
    so: Mapped[int] = mapped_column(Integer, default=0)
    sb: Mapped[int] = mapped_column(Integer, default=0)
    avg_after_game: Mapped[float | None] = mapped_column(Numeric(5, 3), nullable=True)
    plate_appearances: Mapped[list[dict] | None] = mapped_column(JSON, nullable=True)


class PitchingGameStat(Base, TimestampMixin):
    __tablename__ = "pitching_game_stats"

    id: Mapped[int] = mapped_column(primary_key=True)
    game_id: Mapped[int] = mapped_column(ForeignKey("games.id"), index=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id"), index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"))
    innings_pitched: Mapped[float | None] = mapped_column(Numeric(4, 1), nullable=True)
    hits: Mapped[int] = mapped_column(Integer, default=0)
    home_runs: Mapped[int] = mapped_column(Integer, default=0)
    batters_faced: Mapped[int] = mapped_column(Integer, default=0)
    runs: Mapped[int] = mapped_column(Integer, default=0)
    earned_runs: Mapped[int] = mapped_column(Integer, default=0)
    walks: Mapped[int] = mapped_column(Integer, default=0)
    strikeouts: Mapped[int] = mapped_column(Integer, default=0)
    pitches: Mapped[int | None] = mapped_column(Integer, nullable=True)
    decision: Mapped[str | None] = mapped_column(String(10), nullable=True)
    era_after_game: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
