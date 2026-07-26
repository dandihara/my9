from datetime import date

from sqlalchemy import Date, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class Player(Base, TimestampMixin):
    __tablename__ = "players"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(100), index=True)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    throwing_hand: Mapped[str | None] = mapped_column(String(10), nullable=True)
    batting_hand: Mapped[str | None] = mapped_column(String(10), nullable=True)
    external_player_id: Mapped[str | None] = mapped_column(String(100), unique=True, nullable=True)
