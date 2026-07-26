"""add attendance leagues

Revision ID: d8f4a2c901b7
Revises: c317ad18d2a1
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "d8f4a2c901b7"
down_revision: str | None = "c317ad18d2a1"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table("attendance_leagues",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(60), nullable=False),
        sa.Column("owner_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("invite_code", sa.String(20), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False))
    op.create_index("ix_attendance_leagues_owner_id", "attendance_leagues", ["owner_id"])
    op.create_index("ix_attendance_leagues_invite_code", "attendance_leagues", ["invite_code"], unique=True)
    op.create_table("attendance_league_members",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("league_id", sa.Integer(), sa.ForeignKey("attendance_leagues.id", ondelete="CASCADE"), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("role", sa.String(20), nullable=False, server_default="member"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("league_id", "user_id"))
    op.create_index("ix_attendance_league_members_league_id", "attendance_league_members", ["league_id"])
    op.create_index("ix_attendance_league_members_user_id", "attendance_league_members", ["user_id"])


def downgrade() -> None:
    op.drop_table("attendance_league_members")
    op.drop_table("attendance_leagues")
