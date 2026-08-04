"""add plate appearance results

Revision ID: f8b21c4d9a10
Revises: e7ac34a9120b
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "f8b21c4d9a10"
down_revision: str | None = "e7ac34a9120b"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "batting_game_stats",
        sa.Column("plate_appearances", sa.JSON(), nullable=True),
    )
    op.execute(
        "UPDATE games SET boxscore_finalized_at = NULL "
        "WHERE season_year = 2026 AND status = 'completed'"
    )


def downgrade() -> None:
    op.drop_column("batting_game_stats", "plate_appearances")
