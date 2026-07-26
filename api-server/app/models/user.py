from sqlalchemy import Boolean, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    nickname: Mapped[str | None] = mapped_column(String(50), nullable=True)
    my_team_id: Mapped[int | None] = mapped_column(ForeignKey("teams.id"), nullable=True)
    device_login_key: Mapped[str | None] = mapped_column(String(200), unique=True, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)


class Device(Base, TimestampMixin):
    __tablename__ = "devices"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    platform: Mapped[str] = mapped_column(String(20))
    fcm_token: Mapped[str | None] = mapped_column(String(500), nullable=True)
    app_version: Mapped[str | None] = mapped_column(String(50), nullable=True)
