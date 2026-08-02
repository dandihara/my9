"""add complete plate appearance fields

Revision ID: d91f3c72a601
Revises: b63df91e2847
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "d91f3c72a601"
down_revision: str | None = "b63df91e2847"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    for table in ("batting_game_stats", "player_season_batting_metrics"):
        op.add_column(
            table,
            sa.Column("sh", sa.Integer(), nullable=False, server_default="0"),
        )
        op.add_column(
            table,
            sa.Column("ci", sa.Integer(), nullable=False, server_default="0"),
        )
    # Re-read the current season so PA includes sacrifice bunts and interference.
    op.execute(
        """
        UPDATE games
        SET boxscore_finalized_at = NULL
        WHERE season_year = EXTRACT(YEAR FROM CURRENT_DATE)
          AND status = 'completed'
        """
    )


def downgrade() -> None:
    for table in ("player_season_batting_metrics", "batting_game_stats"):
        op.drop_column(table, "ci")
        op.drop_column(table, "sh")
