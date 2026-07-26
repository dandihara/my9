"""add stolen bases and pitching decision

Revision ID: f41ac9d63b20
Revises: e31b74f0a922
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "f41ac9d63b20"
down_revision: str | None = "e31b74f0a922"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "batting_game_stats",
        sa.Column("sb", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "player_season_batting_metrics",
        sa.Column("sb", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "pitching_game_stats",
        sa.Column("decision", sa.String(length=10), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("pitching_game_stats", "decision")
    op.drop_column("player_season_batting_metrics", "sb")
    op.drop_column("batting_game_stats", "sb")
