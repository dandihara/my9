from sqlalchemy import Boolean, ForeignKey, Integer, Numeric, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class PlayerSeasonBattingMetric(Base, TimestampMixin):
    __tablename__ = "player_season_batting_metrics"
    __table_args__ = (UniqueConstraint("season_year", "player_id", "team_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    season_year: Mapped[int] = mapped_column(Integer, index=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id"), index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), index=True)
    games: Mapped[int] = mapped_column(Integer, default=0)
    pa: Mapped[int] = mapped_column(Integer, default=0)
    ab: Mapped[int] = mapped_column(Integer, default=0)
    r: Mapped[int] = mapped_column(Integer, default=0)
    h: Mapped[int] = mapped_column(Integer, default=0)
    doubles: Mapped[int] = mapped_column(Integer, default=0)
    triples: Mapped[int] = mapped_column(Integer, default=0)
    hr: Mapped[int] = mapped_column(Integer, default=0)
    rbi: Mapped[int] = mapped_column(Integer, default=0)
    bb: Mapped[int] = mapped_column(Integer, default=0)
    hbp: Mapped[int] = mapped_column(Integer, default=0)
    sf: Mapped[int] = mapped_column(Integer, default=0)
    so: Mapped[int] = mapped_column(Integer, default=0)
    sb: Mapped[int] = mapped_column(Integer, default=0)
    avg: Mapped[float] = mapped_column(Numeric(6, 3), default=0)
    obp: Mapped[float] = mapped_column(Numeric(6, 3), default=0)
    slg: Mapped[float] = mapped_column(Numeric(6, 3), default=0)
    ops: Mapped[float] = mapped_column(Numeric(6, 3), default=0)
    estimated_woba: Mapped[float] = mapped_column(Numeric(6, 3), default=0)
    estimated_wrc: Mapped[float] = mapped_column(Numeric(8, 1), default=0)
    estimated_wrc_plus: Mapped[float] = mapped_column(Numeric(8, 1), default=0)
    qualification_pa: Mapped[int] = mapped_column(Integer, default=0)
    is_qualified: Mapped[bool] = mapped_column(Boolean, default=False)


class PlayerSeasonPitchingMetric(Base, TimestampMixin):
    __tablename__ = "player_season_pitching_metrics"
    __table_args__ = (UniqueConstraint("season_year", "player_id", "team_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    season_year: Mapped[int] = mapped_column(Integer, index=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id"), index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), index=True)
    games: Mapped[int] = mapped_column(Integer, default=0)
    innings_pitched: Mapped[float] = mapped_column(Numeric(7, 1), default=0)
    hits: Mapped[int] = mapped_column(Integer, default=0)
    home_runs: Mapped[int] = mapped_column(Integer, default=0)
    batters_faced: Mapped[int] = mapped_column(Integer, default=0)
    runs: Mapped[int] = mapped_column(Integer, default=0)
    earned_runs: Mapped[int] = mapped_column(Integer, default=0)
    walks: Mapped[int] = mapped_column(Integer, default=0)
    strikeouts: Mapped[int] = mapped_column(Integer, default=0)
    pitches: Mapped[int] = mapped_column(Integer, default=0)
    era: Mapped[float] = mapped_column(Numeric(7, 2), default=0)
    whip: Mapped[float] = mapped_column(Numeric(7, 2), default=0)
    k_per_nine: Mapped[float] = mapped_column(Numeric(7, 2), default=0)
    bb_per_nine: Mapped[float] = mapped_column(Numeric(7, 2), default=0)
    k_bb: Mapped[float] = mapped_column(Numeric(7, 2), default=0)
    fip: Mapped[float] = mapped_column(Numeric(7, 2), default=0)
    k_bb_percent: Mapped[float] = mapped_column(Numeric(7, 1), default=0)
    qualification_innings: Mapped[int] = mapped_column(Integer, default=0)
    is_qualified: Mapped[bool] = mapped_column(Boolean, default=False)


class PlayerSeasonWpaMetric(Base, TimestampMixin):
    __tablename__ = "player_season_wpa_metrics"
    __table_args__ = (UniqueConstraint("season_year", "player_id", "team_id"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    season_year: Mapped[int] = mapped_column(Integer, index=True)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id"), index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), index=True)
    games: Mapped[int] = mapped_column(Integer, default=0)
    batting_wpa: Mapped[float] = mapped_column(Numeric(9, 4), default=0)
    pitching_wpa: Mapped[float] = mapped_column(Numeric(9, 4), default=0)
    total_wpa: Mapped[float] = mapped_column(Numeric(9, 4), default=0)
