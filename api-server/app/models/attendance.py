from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class AttendanceRecord(Base, TimestampMixin):
    __tablename__ = "attendance_records"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    game_id: Mapped[int] = mapped_column(ForeignKey("games.id"), index=True)
    attend_type: Mapped[str] = mapped_column(String(20), default="stadium")
    my_team_id: Mapped[int | None] = mapped_column(ForeignKey("teams.id"), nullable=True)
    result_for_my_team: Mapped[str | None] = mapped_column(String(10), nullable=True)
    seat_section: Mapped[str | None] = mapped_column(String(100), nullable=True)
    seat_row: Mapped[str | None] = mapped_column(String(100), nullable=True)
    seat_number: Mapped[str | None] = mapped_column(String(100), nullable=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
